#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 30, 15

Numpad5::
    if !FileExist("reactor_mappings.lua") {
        MsgBox, Error: reactor_mappings.lua not found in the script directory!
        return
    }
    
    FileRead, scriptContent, reactor_mappings.lua
    
    ; Normalize line endings by stripping all carriage returns
    StringReplace, scriptContent, scriptContent, `r,, All
    
    Loop, parse, scriptContent, `n
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
        Sleep, 100  ; Adjusted for smoother typing
    }
return