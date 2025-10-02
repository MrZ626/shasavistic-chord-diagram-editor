local abs = math.abs

local dimData = {
    [0] = { freq = 1 }, -- 0D
    { freq = 2 / 1 },   -- 1D Octave
    { freq = 3 / 2 },   -- 2D Fifth
    { freq = 5 / 4 },   -- 3D Third
    { freq = 7 / 4 },   -- 4D Minor Seventh
    { freq = 11 / 4 },  -- 5D
    { freq = 13 / 4 },  -- 6D
    { freq = 17 / 4 },  -- 7D
    { freq = 19 / 4 },  -- 8D
    { freq = 23 / 4 },  -- 9D
    { freq = 29 / 4 },  -- 10D
    { freq = 31 / 4 },  -- 11D
    { freq = 37 / 8 },  -- 12D
    { freq = 41 / 8 },  -- 13D
    { freq = 43 / 8 },  -- 14D
    { freq = 47 / 8 },  -- 15D
    { freq = 53 / 8 },  -- 16D
    { freq = 59 / 8 },  -- 17D
    { freq = 61 / 8 },  -- 18D
    { freq = 67 / 16 }, -- 19D
    { freq = 71 / 16 }, -- 20D
    { freq = 73 / 16 }, -- 21D
    { freq = 79 / 16 }, -- 22D
    { freq = 83 / 16 }, -- 23D
}
for i = 0, #dimData do
    local dim = dimData[i]
    dim.yStep = -math.log(dim.freq, 2)
    dimData[-i] = {
        freq = 1 / dim.freq,
        yStep = -dim.yStep,
    }
end

local ins = table.insert

---@alias SSVC.Dim number

---@class SSVC.Note
---@field d? SSVC.Dim
---@field mode? 'skip' | 'mute' | 'tense' | 'pink'
---@field bias? number
---@field base? 'l' | 'r'
---@field extended? true
---@field pitch? number GUI use only
---@field [number] SSVC.Note

---@class SSVC.Shape
---@field texture string
---@field _layer number
---@field x number
---@field y number
---@field w number
---@field h number

---@type SSVC.Shape[]
local drawBuffer

---@class SSVC.Environment
local env = {
    bodyW = .1,   -- body width
    noteW = .014, -- Note width
    chordDist = 1.2,
    theme = 'dark',
}

local ucs_x, ucs_y = 0, 0
local function moveOrigin(dx, dy)
    ucs_x = ucs_x + dx
    ucs_y = ucs_y + dy
end

local palette = {
    normal = { 1, 1, 1 },
    fade = { 1, 1, 1, .7 },
}
local themes = require('themes')

local function addShape(texture, color, layer, x, y, w, h)
    ins(drawBuffer, {
        texture = texture,
        color = color or palette.normal,
        _layer = layer,
        x = ucs_x + x,
        y = ucs_y + y,
        w = w,
        h = h,
    })
end

local function drawBase(mode, x1, x2)
    if mode == 'l' then
        addShape('base', nil, 99, x1 - 0.12, -.04, 0.07, .08)
    else
        addShape('base', nil, 99, x2 + 0.12, -.04, -0.07, .08)
    end
end
local function drawExtend(x2)
    addShape('dotted_line', palette.fade, -1, x2 - .02, -env.noteW / 2, env.chordDist - x2 + .04, env.noteW)
end
local function drawNote(mode, x1, x2)
    if mode == 'mute' then
        addShape('dotted_line', themes[env.theme].note.normal, 0, x1 + .02, -env.noteW / 2, x2 - x1 - .04, env.noteW)
    elseif mode == 'tense' then
        addShape('note', themes[env.theme].note.tense, 0, x1 + .02, -env.noteW / 2, x2 - x1 - .04, env.noteW)
    elseif mode == 'pink' then
        addShape('note', themes[env.theme].note.pink, 0, x1 + .02, -env.noteW / 2, x2 - x1 - .04, env.noteW)
    elseif mode == 'skip' then
        -- addShape('note',nil, 0, (x1 + x2) / 2 - .1, -env.noteW / 2, .2, env.noteW) -- Short line
    else
        addShape('note', nil, 0, x1 + .02, -env.noteW / 2, x2 - x1 - .04, env.noteW)
    end
end
local function drawBody(d, color, x1, x2, y1, y2, ox1, ox2)
    if d == 0 then return end
    local flip
    if y1 > y2 then flip, y1, y2 = true, y2, y1 end
    y1, y2 = y1 - env.noteW / 2, y2 + env.noteW / 2
    d = abs(d)
    if d == 1 then
        local m = (x1 + x2) / 2
        if flip then y1, y2 = y2, y1 end
        addShape('body_1d', color, 1, m - .1, y1, .2, y2 - y1)
    elseif d == 2 then
        addShape('body_2d', color, 3, x1, y1, env.bodyW, y2 - y1)
    elseif d == 3 then
        addShape('body_3d', color, 3, x2, y1, -env.bodyW, y2 - y1)
    elseif d == 4 then
        if flip then
            x1, x2 = math.max(x1, ox1), math.max(x2, ox2)
        else
            x1, x2 = math.min(x1, ox1), math.min(x2, ox2)
        end
        addShape('body_4d', color, 4, x1, y1, x2 - x1, y2 - y1)
    elseif d == 5 then
        if flip then
            x1, x2 = math.min(x1, ox1), math.min(x2, ox2)
        else
            x1, x2 = math.max(x1, ox1), math.max(x2, ox2)
        end
        addShape('body_5d', color, 4, x1, y1, x2 - x1, y2 - y1)
    elseif d == 6 then
        addShape('body_6d', color, 2, x1 - .25, y1, .3, y2 - y1)
    elseif d == 7 then
        addShape('body_7d', color, 2, x2 - .05, y1, .32, y2 - y1)
    else
        local x = MATH.lerp(x1, x2, MATH.interpolate(8, .15, 23, .85, d)) - env.bodyW / 6
        addShape('body_other', color, 3, x, y1, env.bodyW / 3, y2 - y1)
    end
