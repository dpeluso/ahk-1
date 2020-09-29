; GetSharepointUrl - Get clean sharepoint document library Url from browser url
; Syntax:
;	newurl := GetSharepointUrl(url)
; Example:
; 	https://continental.sharepoint.com/teams/team_10000035/Guides%20-%20Documents/Forms/AllItems.aspx?cid=e18e743c%2D86a5%2D4eb2%2D9e66%2Dded0fa83986f&RootFolder=%2Fteams%2Fteam%5F10000035%2FGuides%20%2D%20Documents%2FGeneral&FolderCTID=0x012000A46ECE04B4C0CD4D963D7DF0C1F91CBA
; in IE https://continental.sharepoint.com/teams/team_10000035/Guides%20-%20Documents/Forms/AllItems.aspx?cid=e18e743c%2D86a5%2D4eb2%2D9e66%2Dded0fa83986f&id=%2Fteams%2Fteam%5F10000035%2FGuides%20%2D%20Documents%2FGeneral
; =>
; https://continental.sharepoint.com/teams/team_10000035/Guides - Documents/General
; https://continental.sharepoint.com/teams/team_10000035/Guides%20-%20Documents/General
;
#Include <UriDecode>

; Syntax:
; 	sUrl := GetSharepointUrl(sUrl)
; Calls: uriDecode
; Called by: CleanUrl
;       MyScript Ctrl+E: open SharePoint Document Library from browser into File Explorer
GetSharepointUrl(url){
	If InStr(url,"_vti_history") ; speciasl case hardlink for old sharepoints
	{
		url := uriDecode(url)
		RegExMatch(url,"\?url=(.*)",newurl)
		return newurl1
	}

	; For new spo links
	If RegExMatch(url ,":[a-z]:/r/") { ; New SPO links
		url := RegExReplace(url ,":[a-z]:/r/","")
		; keep durable link
		If RegExMatch(url,"\?d=")
			url := RegExReplace(url ,"&.*","")
		Else
			url := RegExReplace(url ,"\?.*","")
		return url
	}

	url := StrReplace(url,"?Web=1","") ; old sharepoint link opening in browser


	; For old SP links
	RegExMatch(url,"https://([^/]*)",rooturl) 
	rooturl = https://%rooturl1%

	If !RegExMatch(url,"(?:\?|&)RootFolder=([^&]*)",RootFolder) 
		If !RegExMatch(url,"(?:\?|&)id=([^&]*)",RootFolder) 
			return RegExReplace(url,"/Forms/AllItems.aspx.*$","")
		
	; exclude & 
	; non-capturing group starts with ?: see https://autohotkey.com/docs/misc/RegEx-QuickRef.htm
		
	; decode url			
	RootFolder:= uriDecode(RootFolder1)
	;msgbox %RootFolder%	
	
	newurl := rooturl . RootFolder
	;MsgBox %newurl%
	return newurl	
}


; TEST old SharePoint
;   https://cws7.conti.de/content/11011979/CFST_Documents/Forms/AllItems.aspx?RootFolder=%2fcontent%2f11011979%2fCFST%5fDocuments%2fTest%5fArchitecture%5fand%5fLibrary%2fStart%5fSmart%5fPackage&FolderCTID=0x012000DB1CEDE45CDD754299DFD96C87BD058F
; TEST Teams
; https://continental.sharepoint.com/teams/team_10000778/Shared%20Documents/Forms/AllItems.aspx?FolderCTID=0x012000761015BBA31DEE4AB964DB6D73C115C2&id=%2Fteams%2Fteam%5F10000778%2FShared%20Documents%2FTools
; TEST Teams with Copy Link
; https://continental.sharepoint.com/:f:/r/teams/team_10000035/Shared%20Documents/General/Pictures?csf=1&e=Um9ecD