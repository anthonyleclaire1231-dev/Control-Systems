#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 7, 3

Numpad5::
    if !FileExist("reactor_monitor_slave.lua") {
        MsgBox, Error: reactor_monitor_slave.lua not found in the script directory!
        return
    }
    
    FileRead, scriptContent, reactor_monitor_slave.lua
    Loop, parse, scriptContent, `n, `r
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
        Sleep, 500
    }
return