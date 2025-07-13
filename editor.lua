local ssvt = require('chord')
local audio = require('audio')

local max, min = math.max, math.min
local ins, rem = table.insert, table.remove
local floor, abs = math.floor, math.abs

local E = {
    chordList = {}, ---@type wrappedChord[]
    cursor = 0,
    selMark = false,
    nCur = {}, ---@type number[]
    cursorText = "0",
    curPitch = 1,

    combo = '', ---@type '' | 'C' | 'S' | 'A'

    scrX = 0, -- Scroll position
    scrY = 0,

    theme = 'dark',
    gridStep = 2,

    playing = false,
    playL = false,
    playR = false,
    count = 0,
    timer = 0,

    -- Animation variables
    cursor1 = 0,
    curPitch1 = 0,
    scrX1 = 0,
    scrY1 = 0,
}

local function pitchSorter(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end
local function levelSorter(a, b) return a.d < b.d end

E._pitchSorter = pitchSorter
E._levelSorter = levelSorter

-- Scroll
function E:scroll(dx, dy)
    self.scrX = MATH.clamp(self.scrX + dx, 0, (max(#self.chordList, 4.8) - 4.8) * 1.2)
    self.scrY = MATH.clamp(self.scrY + dy, -2, 2)
end

function E:getChord()
    return self.chordList[self.cursor]
end

function E:getNote()
    return TABLE.listIndex(self.chordList[self.cursor].tree, self.nCur)
end

function E:refreshText()
    local buffer = "0"
    local tree = self:getChord().tree
    for i = 1, #self.nCur do
        tree = tree[self.nCur[i]]
        buffer = buffer .. (tree.d > 0 and '+' or '') .. tree.d
    end
    self.cursorText = buffer
end

function E:reCalculatePitch(tree, curPitch)
    for _, v in next, tree do
        if type(v) == 'table' then
            self:reCalculatePitch(v, curPitch * ssvt.dimData[v.d].freq)
        end
    end
    tree.pitch = curPitch
end

function E:redrawChord(chord)
    local data = ssvt.drawChord(chord.tree)
    chord.drawData = data
    chord.text = ssvt.encode(chord.tree)
end

function E:newChord(pos)
    local chord = {
        tree = { d = 0, pitch = 1 },
        text = "0",
    }
    self:redrawChord(chord)
    ins(self.chordList, MATH.clamp(pos, 1, #self.chordList + 1), chord)
end

function E:snapCursor()
    local allInfo = TABLE.flatten(TABLE.copyAll(self.chordList[self.cursor].tree))
    local pitchInfo = TABLE.alloc() -- {{pitch, key}, ...}
    for k, v in next, allInfo do
        if k:sub(-5) == 'pitch' then
            ins(pitchInfo, { v, k:sub(1, -7) })
        end
    end
    table.sort(pitchInfo, pitchSorter)
    TABLE.transpose(pitchInfo) -- {pitches, keys}
    local curPos = floor(MATH.ilLerp(pitchInfo[1], self.curPitch) * (#pitchInfo[1] - 1) + 1 + .5)
    E.curPitch = pitchInfo[1][curPos]
    E.nCur = STRING.split(pitchInfo[2][curPos], ".")
    for i = 1, #E.nCur do
        E.nCur[i] = tonumber(E.nCur[i])
    end
    TABLE.free(pitchInfo)
end

function E:moveCursor(offset)
    local newPos = MATH.clamp(self.cursor + offset, 1, #self.chordList)
    if self.combo == 'S' then
        if not self.selMark then self.selMark = self.cursor end
    elseif self.selMark then
        if abs(offset) == 1 then
            newPos = (offset == -1 and min or max)(self.cursor, self.selMark)
        end
        self.selMark = false
    end
    if newPos ~= self.cursor then
        self.cursor = newPos
        self:snapCursor()
        self:refreshText()
    else
        self:snapCursor()
    end
    self.scrX = MATH.clamp(self.scrX, (self.cursor - 4.8) * 1.2, (self.cursor - 1) * 1.2)
end

function E:moveChord(chord, step)
    self:reCalculatePitch(chord.tree, chord.tree.pitch * ssvt.dimData[step].freq)
    if chord == self.chordList[self.cursor] then
        self.curPitch = chord.tree.pitch
    end
end

function E:deleteChord(s, e)
    if s > e then s, e = e, s end
    for i = e, s, -1 do
        rem(self.chordList, i)
    end
    if #self.chordList == 0 then self:newChord(1) end
    self:moveCursor(0)
end

function E:switchTheme()
    self.theme = self.theme == 'bright' and 'dark' or 'bright'
end

function E:dumpChords(s, e)
    if s > e then s, e = e, s end
    local buffer = {}
    for i = s, e do
        ins(buffer, '"' .. self.chordList[i].text .. '"')
    end
    return buffer
end

function E:pasteChords(buffer, after)
    local s = after or self.cursor
    local count = 0
    for str in buffer:gmatch('"(.-)"') do
        local chord = {
            tree = ssvt.decode(str),
            text = str,
        }
        chord.tree.d = 0 -- Force root note being legal
        self:reCalculatePitch(chord.tree, 1)
        self:redrawChord(chord)
        count = count + 1
        ins(self.chordList, s + count, chord)
    end
    return count
end

function E:stopChord(stopAll)
    for i = 1, self.count do audio.stopNote('chord' .. i) end
    if stopAll then
        self.playL, self.playR = false, false
        self.playing, E.timer = false, 0
    end
end

function E:playNextChord()
    if self.playing >= self.playR then
        self.playing = false
        self.playL, self.playR = false, false
    else
        self.playing = self.playing + 1
        self:playChord()
    end
end

function E:playChord()
    UTIL.trace()
    if self.timer > 0 then self:stopChord() end

    self.coun = 0
    self.timer = self.timer0
    local chord = E.chordList[self.playing]
    local allInfo = TABLE.flatten(TABLE.copyAll(chord.tree))
    local basePitch = -1e99
    for k in next, allInfo do
        if k:sub(-4) == 'base' then
            basePitch = allInfo[k:sub(1, -5) .. 'pitch']
            break
        end
    end

    local temp = TABLE.alloc()
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
    TABLE.free(temp)
end

return E
