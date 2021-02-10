reaper.ClearConsole()

-- reaper.MB("Test","Mixer Toolbox",0)

-- Set path Lokasenna GUI
-- commandId = reaper.NamedCommandLookup("_RS1c6ad1164e1d29bb4b1f2c1acf82f5853ce77875")
-- reaper.Main_OnCommand(commandId, 0)

-- Lokasenna GUI
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Core.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Button.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Frame.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Knob.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Label.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Listbox.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Menubar.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Menubox.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Options.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Slider.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Tabs.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Textbox.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - TextEditor.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Classes/Class - Window.Lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/GUILibrary/Modules/Window - GetUserInputs.Lua")()

-- Custom L-GUI

-- Extra Classes
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/Arpeggiator/Source/Note.lua")()
loadfile("C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/Arpeggiator/Source/CC.lua")()

-- local Notes = require "classes"

local helper = dofile "C:/Users/pract/Documents/Repos/ReaperPlugins/Lua/Arpeggiator/Source/HelperFunctions.lua"

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

---[[
----------- Main 
local oldTime = os.time();
local updateTime = 1 -- in sec, cant go lower. Could count frames
local exitChar = 0
--]]

---[[
---------- GUI Ini
local guiName = "Reaper Arp - Version 0.1"
local guiHeight = 200
local guiWidth = 500

-- Buttons

-- variables
local timeMap 
-- index = { ["time"] = time, [BPM] = bpm }

local listSelectedNotes 
-- index = { note }

local listAllItems 
-- index = {["Item"] = item, ["Notes"] = notesList, ["CC"] = CCList}

local currentProj = reaper.EnumProjects(-1)
local firstMeasureIndex -- index 1 less than measure number in reaper editor window
local timeNew


--]]

------------------------------------------------------
---------------- Functions --------------------------
-----------------------------------------------------

local function Msg(param) 
    reaper.ShowConsoleMsg(tostring(param).."\n")
end

-----------------------------------------------------------------------------------
---------------------- Functions for Saving Midi Items ----------------------------

local function GetListAllMidiNotesInItem(item)
    local activeTake = reaper.GetMediaItemTake(item, 0) -- TODO preserve all takes..
    local listAllNotes = {} -- lua index starts at 1
    local retval = reaper.MIDI_GetNote(activeTake, 0) -- bool, check there is a 1st note in take
    local currentNoteIdx = 0
    local midiNote

    while retval do
        midiNote = Note:New()
        retval, midiNote.isSelected, midiNote.isMuted,
        midiNote.startppqpos, midiNote.endppqpos, 
        midiNote.chan, midiNote.pitch, midiNote.vel = reaper.MIDI_GetNote(activeTake, currentNoteIdx)
        -- Msg("Note "..tostring(currentNoteIdx+1).." Start pos "..midiNote.startppqpos)
        -- Msg("retval "..tostring(retval))
        midiNote:CalculateStartAndEndInProjTime(activeTake) -- Ini note
        listAllNotes[currentNoteIdx+1] = midiNote -- lua index starts at 1
        currentNoteIdx = currentNoteIdx + 1
        retval = reaper.MIDI_GetNote(activeTake, currentNoteIdx)
    end
    return listAllNotes
end

local function GetListAllCCInItem(item)
    local listAllCC = {}
    local takeId = 0
    local activeTake = reaper.GetMediaItemTake(item, takeId) -- TODO preserve all takes..
    local retval = reaper.MIDI_GetCC(activeTake, 0)
    local currentCC_Idx = 0
    local cc

    while retval do 
        cc = CC:New()
        retval, cc.isSelected, cc.isMuted, cc.ppqpos, cc.chanmsg, 
        cc.chan, cc.msg2, cc.msg3 = 
        reaper.MIDI_GetCC(activeTake, currentCC_Idx)
        retval, cc.shape, cc.beztension = reaper.MIDI_GetCCShape(activeTake, currentCC_Idx) -- add bezier shape and tension to cc
        listAllCC[currentCC_Idx+1] = cc
        cc:CalculateStartInProjTime(activeTake) -- ini CC
        currentCC_Idx = currentCC_Idx + 1
        retval = reaper.MIDI_GetCC(activeTake, currentCC_Idx) -- test if next cc exists
    end
    Msg("# of cc saved in this item : "..currentCC_Idx)

    return listAllCC
end





------------------------------------------------------------------------------------------------------
--------------------------------- Functions for Saving Quarter Notes ---------------------------------

