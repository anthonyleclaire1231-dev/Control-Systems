#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 7, 3

Numpad5::
    if !FileExist("turtle_bridge.lua") {
        MsgBox, Error: turtle_bridge.lua not found in the script directory!
        return
    }
    
    FileRead, scriptContent, turtle_bridge.lua
    Loop, parse, scriptContent, `n, `r
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
        Sleep, 500
    }
return