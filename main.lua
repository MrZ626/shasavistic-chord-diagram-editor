require 'Zenitha'

ZENITHA.setFirstScene('main')
ZENITHA.setShowFPS(false)
ZENITHA.setVersionText("")
ZENITHA.globalEvent.drawCursor = NULL
ZENITHA.globalEvent.clickFX = NULL
SCR.setSize(1600, 1000)
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
        table.insert(transition, { 'setCL', 1, 1, 1, 1 - x / 128 })
        table.insert(transition, { 'fRect', x, 0, 1, 1 })
    end
    TEX.transition = GC.load(transition)
end

-- Audio
local srcCount = 0
---@type love.Source[]
local srcLib = {}
do
    local sampleRate = 48000
    local baseFreq = 440
    local loopCount = 62
    local snd = love.sound.newSoundData(math.floor(sampleRate / baseFreq * loopCount), sampleRate, 16, 1)
    for i = 0, snd:getSampleCount() - 1 do
        local t = i / sampleRate
        local v = math.sin(6.283185307179586 * baseFreq * t)
        snd:setSample(i, MATH.sign(v) * math.abs(v) ^ .8)
    end

    srcLib[1] = love.audio.newSource(snd, "static")
    srcLib[1]:setLooping(true)
    srcCount = 1

    snd:release()
end

local ins, rem = table.insert, table.remove
local KBisDown = love.keyboard.isDown

---@type Map<love.Source>
local activeSrc = {}

local function startNote(freq, key, volume)
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
local function stopNote(key)
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

---@type wrappedChord[]
local chordList = {}
local edit = {
    editing = 0,
    selMark = false,
    cursor = {}, ---@type number[]
    cursorText = "0",
    curPitch = 1,
}
function edit:getChord()
    return chordList[self.editing]
end

function edit:getNote()
    return TABLE.listIndex(chordList[self.editing].tree, self.cursor)
end

function edit:refreshText()
    local buffer = "0"
    local tree = self:getChord().tree
    for i = 1, #self.cursor do
        tree = tree[self.cursor[i]]
        buffer = buffer .. (tree.d > 0 and '+' or '') .. tree.d
    end
    self.cursorText = buffer
end

local function reCalculatePitch(tree, curPitch)
    for _, v in next, tree do
        if type(v) == 'table' then
            reCalculatePitch(v, curPitch * ssvt.dimData[v.d].freq)
        end
    end
    tree.pitch = curPitch
end

local function redrawChord(chord)
    local data = ssvt.drawChord(chord.tree)
    chord.drawData = data
    chord.text = ssvt.encode(chord.tree)
end

local function newChord()
    local chord = {
        tree = { d = 0, pitch = 1 },
        text = "0",
    }
    redrawChord(chord)

    edit.editing = edit.editing + 1
    ins(chordList, edit.editing, chord)
    edit.cursor = {}
    edit:refreshText()

    edit.curPitch = 1
end

newChord()

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
local mode = 'dark'
local customGrid = 2
local scrollX, scrollY = 0, 0 -- Actual scroll position
local scrX1, scrY1 = 0, 0     -- Smooth scroll position, follow {scrollX, scrollY} by time

local preview = {
    playing = false,
    start = false,
    stop = false,
    count = 0,
    timer = 0,
}

---@type Zenitha.Scene
local scene = {}

function preview:stopChord(stopAll)
    for i = 1, self.count do stopNote('chord' .. i) end
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
    local chord = chordList[self.playing]
    local allInfo = TABLE.flatten(TABLE.copyAll(chord.tree))
    TABLE.clear(temp)
    for k, v in next, allInfo do
        if k:sub(-5) == 'pitch' then
            if not temp[v] and not allInfo[k:sub(1, -6) .. 'note'] then
                self.count = self.count + 1
                temp[v] = true
                startNote(v, 'chord' .. self.count, .26)
            end
        end
    end
end

