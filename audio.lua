local ins, rem = table.insert, table.remove

local srcLib = {} ---@type love.Source[]
local activeSrc = {} ---@type Map<love.Source>
local srcCount = 0

do -- Create first sudio source
    local sampleRate = 48000
    local baseFreq = 440
    local period = 1 / baseFreq
    local loopCount = 62
    local snd = love.sound.newSoundData(math.floor(sampleRate / baseFreq * loopCount), sampleRate, 16, 1)
    for i = 0, snd:getSampleCount() - 1 do
        local t = i / sampleRate

        -- Sine Wave ~
        local v = math.sin(6.283185307179586 / period * t)

        -- Square Wave -_
        -- local v = t % period < period * .5 and 1 or -1

        -- Triangle Wave ^v
        -- local v = -1 + math.abs((t - period / 4) % period - period / 2) * 2 / (period / 2)

        -- Sine-Square Wave /-\_/
        -- local v = math.sin(6.283185307179586 /period * t)
        -- v = (v >= 0 and 1 or -1) * math.abs(v) ^ .8

        snd:setSample(i, v)
    end

    srcLib[1] = love.audio.newSource(snd, "static")
    srcLib[1]:setLooping(true)
    srcCount = srcCount + 1

    snd:release()
end


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

function audio.getCount()
    return srcCount, #srcLib
end

return audio
