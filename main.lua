love.mouse.setVisible(false)

require 'Zenitha'

ZENITHA.setMainLoopSpeed(120)
ZENITHA.setUpdateRate(100)
ZENITHA.setRenderRate(75)
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
    elseif key == 'f12' then
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
local function src(name) return 'image/' .. name end ---@return love.Texture
TEX = {
    lamplight = src 'lamplight.png',
}

local transition = { w = 128, h = 1 }
for x = 0, 127 do
    table.insert(transition, { 'setCL', 1, 1, 1, 1 - x / 128 })
    table.insert(transition, { 'fRect', x, 0, 1, 1 })
end
TEX.transition = GC.load(transition)

---@class SSVC.TextureMap
TEX.dark = {
    note = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "FFFFFF" } },
    note_mute = (function()
        local L = { w = 151, h = 1, { 'setCL', COLOR.HEX "FFFFFF" } }
        for x = 0, 140, 20 do
            table.insert(L, { 'fRect', x, 0, 11, 1 })
        end
        return GC.load(L)
    end)(),
    note_tense = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "00FFFF" } },
    note_pink = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "F0A3F0" } },
    dotted_line = (function()
        local L = { w = 157, h = 1, { 'setCL', COLOR.HEX "FFFFFF" } }
        for x = 0, 150, 15 do
            table.insert(L, { 'fRect', x, 0, 7, 1 })
        end
        return GC.load(L)
    end)(),
    -- pitch_canceled = src "dark/pitch-line-canceled.png",
    body_1d = src "dark/1d-ascent-group.png",
    body_2d = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "F27992" } },
    body_3d = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "6CD985" } },
    body_4d = src "dark/4d-line.png",
    body_5d = src "dark/5d-line.png",
    body_6d = src "dark/6d-line.png",
    body_7d = src "dark/7d-line.png",
    base = src "dark/base-symbol.png",
    node = GC.load { w = 128, h = 128, { 'setCL', COLOR.HEX '65647F' }, { 'fCirc', 64, 64, 64 } },
    keyboard = src "dark/keyboard-segment.png",
    symbol = {
        src "dark/1d-symbol.png",
        src "dark/2d-symbol.png",
        src "dark/3d-symbol.png",
        src "dark/4d-symbol.png",
        src "dark/5d-symbol.png",
        src "dark/6d-symbol.png",
        src "dark/7d-symbol.png",
    },
    -- ascent_group = src "dark/1d-ascent-group.png",
    -- ascent_triangle = src "dark/1d-ascent-triangle.png",
    -- descent_group = src "dark/1d-descent-group.png",
    -- descent_triangle = src "dark/1d-descent-triangle.png",
    -- ascent_symbol = src "dark/ascent-symbol.png",
    -- descent_symbol = src "dark/descent-symbol.png",
}
---@class SSVC.TextureMap
TEX.bright = {
    note = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "AAAAAA" } },
    note_mute = GC.load { w = 151, h = 1, { 'setCL', COLOR.HEX "AAAAAA" }, { 'fRect', 00, 0, 11, 1 }, { 'fRect', 20, 0, 11, 1 }, { 'fRect', 40, 0, 11, 1 }, { 'fRect', 60, 0, 11, 1 }, { 'fRect', 80, 0, 11, 1 }, { 'fRect', 100, 0, 11, 1 }, { 'fRect', 120, 0, 11, 1 }, { 'fRect', 140, 0, 11, 1 } },
    note_tense = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "00DDDD" } },
    -- pitch_canceled = src "bright/pitch-line-canceled.png",
    body_1d = src "bright/1d-ascent-group.png",
    body_2d = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "F27992" } },
    body_3d = GC.load { w = 1, h = 1, { 'clear', COLOR.HEX "17AB39" } },
    body_4d = src "bright/4d-line.png",
    body_5d = src "bright/5d-line.png",
    body_6d = src "bright/6d-line.png",
    body_7d = src "bright/7d-line.png",
    base = src "bright/base-symbol.png",
    node = GC.load { w = 128, h = 128, { 'setCL', COLOR.HEX 'FFFFFF' }, { 'fCirc', 64, 64, 64 } },
    keyboard = src "bright/keyboard-segment.png",
    symbol = {
        src "bright/1d-symbol.png",
        src "bright/2d-symbol.png",
        src "bright/3d-symbol.png",
        src "bright/4d-symbol.png",
        src "bright/5d-symbol.png",
        src "bright/6d-symbol.png",
        src "bright/7d-symbol.png",
    },
    -- ascent_group = src "bright/1d-ascent-group.png",
    -- ascent_triangle = src "bright/1d-ascent-triangle.png",
    -- descent_group = src "bright/1d-descent-group.png",
    -- descent_triangle = src "bright/1d-descent-triangle.png",
    -- ascent_symbol = src "bright/ascent-symbol.png",
    -- descent_symbol = src "bright/descent-symbol.png",
}
TEX.dark.note_mute:setFilter('nearest', 'nearest')
TEX.bright.note_mute:setFilter('nearest', 'nearest')

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
