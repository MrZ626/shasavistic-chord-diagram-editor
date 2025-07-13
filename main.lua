require 'Zenitha'

ZENITHA.setFirstScene('main')
ZENITHA.setShowFPS(false)
ZENITHA.setVersionText("")

ZENITHA.globalEvent.clickFX = NULL
SCR.setSize(1600, 1000)
love.mouse.setVisible(false)

local ssvt = require('chord')

local themes = {
    dark = {
        bgbase = { COLOR.HEX '61607B' },
        bg = { COLOR.HEX '65647F' },
        sepLine = { COLOR.HEX '00000010' },
        select = { COLOR.HEX 'F5C40018' },
        cursor = { COLOR.HEX 'F5C400FF' },
        preview = { COLOR.HEX '00F1F580' },
        playline = { COLOR.HEX 'C0F0FF' },
        text = COLOR.L,
        dim = {
            { COLOR.HEX 'AAAAAA' },
            { COLOR.HEX 'F27992' },
            { COLOR.HEX '6CD985' },
            { COLOR.HEX 'B598EE' },
            { COLOR.HEX 'FFC247' },
            { COLOR.HEX '3C3D12' },
            { COLOR.HEX 'ED9877' },
        },
        dimGridColor = {
            { COLOR.HEX 'AAAAAA42' },
            { COLOR.HEX 'F2799226' },
            { COLOR.HEX '2FD65626' },
            { COLOR.HEX 'AA88EE26' },
            { COLOR.HEX 'FFAA0126' },
            { COLOR.HEX 'B5B50026' },
            { COLOR.HEX 'ED987726' },
        },
    },
    bright = {
        bgbase = { COLOR.HEX 'DCD3C6' },
        bg = { COLOR.HEX 'E0D7CA' },
        sepLine = { COLOR.HEX '00000010' },
        select = { COLOR.HEX 'FF312618' },
        cursor = { COLOR.HEX 'FF312680' },
        preview = { COLOR.HEX '2680FF80' },
        playline = { COLOR.HEX '0042D0' },
        text = COLOR.D,
        dim = {
            { COLOR.HEX 'AAAAAA' },
            { COLOR.HEX 'F27992' },
            { COLOR.HEX '17AB39' },
            { COLOR.HEX 'AA88EE' },
            { COLOR.HEX 'EA9C02' },
            { COLOR.HEX 'B5B500' },
            { COLOR.HEX 'ED9877' },
        },
        dimGridColor = {
            { COLOR.HEX 'AAAAAA62' },
            { COLOR.HEX 'F2799262' },
            { COLOR.HEX '6CD98562' },
            { COLOR.HEX 'B598EE62' },
            { COLOR.HEX 'FFC24762' },
            { COLOR.HEX 'B5B50062' },
            { COLOR.HEX 'ED987762' },
        },
    },
}

local ins, rem = table.insert, table.remove
local abs = math.abs
local sin, log = math.sin, math.log

local KBisDown = love.keyboard.isDown
local MSisDown = love.mouse.isDown

do -- Texture
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
        ins(transition, { 'setCL', 1, 1, 1, 1 - x / 128 })
        ins(transition, { 'fRect', x, 0, 1, 1 })
    end
    TEX.transition = GC.load(transition)
end

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

local audio = require('audio')

---@class wrappedChord
---@field tree SSVT.Chord
---@field drawData table
---@field text string

local editor = require('editor')

---@type Zenitha.Scene
local scene = {}

function scene.load()
    editor:newChord(1)
    editor:moveCursor(0)
end

function scene.mouseMove(_, _, dx, dy)
    if MSisDown(1) then
        editor:scroll(-dx / 260, dy / 260)
    end
end

function scene.wheelMove(_, dy)
    if KBisDown('lshift', 'rshift') then
        editor:scroll(-dy / 2.6, 0)
    else
        editor:scroll(0, dy / 2.6)
    end
end

