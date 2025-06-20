require 'Zenitha'

ZENITHA.setFirstScene("main")
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
    cursor = 0,
}

local function drawChord(chord)
    local data = ssvt.drawChord(chord)
    for _, shape in next, data do
        shape.colorT = { COLOR.HEX(shape.color) }
    end
    return data
end

local function newChord()
    local chord = {
        data = { d = 0 },
    }
    chord.drawData = drawChord(chord.data)

    ins(chordList, edit.cursor + 1, chord)
    edit.cursor = edit.cursor + 1
end

newChord()

---@type Zenitha.Scene
local scene = {}

function scene.load()
end

function scene.mouseDown(x, y, k)
end

local map = {}
local mat = {
    STRING.atomize "123456789",
    STRING.atomize "qwertyuio",
    STRING.atomize "asdfghjkl",
    STRING.atomize "zxcvbnm,.",
}
for y = 1, 4 do
    for x = 1, #mat[y] do
        local char = mat[y][x]
        map[char] = { x - 5, 3 - y }
    end
end
local function getPitch(pos)
    local pitch =
        (6 / 4) ^ pos[1] *
        (5 / 4) ^ pos[2]
    while pitch > 4 do pitch = pitch / 4 end
    while pitch < .5 do pitch = pitch * 4 end
    return pitch
end

function scene.keyDown(key, isRep)
    if isRep then return end
    if map[key] then
        startNote(getPitch(map[key]), key)
    end
end

function scene.keyUp(key)
    stopNote(key)
end

local dimColor = {}
for i = 1, #ssvt.dimData do
    dimColor[i] = { COLOR.HEX(ssvt.dimData[i].color) }
    dimColor[i][4] = .62
end

function scene.draw()
    GC.setColor(COLOR.L)
    FONT.set(30)
    GC.print(srcCount - #srcLib, 10, 10)
    GC.print(srcCount - 1, 62, 10)

    GC.replaceTransform(SCR.xOy_u)
    GC.translate(0, 360)

    GC.setLineWidth(26)
    GC.setColor(dimColor[2])
    GC.line(-610, 0, 610, 0)
    GC.setColor(dimColor[3])
    GC.line(0, -340, 0, 220)

    GC.setLineWidth(4)
    GC.setColor(COLOR.L)
    FONT.set(70)
    for y = 1, 4 do
        for x = 1, #mat[y] do
            local char = mat[y][x]
            local pos = map[char]
            local x, y = pos[1] * 130, -pos[2] * 130
            if activeSrc[char] then
                GC.setColor(1, 1, 1, .42)
                GC.circle('fill', x, y, 60)
                GC.setColor(COLOR.L)
            end
            GC.circle('line', x, y, 60)
            GC.mStr(char, x, y - 45)
        end
    end

    GC.replaceTransform(SCR.xOy_d)
    GC.translate(-600, -50)
    GC.scale(260, -420)

    for i = 1, #chordList do
        local drawData = chordList[i].drawData
        for j = 1, #drawData do
            local shape = drawData[j]
            GC.setColor(shape.colorT)
            if shape.mode == 'polygon' then
                GC.polygon('fill', shape.points)
            end
        end
    end
end

SCN.add("main", scene)
