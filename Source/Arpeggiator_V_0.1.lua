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

local listSelectedCC
-- index = { ["easeIn"] = {cc}, 
--     ["figure"] = {cc}, ["easeOut"] = {cc} }

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
    local listNotes = {} -- lua index starts at 1
    local retval = reaper.MIDI_GetNote(activeTake, 0) -- bool, check there is a 1st note in take
    local currentNoteIdx = 0 -- Reaper index starts at 0
    local midiNote
    local selectedNoteIndex = 1 -- Lua index starts at 1

    -- 
    local firstQn -- set by first selected =
    local firstNoteIsSelected = false

    while retval do
        midiNote = Note:New()
        retval, midiNote.isSelected, midiNote.isMuted,
        midiNote.startppqpos, midiNote.endppqpos, 
        midiNote.chan, midiNote.pitch, midiNote.vel = reaper.MIDI_GetNote(activeTake, currentNoteIdx)
        Msg("Note "..tostring(currentNoteIdx+1).." Start pos "..midiNote.startppqpos)
        -- Msg("retval "..tostring(retval))
        if midiNote.isSelected then 
            listNotes[selectedNoteIndex] = midiNote
            selectedNoteIndex = selectedNoteIndex + 1
            midiNote:InitializeNote(activeTake)
            if not firstNoteIsSelected then
                firstQn = math.floor(midiNote.qn)
                midiNote.qnInFigure = 0
                firstNoteIsSelected = true
            else
                midiNote.qnInFigure = math.floor(midiNote.qn) -firstQn
            end
            Msg("Qn in figure : "..midiNote.qnInFigure)
        end
        currentNoteIdx = currentNoteIdx + 1
        retval = reaper.MIDI_GetNote(activeTake, currentNoteIdx)
    end
    listNotes[#listNotes].isLastInFigure = true

    return listNotes
end

local function GetListSelectedCCFromNotes(activeTake, qnFirst, qnLast) -- qnZero is qn position of 1st note in figure
    -- qnFirst, qnLast : figure start/end qn position (end is beginning next figure)
    -- save all cc from first to last note (create ppq range)
    local listEaseInCC = {} -- cc before start of figure
    local listFigureCC = {} -- cc within figure
    local listEaseOutCC = {} -- cc after end figure
    local easeInIndex = 1 -- Lua index
    local figureIndex = 1 -- Lua index
    local easeOutIndex = 1 -- Lua index

    -- Bounds
    local firstQnPPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake, qnFirst) 
    local lastQnPPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake, qnLast) 
    local easeInOutPPQ = 300

    local retval = reaper.MIDI_GetCC(activeTake, 0) -- looping from first cc in item
    local currentCC_Idx = 0
    local cc

    while retval do 
        cc = CC:New()
        retval, cc.isSelected, cc.isMuted, cc.ppqpos, cc.chanmsg, 
            cc.chan, cc.msg2, cc.msg3 = 
            reaper.MIDI_GetCC(activeTake, currentCC_Idx)
        retval, cc.shape, cc.beztension = reaper.MIDI_GetCCShape(activeTake, currentCC_Idx) -- add bezier shape and tension to cc
        
        cc:InitializeCC(activeTake, qnFirst)
        
        if cc.ppqpos > firstQnPPQ - easeInOutPPQ and cc.ppqpos < firstQnPPQ then -- ease in CC data 
            listEaseInCC[easeInIndex] = cc
            easeInIndex = easeInIndex + 1
        elseif cc.ppqpos >= firstQnPPQ and cc.ppqpos <= lastQnPPQ then -- figure
            listFigureCC[figureIndex] = cc
            figureIndex = figureIndex + 1
        elseif cc.ppqpos > lastQnPPQ and cc.ppqpos < lastQnPPQ + easeInOutPPQ then -- ease out
            listEaseOutCC[easeOutIndex] = cc
            easeOutIndex = easeOutIndex + 1
        end
        currentCC_Idx = currentCC_Idx + 1
        retval = reaper.MIDI_GetCC(activeTake, currentCC_Idx) -- test if next cc exists
    end

    return { ["easeIn"] = listEaseInCC, ["figure"] = listFigureCC, ["easeOut"] = listEaseOutCC }
