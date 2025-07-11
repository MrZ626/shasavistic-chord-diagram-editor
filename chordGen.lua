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
    dim.yStep = math.log(dim.freq, 2)
    dimData[-i] = {
        freq = 1 / dim.freq,
        yStep = -dim.yStep,
    }
end

local ins = table.insert

---@alias SSVT.Dim number

---@class SSVT.Chord
---@field d? SSVT.Dim
---@field note? 'skip' | 'dotted'
---@field bias? 'l' | 'r'
---@field bass? true
---@field [number] SSVT.Chord

---@class SSVT.Shape
---@field mode 'polygon' | 'path'
---@field _layer number
---@field color string
---@field points (string | number)[]

---@type SSVT.Shape[]
local drawBuffer

---@class SSVT.Environment
local env = {
    bodyW = .1,   -- body width
    noteW = .014, -- Note width
}

local ucs_x, ucs_y = 0, 0
local function moveOrigin(dx, dy)
    ucs_x = ucs_x + dx
    ucs_y = ucs_y + dy
end

local function addShape(texture, layer, x, y, w, h)
    ins(drawBuffer, {
        texture = texture,
        _layer = layer,
        x = ucs_x + x,
        y = ucs_y + y,
        w = w,
        h = h,
    })
end

local function drawBass(mode, x1, x2)
    if mode == 'l' then
        addShape('base', 99, x1 - 0.12, -.04, 0.07, .08)
    else
        addShape('base', 99, x2 + 0.12, -.04, -0.07, .08)
    end
end
local function drawNote(mode, x1, x2)
    if mode == 'dotted' then
        -- Dotted line
        addShape('pitch_dotted', 0, x1, -env.noteW / 2, x2 - x1, env.noteW)
    elseif mode == 'skip' then
        -- Short line
        -- TODO
        addShape('pitch_dotted', 0, x1, -env.noteW / 2, x2 - x1, env.noteW)
    else
        -- Line
        addShape('pitch', 0, x1, -env.noteW / 2, x2 - x1, env.noteW)
    end
end

local function drawBody(d, x1, y1, x2, y2)
    local flip
    if y1 > y2 then flip, y1, y2 = true, y2, y1 end
    y1, y2 = y1 - env.noteW / 2, y2 + env.noteW / 2
    if abs(d) == 1 then
        local m = (x1 + x2) / 2
        if flip then y1, y2 = y2, y1 end
        addShape('line_1d', 1, m - .1, y1, .2, y2 - y1)
    elseif abs(d) == 2 then
        addShape('line_2d', 2, x1, y1, .1, y2 - y1)
    elseif abs(d) == 3 then
        addShape('line_3d', 2, x2, y1, -.1, y2 - y1)
    elseif abs(d) == 4 then
        addShape('line_4d', 3, x1, y1, x2 - x1, y2 - y1)
    elseif abs(d) == 5 then
        addShape('line_5d', 3, x1, y1, x2 - x1, y2 - y1)
    elseif abs(d) == 6 then
        addShape('line_6d', 4, x1 - .15, y1, .2, y2 - y1)
    elseif abs(d) == 7 then
        addShape('line_7d', 4, x2 - .05, y1, .22, y2 - y1)
    end
end

---@param chord SSVT.Chord
---@param x1 number
---@param x2 number
local function DrawBranch(chord, x1, x2)
    local nData = dimData[chord.d]

    assert(nData, "Unknown dimension: " .. tostring(chord.d))

    moveOrigin(0, nData.yStep)

    -- Bass
    if chord.bass then
        drawBass(chord.bias or 'l', x1, x2)
    end

    -- Note
    drawNote(chord.note, x1, x2)

    -- body
    drawBody(chord.d, x1, 0, x2, -nData.yStep)

    -- Branches
    for n = 1, #chord do
        local nxt = chord[n]
        if nxt.bias == 'l' then
            DrawBranch(nxt, x1, x2 - .16)
        elseif nxt.bias == 'r' then
            DrawBranch(nxt, x1 + .16, x2)
        else
            DrawBranch(nxt, x1, x2)
        end
    end

    moveOrigin(0, -nData.yStep)
end

---@param chord SSVT.Chord
local function drawChord(chord)
    drawBuffer = {}
    DrawBranch(chord, 0, 1)
    table.sort(drawBuffer, function(a, b) return a._layer < b._layer end)
    return drawBuffer
end

---@param str string
---@return SSVT.Chord
local function decode(str)
    ---@type SSVT.Chord
    local buf = { d = 0 }
    local note = str:match("^%-?%d+")
    if note then
        buf.d = tonumber(note:match("%-?%d+"))
        str = str:sub(#note + 1)
    end
    while true do
        local char = str:sub(1, 1)
        if char == '.' then
            if math.abs(buf.d) == 1 then
                buf.note = 'skip'
            else
                buf.note = 'dotted'
            end
        elseif char == 'l' or char == 'r' then
            buf.bias = char
        elseif char == 'x' then
            buf.bass = true
        else
            break
        end
        str = str:sub(2)
    end
    local branch = string.match(str, "%b()")
    if branch then
        branch = branch:sub(2, -2) -- Remove outer parentheses (and garbages come after)
        local resStrings = {}
        local balance = 0
        local start = 1
        for i = 1, #branch do
            local char = branch:sub(i, i)
            if char == "(" then
                balance = balance + 1
            elseif char == ")" then
                balance = balance - 1
                assert(balance >= 0, "More ( than )")
            elseif char == "," and balance == 0 then
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

---@param chord SSVT.Chord
---@return string
local function encode(chord)
    local str = {}
    if chord.d then ins(str, chord.d) end
    if chord.bass then ins(str, "x") end
    if chord.bias then ins(str, chord.bias) end
    if chord.note then ins(str, ".") end
    if chord[1] then
        ins(str, "(")
        for i = 1, #chord do
            ins(str, encode(chord[i]))
            if i < #chord then
                ins(str, ",")
            end
        end
        ins(str, ")")
    end
    return table.concat(str)
end

return {
    env = env,
    dimData = dimData,
    decode = decode,
    encode = encode,
    drawChord = drawChord,
}
