#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 7, 3

Numpad5::
    if !FileExist("monitor_print.lua") {
        MsgBox, Error: monitor_print.lua not found in the script directory!
        return
    }
    
    FileRead, scriptContent, monitor_print.lua
    Loop, parse, scriptContent, `n, `r
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
        Sleep, 500
    }
return