end

------------------------------------------------------------------------------------------------------
--------------------------------- Functions for Creating arpeggiation ---------------------------------
local function CreateCCArpeggiationInSelectedFigure(activeTake, lastNoteQn, lastNotePositionBetweenQN)
    -- bounds time selection 
    local startTimeSelection, endTimeSelection
    startTimeSelection, endTimeSelection = reaper.GetSet_LoopTimeRange2(
        currentProj, false, true, -1, -1, false)
    local ppqpos
    -- calc 1st quarter note in midi item after start time selection
    local firstQnInItem = math.ceil(reaper.TimeMap2_timeToQN(currentProj, startTimeSelection))
    local qnPos
    local stillLooping = true
    
    -- Creating CC data
    if listSelectedCC == nil then 
        Msg("Please save CC data") 
    else
        -- easeIn   
        for i, cc in ipairs(listSelectedCC["easeIn"]) do 
            qnPos = firstQnInItem + cc.qnInFigure + cc.positionBetweenQN -- position of CC data relative to qn
            ppqpos = reaper.MIDI_GetPPQPosFromProjQN(activeTake, qnPos)
            reaper.MIDI_InsertCC(activeTake, cc.isSelected, cc.isMuted, ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3)
        end
        -- figure loop
        while stillLooping do 
            for i,cc in ipairs(listSelectedCC["figure"]) do
                qnPos = firstQnInItem + cc.qnInFigure + cc.positionBetweenQN
                Msg("qn Pos : "..qnPos)
                ppqpos = reaper.MIDI_GetPPQPosFromProjQN(activeTake, qnPos)
                reaper.MIDI_InsertCC(activeTake, cc.isSelected, cc.isMuted, ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3)

                -- last cc in list, then repeat
                if i == #listSelectedCC["figure"] then 
                    firstQnInItem = firstQnInItem + lastNoteQn + 1 -- start next figure is qn of the last note in a figure + 1
                    Msg("Setting new firstQnInItem : "..firstQnInItem)
                    -- check if last note in next figure is out of bounds 
                    local startLastNoteInNextFigure = reaper.TimeMap_QNToTime(firstQnInItem + lastNoteQn + lastNotePositionBetweenQN)
                    Msg("Finished a figure")
                    -- can the next figure fit within bounds ?
                    if startLastNoteInNextFigure > endTimeSelection  then 
                        stillLooping = false -- out of bounds
                    end 
                end
            end
        end
        -- easeOut
        for i, cc in ipairs(listSelectedCC["easeOut"]) do 
            qnPos = firstQnInItem + cc.qnInFigure + cc.positionBetweenQN -- position of CC data relative to qn
            ppqpos = reaper.MIDI_GetPPQPosFromProjQN(activeTake, qnPos)
            reaper.MIDI_InsertCC(activeTake, cc.isSelected, cc.isMuted, ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3)
        end
    end
    

    
    -- TODO need to change to correct shape

end




local function CreateNoteArpeggiationInSelectedFigure(take) -- within time selection
    -- bounds time selection 
    local startTimeSelection, endTimeSelection
    startTimeSelection, endTimeSelection = reaper.GetSet_LoopTimeRange2(
        currentProj, false, true, -1, -1, false)
    Msg("Start time selection : "..startTimeSelection)
    Msg("End time selection : "..endTimeSelection)

    local startppqpos, endppqpos

    -- calc 1st quarter note in midi item after start time selection
    local firstQnInItem = math.ceil(reaper.TimeMap2_timeToQN(currentProj, startTimeSelection))
    local qnPos
    local stillLooping = true

    while stillLooping do
        if listSelectedNotes == nil then Msg("Please save a figure") 
        else
            -- creating notes
            for i,n in ipairs(listSelectedNotes) do
                -- start ppq = from start timeline up to 1st qn + positionBetweenQN
                -- can have several notes per qn
                qnPos = firstQnInItem + n.qnInFigure + n.positionBetweenQN
                Msg("qn Pos : "..qnPos)
                startppqpos = reaper.MIDI_GetPPQPosFromProjQN(take, qnPos)
                endppqpos = startppqpos + n.ppqLength
                reaper.MIDI_InsertNote(take, n.isSelected, n.isMuted, startppqpos, 
                endppqpos, n.chan, n.pitch, n.vel)

                -- last qn in finished figure + 1
                if n.isLastInFigure then 
                    firstQnInItem = firstQnInItem + n.qnInFigure + 1 -- start next figure is current qn + 1
                    Msg("Setting new firstQnInItem : "..firstQnInItem)
                    local startLastNoteInNextFigure = reaper.TimeMap_QNToTime(firstQnInItem + n.qnInFigure + n.positionBetweenQN)
                    Msg("Finished a figure")
                    if startLastNoteInNextFigure > endTimeSelection  then 
                        -- can the next figure fit within bounds ?
                        return -- out of bounds
                    end 
                end
            end
            



        end
    end
    -- 
