require 'Zenitha'

ZENITHA.setFirstScene('main')
ZENITHA.setShowFPS(false)
ZENITHA.setVersionText("")
ZENITHA.globalEvent.drawCursor = NULL
ZENITHA.globalEvent.clickFX = NULL
SCR.setSize(1600, 1000)

local ins, rem = table.insert, table.remove
local max, min = math.max, math.min
local floor, abs = math.floor, math.abs
local sin, log = math.sin, math.log

local KBisDown = love.keyboard.isDown

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

-- Audio Source
local srcCount = 0
---@type love.Source[]
local srcLib = {}
do
    local sampleRate = 48000
    local baseFreq = 440
    local loopCount = 62
    local snd = love.sound.newSoundData(floor(sampleRate / baseFreq * loopCount), sampleRate, 16, 1)
    for i = 0, snd:getSampleCount() - 1 do
        local t = i / sampleRate
        local v = sin(6.283185307179586 * baseFreq * t)
        snd:setSample(i, MATH.sign(v) * abs(v) ^ .8)
    end

    srcLib[1] = love.audio.newSource(snd, "static")
    srcLib[1]:setLooping(true)
    srcCount = 1

    snd:release()
end

---@type Map<love.Source>
local activeSrc = {}

local audio = {}

function audio.playNote(freq, key, volume)
    if #srcLib == 1 then
        srcLib[2] = srcLib[1]:clone()
        srcCount = srcCount + 1
    end
    for i = 2, #srcLib do
        local s = srcLib[i]
        if not s:isPlaying() then
            rem(srcLib, i)
            if activeSrc[key] then
                activeSrc[key]:stop()
                ins(srcLib, activeSrc[key])
            end
            activeSrc[key] = s
            s:setVolume(volume or .26)
            s:setPitch(freq)
            s:play()
            return
        end
    end
end

function audio.stopNote(key)
    local s = activeSrc[key]
    if s then
        s:stop()
        ins(srcLib, s)
        activeSrc[key] = nil
    end
end

---@class wrappedChord
---@field tree SSVT.Chord
---@field drawData table
---@field text string

local ssvt = require('chord')

local editor = {
    chordList = {}, ---@type wrappedChord[]
    editing = 0,
    selMark = false,
    cursor = {}, ---@type number[]
    cursorText = "0",
    curPitch = 1,
    combo = '', ---@type '' | 'C' | 'S' | 'A'
    scrX = 0,  -- Actual scroll position
    scrY = 0,
    scrX1 = 0, -- Smooth scroll position, follow {scrollX, editor.scrY} by time
    scrY1 = 0,
    theme = 'dark',
    customGrid = 2,
}

