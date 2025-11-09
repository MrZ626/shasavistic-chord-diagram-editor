local themes = require('themes')
local ssvc = require('chord')
local audio = require('audio')
local edit = require('editor')
local converter = require('svg_converter')

local min, floor = math.min, math.floor
local sin, cos = math.sin, math.cos
local abs, log = math.abs, math.log
local tostring = tostring
local KBisDown = love.keyboard.isDown

local toggles = {
    charge = 0,
    theme = 'dark',
    chordGraph = true,
    keyboard = true,
    cursor = true,
    chordDist = 1.2,
    noteWidth = .014,
}

---@type Zenitha.Scene
local scene = {}

function scene.load()
    edit:newChord(1)
    edit:moveCursor(0)
end

function scene.wheelMove(_, dy)
    if KBisDown('lshift', 'rshift') then
        edit:scroll(-dy / 2.6, 0)
    elseif KBisDown('lctrl', 'rctrl') then
        edit:scale(1 + dy * .1)
    else
        edit:scroll(0, -dy / 2.6)
    end
end

function scene.keyDown(key, isRep)
    if key == 'lctrl' or key == 'rctrl' or key == 'lshift' or key == 'rshift' or key == 'lalt' or key == 'ralt' then return true end
    local CTRL = KBisDown('lctrl', 'rctrl')
    local SHIFT = KBisDown('lshift', 'rshift')
    local ALT = KBisDown('lalt', 'ralt')

    if key == 'space' then
        if isRep then return true end
        if edit.playing and (edit.playL < edit.playR or edit.selMark and edit.cursor ~= edit.selMark) then
            edit:stopPlaying()
        elseif SHIFT then
            -- Play selected note
            audio.playNote(edit.curPitch)
        else
            -- Play selected chords
            edit.playL, edit.playR = edit:getSelection()
            edit.playing = edit.playL
            -- editor.timer0 = .5 + .5 / (editor.playR - editor.playL + 1)
            edit:playChord()
        end
    elseif key == 'down' or key == 'up' then
        if CTRL then return true end
        if ALT then
            -- Move chord
            local s, e = edit:getSelection()
            for i = s, e do
                edit:moveChord(edit.chordList[i], key == 'up' and edit.gridStep[1] or -edit.gridStep[1])
            end
            edit:focusCursor()
            edit:step()
        else
            -- Select note
            local noteList = edit.chordList[edit.cursor].noteList
            local curPos
            for i = 1, #noteList do
                if noteList[i].pitch == edit.curPitch then
                    curPos = i
                    break
                end
            end
            if not curPos then return end
            if key == 'up' then
                while curPos < #noteList and (noteList[curPos].pitch <= edit.curPitch) do curPos = curPos + 1 end
            else
                while curPos > 1 and (noteList[curPos].pitch >= edit.curPitch) do curPos = curPos - 1 end
            end

            edit.curPitch = noteList[curPos].pitch
            edit.ghostPitch = edit.curPitch
            edit.nCur = noteList[curPos].path
            edit:refreshText()
            edit:focusCursor()
        end
    elseif key == 'left' or key == 'right' then
        if CTRL then return true end
        if ALT then
            -- Bias note
            if #edit.nCur == 0 then return true end
            local chord, curNote = edit:getChord(), edit:getNote()
            curNote.bias = MATH.clamp((curNote.bias or 0) + (key == 'left' and -1 or 1), -5, 5)
            if curNote.bias == 0 then curNote.bias = nil end
            edit:renderChord(chord)
            edit:focusCursor()
            edit:step()
        else
            -- Move cursor (normally)
            edit:moveCursor(key == 'left' and -1 or 1)
            edit:focusCursor()
        end
    elseif key == 'pageup' then
        if isRep then return true end
        edit:moveCursor(-4)
        edit:focusCursor()
    elseif key == 'pagedown' then
        if isRep then return true end
        edit:moveCursor(4)
        edit:focusCursor()
    elseif key == 'home' then
        if isRep then return true end
        edit:moveCursor(-1e99)
        edit:focusCursor()
    elseif key == 'end' then
        if isRep then return true end
        edit:moveCursor(1e99)
        edit:focusCursor()
    elseif key == 'return' then
        if isRep then return true end
        -- Create new chord
        edit:newChord(edit.cursor + 1, not CTRL)
        edit:moveCursor(1)
        edit:focusCursor()
        edit:step()
    elseif key == 'backspace' then
        if isRep then return true end
        if ALT then
            -- Reset current chord's pitch
            local chord = edit:getChord()
            chord.pitchVec = TABLE.new(0, 9)
            edit:reCalculatePitch(chord, 1)
            edit.curPitch = 1
            edit.ghostPitch = edit.curPitch
            edit:focusCursor()
            edit:step()
        else
            -- Delete selected note
            edit:deleteCursorNote()
            edit:focusCursor()
            edit:step()
        end
    elseif key == 'delete' then
        if isRep then return true end
        -- Delete current chord
        edit:deleteChord(edit:getSelection())
        edit.selMark = false
        edit:focusCursor()
        edit:step()
    elseif key == 'q' then
        toggles.charge = toggles.charge + 1
    elseif #key == 1 and MATH.between(key, '0', '9') then
        if isRep then return true end

        local keyNum = (key == '0' and 10 or key) + toggles.charge * 10
        toggles.charge = 0
        if not ssvc.dimData[keyNum] then return end
        ---@cast keyNum number

        if ALT then
            -- Set custom grid step
            edit.gridStep[2] = nil
            TABLE.delete(edit.gridStep, keyNum)
            table.insert(edit.gridStep, 1, keyNum)
            edit.gridStepAnimTimer = .42
            edit:focusCursor()
        else
            -- Add/Remove note
            local step = keyNum
            if SHIFT then step = -step end
            local curNote = edit:getNote()
            local exist
            for i = 1, #curNote do
                if curNote[i].d == step then
                    exist = i
                    break
                end
            end

            local pitch = edit.curPitch * ssvc.dimData[step].freq
            local needRender
            if not exist then
                edit:addNote({ d = step, pitch = pitch })
                needRender = true
            end
            if CTRL then
                curNote.mode = 'mute'
                needRender = true
            end
            if needRender then edit:renderChord(edit:getChord()) end
            edit:focusCursor()
            edit:step()

            audio.playNote(pitch, nil, .26)
        end
    elseif ALT and key == 'm' then
        if isRep then return true end
        -- Mark selected note as mute note
        local curNote = edit:getNote()
        curNote.mode = curNote.mode ~= 'mute' and 'mute' or nil
        edit:renderChord(edit:getChord())
        edit:focusCursor()
        edit:step()
    elseif ALT and key == 'h' then
        if isRep then return true end
        -- Mark selected note as hidden note
        local curNote = edit:getNote()
        curNote.mode = curNote.mode ~= 'skip' and 'skip' or nil
        edit:renderChord(edit:getChord())
        edit:focusCursor()
        edit:step()
    elseif ALT and key == 't' then
        if isRep then return true end
        -- Switch tension note
        local curNote = edit:getNote()
        curNote.mode = curNote.mode ~= 'tense' and 'tense' or nil
        edit:renderChord(edit:getChord())
        edit:focusCursor()
        edit:step()
    elseif ALT and key == 'p' then
        if isRep then return true end
        -- Switch pink note
        local curNote = edit:getNote()
        curNote.mode = curNote.mode ~= 'pink' and 'pink' or nil
        edit:renderChord(edit:getChord())
        edit:focusCursor()
        edit:step()
    elseif ALT and key == 'b' then
        if isRep then return true end
        -- Mark selected note as base
        edit:switchBase()
        edit:focusCursor()
        edit:step()
    elseif ALT and key == 'l' then
        if isRep then return true end
        -- Switch extended line
        edit:switchExtended()
        edit:focusCursor()
        edit:step()
    elseif CTRL and key == 'a' then
        if isRep then return true end
        -- Select all
        edit:moveCursor(-1e99)
        edit.selMark = #edit.chordList
        edit:focusCursor()
    elseif CTRL and key == 'c' then
        if isRep then return true end
        -- Copy
        local res = edit:dumpChord(true, edit:getSelection())
        CLIPBOARD.set(table.concat(res, ' '))
        MSG('check', "Copied " .. #res .. " chords")
    elseif CTRL and key == 'x' then
        if isRep then return true end
        -- Cut (Copy+Delete)
        local res = edit:dumpChord(true, edit:getSelection())
        CLIPBOARD.set(table.concat(res, ' '))
        edit:deleteChord(edit:getSelection())
        edit:moveCursor(0)
        edit.selMark = false
        MSG('check', "Cut " .. #res .. " chords")
        edit:focusCursor()
        edit:step()
    elseif CTRL and key == 'v' then
        if isRep then return true end
        -- Paste (after)
        local count = edit:pasteChord(CLIPBOARD.get(), edit.cursor)
        MSG('check', "Pasted " .. count .. " chords")
        edit:focusCursor()
        edit:step()
    elseif SHIFT and key == 'v' then
        if isRep then return true end
        -- Paste (before)
        edit.cursor = edit.cursor - 1
        local count = edit:pasteChord(CLIPBOARD.get(), edit.cursor)
        MSG('check', "Pasted " .. count .. " chords")
        edit.cursor = edit.cursor + 1
        edit:focusCursor()
        edit:step()
    elseif CTRL and key == 'e' then
        if isRep then return true end
        -- Export SVG
        local fileName = os.date("progression_%y%m%d_%H%M%S.svg") ---@cast fileName string
        local s, e = edit:getSelection()
        local chordPitches = {}
        for i = 1, #edit.chordList do
            chordPitches[i] = log(edit.chordList[i].tree.pitch, 2)
        end
        FILE.save(converter(
            edit:dumpChord(false, s, e),
            chordPitches,
            toggles.chordDist,
            nil,
            nil,
            toggles.noteWidth,
            TABLE.removeDuplicate(edit.gridStep)
        ), fileName)
        MSG('check', ("Exported %d chord%s to file " .. fileName .. ",\nPress Ctrl+D to open the export directory"):format(
            e - s + 1,
            e > s and "s" or ""
        ))
    elseif CTRL and key == 'd' then
        if isRep then return true end
        UTIL.openSaveDirectory()
    elseif CTRL and key == 'z' then
        edit:undo()
    elseif CTRL and key == 'y' then
        edit:redo()
    elseif key == 'f1' then
        if isRep then return true end
        toggles.theme = toggles.theme == 'dark' and 'bright' or 'dark'
        ssvc.env.theme = toggles.theme
        edit:reRenderAll()
        MSG('info', "Theme: " .. (toggles.theme == 'dark' and "Dark" or "Light"), .26)
    elseif key == 'f2' then
        if isRep then return true end
        toggles.keyboard = not toggles.keyboard
        MSG('info', toggles.keyboard and "Show keyboard" or "Hide keyboard", .26)
    elseif key == 'f3' then
        if isRep then return true end
        toggles.chordGraph = not toggles.chordGraph
        MSG('info', toggles.chordGraph and "Show chord graph" or "Hide chord graph", .26)
    elseif key == 'f4' then
        if isRep then return true end
        toggles.cursor = not toggles.cursor
        MSG('info', toggles.cursor and "Show cursor" or "Hide cursor", .26)
    elseif key == 'f5' then
        if isRep then return true end
        if toggles.chordDist > 1 then
            toggles.chordDist = MATH.roundUnit(MATH.clamp(toggles.chordDist - .1, 1, 1.5), .1)
            edit.chordDist = toggles.chordDist
            ssvc.env.chordDist = toggles.chordDist
            edit:reRenderAll()
        end
        MSG('info', "Chord distance: " .. (toggles.chordDist * 100) .. "%", .26)
    elseif key == 'f6' then
        if isRep then return true end
        if toggles.chordDist < 1.5 then
            toggles.chordDist = MATH.roundUnit(MATH.clamp(toggles.chordDist + .1, 1, 1.5), .1)
            edit.chordDist = toggles.chordDist
            ssvc.env.chordDist = toggles.chordDist
            edit:reRenderAll()
        end
        MSG('info', "Chord distance: " .. (toggles.chordDist * 100) .. "%", .26)
    elseif key == 'f7' then
        if isRep then return true end
        if toggles.noteWidth > .010 then
            toggles.noteWidth = MATH.roundUnit(MATH.clamp(toggles.noteWidth - .004, .010, .026), .002)
            ssvc.env.noteW = toggles.noteWidth
            edit:reRenderAll()
        end
        MSG('info', "Note width: " .. toggles.noteWidth * 1000, .26)
    elseif key == 'f8' then
        if isRep then return true end
        if toggles.noteWidth < .026 then
            toggles.noteWidth = MATH.roundUnit(MATH.clamp(toggles.noteWidth + .004, .010, .026), .002)
            ssvc.env.noteW = toggles.noteWidth
            edit:reRenderAll()
        end
        MSG('info', "Note width: " .. toggles.noteWidth * 1000, .26)
    elseif key == 'escape' then
        if isRep then return true end
        -- Clear selection
        edit.selMark = false
    end
    return true
end

-- function scene.keyUp(key)
-- end

function scene.update(dt)
    edit:update(dt)
    audio.update(dt)
end

local gc = love.graphics
local gc_push, gc_pop = gc.push, gc.pop
local gc_clear, gc_replaceTransform = gc.clear, gc.replaceTransform
local gc_translate, gc_rotate, gc_scale = gc.translate, gc.rotate, gc.scale
local gc_setColor, gc_setLineWidth = gc.setColor, gc.setLineWidth
local gc_print, gc_draw, gc_line = gc.print, gc.draw, gc.line
local gc_rectangle, gc_circle = gc.rectangle, gc.circle
local gc_setAlpha = GC.setAlpha
local gc_mDraw, gc_strokeDraw = GC.mDraw, GC.strokeDraw

local keyboardQuad = GC.newQuad(0, 0, 137, 543 * 30, TEX.dark.keyboard)
TEX.dark.keyboard:setWrap('clampzero', 'repeat')
TEX.bright.keyboard:setWrap('clampzero', 'repeat')

local CGD = { -- Chord Graph data
    [0] = { a = 0 },
    { a = 0 },
    { a = -1 },
    { a = 1 },
    { a = -.5 },
    { a = .5 },
    { a = -.25 },
    { a = .25 },
    { a = -.75 },
    { a = .75 },
}
local spread = 3.141592653589793 / 4
for i = 0, #CGD do
    CGD[i].a = CGD[i].a * spread
    CGD[i].l = log(ssvc.dimData[i].freq, 2) / cos(CGD[i].a)
    CGD[-i] = TABLE.copyAll(CGD[i])
    CGD[-i].l = -CGD[-i].l
end
local CGNB = {} -- Chord Graph note buffer
local function getCGMove(dim, k, x, y)
    local D = CGD[dim]
    if not D then return end
    local l, a = D.l * (k or 1), D.a
    local dx, dy = l * cos(a), l * sin(a)
    if x then
        return x + dx, y + dy
    else
        return dx, dy
    end
end
local theme
local function drawCGNote(note, x, y, alpha)
    for i = 1, #note do
        local dim = note[i].d
        local nx, ny = getCGMove(dim, 1, x, y)
        if nx then
            gc_setColor(theme.dimGridColor[abs(dim)])
            gc_setAlpha(.0626 * alpha)
            gc_line(x, y, nx, ny)
            CGNB[#CGNB + 1] = nx
            CGNB[#CGNB + 1] = ny
            drawCGNote(note[i], nx, ny, alpha)
        end
    end
end
function scene.draw()
    theme = themes[toggles.theme]
    local tex = TEX[toggles.theme] ---@type SSVC.TextureMap
    local X, Y, K = edit.scrX1, edit.scrY1, edit.scrK1

    FONT.set(30)

    -- Background
    gc_clear(theme.bgbase)
    gc_replaceTransform(SCR.xOy)
    gc_setColor(theme.bg)
    gc_rectangle('fill', 0, 0, SCR.w0, SCR.h0)

    -- Chord Graph in background
    if toggles.chordGraph then
        gc_replaceTransform(SCR.xOy_m)
        gc_scale(260 * edit.scrK1)
        gc_rotate(-1.5708)
        gc_setLineWidth(.06)
        local len = 26
        gc_setColor(1, 1, 1, .02); gc_line(0, -len, 0, len)
        gc_setColor(1, 1, 1, .06); gc_line(-len, 0, len, 0)
        local chord, alpha
        if edit.playing then
            chord = edit.chordList[edit.playing]
            alpha = 4.2
        else
            chord = edit:getChord()
            alpha = 1
        end
        -- Base movement
        for i = 1, 7 do
            local n = chord.pitchVec[i]
            if n ~= 0 then
                local dx, dy = getCGMove(i)
                gc_setColor(1, 1, 1, .01 * alpha)
                gc_line(0, 0, dx * n, dy * n)
                gc_translate(dx * n, dy * n)
            end
        end
        -- Lines
        drawCGNote(chord.tree, 0, 0, alpha)
        -- Notes
        gc_setLineWidth(.012)
        gc_setColor(1, 1, 1, .1 * alpha); for i = 1, #CGNB, 2 do gc_circle('fill', CGNB[i], CGNB[i + 1], .07, 4) end
        gc_setColor(0, 0, 0, .1 * alpha); for i = 1, #CGNB, 2 do gc_circle('line', CGNB[i], CGNB[i + 1], .08, 4) end
        TABLE.clear(CGNB)
        -- Root
        gc_setLineWidth(.016)
        gc_circle('fill', 0, 0, .08, 4)
        gc_circle('line', 0, 0, .11, 4)
        gc_setColor(1, 1, 1, .1 * alpha)
        gc_circle('line', 0, 0, .09, 4)
    end

    -- Grid step icon
    if edit.gridStepAnimTimer > 0 then
        gc_replaceTransform(SCR.xOy_m)
        gc_setColor(1, 1, 1, edit.gridStepAnimTimer)
        gc_mDraw(tex.symbol[edit.gridStep[1]] or tex.symbol[1], 0, 0, 0, 2)
    end

    -- L4MPLIGHT
    gc_replaceTransform(SCR.xOy_ur)
    gc_setColor(1, 1, 1, .26)
    gc_mDraw(TEX.lamplight, -40, 40, 0, .16)

    -- Camera
    gc_replaceTransform(SCR.xOy_l)
    gc_translate(100, 0)
    gc_scale(260 * K)
    gc_translate(-X, -Y)
    local topY = Y - 2.6 / K
    local btmY = Y + 2.6 / K

    -- Cursor Light
    if toggles.cursor then
        local y = -log(edit.curPitch1, 2)
        gc_setColor(theme.cursorLight1)
        gc_draw(TEX.transition, X - .4, y, 0, 8 / 128, 12 / 128, 0, .5)
        gc_setColor(theme.cursorLight2)
        gc_draw(TEX.transition, X - .4, y, 0, 8 / 128, 4 / 128, 0, .5)
    end

    -- Grid line
    gc_setLineWidth(.01)
    for i = #edit.gridStep, 1, -1 do
        local step = edit.gridStep[i]
        gc_setColor(theme.dimGridColor[step])
        gc_setAlpha(.7 - i * .2)
        local dist = log(ssvc.dimData[step].freq, 2)
        local y = 0
        gc_translate(X, 0)
        while y < 14.7 do
            gc_line(-2.6, y, 26, y)
            y = y + dist
        end
        y = -dist
        while y > -15.2 do
            gc_line(-2.6, y, 26, y)
            y = y - dist
        end
        gc_translate(-X, 0)
    end

    local dist = toggles.chordDist

    -- Selection
    do
        ---@type number, number
        local s, e = edit.cursor1, edit.selMark or edit.cursor1
        if s > e then s, e = e, s end
        s, e = (s - 1) * dist, e * dist
        gc_setColor(theme.select)
        gc_rectangle('fill', s, topY, e - s, btmY - topY)
        if edit.selMark then
            gc_setColor(theme.cursor)
            gc_draw(TEX.transition, s, 0, 0, .2 / 128, 12, 0, .5)
            gc_draw(TEX.transition, e, 0, 0, -.2 / 128, 12, 0, .5)
        end
    end

    -- Chords
    gc_push('transform')
    gc_translate((dist - 1) / 2, 0)
    for i = 1, #edit.chordList do
        -- Separator line
        gc_setColor(theme.sepLine)
        gc_setLineWidth(.01)
        gc_line((dist + 1) / 2, topY, (dist + 1) / 2, btmY)

        -- Chord textures
        gc_setColor(1, 1, 1)
        local drawData = edit.chordList[i].drawData
        local dy = -log(edit.chordList[i].tree.pitch, 2)
        -- if not edit.selMark and i == edit.cursor then
        --     local float = .006 + .002 * sin(love.timer.getTime() * 2.6)
        --     for j = 1, #drawData do
        --         local d = drawData[j]
        --         local t = tex[d.texture]
        --         local x, y = d.x, dy + d.y
        --         local kx, ky = d.w / t:getWidth(), d.h / t:getHeight()
        --         gc_setColorMask(true, false, false, false)
        --         gc_draw(t, x, y - float, 0, kx, ky)
        --         gc_setColorMask(false, true, false, false)
        --         gc_draw(t, x, y, 0, kx, ky)
        --         gc_setColorMask(false, false, true, false)
        --         gc_draw(t, x, y + float, 0, kx, ky)
        --         gc_setColorMask()
        --     end
        -- end
        for j = 1, #drawData do
            local d = drawData[j]
            local t = tex[d.texture]
            gc_setColor(d.color)
            gc_draw(t, d.x, dy + d.y, 0, d.w / t:getWidth(), d.h / t:getHeight())
        end

        -- Chord Code
        gc_setColor(theme.text)
        gc_scale(1 / K)
        local text = edit.chordList[i].textObj
        gc_draw(text, .03, 1.75 + Y * K, 0, min(.004, 1.14 / text:getWidth() * K), .004)
        gc_scale(K)

        gc_translate(dist, 0)
    end
    gc_pop()

    -- Keyboard
    if toggles.keyboard then
        gc_setColor(1, 1, 1, MATH.clampInterpolate(.1, 1, .26, .26, X))
        gc_draw(tex.keyboard, keyboardQuad, X - .36, -15.206, 0, .00184)
    end

    -- Cursor
    if toggles.cursor then
        local x, y = dist * (edit.cursor1 - 1), -log(edit.curPitch1, 2)
        gc_setColor(theme.cursor)
        gc_setAlpha(.7 + .3 * sin(love.timer.getTime() * 6.2))
        gc_setLineWidth(.01)
        gc_rectangle('line', x, y - .03, dist, .06)
        if edit.ghostPitch ~= edit.curPitch then
            gc_setAlpha(.1)
            gc_rectangle('fill', x, -log(edit.ghostPitch, 2) - .03, dist, .06)
        end
        gc_setColor(0, 0, 0)
        gc_strokeDraw('corner', .0042, edit.cursorText, x - .04, y - .16, 0, .0035)
        gc_setColor(theme.cursor)
        gc_draw(edit.cursorText, x - .04, y - .16, 0, .0035)
        gc_setColor(theme.text)
        gc_print(tostring(floor(440 * edit.curPitch)), X - .37, y - .09, 0, .0018)
    end

    -- Playing selection
    if edit.playing then
        local s, e = edit.playL, edit.playR
        s, e = (s - 1) * dist, e * dist
        gc_setColor(theme.preview)
        gc_draw(TEX.transition, s, 0, 0, .2 / 128, 12, 0, .5)
        gc_draw(TEX.transition, e, 0, 0, -.2 / 128, 12, 0, .5)
        gc_setLineWidth(.026)
        gc_setColor(theme.playline)
        local progress = edit.playing + (1 - edit.timer / edit.timer0)
        local x = MATH.interpolate(edit.playL, s, edit.playR + 1, e, progress)
        gc_line(x, topY, x, btmY)
    end

    -- gc_replaceTransform(SCR.xOy)
    -- gc_setColor(1,1,1)
    -- gc_print(edit.scrX,100,0)
end

local aboutText = [[
Based on Shasavistic Music Theory
Theory & Art designed by L4MPLIGHT
Chord Graph designed by Hojo Minori
App designed & developed by MrZ_26
]]
local hintText1 = [[
Help (Edit)
Num(1-9,0,Q)    Add note
Shift+[Num]     Add downwards
Alt+M           Mute note
Alt+H            Hide note
Alt+T            Mark tense note
Alt+P            Mark pink(?) note
Alt+B            Mark base note
Alt+L            Add extended line
Ctrl+[Num]      Mute & Add note

Alt+[Num]       Change grid step
Alt+Up/Down    Move chord
Alt+Left/Right   Nudge note

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
Ctrl+E                    Export selected as SVG
Ctrl+D                    Open export directory
Ctrl+Z/Y                  Undo/Redo

F1                        Switch theme
F2                        Toggle keyboard
F3                        Toggle chord graph
F4                        Toggle cursor
F5 & F6                  Adjust Chord distance
F7 & F8                  Adjust Note width
F11                        Fullscreen
]]
hintText1 = hintText1:gsub(" ", "  ")
hintText2 = hintText2:gsub(" ", "  ")
hintText1 = hintText1:gsub("(%S)  (%S)", "%1 %2")
hintText2 = hintText2:gsub("(%S)  (%S)", "%1 %2")
scene.widgetList = {
    WIDGET.new {
        type = 'hint',
        fontSize = 50, frameColor = COLOR.X,
        pos = { 1, 0 }, x = -40, y = 40, w = 60,
        labelPos = 'bottomLeft',
        floatText = aboutText,
        floatFontSize = 30,
        floatFillColor = { .1, .1, .1, .62 },
    },
    WIDGET.new {
        type = 'hint', text = "?",
        fontSize = 50, frameColor = COLOR.lG, textColor = { .62, .9, .62 },
        pos = { 1, 0 }, x = -110, y = 40, w = 60,
        labelPos = 'bottomLeft',
        floatText = hintText1,
        floatFontSize = 30,
        floatFillColor = { .1, .1, .1, .62 },
    },
    WIDGET.new {
        type = 'hint', text = "?",
        fontSize = 50, frameColor = COLOR.lR, textColor = { 1, .62, .62 },
        pos = { 1, 0 }, x = -180, y = 40, w = 60,
        labelPos = 'bottomLeft',
        floatText = hintText2,
        floatFontSize = 30,
        floatFillColor = { .1, .1, .1, .62 },
    },
}

return scene
