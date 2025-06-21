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
    local volume = .26
    local loopCount = 62
    local snd = love.sound.newSoundData(math.floor(sampleRate / baseFreq * loopCount), sampleRate, 16, 1)
    for i = 0, snd:getSampleCount() - 1 do
        local t = i / sampleRate
        local v = volume * math.sin(6.283185307179586 * baseFreq * t)
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

local function startNote(freq, key)
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

local chordList = {}
local edit = {
    editing = 0,
    cursor = {},
    curFreq = 1,
}

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
        tree = { d = 0 },
        text = "0",
    }
    redrawChord(chord)

    edit.editing = edit.editing + 1
    ins(chordList, edit.editing, chord)
    edit.cursor = {}

    edit.curFreq = 1
end

newChord()

---@type Zenitha.Scene
local scene = {}

function scene.load()
end

function scene.mouseDown(x, y, k)
end

local map = {
    a = 3,
    z = -3,
    s = 2,
    x = -2,
    d = 4,
    c = -4,
    f = 1,
    v = -1,
    g = 5,
    b = -5,
    -- h = 6,
    -- n = -6,
    -- j = 7,
    -- m = -7,
}

function scene.keyDown(key, isRep)
    if isRep then return end
    if key == 'backspace' then
        rem(chordList, edit.editing)
        if edit.editing > #chordList then edit.editing = #chordList end
        if #chordList == 0 then newChord() end
    elseif key == 'return' then
        newChord()
    elseif key == 'left' then
        if #edit.cursor == 0 then return end
        local chord = chordList[edit.editing]
        local curLevel = TABLE.listIndex(chord.tree, edit.cursor)
        curLevel.bias = curLevel.bias ~= 'l' and 'l' or nil
        redrawChord(chord)
    elseif key == 'right' then
        if #edit.cursor == 0 then return end
        local chord = chordList[edit.editing]
        local curLevel = TABLE.listIndex(chord.tree, edit.cursor)
        curLevel.bias = curLevel.bias ~= 'r' and 'r' or nil
        redrawChord(chord)
    elseif key == 'down' or key == 'up' then
        -- TODO
    elseif key == '.' then
        local chord = chordList[edit.editing]
        local curLevel = TABLE.listIndex(chord.tree, edit.cursor)
        if curLevel.note then
            curLevel.note = nil
        else
            curLevel.note = math.abs(curLevel.d) == 1 and 'skip' or 'dotted'
        end
        redrawChord(chord)
    elseif key == '/' then
        local chord = chordList[edit.editing]
        local curLevel = TABLE.listIndex(chord.tree, edit.cursor)
        curLevel.bass = not curLevel.bass or nil
        redrawChord(chord)
    elseif key == 'space' then
        startNote(edit.curFreq, 'space')
    elseif map[key] then
        local step = map[key]
        local pitch = edit.curFreq * ssvt.dimData[step].freq
        local chord = chordList[edit.editing]
        local curLevel = TABLE.listIndex(chord.tree, edit.cursor)
        local exist
        for i = 1, #curLevel do
            if curLevel[i].d == step then
                exist = i
                break
            end
        end
        if exist and love.keyboard.isDown('lctrl', 'rctrl') then
            rem(curLevel, exist)
            redrawChord(chord)
        else
            if not exist then
                ins(curLevel, { d = step })
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
    GC.print(srcCount - #srcLib, 10, 10)
    GC.print(srcCount - 1, 62, 10)

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
            GC.setColor(1, .6, .6, .5 + .26 * math.sin(love.timer.getTime() * 6.2))
            GC.setLineWidth(.01)
            GC.rectangle('line', -.04, math.log(edit.curFreq, 2) - .03, 1.08, .06)
        end

        GC.translate(1.2, 0)
    end
end

SCN.add('main', scene)
