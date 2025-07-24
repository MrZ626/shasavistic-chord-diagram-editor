-- Warning: This file is a modified version from this archived repo:
-- https://github.com/MrZ626/shasavistic-chord-diagram
-- which is the predecessor of this project.

-- These two value could be changed
local bodyW, noteH

local dimData = {
    [0] = { -- 0D
        freq = 1,
        draw = 'none',
    },
    { -- 1D Octave
        freq = 8 / 4,
        draw = 'arrow',
        color = '808080',
    },
    { -- 2D Fifth
        freq = 6 / 4,
        draw = 'left',
        color = 'F27A93',
    },
    { -- 3D Third
        freq = 5 / 4,
        draw = 'right',
        color = '6DD884',
    },
    { -- 4D Minor Seventh
        freq = 7 / 4,
        draw = 'rise',
        color = 'B498EE',
    },
    { -- 5D
        freq = 11 / 4,
        draw = 'fall',
        color = 'FFC247',
    },
    { -- 6D
        freq = 13 / 4,
        draw = 'arcleft',
        color = 'B5B539',
    },
    { -- 7D
        freq = 17 / 4,
        draw = 'arcright',
        color = 'E19C7D',
    },
}
for i = 0, #dimData do
    local dim = dimData[i]
    dim.yStep = math.log(dim.freq, 2)
    dimData[-i] = {
        freq = 1 / dim.freq,
        draw = dim.draw,
        color = dim.color,
        yStep = -dim.yStep,
    }
end

---@alias _SSVC.Dim number

---@class _SSVC.Chord
---@field d? _SSVC.Dim
---@field mode? 'skip' | 'dotted'
---@field bias? 'l' | 'r'
---@field bass? true
---@field [number] _SSVC.Chord

---@class _SSVC.Shape
---@field mode 'polygon' | 'path'
---@field _layer number
---@field color string
---@field points (string | number)[]

---@type _SSVC.Shape[]
local drawBuffer

local ucs_x, ucs_y = 0, 0
local function moveOrigin(dx, dy)
    ucs_x = ucs_x + dx
    ucs_y = ucs_y + dy
end

local function addShape(mode, color, layer, ...)
    local points = { ... }
    local numCount = 0
    for i = 1, #points do
        if type(points[i]) == 'number' then
            numCount = numCount + 1
            points[i] = points[i] + (numCount % 2 == 1 and ucs_x or ucs_y)
        end
    end

    table.insert(drawBuffer, {
        mode = mode,
        _layer = layer,
        color = color,
        points = points,
    })
end

local function lerp(a, b, t)
    return a * (1 - t) + b * t
end

local function drawBass(mode, x1, x2)
    if mode == 'l' then
        addShape('polygon', "F0F0F0", 99,
            x1 - 0.05, 0,
            x1 - 0.12, .04,
            x1 - 0.12, -.04
        )
    else
        addShape('polygon', "F0F0F0", 99,
            x2 + 0.05, 0,
            x2 + 0.12, .04,
            x2 + 0.12, -.04
        )
    end
end
local function drawNote(mode, x1, x2)
    if mode == 'dotted' then
        -- Dotted line
        for i = 0, 10, 2 do
            local x = lerp(x1 + .05, x2 - .05, i / 11)
            local w = (x2 - x1 - .1) / 11
            addShape('polygon', "F0F0F0", 0,
                x, -noteH / 2,
                x + w, -noteH / 2,
                x + w, noteH / 2,
                x, noteH / 2
            )
        end
    elseif mode == 'skip' then
        -- Short line
        x1, x2 = lerp(x1, x2, .3), lerp(x2, x1, .3)
        addShape('polygon', "808080", 0,
            x1 + .05, -noteH / 2,
            x2 - .05, -noteH / 2,
            x2 - .05, noteH / 2,
            x1 + .05, noteH / 2
        )
    else
        -- Line
        addShape('polygon', "F0F0F0", 0,
            x1 + .05, -noteH / 2,
            x2 - .05, -noteH / 2,
            x2 - .05, noteH / 2,
            x1 + .05, noteH / 2
        )
    end
end

