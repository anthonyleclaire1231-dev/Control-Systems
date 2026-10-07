#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 7, 3

Numpad5::
    if !FileExist("elevator_receiver.lua") {
        MsgBox, Error: elevator_receiver.lua not found in the script directory!
        return
    }
    
    FileRead, scriptContent, elevator_receiver.lua
    Loop, parse, scriptContent, `n, `r
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
        Sleep, 500
    }
return