-- Scroll
function editor:scroll(dx, dy)
    self.scrX = MATH.clamp(self.scrX + dx, 0, (max(#self.chordList, 4.8) - 4.8) * 1.2)
    self.scrY = MATH.clamp(self.scrY + dy, -2, 2)
end

function editor:getChord()
    return self.chordList[self.editing]
end

function editor:getNote()
    return TABLE.listIndex(self.chordList[self.editing].tree, self.cursor)
end

function editor:refreshText()
    local buffer = "0"
    local tree = self:getChord().tree
    for i = 1, #self.cursor do
        tree = tree[self.cursor[i]]
        buffer = buffer .. (tree.d > 0 and '+' or '') .. tree.d
    end
    self.cursorText = buffer
end

function editor:reCalculatePitch(tree, curPitch)
    for _, v in next, tree do
        if type(v) == 'table' then
            self:reCalculatePitch(v, curPitch * ssvt.dimData[v.d].freq)
        end
    end
    tree.pitch = curPitch
end

function editor:redrawChord(chord)
    local data = ssvt.drawChord(chord.tree)
    chord.drawData = data
    chord.text = ssvt.encode(chord.tree)
end

function editor:newChord()
    local chord = {
        tree = { d = 0, pitch = 1 },
        text = "0",
    }
    self:redrawChord(chord)
    ins(self.chordList, self.editing + 1, chord)
    self:moveCursor(1)
end

function editor:moveCursor(offset)
    local newPos = MATH.clamp(self.editing + offset, 1, #self.chordList)
    if self.combo == 'S' then
        if not self.selMark then self.selMark = self.editing end
    elseif self.selMark then
        if abs(offset) == 1 then
            newPos = (offset == -1 and min or max)(self.editing, self.selMark)
        end
        self.selMark = false
    end
    if newPos ~= self.editing then
        self.editing = newPos
        TABLE.clear(self.cursor)
        self.curPitch = self:getChord().tree.pitch
        self:refreshText()
    end
    self.scrX = MATH.clamp(self.scrX, (self.editing - 4.8) * 1.2, (self.editing - 1) * 1.2)
end

function editor:moveChord(chord, step)
    self:reCalculatePitch(chord.tree, chord.tree.pitch * ssvt.dimData[step].freq)
    if chord == self.chordList[self.editing] then
        self.curPitch = chord.tree.pitch
    end
end

function editor:deleteChord(s, e)
    if s > e then s, e = e, s end
    for i = e, s, -1 do
        rem(self.chordList, i)
    end
    if self.editing > #self.chordList then self.editing = #self.chordList end
    if #self.chordList == 0 then self:newChord() end
end

function editor:switchTheme()
    self.theme = self.theme == 'bright' and 'dark' or 'bright'
end

function editor:dumpChords(s, e)
    if s > e then s, e = e, s end
    local buffer = {}
    for i = s, e do
        ins(buffer, '"' .. self.chordList[i].text .. '"')
    end
    return buffer
end

function editor:pasteChords(buffer, after)
    local s = after or self.editing
    local count = 0
    for str in buffer:gmatch('"(.-)"') do
        local chord = {
            tree = ssvt.decode(str),
            text = str,
        }
        self:reCalculatePitch(chord.tree, 1)
        self:redrawChord(chord)
        count = count + 1
        ins(self.chordList, s + count, chord)
    end
    return count
end

editor:newChord()


local themes = {
    bright = {
        bgbase = { COLOR.HEX 'DCD3C6' },
        bg = { COLOR.HEX 'E0D7CA' },
        sepLine = { COLOR.HEX '00000010' },
        select = { COLOR.HEX 'FF312618' },
        cursor = { COLOR.HEX 'FF312680' },
        preview = { COLOR.HEX '2680FF80' },
        playline = { COLOR.HEX '2680FF' },
        text = COLOR.D,
        dim = {
            { COLOR.HEX 'AAAAAA62' },
            { COLOR.HEX 'F2799262' },
            { COLOR.HEX '6CD98562' },
            { COLOR.HEX 'B598EE62' },
            { COLOR.HEX 'FFC24762' },
            { COLOR.HEX 'B5B50062' },
            { COLOR.HEX 'ED987762' },
        },
    },
    dark = {
        bgbase = { COLOR.HEX '61607B' },
        bg = { COLOR.HEX '65647F' },
        sepLine = { COLOR.HEX '00000010' },
        select = { COLOR.HEX 'F5C40018' },
        cursor = { COLOR.HEX 'F5C400FF' },
        preview = { COLOR.HEX '00F1F580' },
        playline = { COLOR.HEX '00F1F5' },
        text = COLOR.L,
        dim = {
            { COLOR.HEX 'AAAAAA42' },
            { COLOR.HEX 'F2799226' },
            { COLOR.HEX '2FD65626' },
            { COLOR.HEX 'AA88EE26' },
            { COLOR.HEX 'FFAA0126' },
            { COLOR.HEX 'B5B50026' },
            { COLOR.HEX 'ED987726' },
        },
    },
}

local preview = {
    playing = false,
    start = false,
    stop = false,
    count = 0,
    timer = 0,
}

function preview:stopChord(stopAll)
    for i = 1, self.count do audio.stopNote('chord' .. i) end
    if stopAll then
        self.start, self.stop = false, false
        self.playing = false
    end
end

function preview:playNextChord()
    if self.playing >= self.stop then
        self.playing = false
        self.start, self.stop = false, false
    else
        self.playing = self.playing + 1
        self:startChord()
    end
end

local temp = {}
function preview:startChord()
    if self.timer > 0 then self:stopChord() end

    self.coun = 0
    self.timer = self.timer0
    local chord = editor.chordList[self.playing]
    local allInfo = TABLE.flatten(TABLE.copyAll(chord.tree))
    local basePitch = -1e99
    for k in next, allInfo do
        if k:sub(-4) == 'base' then
            basePitch = allInfo[k:sub(1, -5) .. 'pitch']
            break
        end
    end

    TABLE.clear(temp)
    for k, v in next, allInfo do
        if k:sub(-5) == 'pitch' then
            if v < basePitch then repeat v = v * 2 until v > basePitch end
            if not temp[v] and not allInfo[k:sub(1, -6) .. 'note'] then
                self.count = self.count + 1
                temp[v] = true
                audio.playNote(v, 'chord' .. self.count, .26)
            end
        end
    end
end

---@type Zenitha.Scene
local scene = {}

function scene.mouseMove(_, _, dx, dy)
    if love.mouse.isDown(1) then
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

local function pitchSorter(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end
local function levelSorter(a, b) return a.d < b.d end
function scene.keyDown(key, isRep)
    if key == 'lctrl' or key == 'rctrl' or key == 'lshift' or key == 'rshift' or key == 'lalt' or key == 'ralt' then
        if editor.combo == '' then editor.combo = key:sub(2, 2):upper() end
        return true
    end

    if key == 'space' then
        if isRep then return true end
        if preview.playing then preview:stopChord(true) end
        if editor.combo == 'C' then
            -- Preview selected note
            audio.playNote(editor.curPitch, 'space')
        else
            -- Preview selected chords
            preview.start, preview.stop = editor.editing, editor.selMark or editor.editing
            if preview.start > preview.stop then preview.start, preview.stop = preview.stop, preview.start end
            preview.playing = preview.start
            -- preview.timer0 = .5 + .5 / (preview.stop - preview.start + 1)
            preview.timer0 = .626
            preview:startChord()
        end
    elseif key == 'down' or key == 'up' then
        if editor.combo == 'C' then return true end
        if editor.combo == 'A' then
            -- Move chord
            editor:moveChord(editor:getChord(), key == 'up' and editor.customGrid or -editor.customGrid)
        else
            -- Select note
            local allInfo = TABLE.flatten(TABLE.copyAll(editor.chordList[editor.editing].tree))
            local pitches = {}
            for k, v in next, allInfo do
                if k:sub(-5) == 'pitch' then
                    ins(pitches, { v, k:sub(1, -7) })
                end
            end
            table.sort(pitches, pitchSorter)
            local curPos
            for i = 1, #pitches do
                if pitches[i][1] == editor.curPitch then
                    curPos = i; break
                end
            end
            if key == 'up' then
                while curPos < #pitches and (pitches[curPos][1] <= editor.curPitch) do curPos = curPos + 1 end
            else
                while curPos > 1 and (pitches[curPos][1] >= editor.curPitch) do curPos = curPos - 1 end
            end
            editor.curPitch = pitches[curPos][1]
            editor.cursor = STRING.split(pitches[curPos][2], ".")
            for i = 1, #editor.cursor do
                editor.cursor[i] = tonumber(editor.cursor[i])
            end
            editor:refreshText()
        end
    elseif key == 'left' or key == 'right' then
        if editor.combo == 'C' then return true end
        if editor.combo == 'A' then
            -- Bias note
            if #editor.cursor == 0 then return true end
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
        -- Create new chord
        editor:newChord()
    elseif key == 'backspace' then
        if isRep then return true end
        if editor.combo == 'A' then
            local chord = editor:getChord()
            editor:reCalculatePitch(chord.tree, 1)
            editor.curPitch = 1
        else
            -- Delete selected note
            if #editor.cursor == 0 then return true end
            local n = rem(editor.cursor, #editor.cursor)
            local chord, curNote = editor:getChord(), editor:getNote()
            rem(curNote, n)
            editor:redrawChord(chord)
            editor.curPitch = curNote.pitch
            editor:refreshText()
        end
    elseif key == 'delete' then
        if isRep then return true end
        -- Delete current chord
        editor:deleteChord(editor.editing, editor.selMark or editor.editing)
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
        for k in next, TABLE.flatten(TABLE.copyAll(chord.tree)) do
            if k:find('base') then
                local index = STRING.split(k, '.')
                for i = 1, #index do
                    index[i] = tonumber(index[i]) or index[i]
                end
                TABLE.listIndexSet(chord.tree, index, nil)
            end
        end
        curNote.base = not curNote.base or nil
        editor:redrawChord(chord)
    elseif #key == 1 and MATH.between(tonumber(key) or 0, 1, 7) then
        if isRep then return true end

        local keyNum = tonumber(key)
        ---@cast keyNum number

        if editor.combo == 'A' then
            -- Set custom grid step
            editor.customGrid = keyNum
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
                    table.sort(curNote, levelSorter)
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
            editor:moveCursor(1e99)
            editor.selMark = 1
        end
    elseif key == 'c' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Copy
            local res = editor:dumpChords(editor.editing, editor.selMark or editor.editing)
            CLIPBOARD.set(table.concat(res, ' '))
            MSG('info', 'Copied ' .. #res .. ' chords to clipboard.')
        end
    elseif key == 'v' then
        if isRep then return true end
        if editor.combo == 'C' then
            -- Paste
            local count = editor:pasteChords(CLIPBOARD.get())
            MSG('info', 'Imported ' .. count .. ' chords from clipboard.')
        end
    elseif key == 'escape' then
        if editor.selMark then
            -- Clear selection
            editor.selMark = false
        elseif TASK.lock('quit_sure', 1) then
            -- Sure to quit?
            MSG('info', 'Press again to quit')
        else
            -- Quit
            ZENITHA._quit()
        end
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
    if preview.timer > 0 then
        preview.timer = preview.timer - dt
        if preview.timer <= 0 then
            preview:stopChord()
            preview:playNextChord()
        end
    end
    if dt == 0 then return end
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

    gc_replaceTransform(SCR.xOy_ul)
    gc_setColor(theme.text)
    gc_setAlpha(.16)
    FONT.set(30)
    gc_print("Audio Count   " .. srcCount - #srcLib .. "   /  " .. srcCount - 1, 100, 10)

    gc_replaceTransform(SCR.xOy_l)
    gc_translate(100, 0)
    gc_scale(260, -260)
    gc_translate(-editor.scrX1, -editor.scrY1)

    gc_setColor(1, 1, 1, MATH.clampInterpolate(.1, 1, .26, .26, editor.scrX1))
    gc_draw(TEX[editor.theme].keyboard, keyboardQuad, editor.scrX1 - .36, 3.206, 0, .00184, -.00184)

    -- Grid line
    do
        gc_setLineWidth(.01)
        gc_setColor(theme.dim[editor.customGrid])
        local dist = log(ssvt.dimData[editor.customGrid].freq, 2)
        local y = 0
        while y < 3.5 do
            gc_line(-1, y, 26, y)
            y = y + dist
        end
        y = -dist
        while y > -2.6 do
            gc_line(-1, y, 26, y)
            y = y - dist
        end
    end

    -- Selection
    do
        ---@type number, number
        local s, e = editor.editing, editor.selMark or editor.editing
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

    -- Preview selection
    if preview.playing then
        local s, e = preview.start, preview.stop
        s, e = (s - 1) * 1.2, e * 1.2
        gc_setColor(theme.preview)
        gc_draw(TEX.transition, s, 0, 0, .2 / 128, 12, 0, .5)
        gc_draw(TEX.transition, e, 0, 0, -.2 / 128, 12, 0, .5)
        gc_setLineWidth(.026)
        gc_setColor(theme.playline)
        local progress = preview.playing + (1 - preview.timer / preview.timer0)
        local x = MATH.interpolate(preview.start, s, preview.stop + 1, e, progress)
        gc_line(x, editor.scrY1 - 6, x, editor.scrY1 + 6)
    end

    gc_push('transform')

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

        -- Cursor
        if editor.editing == i then
            local y = log(editor.curPitch, 2)
            gc_setColor(theme.cursor)
            gc_setAlpha(.7 + .3 * sin(love.timer.getTime() * 6.2))
            gc_setLineWidth(.01)
            gc_rectangle('line', 0, y - .03, 1.2, .06)
            gc_strokePrint(
                'corner', .00626,
                COLOR.D, COLOR.LS,
                editor.cursorText,
                -.04, y + .16, nil, 'left',
                0, .0035, -.0035
            )
        end

        gc_translate(1.2, 0)
    end
    gc_pop()
end

SCN.add('main', scene)
