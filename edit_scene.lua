local themes = require('themes')
local ssvc = require('chord')
local audio = require('audio')
local editor = require('editor')
local converter = require('svg_converter')

local ins = table.insert
local abs, floor = math.abs, math.floor
local sin, log = math.sin, math.log

---@type Zenitha.Scene
local scene = {}

function scene.load()
    editor:newChord(1)
    editor:moveCursor(0)
end

function scene.mouseMove(_, _, dx, dy)
end

function scene.wheelMove(_, dy)
    if editor.combo == 'S' then
        editor:scroll(-dy / 2.6, 0)
    elseif editor.combo == 'C' then
        editor:scale(1 + dy * .1)
    else
        editor:scroll(0, -dy / 2.6)
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
            editor.playL, editor.playR = editor:getSelection()
            editor.playing = editor.playL
            -- editor.timer0 = .5 + .5 / (editor.stop - editor.start + 1)
            editor.timer0 = .626
            editor:playChord()
        end
    elseif key == 'down' or key == 'up' then
        if editor.combo == 'C' then return true end
        if editor.combo == 'A' then
            -- Move chord
            local s, e = editor:getSelection()
            for i = s, e do
                editor:moveChord(editor.chordList[i], key == 'up' and editor.gridStep or -editor.gridStep)
            end
            editor:focusCursor()
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
            editor:focusCursor()
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
            editor:focusCursor()
        else
            -- Move cursor (normally)
            editor:moveCursor(key == 'left' and -1 or 1)
            editor:focusCursor()
        end
    elseif key == 'pageup' then
        if isRep then return true end
        editor:moveCursor(-4)
        editor:focusCursor()
    elseif key == 'pagedown' then
        if isRep then return true end
        editor:moveCursor(4)
        editor:focusCursor()
    elseif key == 'home' then
        if isRep then return true end
        editor:moveCursor(-1e99)
        editor:focusCursor()
    elseif key == 'end' then
        if isRep then return true end
        editor:moveCursor(1e99)
        editor:focusCursor()
    elseif key == 'return' then
        if isRep then return true end
        editor.combo = ''
        -- Create new chord
        editor:newChord(editor.cursor + 1)
        editor:moveCursor(1)
        editor:focusCursor()
    elseif key == 'backspace' then
        if isRep then return true end
        if editor.combo == 'A' then
            local chord = editor:getChord()
            editor:reCalculatePitch(chord.tree, 1)
            editor.curPitch = 1
            editor:focusCursor()
        else
            -- Delete selected note
            editor:deleteCursorNote()
            editor:focusCursor()
        end
    elseif key == 'delete' then
        if isRep then return true end
        -- Delete current chord
        editor:deleteChord(editor:getSelection())
        editor:moveCursor(0)
        editor.selMark = false
        editor:focusCursor()
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
        editor:focusCursor()
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
        editor:focusCursor()
    elseif #key == 1 and MATH.between(tonumber(key) or 0, 1, 7) then
        if isRep then return true end

        local keyNum = tonumber(key)
        ---@cast keyNum number

        if editor.combo == 'A' then
            -- Set custom grid step
            editor.gridStep = keyNum
            editor.gridStepAnimTimer = .42
            editor:focusCursor()
        elseif editor.combo == '' then
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

            local pitch = editor.curPitch * ssvc.dimData[step].freq
            if not exist then
                ins(curNote, { d = step, pitch = pitch })
                table.sort(curNote, editor._levelSorter)
                editor:redrawChord(chord)
            end
            audio.playNote(pitch, key)
            editor:focusCursor()
        end
    elseif key == 'tab' then
        if isRep then return true end
        editor:switchTheme()
    elseif key == 'a' then
        if editor.combo == 'C' then
            -- Select all
            editor:moveCursor(-1e99)
            editor.selMark = #editor.chordList
            editor:focusCursor()
        end
    elseif key == 'c' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Copy
            local res = editor:dumpChord(editor:getSelection())
            CLIPBOARD.set(table.concat(res, ' '))
            MSG('check', "Copied " .. #res .. " chords")
        end
    elseif key == 'x' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Cut (Copy+Delete)
            local res = editor:dumpChord(editor:getSelection())
            CLIPBOARD.set(table.concat(res, ' '))
            editor:deleteChord(editor:getSelection())
            editor:moveCursor(0)
            editor.selMark = false
            MSG('check', "Cut " .. #res .. " chords")
            editor:focusCursor()
        end
    elseif key == 'v' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Paste (after)
            local count = editor:pasteChord(CLIPBOARD.get())
            MSG('check', "Pasted " .. count .. " chords")
            editor:focusCursor()
        elseif editor.combo == 'S' then
            -- Paste (before)
            editor.cursor = editor.cursor - 1
            local count = editor:pasteChord(CLIPBOARD.get())
            MSG('check', "Pasted " .. count .. " chords")
            editor.cursor = editor.cursor + 1
            editor:focusCursor()
        end
    elseif key == 'e' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Export SVG
            local fileName = os.date("progression_%y%m%d_%H%M%S.svg") ---@cast fileName string
            local s, e = editor:getSelection()
            FILE.save(converter(editor:dumpChord(s, e)), fileName)
            MSG('check', ("Exported %d chord%s to file " .. fileName .. ",\nPress Ctrl+D to open the export directory"):format(
                e - s + 1,
                e > s and "s" or ""
            ))
        end
    elseif key == 'd' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Open export directory
            UTIL.openSaveDirectory()
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
    editor:update(dt)
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
local gc_strokeDraw = GC.strokeDraw

local keyboardQuad = GC.newQuad(0, 0, 137, 543 * 6, TEX.dark.keyboard)
TEX.dark.keyboard:setWrap('clampzero', 'repeat')
TEX.bright.keyboard:setWrap('clampzero', 'repeat')
function scene.draw()
    local theme = themes[editor.theme]
    local tex = TEX[editor.theme] ---@type SSVT.TextureMap

    FONT.set(30)

    gc_clear(theme.bgbase)

    gc_replaceTransform(SCR.xOy)
    gc_setColor(theme.bg)
    gc_rectangle('fill', 0, 0, SCR.w0, SCR.h0)

    if editor.gridStepAnimTimer > 0 then
        gc_replaceTransform(SCR.xOy_m)
        gc_setColor(1, 1, 1, editor.gridStepAnimTimer)
        GC.mDraw(tex.symbol[editor.gridStep], 0, 0, 0, 2)
    end

    gc_replaceTransform(SCR.xOy_l)
    gc_translate(100, 0)
    gc_scale(260 * editor.scrK1)
    gc_translate(-editor.scrX1, -editor.scrY1)
    local topY = editor.scrY1 - 2.6 / editor.scrK1
    local btmY = editor.scrY1 + 2.6 / editor.scrK1

    -- Grid line
    do
        gc_setLineWidth(.01)
        gc_setColor(theme.dimGridColor[editor.gridStep])
        local dist = log(ssvc.dimData[editor.gridStep].freq, 2)
        local y = 0
        gc_translate(editor.scrX1, 0)
        while y < 2.6 do
            gc_line(-2.6, y, 26, y)
            y = y + dist
        end
        y = -dist
        while y > -3.5 do
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
        gc_rectangle('fill', s, topY, e - s, btmY - topY)
        if editor.selMark then
            gc_setColor(theme.cursor)
            gc_draw(TEX.transition, s, 0, 0, .2 / 128, 12, 0, .5)
            gc_draw(TEX.transition, e, 0, 0, -.2 / 128, 12, 0, .5)
        end
    end

    -- Chords
    gc_push('transform')
    for i = 1, #editor.chordList do
        -- Separator line
        gc_setColor(theme.sepLine)
        gc_setLineWidth(.01)
        gc_line(1.2, topY, 1.2, btmY)

        -- Chord textures
        gc_setColor(1, 1, 1)
        local drawData = editor.chordList[i].drawData
        local dy = -log(editor.chordList[i].tree.pitch, 2)
        for j = 1, #drawData do
            local d = drawData[j]
            local t = tex[d.texture]
            gc_draw(t, .1 + d.x, dy + d.y, 0, d.w / t:getWidth(), d.h / t:getHeight())
        end

        -- Chord Code
        local y = ((i % 2 == 1 and .75 or 1) - 2.6) / editor.scrK1 + editor.scrY1
        gc_setColor(theme.text)
        gc_print(editor.chordList[i].text, .05, y, 0, .005)
        gc_setAlpha(.26)
        gc_print(i, .05, y - .07, 0, .003)

        gc_translate(1.2, 0)
    end
    gc_pop()

    -- Keyboard
    gc_setColor(1, 1, 1, MATH.clampInterpolate(.1, 1, .26, .26, editor.scrX1))
    gc_draw(tex.keyboard, keyboardQuad, editor.scrX1 - .36, -3.206, 0, .00184)

    -- Cursor
    do
        gc_setColor(theme.cursor)
        local x, y = 1.2 * (editor.cursor1 - 1), -log(editor.curPitch1, 2)
        gc_draw(TEX.transition, editor.scrX1 - .62, y, 0, .62 / 128, 2.6 / 128, 0, .5)
        gc_print(floor(440 * editor.curPitch), editor.scrX1 - .37, y - .09, 0, .0018)
        gc_setAlpha(.7 + .3 * sin(love.timer.getTime() * 6.2))
        gc_setLineWidth(.01)
        gc_rectangle('line', x, y - .03, 1.2, .06)
        gc_setColor(0, 0, 0)
        gc_strokeDraw('corner', .0042, editor.cursorText, x - .04, y - .16, 0, .0035)
        gc_setColor(theme.cursor)
        gc_draw(editor.cursorText, x - .04, y - .16, 0, .0035)
    end

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
        gc_line(x, topY, x, btmY)
    end
end

local hintText1 = [[
Help (Edit)
1-7               Add note
Shift+1-7         Add downwards
/                 Mark base note
.                 Mute note

Alt+1-7          Change grid step
Alt+Up/Down    Move chord
Alt+Left/Right   Bias note

Bksp             Delete note
Alt+Bksp         Reset chord pitch

Enter            Add chord
Delete           Delete chord
]]
local hintText2 = [[
Help (Navigation)
(Ctrl/Shift+)WHEEL      Scroll & Zoom

ARROW                  Move cursor
PgUp/PgDn/Home/End  Fast Move
Ctrl+ARROW/'-'/'='       Scroll & Zoom

Shift+[Move]             Create selection
Ctrl+A                    Select all
Ctrl+C/V/X               Copy/Paste/Cut
Shift+V                   Paste before cursor
Ctrl+E                    Export SVG
Ctrl+D                    Open export directory

Tab                       Switch theme
F11                        Fullscreen
]]
hintText1 = hintText1:gsub(" ", "  ")
hintText2 = hintText2:gsub(" ", "  ")
scene.widgetList = {
    WIDGET.new {
        type = 'hint', text = "?",
        fontSize = 50, frameColor = COLOR.lG, textColor = { .62, .9, .62 },
        pos = { 1, 0 }, x = -40, y = 40, w = 60,
        labelPos = 'bottomLeft',
        floatText = hintText1,
        floatFontSize = 30,
        floatFillColor = { .1, .1, .1, .62 },
    },
    WIDGET.new {
        type = 'hint', text = "?",
        fontSize = 50, frameColor = COLOR.lR, textColor = { 1, .62, .62 },
        pos = { 1, 0 }, x = -110, y = 40, w = 60,
        labelPos = 'bottomLeft',
        floatText = hintText2,
        floatFontSize = 30,
        floatFillColor = { .1, .1, .1, .62 },
    },
}

return scene
