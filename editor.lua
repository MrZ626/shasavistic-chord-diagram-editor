local ssvc = require('chord')
local audio = require('audio')

local max, min = math.max, math.min
local floor, abs = math.floor, math.abs
local log = math.log
local ins, rem = table.insert, table.remove
local clamp, expApproach = MATH.clamp, MATH.expApproach
local KBisDown = love.keyboard.isDown

---@class SSVC.NoteInList
---@field path SSVC.Dim[]
---@field pitch number
---@field sound boolean
---@field base? 'l' | 'r'
---@field note SSVC.Note

---@class SSVC.Chord
---@field tree SSVC.Note
---@field drawData table
---@field text string
---@field textObj love.Text
---@field pitchVec number[]
---@field noteList SSVC.NoteInList[] read-only, update on E:renderChord, sorted by pitch

local E = {
    chordList = {}, ---@type SSVC.Chord[]
    cursor = 0,
    selMark = false,
    nCur = {}, ---@type number[]
    cursorText = GC.newText(FONT.get(30), "0"),
    curPitch = 1,
    ghostPitch = 1,

    scrX = 0, -- Scroll position
    scrY = 0,
    scrK = 1,

    gridStep = { 2, 1 },
    chordDist = 1.2,

    playing = false,
    playL = false,
    playR = false,
    count = 0,
    timer = 0,

    history = { '!0' },
    hisPtr = 1,

    -- Animation variables
    cursor1 = 0,
    curPitch1 = 0,
    scrX1 = 0,
    scrY1 = 0,
    scrK1 = 1,
    gridStepAnimTimer = 0,
}

