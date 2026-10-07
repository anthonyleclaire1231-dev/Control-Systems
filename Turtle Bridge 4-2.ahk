#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 7, 3

Numpad5::
    if !FileExist("Turtle Bridge 4-2.lua") {
        MsgBox, Error: Turtle Bridge 4-2.lua not found in the script directory!
        return
    }
    
    FileRead, scriptContent, Turtle Bridge 4-2.lua
    Loop, parse, scriptContent, `n, `r
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
        Sleep, 500
    }
return