local function SaveQuarterNotes() -- saves selected midi notes as new quarter note time-map 
    listSelectedNotes = {}
    
    -- TODO check midi editor open with notes selection

    local activeMidiEditor = reaper.MIDIEditor_GetActive()
    local activeTake = reaper.MIDIEditor_GetTake(activeMidiEditor)
    local retval = false
    local noteIdx = 0
    local selectedNoteIndex = 1
    local note

    retval = reaper.MIDI_GetNote(activeTake, 0) -- check item has notes 
    if not retval then 
        Msg("item is empty")
        return false
    end
     
    while retval do
        note = Note:New()
        retval, note.isSelected, note.isMuted, note.startppqpos, note.endppqpos, note.chan, note.pitch, note.vel = reaper.MIDI_GetNote(activeTake, noteIdx)
        if note.isSelected then 
            listSelectedNotes[selectedNoteIndex] = note
            selectedNoteIndex = selectedNoteIndex + 1
            note:CalculateStartAndEndInProjTime(activeTake)
        end
        noteIdx = noteIdx + 1
    end
    Msg("# of selected notes : "..#listSelectedNotes)
    if #listSelectedNotes == 0 or nil then Msg("no selected notes!") return false end

    return true
end





-------------------------------------------------------------------------------------------------------
--------------------------------- Functions for Time-map --------------------------------------------

local function GenerateTimeMap()
    -- create list start 1st note to start 2nd note
    timeMap = {};
    local distanceStartToStart
    local startLastNote
    local timeMapIndex = 1
    if(listSelectedNotes == nil) then 
        Msg("No selected Quarter notes saved?!") 
    else
        for i, n in ipairs(listSelectedNotes) do 
            if i ~= 1 then
                distanceStartToStart = n.startTime - startLastNote -- beat length in sec
                timeMap[timeMapIndex] = { ["time"] = startLastNote, ["BPM"] = 60/distanceStartToStart} -- calc BPM
                timeMapIndex = timeMapIndex + 1
            end
            startLastNote = listSelectedNotes[i].startTime
        end
    end

    for i, timeItem in ipairs(timeMap) do 
        Msg(i.." has time "..timeItem["time"].." and BPM "..timeItem["BPM"])
    end

    local activeMidiEditor = reaper.MIDIEditor_GetActive()
    local activeTake = reaper.MIDIEditor_GetTake(activeMidiEditor) -- type MediaItem_Take
    local startFirstMeasurePPQ = reaper.MIDI_GetPPQPos_EndOfMeasure(activeTake, listSelectedNotes[1].startppqpos) -- we will calculate new tempi from here..
    local startFirstMeasureQN = reaper.MIDI_GetProjQNFromPPQPos(activeTake, startFirstMeasurePPQ)
    timeNew = reaper.TimeMap2_QNToTime(currentProj, startFirstMeasureQN)
    firstMeasureIndex = (reaper.TimeMap_QNToMeasures(currentProj, startFirstMeasureQN)) - 1 -- which measure QN falls in. Subtract 1 to get right index (reaper index start from 0)

end

local function SetTimeMapInProj()
    Msg("Setting time map")
    
    local beat = 0
    local measure = firstMeasureIndex

    -- TODO reset BPM changes in range!

    for i, timeBPM in ipairs(timeMap) do 
        reaper.SetTempoTimeSigMarker(currentProj, -1, -1, measure, beat, timeBPM["BPM"], 0, 0, false)
        beat = beat + 1

        if beat > 3 then 
            beat = 0
            measure = measure + 1
        end
    end
end





-------------------------------------------------------------------------------------------------------
--------------------------------- Functions for Creating Midi Data-------------------------------------

local function CreateMidiNotesInNewItem(newMediaItem, notesList, timeOffset)

    local take = reaper.GetMediaItemTake(newMediaItem, 0)
    local startppqpos, endppqpos
    
    for i,n in ipairs(notesList) do 
        startppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, n.startTime + timeOffset)
        endppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, n.endTime + timeOffset)
        reaper.MIDI_InsertNote(take, n.isSelected, n.isMuted, startppqpos, 
            endppqpos, n.chan, n.pitch, n.vel)
    end
end

local function CreateCC_DataInNewItem(newMediaItem, ccList, timeOffset)
    -- add shape : Lua: boolean reaper.MIDI_SetCCShape(MediaItem_Take take, integer ccidx, integer shape, number beztension, optional boolean noSortIn)
    -- respect bounds of media item
    local take = reaper.GetMediaItemTake(newMediaItem, 0)
    local ppqpos
    local wasInserted, shapeWasSet
    local itemStartTime = reaper.GetMediaItemInfo_Value(newMediaItem, "D_POSITION")
    local itemEndTime = itemStartTime + reaper.GetMediaItemInfo_Value(newMediaItem, "D_LENGTH")
    Msg("item start time : "..itemStartTime) -- in sec
    for i, cc in ipairs(ccList) do 
        -- insert from start item
        if(cc.startTime + timeOffset < itemEndTime) then -- also sets cc out of bounds. Neccessary to later set shape.
            ppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, cc.startTime + timeOffset)
            wasInserted = reaper.MIDI_InsertCC(take, cc.isSelected, cc.isMuted, ppqpos, cc.chanmsg,
                cc.chan, cc.msg2, cc.msg3)
            --Msg("cc "..i.." inserted : "..helper.BoolToString(wasInserted)) -- inserts also before clip starts!
        end
    end
    -- set shape
    Msg("Setting Shape")
    for i, cc in ipairs(ccList) do 
        if(cc.startTime + timeOffset > itemStartTime and cc.startTime + timeOffset < itemEndTime) then
            shapeWasSet = reaper.MIDI_SetCCShape(take, i-1, cc.shape, cc.beztension)
            -- Msg("cc "..i.." cc shape set : "..helper.BoolToString(shapeWasSet)) -- inserts also before clip starts!
        end
    end
    Msg("End CreateCC")
