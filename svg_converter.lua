-- Warning: This file is a modified version from this archived repo:
-- https://github.com/MrZ626/shasavistic-chord-diagram
-- which is the predecessor of this project.

local chordD, chordH
local bodyW, noteW

local dimData = {
    [0] = { -- 0D
        freq = 1,
        draw = 'none',
        color = "FFFFFF",
    },
    { -- 1D Octave
        freq = 2 / 1,
        draw = 'arrow',
        color = "808080",
    },
    { -- 2D Fifth
        freq = 3 / 2,
        draw = 'left',
        color = "F27992",
    },
    { -- 3D Third
        freq = 5 / 4,
        draw = 'right',
        color = "6CD985",
    },
    { -- 4D Minor Seventh
        freq = 7 / 4,
        draw = 'rise',
        color = "B598EE",
    },
    { -- 5D
        freq = 11 / 4,
        draw = 'fall',
        color = "FFC247",
    },
    { -- 6D
        freq = 13 / 4,
        draw = 'arcleft',
        color = "EA6FC9",
    },
    { -- 7D
        freq = 17 / 4,
        draw = 'arcright',
        color = "93F6B8",
    },
    { -- 8D
        freq = 19 / 4,
        draw = 'dim8',
        color = "72AFE8",
    },
    { -- 9D
        freq = 23 / 4,
        draw = 'dim9',
        color = "72E0D5",
    },
    { -- 10D
        freq = 29 / 4,
        draw = 'dim10',
        color = "FF7DD2",
    },
    { -- 11D
        freq = 31 / 4,
        draw = 'dim11',
        color = "FEB3FF",
    },
    { -- 12D
        freq = 37 / 8,
        draw = 'dim12',
        color = '90F196'
    },
    { -- 13D
        freq = 41 / 8,
        draw = 'dim13',
        color = 'ABCC5A'
    },
    { -- 14D
        freq = 43 / 8,
        draw = 'dim14',
        color = 'D4CC57'
    },
    { -- 15D
        freq = 47 / 8,
        draw = 'dim15',
        color = 'F09E65'
    },
    { -- 16D
        freq = 53 / 8,
        draw = 'dim16',
        color = 'E075DA'
    },
    { -- 17D
        freq = 59 / 8,
        draw = 'dim17',
        color = '9192F6'
    },
    { -- 18D
        freq = 61 / 8,
        draw = 'dim18',
        color = '84B1F8'
    },
    { -- 19D
        freq = 67 / 16,
        draw = 'dim19',
        color = '8FF3D7'
    },
    { -- 20D
        freq = 71 / 16,
        draw = 'dim20',
        color = '91F7BA'
    },
    { -- 21D
        freq = 73 / 16,
        draw = 'dim21',
        color = '91F39E'
    },
    { -- 22D
        freq = 79 / 16,
        draw = 'dim22',
        color = '92D973'
    },
    { -- 23D
        freq = 83 / 16,
        draw = 'dim23',
        color = 'A9CD5C'
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
---@field mode? 'skip' | 'mute' | 'tense' | 'pink'
---@field bias? number
---@field base? 'l' | 'r'
---@field extended? true
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

local function fadeColor(color, a)
    local r, g, b = COLOR.HEX(color)
    r = r * a + 097 / 255 * (1 - a)
    g = g * a + 096 / 255 * (1 - a)
    b = b * a + 123 / 255 * (1 - a)
    return COLOR.toHEX(r, g, b)
end

local function drawDottedLine(c, x1, x2, y1, y2)
    local l, r = x1, x2
    for i = 0, 14, 2 do
        local _1, _2 = lerp(l, r, i / 15.1), lerp(l, r, (i + 1.1) / 15.1)
        addShape('polygon', c, -1,
            _1, y1,
            _2, y1,
            _2, y2,
            _1, y2
        )
    end
end
local function drawBase(mode, x1, x2)
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
    if mode == 'mute' then
        -- Dotted line
        drawDottedLine("F0F0F0", x1 + .05, x2 - .05, -noteW / 2, noteW / 2)
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
    elseif mode == 'pink' then
        -- Pink line
        addShape('polygon', "F0A3F0", 0,
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
        elseif mode:sub(1, 3) == 'dim' then
            local d = tonumber(mode:sub(4))
            ---@cast d number
            local x = MATH.lerp(x1, x2, MATH.interpolate(8, .15, 23, .85, d)) - bodyW / 6
            addShape('polygon', color, 3,
                x, y1,
                x, y2,
                x + bodyW / 3, y2,
                x + bodyW / 3, y1
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

    -- Base
    if note.base then drawBase(note.base, x1, x2) end

    -- Extended line
    if note.extended then
        drawDottedLine(fadeColor("FFFFFF", .4), x2 - .05, x2 + (chordD - 1) + .05, -noteW / 2, noteW / 2)
    end

    -- Note
    drawNote(note.mode, x1, x2)

    -- Body
    drawBody(
        (note.mode == 'tense' or note.mode == 'pink') and fadeColor(nData.color, .45) or nData.color,
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
    local note = str:match("^%-?%w+")
    if note then
        buf.d = tonumber(note:match("%-?%w+"), 36)
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
---@param cd? number ChordDist
---@param ch? number
---@param bw? number Body width
---@param nw? number Note width
---@param grids? number[]
return function(chords, biasList, cd, ch, bw, nw, grids)
    chordD, chordH = cd or 1.2, ch or 128
    bodyW, noteW = bw or .1, nw or .014
    grids = grids or {}
    drawBuffer = {}

    local gap = (chordD - 1) / 2
    -- Process input data
    for i = 1, #chords do
        local d = biasList[i]
        moveOrigin(0, d)
        local x1, x2 = chordD * (i - 1) + gap, chordD * i - gap
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
    local WW = #chords * chordD
    for i = 1, #grids do
        local v = grids[i]
        local dy, color = dimData[v].yStep, fadeColor(dimData[v].color, i == 1 and .4 or i == 2 and .26 or .1)
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
    addShape('polygon', fadeColor("FFFFFF", .26), -99,
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
                ([[<circle cx="%s" cy="%s" r="%s" fill="#%s" />]]):format(
                    shape.points[1], shape.points[2], shape.points[3],
                    shape.color
                )
        end
    end

    return ([[<svg width="%d" height="%d" viewBox="0 0 %g %g" xmlns="http://www.w3.org/2000/svg">%s%s%s</svg>]]):format(
        math.ceil(chordH / maxY * maxX),
        math.ceil(chordH / maxY * maxY),
        ("%.4g"):format(maxX),
        ("%.4g"):format(maxY),
        [[<!-- Generated by MrZ's Shasavistic Chord Diagram Editor -->]],
        [[<rect width="100%" height="100%" fill="#61607B" />]],
        shapeData
    )
end
