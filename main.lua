love.mouse.setVisible(false)

require 'Zenitha'

ZENITHA.setFirstScene('main')
ZENITHA.setShowFPS(false)
ZENITHA.setVersionText("")

-- Screen
SCR.setSize(1600, 1000)

-- Texture
TEX = {
    bright = {}, ---@type SSVT.Texture
    dark = {}, ---@type SSVT.Texture
}
---@class SSVT.Texture
local images = {
    note = "pitch-line.png",
    note_skip = "pitch-line-dotted.png",
    -- pitch_canceled = "pitch-line-canceled.png",
    body_1d = "1d-ascent-group.png",
    body_2d = "2d-line.png",
    body_3d = "3d-line.png",
    body_4d = "4d-line.png",
    body_5d = "5d-line.png",
    body_6d = "6d-line.png",
    body_7d = "7d-line.png",
    base = "base-symbol.png",
    node = "node.png",
    keyboard = "keyboard-segment.png",
    -- symbol_1d = "1d-symbol.png",
    -- symbol_2d = "2d-symbol.png",
    -- symbol_3d = "3d-symbol.png",
    -- symbol_4d = "4d-symbol.png",
    -- symbol_5d = "5d-symbol.png",
    -- symbol_6d = "6d-symbol.png",
    -- ascent_group = "1d-ascent-group.png",
    -- ascent_triangle = "1d-ascent-triangle.png",
    -- descent_group = "1d-descent-group.png",
    -- descent_triangle = "1d-descent-triangle.png",
    -- ascent_symbol = "ascent-symbol.png",
    -- descent_symbol = "descent-symbol.png",
}
for k, v in next, images do
    TEX.bright[k] = 'components/bright/' .. v
    TEX.dark[k] = 'components/dark/' .. v
end
TEX = IMG.init(TEX, true)
local transition = { w = 128, h = 1 }
for x = 0, 127 do
    table.insert(transition, { 'setCL', 1, 1, 1, 1 - x / 128 })
    table.insert(transition, { 'fRect', x, 0, 1, 1 })
end
TEX.transition = GC.load(transition)

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

SCN.add('main', require('edit_scene'))
