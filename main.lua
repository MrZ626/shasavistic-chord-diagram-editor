love.mouse.setVisible(false)

require 'Zenitha'

ZENITHA.setFirstScene('main')
ZENITHA.setShowFPS(false)
ZENITHA.setVersionText("")

-- globalEvent
local MSisDown, KBisDown = love.mouse.isDown, love.keyboard.isDown
local gc = love.graphics
local gc_setColor, gc_setLineWidth = gc.setColor, gc.setLineWidth
local gc_line = gc.line

ZENITHA.globalEvent.clickFX = NULL

function ZENITHA.globalEvent.keyDown(key, isRep)
    if isRep then return end
    if KBisDown('lctrl', 'rctrl') then return end
    if key == 'f11' then
        love.window.setFullscreen(not love.window.getFullscreen())
    elseif key == 'f8' then
        local m = ZENITHA.getDevMode()
        ZENITHA.setDevMode(m == false and 1)
    end
end

local themes = require('themes')
function ZENITHA.globalEvent.drawCursor(x, y)
    gc_setColor(COLOR.L)
    gc_setLineWidth(3)
    gc_setColor(1, 1, 1, .626)
    gc_line(x - 13, y - 13, x + 13, y - 13)
    gc_line(x - 13, y + 13, x + 13, y + 13)
    gc_setLineWidth(6)
    if MSisDown(1) then
        gc_setColor(themes.dark.dim[2])
        gc_line(x - 13, y - 13, x - 13, y + 13)
    end
    if MSisDown(2) then
        gc_setColor(themes.dark.dim[3])
        gc_line(x + 13, y - 13, x + 13, y + 13)
    end
    if MSisDown(3) then
        gc_setColor(themes.dark.dim[4])
        gc_line(x - 13, y + 13, x + 13, y - 13)
    end
    if MSisDown(4, 5, 6) then
        gc_setColor(themes.dark.dim[5])
        gc_line(x + 13, y - 13, x - 13, y + 13)
    end
end

-- Screen
SCR.setSize(1600, 1000)

-- Texture
TEX = {}
local transition = { w = 128, h = 1 }
for x = 0, 127 do
    table.insert(transition, { 'setCL', 1, 1, 1, 1 - x / 128 })
    table.insert(transition, { 'fRect', x, 0, 1, 1 })
end
TEX.transition = GC.load(transition)

---@return love.Texture
local function src(name) return 'components/dark/' .. name end
---@class SSVT.TextureMap
TEX.dark = {
    note = src "pitch-line.png",
    note_skip = src "pitch-line-dotted.png",
    -- pitch_canceled = src"pitch-line-canceled.png",
    body_1d = src "1d-ascent-group.png",
    body_2d = src "2d-line.png",
    body_3d = src "3d-line.png",
    body_4d = src "4d-line.png",
    body_5d = src "5d-line.png",
    body_6d = src "6d-line.png",
    body_7d = src "7d-line.png",
    base = src "base-symbol.png",
    node = src "node.png",
    keyboard = src "keyboard-segment.png",
    symbol = {
        src "1d-symbol.png",
        src "2d-symbol.png",
        src "3d-symbol.png",
        src "4d-symbol.png",
        src "5d-symbol.png",
        src "6d-symbol.png",
        src "7d-symbol.png",
    },
    -- ascent_group = src"1d-ascent-group.png",
    -- ascent_triangle = src"1d-ascent-triangle.png",
    -- descent_group = src"1d-descent-group.png",
    -- descent_triangle = src"1d-descent-triangle.png",
    -- ascent_symbol = src"ascent-symbol.png",
    -- descent_symbol = src"descent-symbol.png",
}
TEX.bright = {} ---@type SSVT.TextureMap
for k, v in next, TEX.dark do
    if type(v) == 'string' then
        TEX.bright[k] = v:gsub('dark', 'bright')
    else
        TEX.bright[k] = {}
        for k2, v2 in next, v do
            TEX.bright[k][k2] = v2:gsub('dark', 'bright')
        end
    end
end
TEX = IMG.init(TEX, true)

-- Widget
WIDGET.setDefaultOption {
    button = {
        fontSize = 50,
        lineWidth = 2,
        cornerR = 0,
        frameColor = COLOR.LD,
        textColor = { .626, .626, .626 },
        _hoverTimeMax = .0626,
    },
    hint = {
        lineWidth = 2,
        cornerR = 20,
        floatCornerR = 20,
        frameColor = COLOR.D,
        textColor = { .626, .626, .626 },
        _hoverTimeMax = .0626,
    },
}

-- Scene
SCN.add('main', require('edit_scene'))
