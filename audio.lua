local ins, rem = table.insert, table.remove

---@class wrappedSource
---@field src love.Source
---@field volume? number
---@field timer? number
---@field duration? number

local srcLib = {} ---@type wrappedSource[]
local activeSrc = {} ---@type Map<wrappedSource>
local srcCount = 0

do -- Create first sudio source
    local sampleRate = 48000
    local baseFreq = 440
    local period = 1 / baseFreq
    local loopCount = 210 -- 2*3*5*7
    local snd = love.sound.newSoundData(math.floor(sampleRate / baseFreq * loopCount), sampleRate, 16, 1)
    local harmonicSeries = {
        { 1,  .25 ^ 0 },
        { 3,  .25 ^ 1 },
        { 5,  .25 ^ 2 },
        { 7,  .25 ^ 3 },
        { 11, .25 ^ 4 },
    }
    for i = 0, snd:getSampleCount() - 1 do
        local t = i / sampleRate

        -- Custom Harmonic Series
        local v = 0
        for j = 1, #harmonicSeries do
            local h = harmonicSeries[j]
            v = v + h[2] * math.sin(6.283185307179586 / (period / h[1]) * t)
        end

        -- Sine Wave ~
        -- local v = math.sin(6.283185307179586 / period * t)

        -- Sine Wave ~
        -- local v = math.sin(6.283185307179586 / period * t)

        -- Square Wave -_
        -- local v = t % period < period * .5 and .4 or -.4

        -- Triangle Wave ^v
        -- local v = -1 + math.abs((t - period / 4) % period - period / 2) * 2 / (period / 2)

        -- Sine-Square Wave /-\_/
        -- local v = math.sin(6.283185307179586 /period * t)
        -- v = (v >= 0 and 1 or -1) * math.abs(v) ^ .8

        snd:setSample(i, v)
    end

    local src = love.audio.newSource(snd, "static")
    src:setLooping(true)
    srcLib[1] = {
        src = src,
        timer = 0,
        volume = 0, -- Default volume
        duration = snd:getDuration()
    }
    srcCount = srcCount + 1

    snd:release()
end


local audio = {}

function audio.playNote(freq, volume, duration)
    if #srcLib == 1 then
        srcLib[2] = { src = srcLib[1].src:clone() }
        srcCount = srcCount + 1
    end
    for i = 2, #srcLib do
        local S = srcLib[i]
        if not S.src:isPlaying() then
            ins(activeSrc, rem(srcLib, i))
            S.duration = duration or 1.62
            S.timer = S.duration
            S.volume = volume or .26
            S.src:setVolume(S.volume)
            if freq==7.75 then freq=7.7499 end
            S.src:setPitch(freq)
            S.src:play()
            return
        end
    end
end

function audio.getCount()
    return srcCount, #srcLib
end

function audio.update(dt)
    for i = #activeSrc, 1, -1 do
        local S = activeSrc[i]
        S.timer = S.timer - dt
        if S.timer > 0 then
            S.src:setVolume(S.volume * (S.timer / S.duration) ^ 2)
        else
            S.src:stop()
            ins(srcLib, rem(activeSrc, i))
        end
    end
end

return audio
