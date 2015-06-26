;NSIS Modern User Interface
;Basic Example Script
;Written by Joost Verburg

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
;General

  ;Name and file
  Name "PostgreSQL 9.4"
  OutFile "Postgre_94_x86.exe"

  ;Default installation folder
  InstallDir "$LOCALAPPDATA\PostgreSQL\9.4"
  
  ;Get installation folder from registry if available
  ;InstallDirRegKey HKCU "Software\Modern UI Test" ""
  InstallDirRegKey HKLM "Software\PostgresPro\PostgreSQL\9.4" ""

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin

;--------------------------------
;Interface Settings

  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\win.bmp" ; optional
  !define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\win-install.ico"
  !define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\win-uninstall.ico"


  !define MUI_ABORTWARNING

;--------------------------------
;Pages
Page custom nsDialogsPage

  !insertmacro MUI_PAGE_LICENSE "License.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English" ;first language is the default language
  !insertmacro MUI_LANGUAGE "Russian"

  ;Language strings
  LangString DESC_Sec1 ${LANG_ENGLISH} "Application executable files"
  LangString DESC_Sec1 ${LANG_RUSSIAN} "Исполняемые файлы программы"


;--------------------------------
;Installer Sections

Section "Dummy Section" SecDummy

  SetOutPath "$INSTDIR"
  
  ;ADD YOUR OWN FILES HERE...
  
  ;Store installation folder
  WriteRegStr HKCU "Software\Modern UI Test" "" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecDummy ${LANG_ENGLISH} "A test section."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDummy} $(DESC_SecDummy)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Section "Uninstall"

  ;ADD YOUR OWN FILES HERE...

  Delete "$INSTDIR\Uninstall.exe"

  RMDir "$INSTDIR"

  DeleteRegKey /ifempty HKCU "Software\Modern UI Test"

SectionEnd




Var BUTTON
Var EDIT
Var CHECKBOX

Function nsDialogsPage

	nsDialogs::Create 1018
	Pop $0

	GetFunctionAddress $0 OnBack
	nsDialogs::OnBack $0

	${NSD_CreateButton} 0 0 100% 12u Test
	Pop $BUTTON
	GetFunctionAddress $0 OnClick
	nsDialogs::OnClick $BUTTON $0

	${NSD_CreateText} 0 35 100% 12u hello
	Pop $EDIT
	GetFunctionAddress $0 OnChange
	nsDialogs::OnChange $EDIT $0

	${NSD_CreateCheckbox} 0 -50 100% 8u Test
	Pop $CHECKBOX
	GetFunctionAddress $0 OnCheckbox
	nsDialogs::OnClick $CHECKBOX $0

	${NSD_CreateLabel} 0 40u 75% 40u "* Type `hello there` above.$\n* Click the button.$\n* Check the checkbox.$\n* Hit the Back button."
	Pop $0

	nsDialogs::Show

FunctionEnd

Function OnClick

# allocate

System::Alloc 64

Pop $1

# init

System::Call "*$1(i64)"

# call

System::Call "Kernel32::GlobalMemoryStatusEx(i r1)"

# get

System::Call "*$1(i.r2, i.r3, l.r4, l.r5, l.r6, l.r7, l.r8, l.r9, l.r10)"

# free

System::Free $1

# print

DetailPrint "Structure size: $2 bytes"

DetailPrint "Memory load: $3%"

DetailPrint "Total physical memory: $4 bytes"

DetailPrint "Free physical memory: $5 bytes"

DetailPrint "Total page file: $6 bytes"

DetailPrint "Free page file: $7 bytes"

DetailPrint "Total virtual: $8 bytes"

DetailPrint "Free virtual: $9 bytes"


	Pop $0 # HWND

	MessageBox MB_OK "Total physical memory: $4 bytes"

FunctionEnd

Function OnChange

	Pop $0 # HWND

	System::Call user32::GetWindowText(p$EDIT,t.r0,i${NSIS_MAX_STRLEN})

	${If} $0 == "hello there"
		MessageBox MB_OK "right back at ya"
	${EndIf}

FunctionEnd

Function OnBack

	MessageBox MB_YESNO "are you sure?" IDYES +2
	Abort

FunctionEnd

Function OnCheckbox

	Pop $0 # HWND

	MessageBox MB_OK "checkbox clicked"

FunctionEnd

Section
SectionEnd



Function .onInit

  !insertmacro MUI_LANGDLL_DISPLAY

FunctionEnd