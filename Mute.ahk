#SingleInstance force ; for running from editor
global G_SetVolExe
global G_IsOn
G_SetVolExe := PowerTools_RegRead("SetVolExe")
If (G_SetVolExe = "") {
    G_SetVolExe := Mute_SetExe()
    If (G_SetVolExe = "")
        return
}

SubMenuSettings := PowerTools_MenuTray()
;Menu, Tray, NoStandard  

Devices := PowerTools_RegRead("MuteDevices")
Loop, parse,  Devices, `;
{
    Menu, SubMenuDevices, Add, %A_LoopField%, MenuCb_Device
}
Menu, Tray, Add, Device, :SubMenuDevices

; Default Value for Device Name
Device := PowerTools_RegRead("MuteDevice")

Menu, TrayToggleMute, Add, Toggle Mute..., DoNothing  
Menu, TrayMuteOn, Add, Muted..., DoNothing 

If Not InStr(Device . ";",Devices) {
    Device := RegExReplace(Devices,";.*","")
    PowerTools_RegWrite("MuteDevice",Device)
}
Menu,SubMenuDevices,Check, %Device%
Tray_Icon_On := "HBITMAP:*" . Create_Mic_On_ico()
Tray_Icon_Off := "HBITMAP:*" . Create_Mic_Off_ico()

GoSub RefreshIcon

; Command line
If (A_Args.Length() > 0) {
    sInput := A_Args[1]
    FoundPos := InStr(sInput," ")  
    If (FoundPos) {
        Device := SubStr(sInput,1,FoundPos-1)
        sCmd := SubStr(sInput,FoundPos+1)
    } Else {
        Device := sInput
        sCmd =
    }

    Mute(Device, sCmd)
}



return

; ########################################## HOTKEYS ###################################################
; ----------------------------------------------------------------------

f3::
IsOn := Mute_Get()
MsgBox %IsOn%
return


RefreshIcon:
If (G_IsOn="")
    G_IsOn := Mute_Get()
If (G_IsOn) {
    Menu, Tray, Icon, %Tray_Icon_On%
} Else {
    Menu, Tray, Icon, %Tray_Icon_Off%
}
return


; ######################################################################
NotifyTrayClick_208:   ; Middle click (Button up)
Mute("","on")
Menu_Show(MenuGetHandle("TrayMuteOn"), False, Menu_TrayParams()*)
Return 

NotifyTrayClick_202:   ; Left click (Button up)
Mute()
Menu_Show(MenuGetHandle("TrayToggleMute"), False, Menu_TrayParams()*)
Return


DoNothing:
return

; ########################################## FUNCTIONS ###################################################
Mute(Device:="",sCmd:=""){
; Mute(Device,sCmd)

If (Device="")
    Device := PowerTools_RegRead("MuteDevice")
If (sCmd="") 
    sCmd = switch
 
;SoundVolumeView(sCmd,Device)
Switch sCmd
{
Case "mute","mu","on":
    sCmd = mute
    G_IsOn := False
Case "unmute","un","off":
    sCmd = unmute
    G_IsOn := True
Case "switch","toggle","to","sw":
    If (G_IsOn)
        sCmd = mute
    Else
        sCmd = unmute
    G_IsOn := Not (G_IsOn)
} ;eo switch
sCmd = "%G_SetVolExe%" %sCmd% device %Device%
Run, %sCmd%,,Hide

GoSub RefreshIcon

} ; eofun
; ----------------------------------------------------------------------
SoundVolumeView(sCmd:="/Switch",Device:="") {
sCmd = "%SVVExe%" %sCmd% "%Device%"
Run, %sCmd%
} ; eofun
; ----------------------------------------------------------------------

Mute_Get(Device:="") {
; IsOn := Mute_Get(Device)
If (Device="")
    Device := PowerTools_RegRead("MuteDevice")
;sCmd = "%SVVExe%" /GetMute "%Device%"
sCmd = "%G_SetVolExe%" report device %Device%
;MsgBox %sCmd%
RunWait, %sCmd%,,Hide
IsOn :=  (ErrorLevel >= 0)
return IsOn
} ; eofun
; ----------------------------------------------------------------------

Mute_SetExe(){
FileSelectFile, SetVolExe , 1, SetVol.exe, Select the location of SetVol.exe, SetVol.exe
If ErrorLevel
    return
PowerTools_RegWrite("SetVolExe",SetVolExe)
return SetVolExe
} ; eofun

; ----------------------------------------------------------------------

Mute_GetDevice() {
MuteDevice := PowerTools_RegGet("MuteDevice")
}
; ----------------------------------------------------------------------

Mute_SetDevice(Device) {
If (Device="Custom") {

}
PowerTools_RegWrite("MuteDevice",Device)
} ; eofun
; ----------------------------------------------------------------------
Mute_GetDevices() {
SplitPath, G_SetVolExe , , OutDir
sFile = %OutDir%\devices.txt
sCmd = "%G_SetVolExe%" device > "%sFile%"
Run, %ComSpec% /c "%sCmd%",,Hide
FileRead, DevicesTxt, %sFile%
DevicesTxt := RegExReplace(DevicesTxt,"s).*Recording","")
Loop, parse, DevicesTxt, `n, `r
{
    If RegExMatch(A_LoopField,"^    (.*)",sMatch)
        sDevices := sDevices . ";" . sMatch1
}
sDevices := SubStr(sDevices,2) ; remove starting ;
;MsgBox %sDevices% ; DBG
PowerTools_RegWrite("MuteDevices",sDevices)
return sDevices
} ; eofun


; ----------------------------------------------------------------------

MenuCb_Device(ItemName, ItemPos, MenuName){
Devices := PowerTools_RegRead("MuteDevices")
Loop, parse,  Devices, `;
{
    If (A_LoopField = ItemName)
        Menu, %MenuName%, Check, %A_LoopField%
    Else
        Menu, %MenuName%, Uncheck, %A_LoopField%
}
PowerTools_RegWrite("MuteDevice",ItemName)
} ; eofun