local function scroll(dx, dy)
    scrollX = MATH.clamp(scrollX + dx, 0, (math.max(#chordList, 4.8) - 4.8) * 1.2)
    scrollY = MATH.clamp(scrollY + dy, -2, 2)
end

function scene.mouseMove(_, _, dx, dy)
    if love.mouse.isDown(1) then
        scroll(-dx / 260, dy / 260)
    end
end

function scene.wheelMove(_, dy)
    if KBisDown('lshift', 'rshift') then
        scroll(-dy / 2.6, 0)
    else
        scroll(0, dy / 2.6)
    end
end

local combo = ''

local function pitchSorter(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end
local function levelSorter(a, b) return a.d < b.d end
local function moveCursor(offset)
    local newPos = MATH.clamp(edit.editing + offset, 1, #chordList)
    if combo == 'S' then
        if not edit.selMark then edit.selMark = edit.editing end
    elseif edit.selMark then
        if math.abs(offset) == 1 then
            newPos = (offset == -1 and math.min or math.max)(edit.editing, edit.selMark)
        end
        edit.selMark = false
    end
    if newPos ~= edit.editing then
        edit.editing = newPos
        edit.cursor = {}
        edit.curPitch = edit:getChord().tree.pitch
        edit:refreshText()
    end
    scrollX = MATH.clamp(scrollX, (edit.editing - 4.8) * 1.2, (edit.editing - 1) * 1.2)
end
local function moveChord(chord, step)
    reCalculatePitch(chord.tree, chord.tree.pitch * ssvt.dimData[step].freq)
    if chord == chordList[edit.editing] then
        edit.curPitch = chord.tree.pitch
    end
end
local function deleteChord(s, e)
    if s > e then s, e = e, s end
    for i = e, s, -1 do
        rem(chordList, i)
    end
    if edit.editing > #chordList then edit.editing = #chordList end
    if #chordList == 0 then newChord() end
end
local function switchTheme()
    mode = mode == 'bright' and 'dark' or 'bright'
end
local function dumpChords(s, e)
    if s > e then s, e = e, s end
    local buffer = {}
    for i = s, e do
        ins(buffer, '"' .. chordList[i].text .. '"')
    end
    return buffer
end
local function pasteChords(buffer, after)
    local s = after or edit.editing
    local count = 0
    for str in buffer:gmatch('"(.-)"') do
        local chord = {
            tree = ssvt.decode(str),
            text = str,
        }
        reCalculatePitch(chord.tree, 1)
        redrawChord(chord)
        count = count + 1
        ins(chordList, s + count, chord)
    end
    return count
end

function scene.keyDown(key, isRep)
    if key == 'lctrl' or key == 'rctrl' or key == 'lshift' or key == 'rshift' or key == 'lalt' or key == 'ralt' then
        if combo == '' then combo = key:sub(2, 2):upper() end
        return true
    end

    if key == 'space' then
        if isRep then return true end
        if preview.playing then preview:stopChord(true) end
        if combo == 'C' then
            -- Preview selected note
            startNote(edit.curPitch, 'space')
        else
            -- Preview selected chords
            preview.start, preview.stop = edit.editing, edit.selMark or edit.editing
            if preview.start > preview.stop then preview.start, preview.stop = preview.stop, preview.start end
            preview.playing = preview.start
            -- preview.timer0 = .5 + .5 / (preview.stop - preview.start + 1)
            preview.timer0 = .626
            preview:startChord()
        end
    elseif key == 'down' or key == 'up' then
        if combo == 'C' then return true end
        if combo == 'A' then
            -- Move chord
            moveChord(edit:getChord(), key == 'up' and customGrid or -customGrid)
        else
            -- Select note
            local allInfo = TABLE.flatten(TABLE.copyAll(chordList[edit.editing].tree))
            local pitches = {}
            for k, v in next, allInfo do
                if k:sub(-5) == 'pitch' then
                    ins(pitches, { v, k:sub(1, -7) })
                end
            end
            table.sort(pitches, pitchSorter)
            local curPos
            for i = 1, #pitches do
                if pitches[i][1] == edit.curPitch then
                    curPos = i; break
                end
            end
            if key == 'up' then
                while curPos < #pitches and (pitches[curPos][1] <= edit.curPitch) do curPos = curPos + 1 end
            else
                while curPos > 1 and (pitches[curPos][1] >= edit.curPitch) do curPos = curPos - 1 end
            end
            edit.curPitch = pitches[curPos][1]
            edit.cursor = STRING.split(pitches[curPos][2], ".")
            for i = 1, #edit.cursor do
                edit.cursor[i] = tonumber(edit.cursor[i])
            end
            edit:refreshText()
        end
    elseif key == 'left' or key == 'right' then
        if combo == 'C' then return true end
        if combo == 'A' then
            -- Bias note
            if #edit.cursor == 0 then return true end
            local chord, curNote = edit:getChord(), edit:getNote()
            local tar = key == 'left' and 'l' or 'r'
            if curNote.bias ~= tar then
                curNote.bias = not curNote.bias and tar or nil
                redrawChord(chord)
            end
        else
            -- Move cursor (normally)
            moveCursor(key == 'left' and -1 or 1)
        end
    elseif key == 'pageup' then
        if isRep then return true end
        moveCursor(-4)
    elseif key == 'pagedown' then
        if isRep then return true end
        moveCursor(4)
    elseif key == 'home' then
        if isRep then return true end
        moveCursor(-1e99)
    elseif key == 'end' then
        if isRep then return true end
        moveCursor(1e99)
    elseif key == 'return' then
        if isRep then return true end
        -- Create new chord
        newChord()
    elseif key == 'backspace' then
        if isRep then return true end
        if combo == 'A' then
            local chord = edit:getChord()
            reCalculatePitch(chord.tree, 1)
            edit.curPitch = 1
        else
            -- Delete selected note
            if #edit.cursor == 0 then return true end
            local n = rem(edit.cursor, #edit.cursor)
            local chord, curNote = edit:getChord(), edit:getNote()
            rem(curNote, n)
            redrawChord(chord)
            edit.curPitch = curNote.pitch
            edit:refreshText()
        end
    elseif key == 'delete' then
        if isRep then return true end
        -- Delete current chord
        deleteChord(edit.editing, edit.selMark or edit.editing)
        edit.selMark = false
    elseif key == '.' then
        if isRep then return true end
        -- Mark selected note as fake note
        local chord, curNote = edit:getChord(), edit:getNote()
        if curNote.note then
            curNote.note = nil
        else
            curNote.note = math.abs(curNote.d) == 1 and 'skip' or 'dotted'
        end
        redrawChord(chord)
    elseif key == '/' then
        if isRep then return true end
        -- Mark selected note as bass
        local chord, curNote = edit:getChord(), edit:getNote()
        for k in next, TABLE.flatten(TABLE.copyAll(chord.tree)) do
            if k:find('bass') then
                local index = STRING.split(k, '.')
                for i = 1, #index do
                    index[i] = tonumber(index[i]) or index[i]
                end
                TABLE.listIndexSet(chord.tree, index, nil)
            end
        end
        curNote.bass = not curNote.bass or nil
        redrawChord(chord)
    elseif #key == 1 and MATH.between(tonumber(key) or 0, 1, 7) then
        if isRep then return true end

        local keyNum = tonumber(key)
        ---@cast keyNum number

        if combo == 'A' then
            -- Set custom grid step
            customGrid = keyNum
        else
            -- Add/Remove note
            local step = keyNum
            if combo == 'S' then step = -step end
            local chord, curNote = edit:getChord(), edit:getNote()
            local exist
            for i = 1, #curNote do
                if curNote[i].d == step then
                    exist = i
                    break
                end
            end

            if combo == 'C' then
                if exist then
                    rem(curNote, exist)
                    redrawChord(chord)
                end
            else
                local pitch = edit.curPitch * ssvt.dimData[step].freq
                if not exist then
                    ins(curNote, { d = step, pitch = pitch })
                    table.sort(curNote, levelSorter)
                    redrawChord(chord)
                end
                startNote(pitch, key)
            end
        end
    elseif key == 'tab' then
        if isRep then return true end
        switchTheme()
    elseif key == 'a' then
        if combo == 'C' then
            -- Select all
            edit.selMark = 1
            edit.editing = #chordList
            scroll(1e99, 0)
        end
    elseif key == 'c' then
        if isRep then return true end
        if combo == 'C' then
            -- Copy
            local res = dumpChords(edit.editing, edit.selMark or edit.editing)
            CLIPBOARD.set(table.concat(res, ' '))
            MSG('info', 'Copied ' .. #res .. ' chords to clipboard.')
        end
    elseif key == 'v' then
        if isRep then return true end
        if combo == 'C' then
            -- Paste
            local count = pasteChords(CLIPBOARD.get())
            MSG('info', 'Imported ' .. count .. ' chords from clipboard.')
        end
    elseif key == 'escape' then
        if edit.selMark then
            -- Clear selection
            edit.selMark = false
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
        if combo == 'C' then combo = '' end
    elseif key == 'lshift' or key == 'rshift' then
        if combo == 'S' then combo = '' end
    elseif key == 'lalt' or key == 'ralt' then
        if combo == 'A' then combo = '' end
    end
    stopNote(key)
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
    scrX1 = MATH.expApproach(scrX1, scrollX, dt * 20)
    scrY1 = MATH.expApproach(scrY1, scrollY, dt * 20)
    if KBisDown('lctrl', 'rctrl') then
        if KBisDown('left') then scroll(-dt * 6.2, 0) end
        if KBisDown('right') then scroll(dt * 6.2, 0) end
        if KBisDown('up') then scroll(0, dt * 6.2) end
        if KBisDown('down') then scroll(0, -dt * 6.2) end
    end
end

local keyboardQuad = GC.newQuad(0, 0, 137, 543 * 6, TEX.dark.keyboard)
TEX.dark.keyboard:setWrap('clampzero', 'repeat')
TEX.bright.keyboard:setWrap('clampzero', 'repeat')
function scene.draw()
    local theme = themes[mode]
    GC.clear(theme.bgbase)

    GC.replaceTransform(SCR.xOy)
    GC.setColor(theme.bg)
    GC.rectangle('fill', 0, 0, SCR.w0, SCR.h0)

    GC.replaceTransform(SCR.xOy_ul)
    GC.setColor(theme.text)
    GC.setAlpha(.16)
    FONT.set(30)
    GC.print("Audio Count   " .. srcCount - #srcLib .. "   /  " .. srcCount - 1, 100, 10)

    GC.replaceTransform(SCR.xOy_l)
    GC.translate(100, 0)
    GC.scale(260, -260)
    GC.translate(-scrX1, -scrY1)

    GC.setColor(1, 1, 1, MATH.clampInterpolate(.1, 1, .26, .26, scrX1))
    GC.draw(TEX[mode].keyboard, keyboardQuad, scrX1 - .36, 3.206, 0, .00184, -.00184)

    -- Grid line
    do
        GC.setLineWidth(.01)
        GC.setColor(theme.dim[customGrid])
        local dist = math.log(ssvt.dimData[customGrid].freq, 2)
        local y = 0
        while y < 3.5 do
            GC.line(-1, y, 26, y)
            y = y + dist
        end
        y = -dist
        while y > -2.6 do
            GC.line(-1, y, 26, y)
            y = y - dist
        end
    end

    -- Selection
    do
        ---@type number, number
        local s, e = edit.editing, edit.selMark or edit.editing
        if s > e then s, e = e, s end
        s, e = (s - 1) * 1.2, e * 1.2
        GC.setColor(theme.select)
        GC.rectangle('fill', s, -6, e - s, 12)
        if edit.selMark then
            GC.setColor(theme.cursor)
            GC.draw(TEX.transition, s, 0, 0, .2 / 128, 12, 0, .5)
            GC.draw(TEX.transition, e, 0, 0, -.2 / 128, 12, 0, .5)
        end
    end

    -- Preview selection
    if preview.playing then
        local s, e = preview.start, preview.stop
        s, e = (s - 1) * 1.2, e * 1.2
        GC.setColor(theme.preview)
        GC.draw(TEX.transition, s, 0, 0, .2 / 128, 12, 0, .5)
        GC.draw(TEX.transition, e, 0, 0, -.2 / 128, 12, 0, .5)
        GC.setLineWidth(.026)
        GC.setColor(theme.playline)
        local progress = preview.playing + (1 - preview.timer / preview.timer0)
        local x = MATH.interpolate(preview.start, s, preview.stop + 1, e, progress)
        GC.line(x, scrY1 - 6, x, scrY1 + 6)
    end

    GC.push('transform')

    for i = 1, #chordList do
        -- Separator line
        GC.setColor(theme.sepLine)
        GC.setLineWidth(.01)
        GC.line(1.2, scrY1 - 6, 1.2, scrY1 + 6)

        -- Chord textures
        GC.setColor(1, 1, 1)
        local texSrc = TEX[mode]
        local drawData = chordList[i].drawData
        local move = math.log(chordList[i].tree.pitch, 2)

        GC.translate(.1, move)
        for j = 1, #drawData do
            local d = drawData[j]
            local tex = texSrc[d.texture]
            GC.draw(tex, d.x, d.y, 0, d.w / tex:getWidth(), d.h / tex:getHeight())
        end
        GC.translate(-.1, -move)

        -- Text
        GC.setColor(theme.text)
        GC.print(chordList[i].text, 0, -1.626 + scrY1, 0, .005, -.005)
        GC.setAlpha(.26)
        GC.print(i, 0, -1.52 + scrY1, 0, .003, -.003)

        -- Cursor
        if edit.editing == i then
            local y = math.log(edit.curPitch, 2)
            GC.setColor(theme.cursor)
            GC.setAlpha(.7 + .3 * math.sin(love.timer.getTime() * 6.2))
            GC.setLineWidth(.01)
            GC.rectangle('line', 0, y - .03, 1.2, .06)
            GC.strokePrint(
                'corner', .00626,
                COLOR.D, COLOR.LS,
                edit.cursorText,
                -.04, y + .16, nil, 'left',
                0, .0035, -.0035
            )
        end

        GC.translate(1.2, 0)
    end
    GC.pop()
end

SCN.add('main', scene)