local function drawBody(color, mode, x1, y1, x2, y2)
    if mode == 'none' then return end
    if mode == 'arrow' then
        local m = (x1 + x2) / 2
        addShape('polygon', color, 1,
            m, y1,
            m + bodyW * .8, y1 * .9 + y2 * .1,
            m + bodyW * .2, y1 * .9 + y2 * .1,
            m + bodyW * .2, y2,
            m - bodyW * .2, y2,
            m - bodyW * .2, y1 * .9 + y2 * .1,
            m - bodyW * .8, y1 * .9 + y2 * .1
        )
    else
        if y1 > y2 then y1, y2 = y2, y1 end
        y1, y2 = y1 - noteH / 2, y2 + noteH / 2
        if mode == 'left' then
            addShape('polygon', color, 2,
                x1, y1,
                x1, y2,
                x1 + bodyW, y2,
                x1 + bodyW, y1
            )
        elseif mode == 'right' then
            addShape('polygon', color, 2,
                x2, y1,
                x2, y2,
                x2 - bodyW, y2,
                x2 - bodyW, y1
            )
        elseif mode == 'mid' then
            local m = (x1 + x2) / 2
            addShape('polygon', color, 2,
                m - bodyW / 4, y1,
                m + bodyW / 4, y1,
                m + bodyW / 4, y2,
                m - bodyW / 4, y2
            )
        elseif mode == 'rise' then
            addShape('polygon', color, 3,
                x1, y1,
                x1 + bodyW * 1.26, y1,
                x2, y2,
                x2 - bodyW * 1.26, y2
            )
        elseif mode == 'fall' then
            addShape('polygon', color, 3,
                x2, y1,
                x2 - bodyW * 1.1, y1,
                x1, y2,
                x1 + bodyW * 1.1, y2
            )
        elseif mode == 'arcleft' then
            addShape('path', color, 4,
                "M", x1, y1,
                "Q", x1 - 2.6 * bodyW, (y1 + y2) / 2, x1, y2,
                "L", x1 + bodyW, y2,
                "Q", x1 + bodyW - 2.6 * bodyW, (y1 + y2) / 2, x1 + bodyW, y1,
                "Z"
            )
        elseif mode == 'arcright' then
            addShape('path', color, 4,
                "M", x2, y1,
                "Q", x2 + 2.6 * bodyW, (y1 + y2) / 2, x2, y2,
                "L", x2 - bodyW, y2,
                "Q", x2 - bodyW + 2.6 * bodyW, (y1 + y2) / 2, x2 - bodyW, y1,
                "Z"
            )
        else
            error("Unknown body style: " .. mode)
        end
    end
end

---@param chord _SSVC.Chord
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
    drawNote(chord.mode, x1, x2)

    -- Body
    drawBody(nData.color, nData.draw, x1, 0, x2, -nData.yStep)

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

---@param str string
---@return _SSVC.Chord
local function decode(str)
    ---@type _SSVC.Chord
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
                buf.mode = 'skip'
            else
                buf.mode = 'dotted'
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
                table.insert(resStrings, branch:sub(start, i - 1))
                start = i + 1
            end
        end
        table.insert(resStrings, branch:sub(start))
        for i = 1, #resStrings do
            table.insert(buf, decode(resStrings[i]))
        end
    end
    return buf
end

---@param chords string[]
---@param height? number
---@param bw? number Body width
---@param nw? number Note width
return function(chords, biasList, height, bw, nw)
    height = height or 128
    bodyW, noteH = bw or .1, nw or .014
    drawBuffer = {}

    -- Process input data
    for i = 1, #chords do
        local d = biasList[i]
        moveOrigin(0, d)
        DrawBranch(decode(chords[i]), 1.2 * i - 1.1, 1.2 * i - .1)
        moveOrigin(0, -d)
    end
    table.sort(drawBuffer, function(a, b) return a._layer < b._layer end)

    -- Calculate bounding box
    local minX, maxX, minY, maxY = 999, -999, 999, -999
    for i = 1, #drawBuffer do
        local shape = drawBuffer[i].points
        local numCount = 0
        for j = 1, #shape do
            local v = shape[j]
            if type(v) == 'number' then
                numCount = numCount + 1
                if numCount % 2 == 1 then
                    if v < minX then minX = v elseif v > maxX then maxX = v end
                else
                    if v < minY then minY = v elseif v > maxY then maxY = v end
                end
            end
        end
    end

    minX, maxX = minX - .1, maxX + .1
    minY, maxY = minY - .1, maxY + .1

    -- Snap to zero & Flip vertically
    maxX, maxY = maxX - minX, maxY - minY
    for i = 1, #drawBuffer do
        local shape = drawBuffer[i].points
        local numCount = 0
        for j = 1, #shape do
            if type(shape[j]) == 'number' then
                numCount = numCount + 1
                if numCount % 2 == 1 then
                    shape[j] = shape[j] - minX
                else
                    shape[j] = maxY - (shape[j] - minY)
                end
            end
        end
    end

    -- Stringify (to 4 significant digits)
    for i = 1, #drawBuffer do
        local shape = drawBuffer[i].points
        for j = 1, #shape do
            if type(shape[j]) == 'number' then
                shape[j] = string.format("%.4g", shape[j])
            end
        end
    end

    -- Generate SVG chunks
    local shapeData = ""
    for i = 1, #drawBuffer do
        local shape = drawBuffer[i]
        if shape.mode == 'polygon' then
            shapeData = shapeData ..
                ([[<polygon points="%s" fill="#%s" />]]):format(
                    table.concat(shape.points, ","),
                    shape.color
                )
        elseif shape.mode == 'path' then
            shapeData = shapeData ..
                ([[<path d="%s" fill="#%s" />]]):format(
                    table.concat(shape.points, " "),
                    shape.color
                )
        end
    end

    return ([[<svg width="%d" height="%d" viewBox="0 0 %f %f" xmlns="http://www.w3.org/2000/svg">%s%s%s</svg>]]):format(
        math.ceil(height / maxY * maxX),
        math.ceil(height / maxY * maxY),
        ("%.4g"):format(maxX),
        ("%.4g"):format(maxY),
        [[<!-- Generator: Shasavistic Chord Diagram Editor by MrZ -->]],
        [[<rect width="100%" height="100%" fill="#61607B" />]],
        shapeData
    )
end