; ----------------------------------------------------------------------
; https://www.autohotkey.com/boards/viewtopic.php?t=81157


NotifyTrayClick(P*) {              ;  v0.41 by SKAN on D39E/D39N @ tiny.cc/notifytrayclick
Static Msg, Fun:="NotifyTrayClick", NM:=OnMessage(0x404,Func(Fun),-1),  Chk,T:=-250,Clk:=1
  If ( (NM := Format(Fun . "_{:03X}", Msg := P[2])) && P.Count()<4 )
     Return ( T := Max(-5000, 0-(P[1] ? Abs(P[1]) : 250)) )
  Critical
  If ( ( Msg<0x201 || Msg>0x209 ) || ( IsFunc(NM) || Islabel(NM) )=0 )
     Return
  Chk := (Fun . "_" . (Msg<=0x203 ? "203" : Msg<=0x206 ? "206" : Msg<=0x209 ? "209" : ""))
  SetTimer, %NM%,  %  (Msg==0x203        || Msg==0x206        || Msg==0x209)
    ? (-1, Clk:=2) : ( Clk=2 ? ("Off", Clk:=1) : ( IsFunc(Chk) || IsLabel(Chk) ? T : -1) )
Return True
}


; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################
Create_Mic_on_ico(NewHandle := False) {
Static hBitmap := 0
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 884 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAnFBMVEUAAAAAxgAA0gwA0w0A0g0A0w0A0w0A3wAA0w0A1Q4A1g4A1AsAzgwA0w0A0wkAzAkA2Q0AqgAA0w0A0w0A0w0A1Q0A0w0A/wAA0w4A0w0A0w8A0g0A1A4A0w0A0g4A1w0A0w0A0w0A1w0A1A0A2A0A0w0A0w0A1Q4A0QkA0g0A0w0A0w0A2AoA0A0A0g8A1A0A0w0A0w0A0w0AAACNi8PxAAAAMnRSTlMACY/mjp2cCPokJS8V/B0eFAPvOtM87gKWxTTlNcaUE96zJk0ntN0SHLfMtRomIp/49wBmOSwAAAABYktHRACIBR1IAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAB3RJTUUH5QEdDQIQMhdn1gAAAIBJREFUGNNjYAABRiZmZhZGBgRgNQICNgSfnQMkwIFQwmkEBpxwAS6IABfxAtwwAW4In4eXDyLAzysAFhAUEhYB8UVExcQhSiQkpaSNjKRlZOWgZsgrKCopK6uoqqnDTNXQ5NDS4tDWQfKMrqIiFxKXQUdPX18PSQGPAcgWQ7ClALhDEXOeykbUAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIxLTAxLTI5VDEzOjAyOjE2KzAwOjAwTlt0UgAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMS0wMS0yOVQxMzowMjoxNiswMDowMD8GzO4AAAAZdEVYdFNvZnR3YXJlAHd3dy5pbmtzY2FwZS5vcmeb7jwaAAAAAElFTkSuQmCC"
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", 0, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", &Dec, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, "UPtr", DecLen, "UPtr")
pData := DllCall("Kernel32.dll\GlobalLock", "Ptr", hData, "UPtr")
DllCall("Kernel32.dll\RtlMoveMemory", "Ptr", pData, "Ptr", &Dec, "UPtr", DecLen)
DllCall("Kernel32.dll\GlobalUnlock", "Ptr", hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", "Ptr", hData, "Int", True, "PtrP", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &SI, "Ptr", 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  "Ptr", pStream, "PtrP", pBitmap)
DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "PtrP", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", pToken)
DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)
DllCall(NumGet(NumGet(pStream + 0, 0, "UPtr") + (A_PtrSize * 2), 0, "UPtr"), "Ptr", pStream)
Return hBitmap
}

; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; ##################################################################################
Create_Mic_off_ico(NewHandle := False) {
Static hBitmap := 0
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 920 << !!A_IsUnicode)
B64 := "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAolBMVEUAAAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAAAAACyecVlAAAANHRSTlMAA4Pm5YJ0c07jSMf5+jna9VBiGlbrT+GkeMxc4LOmq0r4Rv78o1k4dpue/XI9tkAUM7ET+6bC8AAAAAFiS0dEAIgFHUgAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAAHdElNRQflAR0NAQrkWM1vAAAAkUlEQVQY01XP2RaCIBCA4dGMLCXArcXMFttXbN7/2YLgHGiu+L8zFwOAniAcRMMA3BBUM4J4PLGQaEjilE4tMA08pQJ8QNcGvP6B11nOdBd5ZqGsmGrCqtLCbE6pWOCyXlloUDeG69b0ZkvFbt8djp0566TuOV/q4nq724VIwKPh/PlyZ7yl7HspP/+fRST6/QXOExB226vKAgAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wMS0yOVQxMzowMToxMCswMDowMMa8+msAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDEtMjlUMTM6MDE6MTArMDA6MDC34ULXAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAABJRU5ErkJggg=="
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", 0, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", &Dec, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, "UPtr", DecLen, "UPtr")
pData := DllCall("Kernel32.dll\GlobalLock", "Ptr", hData, "UPtr")
DllCall("Kernel32.dll\RtlMoveMemory", "Ptr", pData, "Ptr", &Dec, "UPtr", DecLen)
DllCall("Kernel32.dll\GlobalUnlock", "Ptr", hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", "Ptr", hData, "Int", True, "PtrP", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &SI, "Ptr", 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  "Ptr", pStream, "PtrP", pBitmap)
DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "PtrP", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", pToken)
DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)
DllCall(NumGet(NumGet(pStream + 0, 0, "UPtr") + (A_PtrSize * 2), 0, "UPtr"), "Ptr", pStream)
Return hBitmap
}