-- Is selected, midi index changing on edit, thus cannot update

-- auto update from Lua - keep track of midi changes ?

    
local function Msg(param) 
    reaper.ShowConsoleMsg(tostring(param).."\n")
end


Note = {
    -- startTime = 0, -- sec
    -- endTime = 0,
    startppqpos = 0,
    endppqpos = 0,
    ppqLength = 0,
    qn = 0, -- qn with fraction
    qnInFigure = 0, -- first note in figure has qn 0, then incr or skip
    positionBetweenQN = 0, -- in fraction, 0 to 1
    chan = 0,
    pitch = 0,
    vel = 0,
    isMuted = false,
    isSelected = false,
    isInitialized = false
}

function Note:New(o)
    o = o or {}
    self.__index = self
    setmetatable(o,self)
    return o
end

function Note:InitializeNote(activeTake) -- in sec
    --self.startTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, self.startppqpos)
    -- Msg("Note with start ppq "..self.startppqpos.." has time "..self.startTime)
    --reaper.ShowConsoleMsg(tostring(param).."\n")
    --self.endTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, self.endppqpos)

    -- get ppq from previous QN 
    -- number reaper.MIDI_GetPPQPos_EndOfMeasure(MediaItem_Take take, number ppqpos)
    --number reaper.MIDI_GetPPQPos_StartOfMeasure(MediaItem_Take take, number ppqpos)
    --number reaper.MIDI_GetPPQPosFromProjQN(MediaItem_Take take, number projqn)
    
    self.qn = reaper.MIDI_GetProjQNFromPPQPos(activeTake, self.startppqpos) -- 
    Msg("position of note relative to qn : "..self.qn)
    
    -- local previousQnPPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake, previousQn)
    -- Msg("previous qn ppq : "..previousQnPPQ)
    -- local nextQnPPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake, previousQn+1)
    -- Msg("next qn ppq : "..nextQnPPQ)
    -- local differenceBetweenQN = nextQnPPQ - previousQnPPQ

    self.positionBetweenQN = math.fmod(self.qn,1)
    Msg("position between qn "..self.positionBetweenQN)

    self.ppqLength = self.endppqpos - self.startppqpos
    
    self.isInitialized = true
end

-- function Note:GetLengthInProjTime()
--     if not self.isInitialized then
--         --
--         reaper.MB("Note not initialized!","Note.lua error", 0)
--         return 0
--     end
--     return self.endTime - self.startTime
    
-- end




   