end
local function needNode(n1, n2)
    if n1.d == n2.d then
        local t1 = n1.mode == 'tense' or n1.mode == 'pink'
        local t2 = n2.mode == 'tense' or n2.mode == 'pink'
        if t1 == t2 and MATH.between(abs(n1.d), 2, 3) then
            return true
        end
    end
    return false
end
local function drawNode(mode, x1, x2)
    local r = env.bodyW * .3
    if mode == 'l' then
        addShape('node', nil, 10, x1 + env.bodyW / 2 - r, -r, 2 * r, 2 * r)
    elseif mode == 'r' then
        addShape('node', nil, 10, x2 - env.bodyW / 2 - r, -r, 2 * r, 2 * r)
    end
end

---@param note SSVC.Note
---@param x1 number
---@param x2 number
local function drawBranch(note, x1, x2, ox1, ox2)
    local nData = dimData[note.d]
    if not nData then error("Unknown dimension: " .. note.d) end

    moveOrigin(0, nData.yStep)

    -- Base
    if note.base then drawBase(note.base, x1, x2) end

    -- Extended line
    if note.extended then drawExtend(x2) end

    -- Note
    drawNote(note.mode, x1, x2)

    -- Body
    drawBody(note.d, themes[env.theme][(note.mode == 'tense' or note.mode == 'pink') and 'dimFade' or 'dim'][abs(note.d)], x1, x2, 0, -nData.yStep, ox1, ox2)

    -- Branches
    for n = 1, #note do
        local nxt = note[n]
        if needNode(note, nxt) then
            drawNode(abs(note.d) == 2 and 'l' or 'r', x1, x2)
        end
        if not nxt.bias then
            drawBranch(nxt, x1, x2, x1, x2)
        elseif nxt.bias < 0 then
            drawBranch(nxt, x1, x2 + .15 * nxt.bias, x1, x2)
        elseif nxt.bias > 0 then
            drawBranch(nxt, x1 + .15 * nxt.bias, x2, x1, x2)
        end
    end

    moveOrigin(0, -nData.yStep)
end

---@param chord SSVC.Note
local function drawChord(chord)
    drawBuffer = {}
    drawBranch(chord, 0, 1, 0, 1)
    table.sort(drawBuffer, function(a, b) return a._layer < b._layer end)
    return drawBuffer
end

---@param str string
---@return SSVC.Note
local function decode(str)
    ---@type SSVC.Note
    local buf = { d = 0 }
    local note = str:match('^%-?%w+')
    if note then
        buf.d = tonumber(note:match('%-?%w+'), 36)
        str = str:sub(#note + 1)
    end
    while true do
        local char = str:sub(1, 1)
        if char == '.' then
            buf.mode = 'skip'
        elseif char == '-' then
            buf.mode = 'mute'
        elseif char == '*' then
            buf.mode = 'tense'
        elseif char == 'p' then
            buf.mode = 'pink'
        elseif char == 'l' or char == 'r' then
            buf.bias = (buf.bias or 0) + (char == 'l' and -1 or 1)
        elseif char == 'x' or char == 'X' then
            buf.base = char == 'x' and 'l' or 'r'
        elseif char == 'e' then
            buf.extended = true
        else
            break
        end
        str = str:sub(2)
    end
    local branch = string.match(str, '%b()')
    if branch then
        branch = branch:sub(2, -2) -- Remove outer parentheses (and garbages come after)
        local resStrings = {}
        local balance = 0
        local start = 1
        for i = 1, #branch do
            local char = branch:sub(i, i)
            if char == '(' then
                balance = balance + 1
            elseif char == ')' then
                balance = balance - 1
                -- assert(balance >= 0, "More ( than )") -- Impossible
            elseif char == ',' and balance == 0 then
                ins(resStrings, branch:sub(start, i - 1))
                start = i + 1
            end
        end
        ins(resStrings, branch:sub(start))
        for i = 1, #resStrings do
            ins(buf, decode(resStrings[i]))
        end
    end
    return buf
end

local chordChar = {}
for i = 0, 9 do chordChar[i] = tostring(i) end
for i = 10, 23 do chordChar[i] = string.char(65 + i - 10) end
for k, v in next, chordChar do if k > 0 then chordChar[-k] = '-' .. v end end

---@param chord SSVC.Note
---@return string
local function encode(chord)
    local str = STRING.newBuf()
    if chord.d then str:put(chordChar[chord.d]) end
    if chord.base then str:put(chord.base == 'l' and 'x' or 'X') end
    if chord.bias then str:put(string.rep(chord.bias < 0 and 'l' or 'r', abs(chord.bias))) end
    if chord.mode then str:put(chord.mode == 'tense' and '*' or chord.mode == 'pink' and 'p' or chord.mode == 'mute' and '-' or chord.mode == 'skip' and '.' or '') end
    if chord.extended then str:put('e') end
    if chord[1] then
        str:put('(')
        for i = 1, #chord do
            str:put(encode(chord[i]))
            if i < #chord then
                str:put(',')
            end
        end
        str:put(')')
    end
    return str:tostring()
end

return {
    env = env,
    dimData = dimData,
    decode = decode,
    encode = encode,
    drawChord = drawChord,
}
