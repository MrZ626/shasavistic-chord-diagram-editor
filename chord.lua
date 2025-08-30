local abs = math.abs

local dimData = {
    [0] = { freq = 1 }, -- 0D
    { freq = 8 / 4 },   -- 1D Octave
    { freq = 6 / 4 },   -- 2D Fifth
    { freq = 5 / 4 },   -- 3D Third
    { freq = 7 / 4 },   -- 4D Minor Seventh
    { freq = 11 / 4 },  -- 5D N/A
    { freq = 13 / 4 },  -- 6D N/A
    { freq = 17 / 4 },  -- 7D N/A
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
---@field mode? 'skip' | 'mute' | 'tense'
---@field bias? number
---@field base? true
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
}

local ucs_x, ucs_y = 0, 0
local function moveOrigin(dx, dy)
    ucs_x = ucs_x + dx
    ucs_y = ucs_y + dy
end

local clr = {
    normal = { 1, 1, 1 },
    glass = { 1, 1, 1, .42 },
}

local function addShape(texture, color, layer, x, y, w, h)
    ins(drawBuffer, {
        texture = texture,
        color = color or clr.normal,
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
    addShape('note_mute', nil, -1, x2 - .02, -env.noteW / 2, env.chordDist - x2 + .04, env.noteW)
end
local function drawNote(mode, x1, x2)
    if mode == 'mute' then
        addShape('note_mute', nil, 0, x1 + .02, -env.noteW / 2, x2 - x1 - .04, env.noteW)
    elseif mode == 'tense' then
        addShape('note_tense', nil, 0, x1 + .02, -env.noteW / 2, x2 - x1 - .04, env.noteW)
    elseif mode == 'skip' then
        -- addShape('note',nil, 0, (x1 + x2) / 2 - .1, -env.noteW / 2, .2, env.noteW) -- Short line
    else
        addShape('note', nil, 0, x1 + .02, -env.noteW / 2, x2 - x1 - .04, env.noteW)
    end
end
local function drawBody(d, color, x1, x2, y1, y2, ox1, ox2)
    local flip
    if y1 > y2 then flip, y1, y2 = true, y2, y1 end
    y1, y2 = y1 - env.noteW / 2, y2 + env.noteW / 2
    if abs(d) == 1 then
        local m = (x1 + x2) / 2
        if flip then y1, y2 = y2, y1 end
        addShape('body_1d', color, 1, m - .1, y1, .2, y2 - y1)
    elseif abs(d) == 2 then
        addShape('body_2d', color, 3, x1, y1, env.bodyW, y2 - y1)
    elseif abs(d) == 3 then
        addShape('body_3d', color, 3, x2, y1, -env.bodyW, y2 - y1)
    elseif abs(d) == 4 then
        if flip then
            x1, x2 = math.max(x1, ox1), math.max(x2, ox2)
        else
            x1, x2 = math.min(x1, ox1), math.min(x2, ox2)
        end
        addShape('body_4d', color, 4, x1, y1, x2 - x1, y2 - y1)
    elseif abs(d) == 5 then
        if flip then
            x1, x2 = math.min(x1, ox1), math.min(x2, ox2)
        else
            x1, x2 = math.max(x1, ox1), math.max(x2, ox2)
        end
        addShape('body_5d', color, 4, x1, y1, x2 - x1, y2 - y1)
    elseif abs(d) == 6 then
        addShape('body_6d', color, 2, x1 - .15, y1, .2, y2 - y1)
    elseif abs(d) == 7 then
        addShape('body_7d', color, 2, x2 - .05, y1, .22, y2 - y1)
    end
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
    if note.base then drawBase(note.bias or 'l', x1, x2) end

    -- Extended line
    if note.extended then drawExtend(x2) end

    -- Note
    drawNote(note.mode, x1, x2)

    -- Body
    drawBody(note.d, note.mode == 'tense' and clr.glass, x1, x2, 0, -nData.yStep, ox1, ox2)

    -- Branches
    for n = 1, #note do
        local nxt = note[n]
        if nxt.d == note.d and MATH.between(abs(note.d), 2, 3) then
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
    local note = str:match('^%-?%d+')
    if note then
        buf.d = tonumber(note:match('%-?%d+'))
        str = str:sub(#note + 1)
    end
    while true do
        local char = str:sub(1, 1)
        if char == '.' then
            if abs(buf.d) == 1 then
                buf.mode = 'skip'
            else
                buf.mode = 'mute'
            end
        elseif char == 'l' or char == 'r' then
            buf.bias = (buf.bias or 0) + (char == 'l' and -1 or 1)
        elseif char == 'x' then
            buf.base = true
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

---@param chord SSVC.Note
---@return string
local function encode(chord)
    local str = STRING.newBuf()
    if chord.d then str:put(chord.d) end
    if chord.base then str:put('x') end
    if chord.bias then str:put(string.rep(chord.bias < 0 and 'l' or 'r', abs(chord.bias))) end
    if chord.mode then str:put(chord.mode == 'tense' and '*' or '.') end
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
