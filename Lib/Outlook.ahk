Outlook_PersonalizeMentions(sName:=""){
 If GetKeyState("Ctrl") {
	Run, "https://tdalon.blogspot.com/2020/11/teams-shortcuts-personalize-mentions.html"
	return
}
If (sName="") {
    SendInput +{Left}
    sLastLetter := GetSelection()
    SendInput {Right}
} Else
    sLastLetter := SubStr(sName,0)

If (sLastLetter = ")") {
    SendInput +{Backspace}+{Backspace}+{Backspace}^{Left}^{Backspace}^{Backspace}^{Right}
} Else {
    SendInput ^{Left}^{Backspace}^{Backspace}^{Right}
}
  
; Remove numbers from mention
SendInput +{Left}
sLastLetter := GetSelection()
If RegExMatch(sLastLetter,"\d")
    SendInput {Delete}
SendInput +{Left}
sLastLetter := GetSelection()
If RegExMatch(sLastLetter,"\d")
    SendInput {Delete}
SendInput {Right}
} ; eofun 


; ------------------------------------------------------------------

Outlook_GetCurrentItem(olApp:="") {
If (olApp = "")
    olApp := ComObjActive("Outlook.Application")
try
    olItem := olApp.ActiveWindow.CurrentItem
catch
    olItem := olApp.ActiveExplorer.Selection.Item(1)

return olItem
} ; eofun

; ------------------------------------------------------------------
Outlook_Recipients2Emails(oItem) {
cnt := oItem.Recipients.Count

Loop, %cnt%
{
    sEmail := oItem.Recipients.Item(A_Index).Address 
    sEmailList := sEmailList . ";" . sEmail
}

sEmailList :=	SubStr(sEmailList,2) ; remove starting ;
return sEmailList
} ; eofun
; ------------------------------------------------------------------

Outlook_Meeting2Excel(oItem :="") {

olApp := ComObjActive("Outlook.Application")

If (oItem ="")
    oItem := Outlook_GetCurrentItem(olApp)

oExcel := ComObjCreate("Excel.Application") ;handle
oExcel.Workbooks.Add ;add a new workbook
oSheet := oExcel.ActiveSheet
; First Row Header
oSheet.Range("A1").Value := "Name"
oSheet.Range("B1").Value := "LastName"
oSheet.Range("C1").Value := "FirstName"
oSheet.Range("D1").Value := "email"
oSheet.Range("E1").Value := "Response"
oSheet.Range("F1").Value := "Attendance"

oExcel.Visible := True ;by default excel sheets are invisible
oExcel.StatusBar := "Copy to Excel..."

Pos = 1 
RowCount = 2

cnt := oItem.Recipients.Count

Loop, %cnt%
{
    Email := oItem.Recipients.Item(A_Index).Address 
    Name := oItem.Recipients.Item(A_Index).Name 
    LastName := People_ADGetUserField("mail=" . Email, "sn")
    FirstName := People_ADGetUserField("mail=" . Email, "GivenName")
    oSheet.Range("A" . RowCount).Value := Name
    oSheet.Range("B" . RowCount).Value := LastName
    oSheet.Range("C" . RowCount).Value := FirstName
    oSheet.Range("D" . RowCount).Value := Email

    MeetingResponseStatus := oItem.Recipients.Item(A_Index).MeetingResponseStatus
    
    Switch MeetingResponseStatus
    {
        Case 5:
            MeetingResponseStatus = None
        Case 4:
            MeetingResponseStatus = Declined
        Case 3:
            MeetingResponseStatus = Accepted
        Case 2:
            MeetingResponseStatus = Tentative
        Case 1:
            MeetingResponseStatus = Organizer ; not used Outlook Bug - Organizer returns 0
        Case 0:
            MeetingResponseStatus = N/A
    } 
    oSheet.Range("E" . RowCount).Value := MeetingResponseStatus
    
    Type := oItem.Recipients.Item(A_Index).Type
     MsgBox % Type
    Switch Type
    {
        Case 3:
            Type = Resource
        Case 2:
            Type = Optional
        Case 1:
            Type = Required
        Case 0:
            Type = Organizer ; not used Outlook Bug. Organizer = Required
    }
    oSheet.Range("F" . RowCount).Value := Type

    RowCount +=1
}


; expression.Add (SourceType, Source, LinkSource, XlListObjectHasHeaders, Destination, TableStyleName)
oTable := oSheet.ListObjects.Add(1, oSheet.UsedRange,,1)
oTable.Name := "OutlookRecipientsExport"

oTable.Range.Columns.AutoFit
oExcel.StatusBar := "READY"


} ; eofun
; ------------------------------------------------------------------
