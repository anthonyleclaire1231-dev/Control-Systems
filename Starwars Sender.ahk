#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 7, 3

Numpad5::
    if !FileExist("starwars_sender.lua") {
        MsgBox, Error: starwars_sender.lua not found in the script directory!
        return
    }
    
    FileRead, scriptContent, starwars_sender.lua
    Loop, parse, scriptContent, `n, `r
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
        Sleep, 500
    }
return