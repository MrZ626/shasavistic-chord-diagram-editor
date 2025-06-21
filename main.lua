require 'Zenitha'

ZENITHA.setFirstScene('main')
ZENITHA.setShowFPS(false)
ZENITHA.setVersionText("")
ZENITHA.globalEvent.drawCursor = NULL
ZENITHA.globalEvent.clickFX = NULL
SCR.setSize(1600, 1000)

local ssvt = require('shasavistic-chord-diagram.chordGen')

local srcCount = 0
---@type love.Source[]
local srcLib = {}
do
    local sampleRate = 44100
    local baseFreq = 440
    local loopCount = 62
    local snd = love.sound.newSoundData(math.floor(sampleRate / baseFreq * loopCount), sampleRate, 16, 1)
    for i = 0, snd:getSampleCount() - 1 do
        local t = i / sampleRate
        local v = math.sin(6.283185307179586 * baseFreq * t)
        snd:setSample(i, v)
    end

    srcLib[1] = love.audio.newSource(snd, "static")
    srcLib[1]:setLooping(true)
    srcCount = 1

    snd:release()
end

local ins, rem = table.insert, table.remove

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

---@type wrappedChord[]
local chordList = {}
local edit = {
    editing = 0,
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

local function redrawChord(chord)
    local data = ssvt.drawChord(chord.tree)
    for _, shape in next, data do
        shape.colorT = { COLOR.HEX(shape.color) }
    end
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

---@type Zenitha.Scene
local scene = {}

local KBisDown = love.keyboard.isDown
local function pitchSorter(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end
local function levelSorter(a, b) return a.d < b.d end
function scene.keyDown(key, isRep)
    if isRep then return end
    if key == 'space' then
        -- Preview selected note
        startNote(edit.curPitch, 'space')
    elseif key == 'down' or key == 'up' then
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
        local ctrl = KBisDown('lctrl', 'rctrl')
        if key == 'up' then
            while curPos < #pitches and (ctrl or pitches[curPos][1] <= edit.curPitch) do curPos = curPos + 1 end
        else
            while curPos > 1 and (ctrl or pitches[curPos][1] >= edit.curPitch) do curPos = curPos - 1 end
        end
        edit.curPitch = pitches[curPos][1]
        edit.cursor = STRING.split(pitches[curPos][2], ".")
        for i = 1, #edit.cursor do
            edit.cursor[i] = tonumber(edit.cursor[i])
        end
        edit:refreshText()
    elseif key == 'return' then
        -- Create new chord
        newChord()
    elseif key == 'backspace' then
        -- Delete selected note
        if #edit.cursor == 0 then return end
        local n = rem(edit.cursor, #edit.cursor)
        local chord, curNote = edit:getChord(), edit:getNote()
        rem(curNote, n)
        redrawChord(chord)
        edit.curPitch = curNote.pitch
        edit:refreshText()
    elseif key == 'delete' then
        -- Delete current chord
        rem(chordList, edit.editing)
        if edit.editing > #chordList then edit.editing = #chordList end
        if #chordList == 0 then newChord() end
    elseif key == 'left' or key == 'right' then
        if KBisDown('lctrl', 'rctrl') then
            -- Move editing cursor
            local newEditing = MATH.clamp(edit.editing + (key == 'left' and -1 or 1), 1, #chordList)
            if newEditing ~= edit.editing then
                edit.editing = newEditing
                edit.cursor = {}
                edit.curPitch = 1
                edit:refreshText()
            end
        else
            -- Change bias
            if #edit.cursor == 0 then return end
            local chord, curNote = edit:getChord(), edit:getNote()
            local tar = key == 'left' and 'l' or 'r'
            if curNote.bias ~= tar then
                curNote.bias = not curNote.bias and tar or nil
                redrawChord(chord)
            end
        end
    elseif key == '.' then
        -- Mark selected note as fake note
        local chord, curNote = edit:getChord(), edit:getNote()
        if curNote.note then
            curNote.note = nil
        else
            curNote.note = math.abs(curNote.d) == 1 and 'skip' or 'dotted'
        end
        redrawChord(chord)
    elseif key == '/' then
        -- Mark selected note as bass
        local chord, curNote = edit:getChord(), edit:getNote()
        curNote.bass = not curNote.bass or nil
        redrawChord(chord)
    elseif #key == 1 and tonumber(key) and MATH.between(tonumber(key), 1, 5) then
        -- Add note
        local step = tonumber(key)
        if KBisDown('lshift', 'rshift') then step = -step end
        local pitch = edit.curPitch * ssvt.dimData[step].freq
        local chord, curNote = edit:getChord(), edit:getNote()
        local exist
        for i = 1, #curNote do
            if curNote[i].d == step then
                exist = i
                break
            end
        end
        if exist and KBisDown('lctrl', 'rctrl') then
            rem(curNote, exist)
            redrawChord(chord)
        else
            if not exist and pitch ~= 1 then
                ins(curNote, { d = step, pitch = pitch })
                table.sort(curNote, levelSorter)
                redrawChord(chord)
            end
            startNote(pitch, key)
        end
    end
end

function scene.keyUp(key)
    stopNote(key)
end

function scene.draw()
    GC.setColor(COLOR.L)
    FONT.set(30)
    GC.print(srcCount - #srcLib .. "   /  " .. srcCount - 1, 10, 10)

    GC.replaceTransform(SCR.xOy_l)
    GC.translate(100, 260)
    GC.scale(260, -260)

    for i = 1, #chordList do
        -- Polygons
        local drawData = chordList[i].drawData
        for j = 1, #drawData do
            local shape = drawData[j]
            GC.setColor(shape.colorT)
            if shape.mode == 'polygon' then
                GC.polygon('fill', shape.points)
            end
        end

        -- Text
        GC.setColor(COLOR.L)
        GC.print(chordList[i].text, 0, -.1, 0, .005, -.005)

        -- Cursor
        if edit.editing == i then
            local y = math.log(edit.curPitch, 2)
            GC.setColor(.4, .6, 1, .5 + .26 * math.sin(love.timer.getTime() * 6.2))
            GC.setLineWidth(.01)
            GC.rectangle('line', -.04, y - .03, 1.08, .06)
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
end

SCN.add('main', scene)
