local function Msg(param) 
    reaper.ShowConsoleMsg(tostring(param).."\n")
end

CC = {
    ppqpos = 0,
    chanmsg = 0,
    chan = 0,
    msg2 = 0,
    msg3 = 0,
    isMuted = false,
    isSelected = false,
    isInitialized = false,
    shape = 0,
    beztension = 0,
    qn = 0,
    qnInFigure = -1,
    positionBetweenQN = 0
}

function CC:New(o)
    o = o or {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function CC:InitializeCC(activeTake, qnFirst)
    self.qn = reaper.MIDI_GetProjQNFromPPQPos(activeTake, self.ppqpos) -- own org qn pos 
    
    self.qnInFigure = math.floor(self.qn) - qnFirst -- close to 0 and - # ???
    self.positionBetweenQN = math.fmod(reaper.MIDI_GetProjQNFromPPQPos(activeTake, self.ppqpos),1)
    self.isInitialized = true
    
end
