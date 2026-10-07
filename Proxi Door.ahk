#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 7, 3

Numpad5::
    if !FileExist("proxi_door.lua") {
        MsgBox, Error: proxi_door.lua not found in the script directory!
        return
    }
    
    FileRead, scriptContent, proxi_door.lua
    Loop, parse, scriptContent, `n, `r
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
        Sleep, 500
    }
return