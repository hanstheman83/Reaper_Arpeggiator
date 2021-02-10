-- Is selected, midi index changing on edit, thus cannot update

-- auto update from Lua - keep track of midi changes ?

    
local function Msg(param) 
    reaper.ShowConsoleMsg(tostring(param).."\n")
end


Note = {
    startTime = 0, -- sec
    endTime = 0,
    startppqpos = 0,
    endppqpos = 0,
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

function Note:CalculateStartAndEndInProjTime(activeTake) -- in sec
    self.startTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, self.startppqpos)
    param = "Note with start ppq "..self.startppqpos.." has time "..self.startTime
    --reaper.ShowConsoleMsg(tostring(param).."\n")
    self.endTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, self.endppqpos)
    self.isInitialized = true
end

function Note:GetLengthInProjTime()
    if not self.isInitialized then
        --
        reaper.MB("Note not initialized!","Note.lua error", 0)
        return 0
    end
    return self.endTime - self.startTime
    
end




   