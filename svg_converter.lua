-- Warning: This file is a modified version from this archived repo:
-- https://github.com/MrZ626/shasavistic-chord-diagram
-- which is the predecessor of this project.

local bodyW, noteW

local dimData = {
    [0] = { -- 0D
        freq = 1,
        draw = 'none',
        color = "FFFFFF",
    },
    { -- 1D Octave
        freq = 8 / 4,
        draw = 'arrow',
        color = "808080",
    },
    { -- 2D Fifth
        freq = 6 / 4,
        draw = 'left',
        color = "F27A93",
    },
    { -- 3D Third
        freq = 5 / 4,
        draw = 'right',
        color = "6DD884",
    },
    { -- 4D Minor Seventh
        freq = 7 / 4,
        draw = 'rise',
        color = "B498EE",
    },
    { -- 5D
        freq = 11 / 4,
        draw = 'fall',
        color = "FFC247",
    },
    { -- 6D
        freq = 13 / 4,
        draw = 'arcleft',
        color = "B5B539",
    },
    { -- 7D
        freq = 17 / 4,
        draw = 'arcright',
        color = "E19C7D",
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

---@class _SSVC.Note
---@field d? _SSVC.Dim
---@field mode? 'skip' | 'dotted' | 'tense'
---@field bias? number
---@field bass? true
---@field [number] _SSVC.Note

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

---@param mode 'polygon' | 'path' | 'circle'
local function addShape(mode, color, layer, ...)
    local points = { ... }
    if mode == 'circle' then
        points[1] = points[1] + ucs_x
        points[2] = points[2] + ucs_y
    else
        local numCount = 0
        for i = 1, #points do
            if type(points[i]) == 'number' then
                numCount = numCount + 1
                points[i] = points[i] + (numCount % 2 == 1 and ucs_x or ucs_y)
            end
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
                x, -noteW / 2,
                x + w, -noteW / 2,
                x + w, noteW / 2,
                x, noteW / 2
            )
        end
    elseif mode == 'skip' then
        -- Short line
        x1, x2 = lerp(x1, x2, .3), lerp(x2, x1, .3)
        addShape('polygon', "808080", 0,
            x1 + .05, -noteW / 2,
            x2 - .05, -noteW / 2,
            x2 - .05, noteW / 2,
            x1 + .05, noteW / 2
        )
    elseif mode == 'tense' then
        -- Cyan line
        addShape('polygon', "08F0F0", 0,
            x1 + .05, -noteW / 2,
            x2 - .05, -noteW / 2,
            x2 - .05, noteW / 2,
            x1 + .05, noteW / 2
        )
    else
        -- Line
        addShape('polygon', "F0F0F0", 0,
            x1 + .05, -noteW / 2,
            x2 - .05, -noteW / 2,
            x2 - .05, noteW / 2,
            x1 + .05, noteW / 2
        )
    end
end
local function drawBody(color, mode, x1, x2, y1, y2, ox1, ox2)
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
        local flip
        if y1 > y2 then flip, y1, y2 = true, y2, y1 end
        y1, y2 = y1 - noteW / 2, y2 + noteW / 2
        if mode == 'mid' then
            local m = (x1 + x2) / 2
            addShape('polygon', color, 1,
                m - bodyW / 4, y1,
                m + bodyW / 4, y1,
                m + bodyW / 4, y2,
                m - bodyW / 4, y2
            )
        elseif mode == 'left' then
            addShape('polygon', color, 3,
                x1, y1,
                x1, y2,
                x1 + bodyW, y2,
                x1 + bodyW, y1
            )
        elseif mode == 'right' then
            addShape('polygon', color, 3,
                x2, y1,
                x2, y2,
                x2 - bodyW, y2,
                x2 - bodyW, y1
            )
        elseif mode == 'rise' then
            if flip then
                x1, x2 = math.min(x1, ox1), math.min(x2, ox2)
            else
                x1, x2 = math.max(x1, ox1), math.max(x2, ox2)
            end
            addShape('polygon', color, 4,
                x1, y1,
                x1 + bodyW * 1.1, y1,
                x2, y2,
                x2 - bodyW * 1.1, y2
            )
        elseif mode == 'fall' then
            if flip then
                x1, x2 = math.max(x1, ox1), math.max(x2, ox2)
            else
                x1, x2 = math.min(x1, ox1), math.min(x2, ox2)
            end
            addShape('polygon', color, 4,
                x2, y1,
                x2 - bodyW * 1.05, y1,
                x1, y2,
                x1 + bodyW * 1.05, y2
            )
        elseif mode == 'arcleft' then
            addShape('path', color, 2,
                "M", x1, y1,
                "Q", x1 - 2.6 * bodyW, (y1 + y2) / 2, x1, y2,
                "L", x1 + bodyW, y2,
                "Q", x1 + bodyW - 2.6 * bodyW, (y1 + y2) / 2, x1 + bodyW, y1,
                "Z"
            )
        elseif mode == 'arcright' then
            addShape('path', color, 2,
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
local function drawNode(mode, x1, x2)
    if mode == 'l' then
        addShape('circle', "61607B", 10, x1 + bodyW / 2, 0, bodyW * .3)
    elseif mode == 'r' then
        addShape('circle', "61607B", 10, x2 - bodyW / 2, 0, bodyW * .3)
    end
end

---@param note _SSVC.Note
---@param x1 number
---@param x2 number
local function drawBranch(note, x1, x2, ox1, ox2)
    local nData = dimData[note.d]

    assert(nData, "Unknown dimension: " .. tostring(note.d))

    moveOrigin(0, nData.yStep)

    -- Bass
    if note.bass then
        drawBass(note.bias or 'l', x1, x2)
    end

    -- Note
    drawNote(note.mode, x1, x2)

    -- Body
    drawBody(
        nData.color .. (note.mode == 'tense' and '80' or ''),
        nData.draw,
        x1, x2, 0, -nData.yStep, ox1, ox2
    )

    -- Branches
    for n = 1, #note do
        local nxt = note[n]
        if nxt.d == note.d and MATH.between(math.abs(note.d), 2, 3) then
            drawNode(math.abs(note.d) == 2 and 'l' or 'r', x1, x2)
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

---@param str string
---@return _SSVC.Note
local function decode(str)
    ---@type _SSVC.Note
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
        elseif char == '*' then
            buf.mode = 'tense'
        elseif char == 'l' or char == 'r' then
            buf.bias = (buf.bias or 0) + (char == 'l' and -1 or 1)
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
---@param biasList number[]
---@param width? number
---@param height? number
---@param bw? number Body width
---@param nw? number Note width
---@param grids? number[]
return function(chords, biasList, width, height, bw, nw, grids)
    width = width or 1.2
    height = height or 128
    bodyW, noteW = bw or .1, nw or .014
    grids = grids or {}
    drawBuffer = {}

    -- Process input data
    for i = 1, #chords do
        local d = biasList[i]
        moveOrigin(0, d)
        local x1, x2 = width * i - 1.1, width * i - .1
        drawBranch(decode(chords[i]), x1, x2, x1, x2)
        moveOrigin(0, -d)
    end

    -- Calculate bounding box
    local minX, maxX, minY, maxY = 999, -999, 999, -999
    for i = 1, #drawBuffer do
        local points = drawBuffer[i].points
        local numCount = 0
        for j = 1, #points do
            local v = points[j]
            if type(v) == 'number' then
                numCount = numCount + 1
                if numCount % 2 == 1 then
                    if v < minX then minX = v elseif v > maxX then maxX = v end
                else
                    if v < minY then minY = v elseif v > maxY then maxY = v end
                end
            end
            if drawBuffer[i].mode == 'circle' and j == 2 then break end
        end
    end

    minX, maxX = minX - .1, maxX + .1
    minY, maxY = minY - .1, maxY + .1

    -- Draw grid lines
    local WW = #chords * width
    for i = 1, #grids do
        local v = grids[i]
        local dy, color = dimData[v].yStep, dimData[v].color .. (i == 1 and "80" or i == 2 and "4D" or "1A")
        for j = -26, 26 do
            local y = dy * j
            if j ~= 0 and MATH.between(y, minY, maxY) then
                addShape('polygon', color, -99 - i,
                    00, y + nw, 00, y - nw,
                    WW, y - nw, WW, y + nw
                )
            end
        end
    end
    addShape('polygon', "FFFFFF42", -99,
        00, 0 + nw, 00, 0 - nw,
        WW, 0 - nw, WW, 0 + nw
    )

    -- Snap to zero & Flip vertically
    maxX, maxY = maxX - minX, maxY - minY
    for i = 1, #drawBuffer do
        local points = drawBuffer[i].points
        local numCount = 0
        for j = 1, #points do
            if type(points[j]) == 'number' then
                numCount = numCount + 1
                if numCount % 2 == 1 then
                    points[j] = points[j] - minX
                else
                    points[j] = maxY - (points[j] - minY)
                end
            end
            if drawBuffer[i].mode == 'circle' and j == 2 then break end
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

    table.sort(drawBuffer, function(a, b) return a._layer < b._layer end)

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
        elseif shape.mode == 'circle' then
            shapeData = shapeData ..
                ([[<circle cx="%s" cy="%s" r="%s" fill="#%s"/>]]):format(
                    shape.points[1], shape.points[2], shape.points[3],
                    shape.color
                )
        end
    end

    return ([[<svg width="%d" height="%d" viewBox="0 0 %g %g" xmlns="http://www.w3.org/2000/svg">%s%s%s</svg>]]):format(
        math.ceil(height / maxY * maxX),
        math.ceil(height / maxY * maxY),
        ("%.4g"):format(maxX),
        ("%.4g"):format(maxY),
        [[<!-- Generator: Shasavistic Chord Diagram Editor by MrZ -->]],
        [[<rect width="100%" height="100%" fill="#61607B" />]],
        shapeData
    )
end