function scene.keyDown(key, isRep)
    if key == 'lctrl' or key == 'rctrl' or key == 'lshift' or key == 'rshift' or key == 'lalt' or key == 'ralt' then
        if editor.combo == '' then editor.combo = key:sub(2, 2):upper() end
        return true
    end

    if key == 'space' then
        if isRep then return true end
        if editor.playing then
            editor:stopChord(true)
        elseif editor.combo == 'S' then
            -- Play selected note
            audio.playNote(editor.curPitch, 'space')
        else
            -- Play selected chords
            editor.playL, editor.playR = editor.cursor, editor.selMark or editor.cursor
            if editor.playL > editor.playR then editor.playL, editor.playR = editor.playR, editor.playL end
            editor.playing = editor.playL
            -- editor.timer0 = .5 + .5 / (editor.stop - editor.start + 1)
            editor.timer0 = .626
            editor:playChord()
        end
    elseif key == 'down' or key == 'up' then
        if editor.combo == 'C' then return true end
        if editor.combo == 'A' then
            -- Move chord
            editor:moveChord(editor:getChord(), key == 'up' and editor.gridStep or -editor.gridStep)
        else
            -- Select note
            local allInfo = TABLE.flatten(TABLE.copyAll(editor.chordList[editor.cursor].tree))
            local pitchInfo = TABLE.alloc()
            for k, v in next, allInfo do
                if k:sub(-5) == 'pitch' then
                    ins(pitchInfo, { v, k:sub(1, -7) })
                end
            end
            table.sort(pitchInfo, editor._pitchSorter)
            local curPos
            for i = 1, #pitchInfo do
                if pitchInfo[i][1] == editor.curPitch then
                    curPos = i; break
                end
            end
            if not curPos then return end
            if key == 'up' then
                while curPos < #pitchInfo and (pitchInfo[curPos][1] <= editor.curPitch) do curPos = curPos + 1 end
            else
                while curPos > 1 and (pitchInfo[curPos][1] >= editor.curPitch) do curPos = curPos - 1 end
            end
            editor.curPitch = pitchInfo[curPos][1]
            editor.nCur = STRING.split(pitchInfo[curPos][2], ".")
            for i = 1, #editor.nCur do
                editor.nCur[i] = tonumber(editor.nCur[i])
            end
            editor:refreshText()
            TABLE.free(pitchInfo)
        end
    elseif key == 'left' or key == 'right' then
        if editor.combo == 'C' then return true end
        if editor.combo == 'A' then
            -- Bias note
            if #editor.nCur == 0 then return true end
            local chord, curNote = editor:getChord(), editor:getNote()
            local tar = key == 'left' and 'l' or 'r'
            if curNote.bias ~= tar then
                curNote.bias = not curNote.bias and tar or nil
                editor:redrawChord(chord)
            end
        else
            -- Move cursor (normally)
            editor:moveCursor(key == 'left' and -1 or 1)
        end
    elseif key == 'pageup' then
        if isRep then return true end
        editor:moveCursor(-4)
    elseif key == 'pagedown' then
        if isRep then return true end
        editor:moveCursor(4)
    elseif key == 'home' then
        if isRep then return true end
        editor:moveCursor(-1e99)
    elseif key == 'end' then
        if isRep then return true end
        editor:moveCursor(1e99)
    elseif key == 'return' then
        if isRep then return true end
        editor.combo = ''
        -- Create new chord
        editor:newChord(editor.cursor + 1)
        editor:moveCursor(1)
    elseif key == 'backspace' then
        if isRep then return true end
        if editor.combo == 'A' then
            local chord = editor:getChord()
            editor:reCalculatePitch(chord.tree, 1)
            editor.curPitch = 1
        else
            -- Delete selected note
            if #editor.nCur == 0 then return true end
            local n = rem(editor.nCur, #editor.nCur)
            local chord, curNote = editor:getChord(), editor:getNote()
            rem(curNote, n)
            editor:redrawChord(chord)
            editor.curPitch = curNote.pitch
            editor:refreshText()
        end
    elseif key == 'delete' then
        if isRep then return true end
        -- Delete current chord
        editor:deleteChord(editor.cursor, editor.selMark or editor.cursor)
        editor.selMark = false
    elseif key == '.' then
        if isRep then return true end
        -- Mark selected note as fake note
        local chord, curNote = editor:getChord(), editor:getNote()
        if curNote.note then
            curNote.note = nil
        else
            curNote.note = abs(curNote.d) == 1 and 'skip' or 'mute'
        end
        editor:redrawChord(chord)
    elseif key == '/' then
        if isRep then return true end
        -- Mark selected note as base
        local chord, curNote = editor:getChord(), editor:getNote()
        if curNote.base then
            curNote.base = nil
        else
            for k in next, TABLE.flatten(TABLE.copyAll(chord.tree)) do
                if k:find('base') then
                    local index = STRING.split(k, '.')
                    for i = 1, #index do
                        index[i] = tonumber(index[i]) or index[i]
                    end
                    TABLE.listIndexSet(chord.tree, index, nil)
                end
            end
            curNote.base = true
        end
        editor:redrawChord(chord)
    elseif #key == 1 and MATH.between(tonumber(key) or 0, 1, 7) then
        if isRep then return true end

        local keyNum = tonumber(key)
        ---@cast keyNum number

        if editor.combo == 'A' then
            -- Set custom grid step
            editor.gridStep = keyNum
        else
            -- Add/Remove note
            local step = keyNum
            if editor.combo == 'S' then step = -step end
            local chord, curNote = editor:getChord(), editor:getNote()
            local exist
            for i = 1, #curNote do
                if curNote[i].d == step then
                    exist = i
                    break
                end
            end

            if editor.combo == 'C' then
                if exist then
                    rem(curNote, exist)
                    editor:redrawChord(chord)
                end
            else
                local pitch = editor.curPitch * ssvt.dimData[step].freq
                if not exist then
                    ins(curNote, { d = step, pitch = pitch })
                    table.sort(curNote, editor._levelSorter)
                    editor:redrawChord(chord)
                end
                audio.playNote(pitch, key)
            end
        end
    elseif key == 'tab' then
        if isRep then return true end
        editor:switchTheme()
    elseif key == 'a' then
        if editor.combo == 'C' then
            -- Select all
            editor:moveCursor(-1e99)
            editor.selMark = #editor.chordList
        end
    elseif key == 'c' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Copy
            local res = editor:dumpChords(editor.cursor, editor.selMark or editor.cursor)
            CLIPBOARD.set(table.concat(res, ' '))
            MSG('check', "Copied " .. #res .. " chords")
        end
    elseif key == 'x' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Cut (Copy+Delete)
            local res = editor:dumpChords(editor.cursor, editor.selMark or editor.cursor)
            CLIPBOARD.set(table.concat(res, ' '))
            editor:deleteChord(editor.cursor, editor.selMark or editor.cursor)
            editor.selMark = false
            MSG('check', "Cut " .. #res .. " chords")
        end
    elseif key == 'v' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Paste (after)
            local count = editor:pasteChords(CLIPBOARD.get())
            MSG('check', "Pasted " .. count .. " chords")
        elseif editor.combo == 'S' then
            -- Paste (before)
            editor.cursor = editor.cursor - 1
            local count = editor:pasteChords(CLIPBOARD.get())
            MSG('check', "Pasted " .. count .. " chords")
            editor.cursor = editor.cursor + 1
        end
    elseif key == 'escape' then
        if isRep then return true end
        -- Clear selection
        editor.selMark = false
    end
    return true
end

function scene.keyUp(key)
    if key == 'lctrl' or key == 'rctrl' then
        if editor.combo == 'C' then editor.combo = '' end
    elseif key == 'lshift' or key == 'rshift' then
        if editor.combo == 'S' then editor.combo = '' end
    elseif key == 'lalt' or key == 'ralt' then
        if editor.combo == 'A' then editor.combo = '' end
    end
    audio.stopNote(key)
end

function scene.update(dt)
    if editor.timer > 0 then
        editor.timer = editor.timer - dt
        if editor.timer <= 0 then
            editor:stopChord()
            editor:playNextChord()
        end
        if editor.playing and editor.selMark and abs(editor.cursor - editor.selMark) + 1 >= 4 then
            editor:scroll((editor.playing - editor.timer / editor.timer0) * 1.2 - .26 - editor.scrX, 0)
        end
    end
    editor.cursor1 = MATH.expApproach(editor.cursor1, editor.cursor, dt * 35)
    editor.curPitch1 = MATH.expApproach(editor.curPitch1, editor.curPitch, dt * 35)
    editor.scrX1 = MATH.expApproach(editor.scrX1, editor.scrX, dt * 20)
    editor.scrY1 = MATH.expApproach(editor.scrY1, editor.scrY, dt * 20)
    if KBisDown('lctrl', 'rctrl') then
        if KBisDown('left') then editor:scroll(-dt * 6.2, 0) end
        if KBisDown('right') then editor:scroll(dt * 6.2, 0) end
        if KBisDown('up') then editor:scroll(0, dt * 6.2) end
        if KBisDown('down') then editor:scroll(0, -dt * 6.2) end
    end
end

local gc = love.graphics
local gc_push, gc_pop = gc.push, gc.pop
local gc_clear, gc_replaceTransform = gc.clear, gc.replaceTransform
local gc_translate, gc_scale = gc.translate, gc.scale
local gc_setColor, gc_setLineWidth = gc.setColor, gc.setLineWidth
local gc_draw, gc_line = gc.draw, gc.line
local gc_rectangle = gc.rectangle
local gc_print = gc.print
local gc_setAlpha = GC.setAlpha
local gc_strokePrint = GC.strokePrint

local keyboardQuad = GC.newQuad(0, 0, 137, 543 * 6, TEX.dark.keyboard)
TEX.dark.keyboard:setWrap('clampzero', 'repeat')
TEX.bright.keyboard:setWrap('clampzero', 'repeat')
function scene.draw()
    local theme = themes[editor.theme]
    gc_clear(theme.bgbase)

    gc_replaceTransform(SCR.xOy)
    gc_setColor(theme.bg)
    gc_rectangle('fill', 0, 0, SCR.w0, SCR.h0)

    -- gc_replaceTransform(SCR.xOy_ul)
    -- gc_setColor(theme.text)
    -- gc_setAlpha(.16)
    -- gc_print("Audio Count   " .. srcCount - #srcLib .. "   /  " .. srcCount - 1, 100, 10)

    gc_replaceTransform(SCR.xOy_l)
    gc_translate(100, 0)
    gc_scale(260, -260)
    gc_translate(-editor.scrX1, -editor.scrY1)

    gc_setColor(1, 1, 1, MATH.clampInterpolate(.1, 1, .26, .26, editor.scrX1))
    gc_draw(TEX[editor.theme].keyboard, keyboardQuad, editor.scrX1 - .36, 3.206, 0, .00184, -.00184)

    -- Grid line
    do
        gc_setLineWidth(.01)
        gc_setColor(theme.dimGridColor[editor.gridStep])
        local dist = log(ssvt.dimData[editor.gridStep].freq, 2)
        local y = 0
        gc_translate(editor.scrX1, 0)
        while y < 3.5 do
            gc_line(-2.6, y, 26, y)
            y = y + dist
        end
        y = -dist
        while y > -2.6 do
            gc_line(-2.6, y, 26, y)
            y = y - dist
        end
        gc_translate(-editor.scrX1, 0)
    end

    -- Selection
    do
        ---@type number, number
        local s, e = editor.cursor1, editor.selMark or editor.cursor1
        if s > e then s, e = e, s end
        s, e = (s - 1) * 1.2, e * 1.2
        gc_setColor(theme.select)
        gc_rectangle('fill', s, -6, e - s, 12)
        if editor.selMark then
            gc_setColor(theme.cursor)
            gc_draw(TEX.transition, s, 0, 0, .2 / 128, 12, 0, .5)
            gc_draw(TEX.transition, e, 0, 0, -.2 / 128, 12, 0, .5)
        end
    end

    gc_push('transform')
    FONT.set(30)
    for i = 1, #editor.chordList do
        -- Separator line
        gc_setColor(theme.sepLine)
        gc_setLineWidth(.01)
        gc_line(1.2, editor.scrY1 - 6, 1.2, editor.scrY1 + 6)

        -- Chord textures
        gc_setColor(1, 1, 1)
        local texSrc = TEX[editor.theme]
        local drawData = editor.chordList[i].drawData
        local move = log(editor.chordList[i].tree.pitch, 2)

        gc_translate(.1, move)
        for j = 1, #drawData do
            local d = drawData[j]
            local tex = texSrc[d.texture]
            gc_draw(tex, d.x, d.y, 0, d.w / tex:getWidth(), d.h / tex:getHeight())
        end
        gc_translate(-.1, -move)

        -- Text
        gc_setColor(theme.text)
        gc_print(editor.chordList[i].text, .05, (i % 2 == 1 and -1.466 or -1.626) + editor.scrY1, 0, .005, -.005)
        gc_setAlpha(.26)
        gc_print(i, .05, (i % 2 == 1 and -1.4 or -1.78) + editor.scrY1, 0, .003, -.003)

        gc_translate(1.2, 0)
    end
    gc_pop()

    -- Cursor
    GC.ucs_move('m', 1.2 * (editor.cursor1 - 1), 0)
    local y = log(editor.curPitch1, 2)
    gc_setColor(theme.cursor)
    gc_setAlpha(.7 + .3 * sin(love.timer.getTime() * 6.2))
    gc_setLineWidth(.01)
    gc_rectangle('line', 0, y - .03, 1.2, .06)
    gc_strokePrint(
        'corner', .00626,
        COLOR.D, theme.cursor,
        editor.cursorText,
        -.04, y + .16, nil, 'left',
        0, .0035, -.0035
    )
    GC.ucs_back()

    -- Playing selection
    if editor.playing then
        local s, e = editor.playL, editor.playR
        s, e = (s - 1) * 1.2, e * 1.2
        gc_setColor(theme.preview)
        gc_draw(TEX.transition, s, 0, 0, .2 / 128, 12, 0, .5)
        gc_draw(TEX.transition, e, 0, 0, -.2 / 128, 12, 0, .5)
        gc_setLineWidth(.026)
        gc_setColor(theme.playline)
        local progress = editor.playing + (1 - editor.timer / editor.timer0)
        local x = MATH.interpolate(editor.playL, s, editor.playR + 1, e, progress)
        gc_line(x, editor.scrY1 - 6, x, editor.scrY1 + 6)
    end
end

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
local hintText1 = [[
Help (Edit)
  Num1-7: add note
  +shift: add downwards
  +ctrl: delete note
  +alt: switch grid step

  alt + Left/Right: set note aside
  alt + Up/Dn: move chord by grid

  Bksp: delete note

  Enter: add new chord

  Del: delete chord(s)

  '/': switch base note

  '.': switch mute note
]]
local hintText2 = [[
Help (Navigation)
  Arrow: move cursor
  +shift: create selection
  +ctrl: view scroll

  PgUp/PgDn: move cursor by 4
  Home/End: move cursor to start/end

  Space: play chord(s)
  +shift: play note

  Ctrl+A: select all

  Ctrl+C: copy selected
  Ctrl+X: cut selected
  Ctrl+V: paste after cursor
  Shift+V: paste before cursor

  Tab: dark/light theme
  F11: toggle fullscreen
]]
scene.widgetList = {
    WIDGET.new {
        type = 'hint', text = "?",
        fontSize = 50, frameColor = COLOR.lG, textColor = { .62, .9, .62 },
        pos = { 1, 0 }, x = -40, y = 40, w = 60,
        labelPos = 'bottomLeft',
        floatText = hintText1,
        floatFillColor = { .1, .1, .1, .62 },
    },
    WIDGET.new {
        type = 'hint', text = "?",
        fontSize = 50, frameColor = COLOR.lR, textColor = { 1, .62, .62 },
        pos = { 1, 0 }, x = -110, y = 40, w = 60,
        labelPos = 'bottomLeft',
        floatText = hintText2,
        floatFillColor = { .1, .1, .1, .62 },
    },
}

SCN.add('main', scene)
