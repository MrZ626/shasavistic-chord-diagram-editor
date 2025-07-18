local ssvc = require('chord')
local audio = require('audio')

local max, min = math.max, math.min
local floor, abs = math.floor, math.abs
local log = math.log
local ins, rem = table.insert, table.remove
local expApproach = MATH.expApproach
local KBisDown = love.keyboard.isDown

---@class wrappedChord
---@field tree SSVC.Chord
---@field drawData table
---@field text string
---@field textObj love.Text
---@field pitchVec number[]

local E = {
    chordList = {}, ---@type wrappedChord[]
    cursor = 0,
    selMark = false,
    nCur = {}, ---@type number[]
    cursorText = GC.newText(FONT.get(30), "0"),
    curPitch = 1,
    ghostPitch = 1,

    combo = '', ---@type '' | 'C' | 'S' | 'A'

    scrX = 0, -- Scroll position
    scrY = 0,
    scrK = 1,

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
    scrK1 = 1,
    gridStepAnimTimer = 0,
}

local function pitchSorter(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end
local function levelSorter(a, b) return a.d < b.d end

E._pitchSorter = pitchSorter
E._levelSorter = levelSorter

---@return wrappedChord
local function newChordObj(text, pitchVec)
    return {
        tree = text and ssvc.decode(text) or { d = 0, pitch = 1 },
        drawData = {},
        text = text or "0",
        textObj = GC.newText(FONT.get(30), text or "0"),
        pitchVec = pitchVec or TABLE.new(0, 7),
    }
end

---@param vec number[]
local function vecToPitch(vec)
    local pitch = 1
    for i = 1, #vec do
        if vec[i] ~= 0 then
            pitch = pitch * ssvc.dimData[i].freq ^ vec[i]
        end
    end
    return pitch
end

---@param vec number[]
local function vecToStr(vec)
    local stop
    for i = #vec, 1, -1 do
        if vec[i] ~= 0 then
            stop = i
            break
        end
    end
    if not stop then return "" end

    local str = ""
    for i = 1, stop do
        str = str .. (
            vec[i] == 0 and "0" or
            vec[i] > 0 and string.char(64 + vec[i]) or
            string.char(96 - vec[i])
        )
    end
    return str
end

local function strToVec(str)
    local vec = TABLE.new(0, 7)
    for i = 1, #str do
        local c = str:sub(i, i)
        if c == '0' then
            vec[i] = 0
        elseif c >= 'A' and c <= 'Z' then
            vec[i] = c:byte() - 64
        elseif c >= 'a' and c <= 'z' then
            vec[i] = 96 - c:byte()
        end
    end
    return vec
end

-- View & Appearance

function E:switchTheme()
    self.theme = self.theme == 'bright' and 'dark' or 'bright'
end

function E:scroll(dx, dy)
    self.scrX = MATH.clamp(self.scrX + dx, 0, max(#self.chordList - 4.8 / self.scrK, 0) * 1.2)
    self.scrY = MATH.clamp(self.scrY + dy, -2, 2)
end

function E:scale(dk)
    self.scrK = MATH.clamp(self.scrK * dk, .5, 1)
    self.scrX = MATH.clamp(self.scrX, 0, max(#self.chordList - 4.8 / self.scrK, 0) * 1.2)
end

function E:focusCursor()
    self.scrX = MATH.clamp(self.scrX, (self.cursor - 4.8 / self.scrK) * 1.2, (self.cursor - 1) * 1.2)
    local h = -log(self.curPitch, 2)
    self.scrY = MATH.clamp(self.scrY, h - 1.6, h + 1.6)
end

function E:snapCursor()
    local allInfo = TABLE.flatten(TABLE.copyAll(self.chordList[self.cursor].tree))
    local pitchInfo = TABLE.alloc() -- {{pitch, key}, ...}
    for k, v in next, allInfo do
        if k:sub(-5) == 'pitch' then
            ins(pitchInfo, { log(v, 2), k:sub(1, -7) })
        end
    end
    table.sort(pitchInfo, pitchSorter)
    TABLE.transpose(pitchInfo) -- {pitches, keys}
    local curPos = floor(.5 + 1 + MATH.ilLerp(pitchInfo[1], log(self.ghostPitch or self.curPitch, 2)) * (#pitchInfo[1] - 1))
    self.nCur = STRING.split(pitchInfo[2][curPos], ".")
    for i = 1, #self.nCur do self.nCur[i] = tonumber(self.nCur[i]) end
    self.curPitch = E:getNote().pitch
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
    end
    self:snapCursor()
    self:refreshText()
end

-- Data

function E:getSelection()
    local s, e = self.cursor, self.selMark or self.cursor
    if s > e then s, e = e, s end
    return s, e
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
    self.cursorText:set(buffer)
end

function E:reCalculatePitch(tree, curPitch)
    for _, v in next, tree do
        if type(v) == 'table' then
            self:reCalculatePitch(v, curPitch * ssvc.dimData[v.d].freq)
        end
    end
    tree.pitch = curPitch
end

---@param chord wrappedChord
function E:renderChord(chord)
    chord.drawData = ssvc.drawChord(chord.tree)
    chord.text = ssvc.encode(chord.tree)
    chord.textObj:set(chord.text)
end

---@param full boolean include pitchVec information?
function E:dumpChord(full, s, e)
    local buffer = {}
    for i = s, e do
        local chord = self.chordList[i]
        ins(buffer, vecToStr(full and chord.pitchVec or NONE) .. '!' .. chord.text)
    end
    return buffer
end

function E:pasteChord(str, after)
    local count = 0
    local list = STRING.split(str, '%s', true)
    for i = 1, #list do
        local pitch, code = list[i]:match('^(.*)!(.*)$')
        local chord = newChordObj(code, strToVec(pitch))
        self:reCalculatePitch(chord.tree, vecToPitch(chord.pitchVec))
        self:renderChord(chord)
        count = count + 1
        ins(self.chordList, after + count, chord)
    end
    return count
end

-- Operation

function E:newChord(pos, useCurPitch)
    local vec
    if useCurPitch then
        vec = TABLE.copy(self:getChord().pitchVec)
        local tree = self:getChord().tree
        for i = 1, #self.nCur do
            tree = tree[self.nCur[i]]
            local pStep = abs(tree.d)
            vec[pStep] = vec[pStep] + MATH.sign(tree.d)
        end
    end
    local chord = newChordObj(nil, vec)
    if vec then self:reCalculatePitch(chord.tree, vecToPitch(vec)) end
    self:renderChord(chord)
    ins(self.chordList, MATH.clamp(pos, 1, #self.chordList + 1), chord)
    self.ghostPitch = self.curPitch
end

---@param chord wrappedChord
function E:moveChord(chord, step)
    local vec = chord.pitchVec
    local pStep = abs(step)
    vec[pStep] = MATH.clamp(vec[pStep] + MATH.sign(step), -26, 26)
    if abs(vec[pStep]) == 26 then MSG('warn', "Reached max movement in single dimension!", 1) end

    self:reCalculatePitch(chord.tree, vecToPitch(vec))
    if chord == self.chordList[self.cursor] then
        self.curPitch = chord.tree.pitch
        self.ghostPitch = self.curPitch
    end
end

function E:deleteCursorNote()
    if #self.nCur == 0 then return end
    local n = rem(self.nCur)
    rem(E:getNote(), n)
    self:renderChord(self:getChord())
    self:snapCursor()
    self:refreshText()
    self.ghostPitch = self.curPitch
end

function E:deleteChord(s, e)
    for i = e, s, -1 do
        local chord = rem(self.chordList, i)
        chord.textObj:release()
    end
    if #self.chordList == 0 then self:newChord(1) end
    if MATH.between(self.cursor, s, e) then self:moveCursor(0) end
    self.ghostPitch = self.curPitch
end

-- Playback

function E:stopChord(stopAll)
    for i = 1, self.count do audio.stopNote('chord' .. i) end
    if stopAll then
        self.playL, self.playR = false, false
        self.playing, self.timer = false, 0
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
    local chord = self.chordList[self.playing]
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

function E:update(dt)
    if self.timer > 0 then
        self.timer = self.timer - dt
        if self.timer <= 0 then
            self:stopChord()
            self:playNextChord()
        end
        if self.playing and self.selMark and abs(self.cursor - self.selMark) + 1 >= 4 then
            self:scroll((self.playing - self.timer / self.timer0) * 1.2 - .26 - self.scrX, 0)
        end
    end
    self.cursor1 = expApproach(self.cursor1, self.cursor, dt * 35)
    self.curPitch1 = expApproach(self.curPitch1, self.curPitch, dt * 35)
    self.scrX1 = expApproach(self.scrX1, self.scrX, dt * 20)
    self.scrY1 = expApproach(self.scrY1, self.scrY, dt * 20)
    self.scrK1 = expApproach(self.scrK1, self.scrK, dt * 20)
    self.gridStepAnimTimer = max(self.gridStepAnimTimer - dt, 0)
    if self.combo == 'C' then
        if KBisDown('left') then self:scroll(-dt * 6.2, 0) end
        if KBisDown('right') then self:scroll(dt * 6.2, 0) end
        if KBisDown('up') then self:scroll(0, -dt * 6.2) end
        if KBisDown('down') then self:scroll(0, dt * 6.2) end
        if KBisDown('-') then self:scale(.5 ^ (dt * 2.6)) end
        if KBisDown('=') then self:scale(2. ^ (dt * 2.6)) end
    end
end

return E
