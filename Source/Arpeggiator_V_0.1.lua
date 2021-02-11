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
---------------------- Functions for Saving Midi ----------------------------
local function GetListAllSelectedMidiNotesInItem(activeTake)
    local listSelectedNotes = {} -- lua index starts at 1
    local retval = reaper.MIDI_GetNote(activeTake, 0) -- bool, check there is a 1st note in take
    local currentNoteIdx = 0 -- Reaper index starts at 0
    local midiNote
    local selectedNoteIndex = 1 -- Lua index starts at 1

    while retval do
        midiNote = Note:New()
        retval, midiNote.isSelected, midiNote.isMuted,
        midiNote.startppqpos, midiNote.endppqpos, 
        midiNote.chan, midiNote.pitch, midiNote.vel = reaper.MIDI_GetNote(activeTake, currentNoteIdx)
        Msg("Note "..tostring(currentNoteIdx+1).." Start pos "..midiNote.startppqpos)
        -- Msg("retval "..tostring(retval))
        if midiNote.isSelected then 
            listSelectedNotes[selectedNoteIndex] = midiNote
            selectedNoteIndex = selectedNoteIndex + 1
            midiNote:InitializeNote(activeTake)
        end
        currentNoteIdx = currentNoteIdx + 1
        retval = reaper.MIDI_GetNote(activeTake, currentNoteIdx)
    end

    return listSelectedNotes
end

------------------------------------------------------------------------------------------------------
--------------------------------- Functions for Creating arpeggiation ---------------------------------

local function CreateArpeggiationInSelectedMidiItem(take) -- within time selection
    -- bounds time selection 
    local startTimeSelection, endTimeSelection
    startTimeSelection, endTimeSelection = reaper.GetSet_LoopTimeRange2(
        currentProj, false, false, -1, -1, false)
    Msg("Start time selection : "..startTimeSelection)
    Msg("End time selection : "..endTimeSelection)

    if listSelectedNotes == nil then Msg("Please save a figure") 
    else
        for i,n in ipairs(listSelectedNotes) do
            -- create new notes in take, from startTime to End, repeating pattern
            -- figure need order of notes - first note starts at 1. qn. incr and skip qn  
        end
    end
    -- 
end

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
    -- get selected midi notes
    local item = reaper.GetSelectedMediaItem(currentProj, 0)
    local activeTake = reaper.GetActiveTake(item)
    listSelectedNotes = GetListAllSelectedMidiNotesInItem(activeTake)
    if #listSelectedNotes == 0 or nil then Msg("no selected notes!") end
    Msg("# of selected notes : "..#listSelectedNotes)
end

local function OnCreateArpeggiation_Pressed()
    Msg("Create Arpeggiation pressed")
    local item = reaper.GetSelectedMediaItem(currentProj, 0)
    local activeTake = reaper.GetActiveTake(item)
    CreateArpeggiationInSelectedMidiItem()
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
    GUI.New("btn_CreateArpeggiation", "Button", 1, 30, 60, 165, 24, "Create Arpeggiation", OnCreateArpeggiation_Pressed)
    

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