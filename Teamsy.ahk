; Homepage: 
; You can compile it via running the Ahk2Exe command e.g. D:\Programs\AutoHotkey\Compiler\Ahk2Exe.exe /in "Teamsy.ahk" /icon "icons\Teams.ico"
LastCompiled = 20210114064703
#Include <Teams>
#Include <Monitor>

#SingleInstance force ; for running from editor

If (A_Args.Length() = 0) {
PowerTools_MenuTray()

; Tooltip
If !a_iscompiled 
	FileGetTime, LastMod , %A_ScriptFullPath%
 Else 
	LastMod := LastCompiled
FormatTime LastMod, %LastMod% D1 R

sTooltip = Teamsy %LastMod%`nClick on icon to access other functionalities.
Menu, Tray, Tip, %sTooltip%

; Run from command line
} Else
    Teamsy(A_Args[1])
return

; ------------------------------------------------------------------- functions --------------------------------------------

Teamsy(sInput){
    
If (!sInput) { ; empty
    WinId := Teams_GetMainWindow()
    WinActivate, ahk_id %WinId%
    return
}

FoundPos := InStr(sInput," ")  

If FoundPos {
    sKeyword := SubStr(sInput,1,FoundPos-1)
    sInput := SubStr(sInput,FoundPos+1)
} Else {
    sKeyword := sInput
    sInput =
}

Switch sKeyword
{
Case "w": ; Web App
    Switch sInput
    {
    Case "c","cal":
        Teams_OpenWebCal()
    Default:
        Teams_OpenWebApp()
    }
    return
Case "h","-h","help":
    Run, https://tdalon.github.io/ahk/Teamsy
    return
Case "news":
    PowerTools_News(A_ScriptName)
    return
Case "u":
    sKeyword = unread
Case "p":
    sKeyword = pop
Case "c":
    sKeyword = call
Case "f":
    sKeyword = find
Case "free","a":
    sKeyword = available
Case "s","save":
    sKeyword = saved
Case "d":
    sKeyword = dnd
Case "cal","calendar":
    WinId := Teams_GetMainWindow()
    WinActivate, ahk_id %WinId%
    SendInput ^4; open calendar
    return
Case "m","meet": ; create a meeting
    WinId := Teams_GetMainWindow()
    WinActivate, ahk_id %WinId%
    WinGetTitle Title, A
    If ! (Title="Calendar | Microsoft Teams") {
            SendInput ^4 ; open calendar
            Sleep, 300
            While ! (Title="Calendar | Microsoft Teams") { 
                WinGetTitle Title, A
                Sleep 500
            }
    }
    SendInput !+n ; schedule a meeting alt+shift+n
    return
Case "l","le","leave": ; leave meeting
    WinId := Teams_GetMeetingWindow()
    If !WinId ; empty
        return
    WinActivate, ahk_id %WinId%
    SendInput ^+b ; ctrl+shift+b
    return
Case "raise","hand","ha":  
    WinId := Teams_GetMeetingWindow()
    If !WinId ; empty
        return
    WinActivate, ahk_id %WinId%
    SendInput ^+m ; ctrl+shift+m 
    sleep, 1000
    SendInput ^+m ; ctrl+shift+m 
    sleep, 1000
    SendInput {Left}{3}{Enter} ; Select first screen
    return
Case "sh","share":  
    Teams_Share()
    return
Case "mu","mute":  
    Teams_Mute()
    return
Case "de":  ; decline call
    WinId := Teams_GetMainWindow()
    If !WinId ; empty
        return
    WinActivate, ahk_id %WinId%
    SendInput ^+d ;  ctrl+shift+d 
    return
Case "q","quit": ; quit
    sCmd = taskkill /f /im "Teams.exe"
    Run %sCmd%,,Hide 
    return
Case "r","restart": ; restart
    Teams_Restart()
    return
Case "clean": ; clean restart
    Teams_CleanRestart()
    return
Case "clear","cache","cl": ; clear cache
    Teams_ClearCache()
    return
Case "n","new","x": ; new expanded conversation 
    WinId := Teams_GetMainWindow()
    WinActivate, ahk_id %WinId%
    Teams_NewConversation()
    return
Case "v","vi": ; Toggle video with background
    Teams_Video()
    return
} ; End Switch

WinId := Teams_GetMainWindow()
WinActivate, ahk_id %WinId%

Send ^e ; Select Search bar
If (SubStr(sKeyword,1,1) = "@") {
    SendInput @
    sleep, 300
    sInput := SubStr(sKeyword,2)
} Else {
    SendInput /
    sleep, 300
    SendInput %sKeyword%
    sleep, 500
    SendInput {enter}
}

If (!sInput) ; empty
    return
sleep, 500

;sLastChar := SubStr(sInput,StrLen(sInput)) 
doBreak := (SubStr(sInput,StrLen(sInput)) == "-")
If (doBreak) {
    sInput := SubStr(sInput,1,StrLen(sInput)-1) ; remove last -
}

SendInput %sInput%
sleep, 800
If !doBreak
    SendInput {enter}
} ; End function     