---@param a SSVC.NoteInList
---@param b SSVC.NoteInList
local function pitchSorter(a, b)
    if a.pitch == b.pitch then
        for i = 1, max(#a.path, #b.path) do
            local av, bv = a.path[i] or 0, b.path[i] or 0
            if av ~= bv then
                return av < bv
            end
        end
    else
        return a.pitch < b.pitch
    end
end
local function levelSorter(a, b) return a.d < b.d end

---@return SSVC.Chord
local function newChordObj(text, pitchVec)
    return {
        tree = text and ssvc.decode(text) or { d = 0, pitch = 1 },
        drawData = {},
        text = text or "0",
        textObj = GC.newText(FONT.get(30), text or "0"),
        pitchVec = pitchVec or TABLE.new(0, 7),
        noteList = {},
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

function E:scroll(dx, dy)
    self.scrX = clamp(self.scrX + dx, 0, max(#self.chordList * self.chordDist - (5.8 - .26) / self.scrK, 0))
    self.scrY = clamp(self.scrY + dy, -12, 12)
end

function E:scale(dk)
    self.scrK = clamp(self.scrK * dk, .5, 1)
    self.scrX = clamp(self.scrX, 0, max(#self.chordList * self.chordDist - (5.8 - .26) / self.scrK, 0))
end

function E:focusCursor()
    self.scrX = clamp(self.scrX, self.cursor * self.chordDist - (5.8 - .26) / self.scrK, (self.cursor - 1) * self.chordDist)
    local h = -log(self.curPitch, 2)
    self.scrY = clamp(self.scrY, h - 1.6, h + 1.6)
end

function E:snapCursor()
    local noteList = self.chordList[self.cursor].noteList
    local pitches = TABLE.alloc()
    local paths = TABLE.alloc()
    for _, note in next, noteList do
        ins(pitches, log(note.pitch, 2))
        ins(paths, note.path)
    end
    local curPos = floor(.5 + 1 + MATH.ilLerp(pitches, log(self.ghostPitch or self.curPitch, 2)) * (#pitches - 1))
    self.nCur = paths[curPos]
    self.curPitch = E:getNote().pitch
    TABLE.free(pitches)
    TABLE.free(paths)
end

function E:moveCursor(offset)
    local newPos = clamp(self.cursor + offset, 1, #self.chordList)
    if KBisDown('lshift', 'rshift') then
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

---@return SSVC.Note
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

---@param note SSVC.Note
local function reCalculatePitch(note, curPitch)
    for _, v in next, note do
        if type(v) == 'table' then
            reCalculatePitch(v, curPitch * ssvc.dimData[v.d].freq)
        end
    end
    note.pitch = curPitch
end
---@param chord SSVC.Chord
function E:reCalculatePitch(chord, curPitch)
    reCalculatePitch(chord.tree, curPitch)
    for i = 1, #chord.noteList do chord.noteList[i].pitch = chord.noteList[i].note.pitch end
end

---@param note SSVC.Note
local function simpNote(note, path)
    return {
        path = TABLE.copy(path),
        pitch = note.pitch,
        base = note.base,
        sound = not note.mode or note.mode == 'tense' or note.mode == 'pink',
        note = note,
    }
end

---@param chord SSVC.Chord
function E:renderChord(chord)
    chord.drawData = ssvc.drawChord(chord.tree)
    chord.text = ssvc.encode(chord.tree)
    chord.textObj:set(chord.text)
    TABLE.clear(chord.noteList)
    chord.noteList[1] = simpNote(chord.tree, {})
    local path = { 1 }
    while true do
        ---@type SSVC.Note
        local note = TABLE.listIndex(chord.tree, path)
        if note then
            ins(chord.noteList, simpNote(note, path))
            if note[1] then
                path[#path + 1] = 1
            else
                path[#path] = path[#path] + 1
            end
        else
            if #path == 1 then break end
            path[#path] = nil
            path[#path] = path[#path] + 1
        end
    end
    table.sort(chord.noteList, pitchSorter)
end

function E:reRenderAll()
    for i = 1, #self.chordList do
        self:renderChord(self.chordList[i])
    end
end

---@param full boolean include pitchVec information?
function E:dumpChord(full, s, e)
    local buffer = {}
    for i = s, e do
        local chord = self.chordList[i]
        ins(buffer, (full and vecToStr(chord.pitchVec) .. '!' or '') .. chord.text)
    end
    -- for k,v in next,buffer do print(k,v)end
    return buffer
end

function E:pasteChord(str, after)
    local count = 0
    local list = STRING.split(str, '%s', true)
    for i = 1, #list do
        local pitch, code = list[i]:match('^(.*)!(.*)$')
        local chord = newChordObj(code, strToVec(pitch))
        self:reCalculatePitch(chord, vecToPitch(chord.pitchVec))
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
    if vec then self:reCalculatePitch(chord, vecToPitch(vec)) end
    self:renderChord(chord)
    ins(self.chordList, clamp(pos, 1, #self.chordList + 1), chord)
    self.ghostPitch = self.curPitch
end

---@param note SSVC.Note
function E:addNote(note)
    local curNote = self:getNote()
    ins(curNote, note)
    table.sort(curNote, levelSorter)
end

---@param chord SSVC.Chord
function E:moveChord(chord, step)
    local vec = chord.pitchVec
    local pStep = abs(step)
    vec[pStep] = clamp(vec[pStep] + MATH.sign(step), -26, 26)
    if abs(vec[pStep]) == 26 then MSG('warn', "Reached max movement in single dimension!", 1) end

    self:reCalculatePitch(chord, vecToPitch(vec))
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

function E:switchBase()
    local chord, curNote = self:getChord(), self:getNote()
    if curNote.base == 'l' then
        curNote.base = 'r'
    elseif curNote.base == 'r' then
        curNote.base = nil
    else
        for k in next, TABLE.flatten(TABLE.copyAll(chord.tree)) do
            if k:find('base') then
                ---@type table
                local index = STRING.split(k, '.')
                for i = 1, #index do
                    index[i] = tonumber(index[i]) or index[i]
                end
                TABLE.listIndexSet(chord.tree, index, nil)
            end
        end
        curNote.base = 'l'
    end
    self:renderChord(chord)
end

function E:switchExtended()
    local curNote = self:getNote()
    curNote.extended = not curNote.extended or nil
    self:renderChord(self:getChord())
end

-- Undo & Redo

function E:step()
    while #self.history > self.hisPtr do rem(self.history) end
    table.insert(self.history, table.concat(self:dumpChord(true, 1, #self.chordList), ' '))
    self.hisPtr = #self.history
end

function E:undo()
    if self.hisPtr > 1 then
        self.hisPtr = self.hisPtr - 1
        TABLE.clear(self.chordList)
        self:pasteChord(self.history[self.hisPtr], 0)
        self.cursor = clamp(self.cursor, 1, #self.chordList)
        self:snapCursor()
    else
        MSG('warn', "No more undo steps!", 1)
    end
end

function E:redo()
    if self.hisPtr < #self.history then
        self.hisPtr = self.hisPtr + 1
        TABLE.clear(self.chordList)
        self:pasteChord(self.history[self.hisPtr], 0)
        self.cursor = clamp(self.cursor, 1, #self.chordList)
        self:snapCursor()
    else
        MSG('warn', "No more redo steps!", 1)
    end
end

-- Playback

function E:stopPlaying()
    self.playL, self.playR = false, false
    self.playing, self.timer = false, 0
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
    self.count = 0
    self.timer = self.timer0
    local chord = self.chordList[self.playing]
    local basePitch = -1e99
    for _, note in next, chord.noteList do
        if note.base then
            basePitch = note.pitch
            break
        end
    end

    local temp = TABLE.alloc()
    for _, note in next, chord.noteList do
        if note.pitch < basePitch then repeat note.pitch = note.pitch * 2 until note.pitch > basePitch end
        if not temp['p' .. note.pitch] and note.sound then
            self.count = self.count + 1
            temp['p' .. note.pitch] = true
            ins(temp, note.pitch)
        end
    end
    self.count = #temp
    for i = 1, #temp do
        local waitT = (i - 1) * .026
        local note, vol = temp[i], 1 / (#temp + 1.6)
        TASK.new(function()
            TASK.yieldT(waitT)
            audio.playNote(note, vol)
        end)
    end
    TABLE.free(temp)
end

function E:update(dt)
    if self.timer > 0 then
        self.timer = self.timer - dt
        if self.timer <= 0 then
            self:playNextChord()
        end
        if self.playing and self.selMark and abs(self.cursor - self.selMark) + 1 >= 4 then
            self:scroll((self.playing - self.timer / self.timer0) * self.chordDist - .26 - self.scrX, 0)
        end
    end
    self.cursor1 = expApproach(self.cursor1, self.cursor, dt * 35)
    self.curPitch1 = expApproach(self.curPitch1, self.curPitch, dt * 35)
    self.scrX1 = expApproach(self.scrX1, self.scrX, dt * 20)
    self.scrY1 = expApproach(self.scrY1, self.scrY, dt * 20)
    self.scrK1 = expApproach(self.scrK1, self.scrK, dt * 20)
    self.gridStepAnimTimer = max(self.gridStepAnimTimer - dt, 0)
    if KBisDown('lctrl', 'rctrl') then
        if KBisDown('left') then self:scroll(-dt * 6.2, 0) end
        if KBisDown('right') then self:scroll(dt * 6.2, 0) end
        if KBisDown('up') then self:scroll(0, -dt * 6.2) end
        if KBisDown('down') then self:scroll(0, dt * 6.2) end
        if KBisDown('-') then self:scale(.5 ^ (dt * 2.6)) end
        if KBisDown('=') then self:scale(2. ^ (dt * 2.6)) end
    end
end

return E