end

local function ChangeSelectedNotesToSavedFigure()
    local item = reaper.GetSelectedMediaItem(currentProj, 0)
    local activeTake = reaper.GetActiveTake(item)
    -- loop through all selected notes
    local noteIdx = -1 -- 
    local isDone = false
    local note
    local retVal = false

    local figureListActiveIndex = 1 -- 


    while not isDone do 
        noteIdx = reaper.MIDI_EnumSelNotes(activeTake, noteIdx)
        Msg("selected : "..noteIdx)
        if noteIdx == -1 then 
            isDone = true 
        else 
            -- save selected note
            note = Note:New()
            retval, note.selected, note.muted, note.startppqpos, note.endppqpos, note.chan, 
                note.pitch, note.vel =  reaper.MIDI_GetNote(activeTake, noteIdx)
            -- set note, change pitch and vel
            reaper.MIDI_SetNote(activeTake, noteIdx, true, note.muted, note.startppqpos, note.endppqpos, note.chan, 
                listSelectedNotes[figureListActiveIndex].pitch, 
                listSelectedNotes[figureListActiveIndex].vel, false) -- TODO what is no sort in ???

            -- update figureListActiveIndex
            figureListActiveIndex = figureListActiveIndex + 1
            if figureListActiveIndex > #listSelectedNotes then 
                figureListActiveIndex = 1
            end
        end
        
    end
    reaper.MIDI_Sort(activeTake)
    -- only change pitch

end







-------------------------------------------------------------------
------------------------- UI Callbacks ----------------------------
-------------------------------------------------------------------

local function OnSaveFigure_Pressed()
    -- get selected midi notes
    local item = reaper.GetSelectedMediaItem(currentProj, 0)
    local activeTake = reaper.GetActiveTake(item)
    listSelectedNotes = GetListAllSelectedMidiNotesInItem(activeTake)
    if #listSelectedNotes == 0 or nil then 
        Msg("no selected notes!") 
    else
        Msg("# of selected notes : "..#listSelectedNotes)
        -- get selected cc data from bounds :
        local qnFigureStart = math.floor(listSelectedNotes[1].qn)
        local qnFigureLast = math.ceil(listSelectedNotes[#listSelectedNotes].qn)
        listSelectedCC = GetListSelectedCCFromNotes(activeTake, qnFigureStart, qnFigureLast)
    end

end

local function OnCreateArpeggiation_Pressed()
    Msg("Create Arpeggiation pressed")
    local item = reaper.GetSelectedMediaItem(currentProj, 0)
    if item == nil then 
        Msg("You need to select a midi item")
    else 
        local activeTake = reaper.GetActiveTake(item)
        CreateNoteArpeggiationInSelectedFigure(activeTake)
        local lastNoteQnInFigure = listSelectedNotes[#listSelectedNotes].qnInFigure
        local lastNotePosQn = listSelectedNotes[#listSelectedNotes].positionBetweenQN
        CreateCCArpeggiationInSelectedFigure(activeTake, lastNoteQnInFigure, lastNotePosQn)
    end
end

local function OnChangeArpeggiation_Pressed() -- changes pitch and vel
    Msg("On Change Arp pressed")
    -- TODO save slots
    ChangeSelectedNotesToSavedFigure()
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
    GUI.New("btn_ChangeArpeggiation", "Button", 1, 30, 90, 165, 24, "Change Arpeggiation", OnChangeArpeggiation_Pressed)
    

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