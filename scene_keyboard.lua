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
            table.remove(srcLib, i)
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
        table.insert(srcLib, s)
        activeSrc[key] = nil
    end
end

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

function scene.update(dt)
end

local dimColor = {}
for i = 1, #ssvt.dimData do
    dimColor[i] = { COLOR.HEX(ssvt.dimData[i].color) }
end

function scene.draw()
    GC.setColor(COLOR.L)
    FONT.set(30)
    GC.print(srcCount - #srcLib .. "/" .. srcCount - 1, 10, 10)

    GC.replaceTransform(SCR.xOy_u)
    GC.translate(-200, 360)

    GC.setLineWidth(26)
    GC.setColor(dimColor[2])
    GC.line(-520, 0, 900, 0)
    GC.setColor(dimColor[3])
    GC.line(0, -300, 0, 200)

    GC.setLineWidth(4)
    GC.setColor(COLOR.L)
    FONT.set(70)
    for y = 1, 4 do
        for x = 1, #mat[y] do
            local char = mat[y][x]
            local pos = map[char]
            local x, y = pos[1] * 110, -pos[2] * 110
            if activeSrc[char] then
                GC.setColor(1, 1, 1, .42)
                GC.circle('fill', x, y, 50)
                GC.setColor(COLOR.L)
            end
            GC.circle('line', x, y, 50)
            GC.mStr(char, x, y - 45)
        end
    end
end

return scene