end

local function CreateNewMidiItems()
    Msg("Creating new midi items")
    local track
    local itemWasDeleted
    local item
    local notesList
    local ccList
    local timeZero = listSelectedNotes[1].startTime -- time of 1st quarter note in sec
    -- ini 

    local endNewMediaItem

    local fallInForCC = 1 -- 1 sec earlier than first note start cc data
    local tail = 1 -- 1 sec tail for cc data

    local timeOffset = timeNew - timeZero -- add this to all new created notes
    -- ignore items when cc and notes < start 1st bar in timeMap. CC will ramp up and down.
    Msg("time new : "..timeNew)
    Msg("time zero : "..timeZero)

    
    for i, object in ipairs(listAllItems) do 
        item = object["Item"]
        track = reaper.GetMediaItem_Track(item)
        itemWasDeleted = reaper.DeleteTrackMediaItem(track, item)
        -- creating new items 
        if itemWasDeleted then Msg("An item was deleted") end
        notesList = object["Notes"]
        ccList = object["CC"]
        endNewMediaItem = notesList[#notesList].endTime + timeOffset
        Msg("creating new midi item")
        item = reaper.CreateNewMIDIItemInProj(track, timeNew - fallInForCC, endNewMediaItem + tail, false)
        CreateMidiNotesInNewItem(item, notesList, timeOffset)
        CreateCC_DataInNewItem(item, ccList, timeOffset)
    end
end





-------------------------------------------------------------------
------------------------- UI Callbacks ----------------------------
-------------------------------------------------------------------

local function OnSaveFigure_Pressed()
    listAllItems = {}
    local count = 0
    local item = reaper.GetSelectedMediaItem(currentProj, count)

    while item ~= nil do 
        listAllItems[count+1] = {["Item"] = item, ["Notes"] = GetListAllMidiNotesInItem(item), ["CC"] = GetListAllCCInItem(item)}
        count = count + 1
        item = reaper.GetSelectedMediaItem(currentProj, count)
    end
    Msg("Number of midi items saved : "..count)
end

local function OnSaveQuarterNotes_Pressed()
    Msg("Save quarter notes pressed")
    local success = SaveQuarterNotes()
    if success then 
        GenerateTimeMap() -- while notes selected..
    end
end

local function OnCreateTimeMapAndSetMidiItems_Pressed()
    Msg("Create Time Map and set Midi Items")
    SetTimeMapInProj()
    CreateNewMidiItems()
    Msg("Done with all calculations")
end



------------------------------------------------------------------------------
------------------------------ Exit functions -----------------------------
local function Exit()
    -- Msg("exiting..")
    -- Save()
end







-----------------------------------------------------------------------------------------------------
-------------------------------------- Main and GUI Functions ---------------------------------------
-----------------------------------------------------------------------------------------------------

---- INI GUI ----
local function InitializeGUI()

    ------------------------------------- GUI INI --------------------------------
    GUI.name = guiName
    GUI.x, GUI.y = 0, 0 -- Top Left : Starting point in pixels, make dynamic
    -- with anchor and corner x and y becomes offset coordinates!
    GUI.h = guiHeight
    GUI.w = guiWidth
    GUI.anchor, GUI.corner = "mouse", "C"


    GUI.New("btn_SaveFigure", "Button", 1, 30, 30, 165, 24, "Save Figure", OnSaveFigure_Pressed)
    GUI.New("btn_SaveQuarterNotes", "Button", 1, 30, 60, 165, 24, "Save Quarter Notes", OnSaveQuarterNotes_Pressed)
    GUI.New("btn_CreateTimeMapAndSetMidiItems", "Button", 1, 30, 90, 165, 24, "Create Time-map and set midi", OnCreateTimeMapAndSetMidiItems_Pressed)

    -------------------------------------- INI GUI --------------------------------------------
    GUI.Init()
    GUI.Main()
end

-------------------------------- Functions for Main ----------------------------------------

local function MouseCursorInWindow()
    return GUI.mouse.x > -1 and GUI.mouse.x < guiWidth and GUI.mouse.y > -30 and GUI.mouse.y < guiHeight -- -30 is window menu padding
end

------------------------------------ MAIN -----------------------------------------------
local function Main()
    local char = gfx.getchar()
    if char ~= 27 and char ~= -1 and exitChar ~= 27 then
        reaper.time_precise()
        -- Msg("main is running!")

        -- Delayed Update Loop --
        if os.time() > oldTime + updateTime then
            -- Msg("Update")
            oldTime = os.time()
            -- check track integrity - compare track name and numbers etc..
        end

        reaper.defer(Main)
    end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------          STARTING SCRIPT            -------------------------------------------------------------------------------


InitializeGUI()
-- Start()
-- Main()

reaper.atexit(Exit)