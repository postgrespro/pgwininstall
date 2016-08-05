; PostgeSQL install Script
; Written by Postgres Professional, Postgrespro.ru
; used plugins: AccessControl, UserMgr,
; and AddToPath plugin was created by Victor Spirin for this project

!addplugindir Plugins
!include "postgres.def.nsh"

;--------------------------------
;Include "Modern UI"
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

!include "WordFunc.nsh"
!include "TextFunc.nsh"
!include "StrRep.nsh"

!include "ReplaceInFile.nsh"
!include "common_macro.nsh"
!include "Utf8Converter.nsh"

!include "WinVer.nsh"

!insertmacro VersionCompare

;--------------------------------
;General
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "${BUILD_DIR}\installers\${PRODUCT_NAME}_${PG_DEF_VERSION}_${PG_INS_SUFFIX}"

!ifdef PG_64bit
  InstallDir "$PROGRAMFILES64\${PRODUCT_NAME}\${PG_MAJOR_VERSION}"
!else
  InstallDir "$PROGRAMFILES32\${PRODUCT_NAME}\${PG_MAJOR_VERSION}"
!endif

BrandingText "Postgres Professional"

;Get installation folder from registry if available
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""

;ShowInstDetails show
;ShowUnInstDetails show

;Request application privileges for Windows Vista
RequestExecutionLevel admin

Var Dialog
Var Label
Var Label2
Var TextPort
Var checkNoLocal
Var Locale
;Var Coding
Var UserName
Var Pass1
Var Pass2

Var DATA_DIR  ;path to data

Var TextPort_text
Var IsTextPortInIni
Var checkNoLocal_state
Var Locale_text
Var Coding_text
Var UserName_text
Var Pass1_text
Var Pass2_text

Var Codepage_text
Var Winver_text

Var ServiceAccount_text
Var ServiceID_text
Var Version_text
Var Branding_text

Var loggedInUser ;current Domain/UserName
Var loggedInUserShort ;current UserName

VAR PG_OLD_VERSION  ; Version of an installed PG
VAR PG_OLD_DIR      ; Directory of an installed PG (Empty string if no PG)

Var tempFileName
Var isDataDirExist

Var StartMenuFolder
Var  tempVar
;Var PORT
;Var ADMINNAME
Var AllMem
Var FreeMem
Var shared_buffers
Var work_mem
Var needOptimiztion
Var rButton1
Var rButton2

; set env variables
Var checkBoxEnvVar
Var isEnvVar

; Set 'install service' variable
Var service

;MUI_COMPONENTSPAGE_SMALLDESC or MUI_COMPONENTSPAGE_NODESC
!define MUI_COMPONENTSPAGE_SMALLDESC

;--------------------------------
;Interface Settings

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "pp_header.bmp" ; optional
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\win-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\win-uninstall.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "Elephant.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "Elephant.bmp"

!define MUI_ABORTWARNING

;--------------------------------
;Pages
;Page custom nsDialogsPage

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "License.txt"

Page custom ChecExistInstall ;PG_OLD_DIR !="" if exist
!insertmacro MUI_PAGE_COMPONENTS
Page custom nsDialogServerExist
!define MUI_PAGE_CUSTOMFUNCTION_PRE dirPre
!insertmacro MUI_PAGE_DIRECTORY

;!insertmacro VersionCompare
PageEx directory
  PageCallbacks func1
  DirVar $DATA_DIR
  DirText $(DATADIR_MESS) $(DATADIR_TITLE) $(BROWSE_BUTTON)
PageExEnd

Page custom ChecExistDataDir

Page custom nsDialogServer nsDialogsServerPageLeave
Page custom nsDialogOptimization nsDialogsOptimizationPageLeave

;Start Menu Folder Page Configuration
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${PRODUCT_DIR_REGKEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
!define MUI_PAGE_CUSTOMFUNCTION_PRE dirPre
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages
!insertmacro MUI_LANGUAGE "English" ;first language is the default language
!insertmacro MUI_LANGUAGE "Russian"

!include translates.nsi

;--------------------------------
;Installer Sections
Section "Microsoft Visual C++ ${REDIST_YEAR} Redistributable" secMS
  GetTempFileName $1
  !ifdef PG_64bit
    File /oname=$1 "${BUILD_DIR}\vcredist\vcredist_x64_${REDIST_YEAR}.exe"
  !else
    File /oname=$1 "${BUILD_DIR}\vcredist\vcredist_x86_${REDIST_YEAR}.exe"
  !endif
  ExecWait "$1  /passive /norestart" $0
  DetailPrint "Visual C++ Redistributable Packages return $0"
  Delete $1
SectionEnd

Section $(PostgreSQLString) sec1
  ${if} $PG_OLD_DIR != "" ;exist PG install
    MessageBox MB_YESNO|MB_ICONQUESTION  "$(MESS_STOP_SERVER)" IDYES doitStop IDNO noyetStop
    noyetStop:
    Return
    doitStop:
    DetailPrint "Stop the server ..."
    ${if} $DATA_DIR != ""
      nsExec::Exec '"$INSTDIR\bin\pg_ctl.exe" stop -D "$DATA_DIR" -m fast -w'
      pop $0
      DetailPrint "pg_ctl.exe stop return $0"
    ${endif}
    ;unregister
    DetailPrint "Unregister the service ..."
    ${if} $ServiceID_text != ""
     nsExec::Exec '"$INSTDIR\bin\pg_ctl.exe" unregister -N "$ServiceID_text"'
      pop $0
      DetailPrint "pg_ctl.exe unregister return $0"
    ${endif}
  ${endif}

  SetOutPath "$INSTDIR"

  File /r ${PG_INS_SOURCE_DIR}
  File  "/oname=$INSTDIR\doc\installation-notes.html" "installation-notes.html"
  File  "/oname=$INSTDIR\doc\installation-notes-ru.html" "installation-notes-ru.html"

  File "License.txt"
  File "3rd_party_licenses.txt"

  CreateDirectory "$INSTDIR\scripts"
  File  "/oname=$INSTDIR\scripts\pg-psql.ico" "pg-psql.ico"
  File  "/oname=$INSTDIR\doc\pg-help.ico" "pg-help.ico"

  ;Store installation folder
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" $INSTDIR

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; write uninstall strings
  WriteRegExpandStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "DisplayName" "$StartMenuFolder"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "DisplayVersion" "${PG_DEF_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "HelpLink" "${PRODUCT_WEB_SITE}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "Comments" "Packaged by PostgresPro.ru"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "UrlInfoAbout" "${PRODUCT_WEB_SITE}"

  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "EstimatedSize" "$0"

  ClearErrors
  FileOpen $0 $INSTDIR\scripts\reload.bat w
  IfErrors creatBatErr
  FileWrite $0 'echo off$\r$\n"$INSTDIR\bin\pg_ctl.exe" reload -D "$DATA_DIR"$\r$\npause'
  FileClose $0
  creatBatErr:
  ClearErrors

  GetWindowsVersion $Winver_text
  MessageBox MB_OK|MB_ICONINFORMATION "Windows Version: $Winver_text"
  
  ${If} $Winver_text == "XP"
    System::Call "kernel32::GetACP() i .r2"
    StrCpy $Codepage_text $2
  ${Else}
    StrCpy $Codepage_text "65001"
  ${EndIf}
  
  DetailPrint "Set codepage $Codepage_text"
  MessageBox MB_OK|MB_ICONINFORMATION "Set codepage: $Codepage_text"

  FileOpen $0 $INSTDIR\scripts\runpgsql.bat w
  IfErrors creatBatErr2
  ;chcp ${Codepage_text}$\r$\n
  FileWrite $0 '@echo off$\r$\nPATH $INSTDIR\bin;%PATH%$\r$\nif not exist %APPDATA%\postgresql md %APPDATA%\postgresql$\r$\npsql.exe -h localhost -U "$UserName_text" -d postgres -p $TextPort_text $\r$\npause'
  FileClose $0

  creatBatErr2:
  ClearErrors
  FileOpen $0 $INSTDIR\scripts\restart.bat w
  IfErrors creatBatErr3
  FileWrite $0 'echo off$\r$\n"$INSTDIR\bin\pg_ctl.exe" stop -D "$DATA_DIR" -m fast $\r$\nsc start "$ServiceID_text" $\r$\npause'
  FileClose $0

  creatBatErr3:
  ClearErrors
  FileOpen $0 $INSTDIR\scripts\stop.bat w
  IfErrors creatBatErr4
  FileWrite $0 'echo off$\r$\n"$INSTDIR\bin\pg_ctl.exe" stop -D "$DATA_DIR" -m fast $\r$\npause'
  FileClose $0

  creatBatErr4:
  ClearErrors
  FileOpen $0 $INSTDIR\scripts\start.bat w
  IfErrors creatBatErr5
  FileWrite $0 'echo off$\r$\nsc start "$ServiceID_text" $\r$\npause'
  FileClose $0

  creatBatErr5:
  ClearErrors
  FileOpen $0 $INSTDIR\scripts\pgpro_upgrade.cmd w
  IfErrors creatBatErr6
  FileWrite $0 '@echo off$\r$\nif "%PGDATA%"=="" set PGDATA=%~1$\r$\nif "%PGDATA%"=="" set PGDATA=$DATA_DIR$\r$\nPATH $INSTDIR\bin;%PATH%$\r$\nsh.exe "$INSTDIR\bin\pgpro_upgrade"$\r$\n'
  FileClose $0

  creatBatErr6:
  ;for all users
    SetShellVarContext all
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

  ;Create shortcuts
  CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

  ${if} ${FileExists} "$INSTDIR\scripts\runpgsql.bat"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\SQL Shell (psql).lnk" "$INSTDIR\scripts\runpgsql.bat" "" "$INSTDIR\scripts\pg-psql.ico" "0" "" "" "PostgreSQL command line utility"
  ${else}
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\SQL Shell (psql).lnk" "$INSTDIR\bin\psql.exe" "-h localhost -U $UserName_text -d postgres -p $TextPort_text" "" "" "" "" "PostgreSQL command line utility"
  ${endif}

  ; set font Lucida Console for shortcut psql
  ReadRegStr $0 HKCU "Console\SQL Shell (psql)" "FaceName"
  ${if} $0 == ""
    WriteRegStr HKCU "Console\SQL Shell (psql)" "FaceName" "Consolas"
    WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontWeight" "400"
    WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontSize" "917504"
    WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontFamily" "54"
  ${endif}

  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Reload Configuration.lnk" "$INSTDIR\scripts\reload.bat" ""  "" "" "" "" "Reload PostgreSQL configuration"
  ;run as administrator
  push "$SMPROGRAMS\$StartMenuFolder\Reload Configuration.lnk"
  call ShellLinkSetRunAs
  pop $0

  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Restart Server.lnk" "$INSTDIR\scripts\restart.bat" ""  "" "" "" "" "Restart PostgreSQL server"
  ;run as administrator
  push "$SMPROGRAMS\$StartMenuFolder\Restart Server.lnk"
  call ShellLinkSetRunAs
  pop $0

  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Stop Server.lnk" "$INSTDIR\scripts\stop.bat" ""  "" "" "" "" "Stop PostgreSQL server"
  push "$SMPROGRAMS\$StartMenuFolder\Stop Server.lnk"
  call ShellLinkSetRunAs
  pop $0

  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Start Server.lnk" "$INSTDIR\scripts\start.bat" ""  "" "" "" "" "Start PostgreSQL server"
  push "$SMPROGRAMS\$StartMenuFolder\Start Server.lnk"
  call ShellLinkSetRunAs
  pop $0
  CreateDirectory "$SMPROGRAMS\$StartMenuFolder\Documentation"

  !insertmacro CreateInternetShortcut \
    "$SMPROGRAMS\$StartMenuFolder\Documentation\Installation notes" \
    "$INSTDIR\doc\installation-notes.html" \
    "$INSTDIR\doc\pg-help.ico" "0"

  !insertmacro CreateInternetShortcut \
    "$SMPROGRAMS\$StartMenuFolder\Documentation\Installation notes (RU)" \
    "$INSTDIR\doc\installation-notes-ru.html" \
    "$INSTDIR\doc\pg-help.ico" "0"

  !insertmacro CreateInternetShortcut \
    "$SMPROGRAMS\$StartMenuFolder\Documentation\PostgreSQL documentation (EN)" \
    "$INSTDIR\doc\postgresql-en.chm" \
    "$INSTDIR\doc\pg-help.ico" "0"

  !insertmacro CreateInternetShortcut \
    "$SMPROGRAMS\$StartMenuFolder\Documentation\PostgreSQL documentation (RU)" \
    "$INSTDIR\doc\postgresql-ru.chm" \
    "$INSTDIR\doc\pg-help.ico" "0"

  !insertmacro CreateInternetShortcut \
    "$SMPROGRAMS\$StartMenuFolder\Documentation\PostgreSQL release notes" \
    "$INSTDIR\doc\postgresql\html\release.html" \
    "$INSTDIR\doc\pg-help.ico" "0"

  !insertmacro MUI_STARTMENU_WRITE_END
  ; Create data dir begin
  ${if} $isDataDirExist == 0
    CreateDirectory "$DATA_DIR"
    ;AccessControl::GrantOnFile "$DATA_DIR" "(BU)" "FullAccess" ;GenericWrite
    ;Pop $0 ;"ok" or "error" + error details

    ;;;AccessControl::GrantOnFile "$DATA_DIR" "$ServiceAccount_text" "FullAccess"
    ;;;Pop $0 ;"ok" or "error" + error details
    ;;;AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUser" "FullAccess" ;GenericWrite
    ;;;Pop $0 ;"ok" or "error" + error details
    AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUserShort" "FullAccess"
    Pop $0

    StrCpy $tempVar ""
    ${if} "$Pass1_text" != ""
      GetTempFileName $tempFileName "$INSTDIR\bin"
      FileOpen $R0 $tempFileName w
      ${AnsiToUtf8} $Pass1_text $0
      FileWrite $R0 $0
      FileClose $R0
      StrCpy $tempVar ' --pwfile "$tempFileName"  -A md5 '
    ${endif}
    DetailPrint "Database initialization ..."
    AccessControl::GetCurrentUserName
    Pop $0 ; or "error"
    AccessControl::GrantOnFile "$DATA_DIR" "$0" "FullAccess" ;GenericWrite
    Pop $0 ;"ok" or "error" + error details
    ${if} "$Locale_text" == "$(DEF_LOCALE_NAME)"
      ; Initialise the database cluster, and set the appropriate permissions/ownership
      nsExec::ExecToStack /TIMEOUT=90000 '"$INSTDIR\bin\initdb.exe" $tempVar \
        --encoding=$Coding_text -U "$UserName_text" \
        -D "$DATA_DIR"'
    ${else}
      nsExec::ExecToStack /TIMEOUT=60000 '"$INSTDIR\bin\initdb.exe" $tempVar \
        --locale="$Locale_text" \
        --encoding=$Coding_text \
        -U "$UserName_text" \
        -D "$DATA_DIR"'
    ${endif}
    pop $0
    Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}

    ${if} $0 != 0
      DetailPrint "initdb.exe return $0"
      DetailPrint "Output: $1"
      Sleep 5000
    ${else}
      DetailPrint "Database initialization OK"
    ${endif}
    ;Delete the password file
    ${if} "$Pass1_text" != ""
      ${If} ${FileExists} "$tempFileName"
        Delete "$tempFileName"
      ${EndIf}
    ${EndIf}
  ${endif}
  ; Create data dir end
  ${if} $isDataDirExist == 0
    ${if} $checkNoLocal_state == ${BST_CHECKED}
      !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#listen_addresses = 'localhost'" "listen_addresses = '*'"
	  ; Add line to pg_hba.conf
	  FileOpen $4 "$DATA_DIR\pg_hba.conf" a
	  FileSeek $4 0 END
	  FileWrite $4 "host$\tall$\tall$\t0.0.0.0/0$\tmd5$\r$\n"
	  FileClose $4
	  ; Add postgres to Windows Firewall exceptions
	  nsisFirewall::AddAuthorizedApplication "$INSTDIR\bin\postgres.exe" "PostgresPro server"
	  pop $0
    ${else}
      !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#listen_addresses = 'localhost'" "listen_addresses = 'localhost'"
    ${EndIf}
    !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#port = 5432" "port = $TextPort_text"
    !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#log_destination = 'stderr'" "log_destination = 'stderr'"
    !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#logging_collector = off" "logging_collector = on"
    !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#log_line_prefix = ''" "log_line_prefix = '%t '"

    ${if} $needOptimiztion == "1"
      ${if} $shared_buffers != ""
        ${ConfigWrite} "$DATA_DIR\postgresql.conf" "shared_buffers = " "$shared_buffers$\t$\t# min 128kB" $R0
      ${endif}
      ${if} $work_mem != ""
        ;#work_mem = 4MB				# min 64kB
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#work_mem = 4MB" "work_mem = $work_mem"
      ${endif}
    ${endif}
  ${EndIf}
  ;# Add line to pg_hba.conf
  Call WriteInstallOptions
  DetailPrint "Service $ServiceID_text registration ..."
  nsExec::ExecToStack /TIMEOUT=60000 '"$INSTDIR\bin\pg_ctl.exe" register -N "$ServiceID_text" -U "$ServiceAccount_text" -D "$DATA_DIR" -w'
  Pop $0 # return value/error/timeout
  Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}

  ${if} $0 != 0
    DetailPrint "pg_ctl.exe register return $0"
    DetailPrint "Output: $1"
    Sleep 5000
  ${else}
    DetailPrint "Service registration OK"
  ${endif}

  ;Write the DisplayName manually
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\$ServiceID_text" "DisplayName" "$ServiceID_text - PostgreSQL Server ${PG_MAJOR_VERSION}"
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\$ServiceID_text" "Description" "Provides relational database storage."

  AccessControl::GrantOnFile "$DATA_DIR" "$ServiceAccount_text" "FullAccess"
  Pop $0 ;"ok" or "error" + error details
  AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUser" "FullAccess" ;GenericWrite
  Pop $0 ;"ok" or "error" + error details
  AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUserShort" "FullAccess" ;GenericWrite
  Pop $0 ;"ok" or "error" + error details

  AccessControl::GrantOnFile "$INSTDIR" "$ServiceAccount_text" "GenericRead + GenericExecute"
  Pop $0 ;"ok" or "error" + error details

  AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$ServiceAccount_text" "FullAccess"
  Pop $0 ;"ok" or "error" + error details
  AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$loggedInUser" "FullAccess" ;"GenericRead + GenericExecute" ;GenericWrite
  Pop $0 ;"ok" or "error" + error details
  AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$loggedInUserShort" "FullAccess" ;GenericWrite
  Pop $0 ;"ok" or "error" + error details

  AccessControl::GrantOnFile "$INSTDIR\scripts" "$loggedInUser" "FullAccess"
  Pop $0 ;"ok" or "error" + error details
  ${if} $isDataDirExist == 1
  ; there exist data directory. We need to stop service,
  ; run pgpro-upgrade script and
  DetailPrint "Performing catalog upgradeon $DATA_DIR"	 
	 nsExec::ExecToStack '"$INSTDIR/scripts/pgpro_upgrade" "$DATA_DIR"'
    pop $0
   Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
	DetailPrint "$1"
  ${endif}

  DetailPrint "Start server service..."
  Sleep 1000

  nsExec::ExecToStack /TIMEOUT=60000 'sc start "$ServiceID_text"'
  Sleep 5000
  Pop $0 # return value/error/timeout
  Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}

  ${if} $0 != 0
    DetailPrint "Start service return $0"
    DetailPrint "Output: $1"
    Sleep 5000
  ${else}
    DetailPrint "Start service OK"
  ${endif}

  ${if} $isDataDirExist == 0
    ;send password to Environment Variable PGPASSWORD
    ${if} "$Pass1_text" != ""
      StrCpy $R0 $Pass1_text
      System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PGPASSWORD", R0).r0'
    ${endif}

    DetailPrint "Create adminpack ..."
    Sleep 5000
    nsExec::ExecToStack /TIMEOUT=60000 '"$INSTDIR\bin\psql.exe" -p $TextPort_text -U "$UserName_text" -c "CREATE EXTENSION adminpack;" postgres'
    pop $0
    Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
    ${if} $0 != 0
      DetailPrint "Create adminpack return $0"
      DetailPrint "Output: $1"
      ;MessageBox MB_OK "Create adminpack error: $1"
      MessageBox MB_OK|MB_ICONSTOP "$(MESS_ERROR_SERVER)"
    ${else}
      DetailPrint "Create adminpack OK"
    ${endif}
    ${if} "$Pass1_text" != ""
      StrCpy $R0 ""
      System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PGPASSWORD", R0).r0'
    ${endif}
  ${endif}
  ${if} $isEnvVar == ${BST_CHECKED}
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGDATA" "$DATA_DIR"
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGDATABASE" "postgres"
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGUSER" "$UserName_text"
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGPORT" "$TextPort_text"
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGLOCALEDIR" "$INSTDIR\share\locale\"
	AddToPath::AddToPath "$INSTDIR\bin"
  ${endif}
SectionEnd

;Uninstaller Section
Section "Uninstall"
  Call un.ChecExistInstall
  DetailPrint "Stop the server ..."
  ${if} $DATA_DIR != ""
    nsExec::Exec '"$INSTDIR\bin\pg_ctl.exe" stop -D "$DATA_DIR" -m fast -w'
    pop $0
    DetailPrint "pg_ctl.exe stop return $0"
  ${endif}
  ;unregister
  DetailPrint "Unregister the service ..."
  ${if} $ServiceID_text != ""
    nsExec::Exec '"$INSTDIR\bin\pg_ctl.exe" unregister -N "$ServiceID_text"'
    pop $0
    DetailPrint "pg_ctl.exe unregister return $0"
  ${endif}

  Delete "$INSTDIR\Uninstall.exe"
  Delete "$INSTDIR\license.txt"
  Delete "$INSTDIR\3rd_party_licenses.txt"

  RMDir /r "$INSTDIR\bin"
  RMDir /r "$INSTDIR\doc"
  RMDir /r "$INSTDIR\include"
  RMDir /r "$INSTDIR\lib"
  RMDir /r "$INSTDIR\share"
  RMDir /r "$INSTDIR\symbols"
  RMDir /r "$INSTDIR\StackBuilder"
  RMDir /r "$INSTDIR\scripts"
  RMDir "$INSTDIR"

  Call un.DeleteInstallOptions
  SetShellVarContext all

  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder

  ${if} $StartMenuFolder != ""
    Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\SQL Shell (psql).lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\pgAdmin3.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\Reload Configuration.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\Restart Server.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\Stop Server.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\Start Server.lnk"
    RMDir /r "$SMPROGRAMS\$StartMenuFolder\Documentation"
    RMDir "$SMPROGRAMS\$StartMenuFolder"
  ${endif}
  ${if} "${PG_DEF_BRANDING}" != ""
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}"
  ${endif}

  DeleteRegKey /ifempty HKLM "${PRODUCT_DIR_REGKEY}"
  ;${EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\bin"
  ; Remove install dir from PATH
  ;Push "$INSTDIR\bin"
  ;Call un.RemoveFromPath
  Pop $0 ; or "error"

  IfSilent 0 +2
    Goto done

  MessageBox MB_OK|MB_ICONINFORMATION "$(UNINSTALL_END)$DATA_DIR" ;debug

  done:
SectionEnd

;--------------------------------
;Descriptions
;Language strings
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${SecMS} $(DESC_SecMS)
!insertmacro MUI_DESCRIPTION_TEXT ${Sec1} $(DESC_Sec1)
!insertmacro MUI_DESCRIPTION_TEXT ${SecService} $(DESC_SecService)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;check existing install
;if exist then get install options to vars
Function ChecExistInstall
  StrCpy $Locale_text "$(DEF_LOCALE_NAME)"
  ReadRegStr $1 HKLM "${PG_REG_KEY}" "Version"

  ${if} $1 != "" ;we have install
    ;get exist options
    ReadRegStr $PG_OLD_VERSION HKLM "${PG_REG_KEY}" "Version"
    ReadRegStr $INSTDIR HKLM "${PG_REG_KEY}" "Base Directory"
    ReadRegStr $DATA_DIR HKLM "${PG_REG_KEY}" "Data Directory"

    ReadRegStr $ServiceAccount_text HKLM "${PG_REG_KEY}" "Service Account"
    ReadRegStr $ServiceID_text HKLM "${PG_REG_KEY}" "Service ID"
    ReadRegStr $UserName_text HKLM "${PG_REG_KEY}" "Super User"
    ReadRegStr $Branding_text HKLM "${PG_REG_KEY}" "Branding"

    StrCpy $PG_OLD_DIR $INSTDIR
  ${endif}

  ReadRegDWORD $1 HKLM "${PG_REG_SERVICE_KEY}" "Port"
  ${if} $1 != "" ;we have install
    StrCpy $TextPort_text $1
  ${else}
    ;calculate free num port - use EnumRegKey
    StrCpy $0 0
    StrCpy $2 5432

    ;SetRegView 32
    SetRegView 64
    ${While} 1 = 1
      EnumRegKey $1 HKLM "SOFTWARE\PostgreSQL\Services" $0
      ${if} $1 == ""
        ${ExitWhile}
      ${endif}
      ReadRegDWORD $3 HKLM "SOFTWARE\PostgreSQL\Services\$1" "Port"
      ${if} $3 >= $2
        IntOp $2 $3 + 1
      ${endif}
      IntOp $0 $0 + 1
    ${EndWhile}
    SetRegView 32
    StrCpy $0 0
    ${While} 1 = 1
      EnumRegKey $1 HKLM "SOFTWARE\PostgreSQL\Services" $0
      ${if} $1 == ""
        ${ExitWhile}
      ${endif}
      ReadRegDWORD $3 HKLM "SOFTWARE\PostgreSQL\Services\$1" "Port"
      ${if} $3 >= $2
        IntOp $2 $3 + 1
      ${endif}

      IntOp $0 $0 + 1
    ${EndWhile}

    ${if} $IsTextPortInIni != 1 ;port can be send in ini file
      StrCpy $TextPort_text $2
    ${endif}
  ${endif}

  ReadRegStr $1 HKLM "${PG_REG_SERVICE_KEY}" "Locale"
  ${if} $1 != ""
    StrCpy $Locale_text $1
  ${endif}
FunctionEnd

;write to PG_REG_KEY - "SOFTWARE\PostgreSQL\Installations\postgresql-9.5"
Function WriteInstallOptions
  ;get exist options
  WriteRegStr HKLM "${PG_REG_KEY}" "Version" "${PG_DEF_VERSION}"
  WriteRegStr HKLM "${PG_REG_KEY}" "Base Directory" $INSTDIR
  WriteRegStr HKLM "${PG_REG_KEY}" "Data Directory" $DATA_DIR
  WriteRegStr HKLM "${PG_REG_KEY}" "Service Account" $ServiceAccount_text
  WriteRegStr HKLM "${PG_REG_KEY}" "Service ID" $ServiceID_text
  WriteRegStr HKLM "${PG_REG_KEY}" "Super User" $UserName_text
  WriteRegStr HKLM "${PG_REG_KEY}" "Branding" $Branding_text
  WriteRegDWORD HKLM "${PG_REG_SERVICE_KEY}" "Port" $TextPort_text
  ${if} "$Locale_text" != "$(DEF_LOCALE_NAME)"
    WriteRegStr HKLM "${PG_REG_SERVICE_KEY}" "Locale" $Locale_text
  ${endif}
  ;for compatibility
  WriteRegStr HKLM "${PG_REG_SERVICE_KEY}" "Data Directory" $DATA_DIR
  WriteRegStr HKLM "${PG_REG_SERVICE_KEY}" "Database Superuser" $UserName_text
  WriteRegStr HKLM "${PG_REG_SERVICE_KEY}" "Display Name" $Branding_text
  WriteRegStr HKLM "${PG_REG_SERVICE_KEY}" "Product Code" $ServiceID_text
  WriteRegStr HKLM "${PG_REG_SERVICE_KEY}" "Service Account" $ServiceAccount_text
FunctionEnd

Function un.DeleteInstallOptions
  ;delete exist options
  DeleteRegValue HKLM "${PG_REG_KEY}" "Version"
  DeleteRegValue HKLM "${PG_REG_KEY}" "Base Directory"
  DeleteRegValue HKLM "${PG_REG_KEY}" "Data Directory"
  DeleteRegValue HKLM "${PG_REG_KEY}" "Service Account"
  DeleteRegValue HKLM "${PG_REG_KEY}" "Service ID"
  DeleteRegValue HKLM "${PG_REG_KEY}" "Super User"
  DeleteRegValue HKLM "${PG_REG_KEY}" "Branding"
  DeleteRegValue HKLM "${PG_REG_SERVICE_KEY}" "Port"
  DeleteRegValue HKLM "${PG_REG_SERVICE_KEY}" "Locale"
  ;for compatibility
  DeleteRegValue HKLM "${PG_REG_SERVICE_KEY}" "Data Directory"
  DeleteRegValue HKLM "${PG_REG_SERVICE_KEY}" "Database Superuser"
  DeleteRegValue HKLM "${PG_REG_SERVICE_KEY}" "Display Name"
  DeleteRegValue HKLM "${PG_REG_SERVICE_KEY}" "Product Code"
  DeleteRegValue HKLM "${PG_REG_SERVICE_KEY}" "Service Account"
  DeleteRegKey /ifempty HKLM "${PG_REG_KEY}"
  DeleteRegKey /ifempty HKLM "${PG_REG_SERVICE_KEY}"
FunctionEnd

Function un.ChecExistInstall
  ReadRegStr $1 HKLM "${PG_REG_KEY}" "Version"
  ${if} $1 != "" ;we have install
    ;get exist options
    ReadRegStr $PG_OLD_VERSION HKLM "${PG_REG_KEY}" "Version"
    ReadRegStr $0 HKLM "${PG_REG_KEY}" "Base Directory"
    ${if} $0! = ""
      StrCpy $INSTDIR $0
    ${endif}
    ReadRegStr $DATA_DIR HKLM "${PG_REG_KEY}" "Data Directory"

    ReadRegStr $ServiceAccount_text HKLM "${PG_REG_KEY}" "Service Account"
    ReadRegStr $ServiceID_text HKLM "${PG_REG_KEY}" "Service ID"
    ReadRegStr $UserName_text HKLM "${PG_REG_KEY}" "Super User"
    ReadRegStr $Branding_text HKLM "${PG_REG_KEY}" "Branding"
  ${endif}
FunctionEnd

Function getServerDataFromDlg
  ${NSD_GetText} $Pass1 $Pass1_text
  ${NSD_GetText} $Pass2 $Pass2_text

  ${NSD_GetText} $UserName $UserName_text
  ${NSD_GetState} $checkNoLocal $checkNoLocal_state
  ${NSD_GetText} $TextPort $TextPort_text

  ${NSD_GetText} $Locale $Locale_text

  ${NSD_GetState} $checkBoxEnvVar $isEnvVar
FunctionEnd

Function nsDialogsServerPageLeave
  Call getServerDataFromDlg
  ${If} $Pass1_text != $Pass2_text
    MessageBox MB_OK|MB_ICONINFORMATION "$(MESS_PASS1)"
    Abort
  ${EndIf}

  ${If} $Pass1_text == ""
    MessageBox MB_YESNO|MB_ICONQUESTION  "$(MESS_PASS2)" IDYES doit1 IDNO noyet1
    noyet1:
    Abort
    doit1:
  ${else}
    push "$Pass1_text"
    Call CheckForAscii
    pop $0
    ${if} $0 != ""
      MessageBox MB_YESNO|MB_ICONQUESTION  "$(MESS_PASS3)" IDYES doit2 IDNO noyet2
      noyet2:
      Abort
      doit2:
    ${endif}
  ${EndIf}
FunctionEnd

;say that PG is exist
Function nsDialogServerExist
  ${Unless} ${SectionIsSelected} ${sec1}
    Abort
  ${EndUnless}
  ${if} $PG_OLD_DIR == "" ;no PG install
    Abort
  ${endif}
  !insertmacro MUI_HEADER_TEXT $(SERVER_EXIST_TITLE) ""

  nsDialogs::Create 1018
  Pop $Dialog
  ${If} $Dialog == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 0 100% 100% "$(SERVER_EXIST_TEXT1) $PG_OLD_DIR $(SERVER_EXIST_TEXT2)"
  Pop $Label
  nsDialogs::Show
FunctionEnd

Function ChecExistDataDir
  ${Unless} ${SectionIsSelected} ${sec1}
    Abort
  ${EndUnless}
  ${If} ${FileExists} "$DATA_DIR\*.*"
    StrCpy $isDataDirExist 1
  ${ElseIf} ${FileExists} "$DATA_DIR"
    StrCpy $isDataDirExist -1
  ${Else}
    StrCpy $isDataDirExist 0
    Abort
  ${EndIf}

  ${If} ${FileExists} "$DATA_DIR\postgresql.conf"
    ClearErrors
    ${ConfigRead} "$DATA_DIR\postgresql.conf" "port" $R0
    ${if} ${Errors}
      StrCpy $isDataDirExist 0
      Abort
    ${EndIf}
    ${StrRep} '$0' '$R0' '=' ''
    ${StrRep} '$1' '$0' ' ' ''

    StrCpy $0 $1 5

    ${StrRep} '$1' '$0' '$\t' ''
    ${StrRep} '$0' '$1' '#' ''
    StrCpy $TextPort_text $0
  ${Else}
    StrCpy $isDataDirExist 0
    Abort
  ${EndIf}

  ${if} $PG_OLD_DIR != "" ;exist PG install
    Abort
  ${endif}

  !insertmacro MUI_HEADER_TEXT $(DATADIR_EXIST_TITLE) ""
  nsDialogs::Create 1018
  Pop $Dialog
  ${If} $Dialog == error
    Abort
  ${EndIf}
  ${if} $isDataDirExist == 1
    ${NSD_CreateLabel} 0 0 100% 100% "$(DATADIR_EXIST_TEXT1)"
  ${else}
    ${NSD_CreateLabel} 0 0 100% 100% "$(DATADIR_EXIST_ERROR1)"
  ${endif}
  Pop $Label
  nsDialogs::Show
FunctionEnd

Function nsDialogServer
  ${Unless} ${SectionIsSelected} ${sec1}
    Abort
  ${EndUnless}
  ${if} $isDataDirExist != 0 ;exist PG data dir
    Abort
  ${endif}
  !insertmacro MUI_HEADER_TEXT $(SERVER_SET_TITLE) $(SERVER_SET_SUBTITLE)
  nsDialogs::Create 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 2u 60u 12u "$(DLG_PORT)"
  Pop $Label

  ${NSD_CreateText} 62u 0 100u 12u "$TextPort_text"
  Pop $TextPort

  ${NSD_CreateLabel} 0 16u 60u 12u "$(DLG_ADR1)"
  Pop $Label2

  ${NSD_CreateCheckBox} 62u 15u 100% 12u "$(DLG_ADR2)"

  Pop $checkNoLocal
  ${NSD_SetState} $checkNoLocal $checkNoLocal_state

  ${NSD_CreateLabel} 0 32u 60u 12u "$(DLG_LOCALE)"
  Pop $Label2

  ${NSD_CreateDropList} 62u 30u 100u 12u ""
  Pop $Locale

  ${NSD_CB_AddString} $Locale "$(DEF_LOCALE_NAME)"

  ${NSD_CB_AddString} $Locale "Afrikaans, South Africa"
  ${NSD_CB_AddString} $Locale "Albanian, Albania"
  ${NSD_CB_AddString} $Locale "Azeri (Cyrillic), Azerbaijan"
  ${NSD_CB_AddString} $Locale "Azeri (Latin), Azerbaijan"
  ${NSD_CB_AddString} $Locale "Basque, Spain"
  ${NSD_CB_AddString} $Locale "Belarusian, Belarus"
  ${NSD_CB_AddString} $Locale "Bosnian, Bosnia and Herzegovina"
  ${NSD_CB_AddString} $Locale "Bosnian (Cyrillic), Bosnia and Herzegovina"
  ${NSD_CB_AddString} $Locale "Bulgarian, Bulgaria"
  ${NSD_CB_AddString} $Locale "Catalan, Spain"
  ${NSD_CB_AddString} $Locale "Croatian, Bosnia and Herzegovina"
  ${NSD_CB_AddString} $Locale "Croatian, Croatia"
  ${NSD_CB_AddString} $Locale "Czech, Czech Republic"
  ${NSD_CB_AddString} $Locale "Danish, Denmark"
  ${NSD_CB_AddString} $Locale "Dutch, Belgium"
  ${NSD_CB_AddString} $Locale "Dutch, Netherlands"
  ${NSD_CB_AddString} $Locale "English, Australia"
  ${NSD_CB_AddString} $Locale "English, Belize"
  ${NSD_CB_AddString} $Locale "English, Canada"
  ${NSD_CB_AddString} $Locale "English, Caribbean"
  ${NSD_CB_AddString} $Locale "English, Ireland"
  ${NSD_CB_AddString} $Locale "English, Jamaica"
  ${NSD_CB_AddString} $Locale "English, New Zealand"
  ${NSD_CB_AddString} $Locale "English, Republic of the Philippines"
  ${NSD_CB_AddString} $Locale "English, South Africa"
  ${NSD_CB_AddString} $Locale "English, Trinidad and Tobago"
  ${NSD_CB_AddString} $Locale "English, United Kingdom"
  ${NSD_CB_AddString} $Locale "English, United States"
  ${NSD_CB_AddString} $Locale "English, Zimbabwe"
  ${NSD_CB_AddString} $Locale "Estonian, Estonia"
  ${NSD_CB_AddString} $Locale "FYRO Macedonian, Former Yugoslav Republic of Macedonia"
  ${NSD_CB_AddString} $Locale "Faroese, Faroe Islands"
  ${NSD_CB_AddString} $Locale "Filipino, Philippines"
  ${NSD_CB_AddString} $Locale "Finnish, Finland"
  ${NSD_CB_AddString} $Locale "French, Belgium"
  ${NSD_CB_AddString} $Locale "French, Canada"
  ${NSD_CB_AddString} $Locale "French, France"
  ${NSD_CB_AddString} $Locale "French, Luxembourg"
  ${NSD_CB_AddString} $Locale "French, Principality of Monaco"
  ${NSD_CB_AddString} $Locale "French, Switzerland"
  ${NSD_CB_AddString} $Locale "Frisian, Netherlands"
  ${NSD_CB_AddString} $Locale "Galician, Spain"
  ${NSD_CB_AddString} $Locale "German, Austria"
  ${NSD_CB_AddString} $Locale "German, Germany"
  ${NSD_CB_AddString} $Locale "German, Liechtenstein"
  ${NSD_CB_AddString} $Locale "German, Luxembourg"
  ${NSD_CB_AddString} $Locale "German, Switzerland"
  ${NSD_CB_AddString} $Locale "Greek, Greece"
  ${NSD_CB_AddString} $Locale "Hungarian, Hungary"
  ${NSD_CB_AddString} $Locale "Icelandic, Iceland"
  ${NSD_CB_AddString} $Locale "Indonesian, Indonesia"
  ${NSD_CB_AddString} $Locale "Inuktitut (Latin), Canada"
  ${NSD_CB_AddString} $Locale "Irish, Ireland"
  ${NSD_CB_AddString} $Locale "Italian, Italy"
  ${NSD_CB_AddString} $Locale "Italian, Switzerland"
  ${NSD_CB_AddString} $Locale "Kazakh, Kazakhstan"
  ${NSD_CB_AddString} $Locale "Kyrgyz, Kyrgyzstan"
  ${NSD_CB_AddString} $Locale "Latvian, Latvia"
  ${NSD_CB_AddString} $Locale "Lithuanian, Lithuania"
  ${NSD_CB_AddString} $Locale "Luxembourgish, Luxembourg"
  ${NSD_CB_AddString} $Locale "Malay, Brunei Darussalam"
  ${NSD_CB_AddString} $Locale "Malay, Malaysia"
  ${NSD_CB_AddString} $Locale "Maltese, Malta"
  ${NSD_CB_AddString} $Locale "Maori, New Zealand"
  ${NSD_CB_AddString} $Locale "Mapudungun, Chile"
  ${NSD_CB_AddString} $Locale "Mohawk, Canada"
  ${NSD_CB_AddString} $Locale "Mongolian, Mongolia"
  ${NSD_CB_AddString} $Locale "Northern Sotho, South Africa"
  ${NSD_CB_AddString} $Locale "Norwegian (Bokmal), Norway"
  ${NSD_CB_AddString} $Locale "Norwegian (Nynorsk), Norway"
  ${NSD_CB_AddString} $Locale "Polish, Poland"
  ${NSD_CB_AddString} $Locale "Portuguese, Brazil"
  ${NSD_CB_AddString} $Locale "Portuguese, Portugal"
  ${NSD_CB_AddString} $Locale "Quechua, Bolivia"
  ${NSD_CB_AddString} $Locale "Quechua, Ecuador"
  ${NSD_CB_AddString} $Locale "Quechua, Peru"
  ${NSD_CB_AddString} $Locale "Romanian, Romania"
  ${NSD_CB_AddString} $Locale "Romansh, Switzerland"
  ${NSD_CB_AddString} $Locale "Russian, Russia"
  ${NSD_CB_AddString} $Locale "Sami (Inari), Finland"
  ${NSD_CB_AddString} $Locale "Sami (Lule), Norway"
  ${NSD_CB_AddString} $Locale "Sami (Lule), Sweden"
  ${NSD_CB_AddString} $Locale "Sami (Northern), Finland"
  ${NSD_CB_AddString} $Locale "Sami (Northern), Norway"
  ${NSD_CB_AddString} $Locale "Sami (Northern), Sweden"
  ${NSD_CB_AddString} $Locale "Sami (Skolt), Finland"
  ${NSD_CB_AddString} $Locale "Sami (Southern), Norway"
  ${NSD_CB_AddString} $Locale "Sami (Southern), Sweden"
  ${NSD_CB_AddString} $Locale "Serbian (Cyrillic), Bosnia and Herzegovina"
  ${NSD_CB_AddString} $Locale "Serbian (Cyrillic), Serbia and Montenegro"
  ${NSD_CB_AddString} $Locale "Serbian (Latin), Bosnia and Herzegovina"
  ${NSD_CB_AddString} $Locale "Serbian (Latin), Serbia and Montenegro"
  ${NSD_CB_AddString} $Locale "Slovak, Slovakia"
  ${NSD_CB_AddString} $Locale "Slovenian, Slovenia"
  ${NSD_CB_AddString} $Locale "Spanish, Argentina"
  ${NSD_CB_AddString} $Locale "Spanish, Bolivia"
  ${NSD_CB_AddString} $Locale "Spanish, Chile"
  ${NSD_CB_AddString} $Locale "Spanish, Colombia"
  ${NSD_CB_AddString} $Locale "Spanish, Costa Rica"
  ${NSD_CB_AddString} $Locale "Spanish, Dominican Republic"
  ${NSD_CB_AddString} $Locale "Spanish, Ecuador"
  ${NSD_CB_AddString} $Locale "Spanish, El Salvador"
  ${NSD_CB_AddString} $Locale "Spanish, Guatemala"
  ${NSD_CB_AddString} $Locale "Spanish, Honduras"
  ${NSD_CB_AddString} $Locale "Spanish, Mexico"
  ${NSD_CB_AddString} $Locale "Spanish, Nicaragua"
  ${NSD_CB_AddString} $Locale "Spanish, Panama"
  ${NSD_CB_AddString} $Locale "Spanish, Paraguay"
  ${NSD_CB_AddString} $Locale "Spanish, Peru"
  ${NSD_CB_AddString} $Locale "Spanish, Puerto Rico"
  ${NSD_CB_AddString} $Locale "Spanish, Spain"
  ${NSD_CB_AddString} $Locale "Spanish, Spain"
  ${NSD_CB_AddString} $Locale "Spanish, Uruguay"
  ${NSD_CB_AddString} $Locale "Spanish, Venezuela"
  ${NSD_CB_AddString} $Locale "Swahili, Kenya"
  ${NSD_CB_AddString} $Locale "Swedish, Finland"
  ${NSD_CB_AddString} $Locale "Swedish, Sweden"
  ${NSD_CB_AddString} $Locale "Tatar, Russia"
  ${NSD_CB_AddString} $Locale "Tswana, South Africa"
  ${NSD_CB_AddString} $Locale "Turkish, Turkey"
  ${NSD_CB_AddString} $Locale "Ukrainian, Ukraine"
  ${NSD_CB_AddString} $Locale "Uzbek (Cyrillic), Uzbekistan"
  ${NSD_CB_AddString} $Locale "Uzbek (Latin), Uzbekistan"
  ${NSD_CB_AddString} $Locale "Welsh, United Kingdom"
  ${NSD_CB_AddString} $Locale "Xhosa, South Africa"
  ${NSD_CB_AddString} $Locale "Zulu, South Africa"

  ${NSD_CB_SelectString} $Locale $Locale_text

  ${NSD_CreateLabel} 0 54u 60u 24u "$(DLG_SUPERUSER)"
  Pop $Label2

  ${NSD_CreateText} 62u 57u 100u 12u "$UserName_text"
  Pop $UserName

  ${NSD_CreateLabel} 0 74u 60u 12u "$(DLG_PASS1)"
  Pop $Label2

  ${NSD_CreatePassword} 62u 72u 100u 12u $Pass1_text
  Pop $Pass1

  ${NSD_CreateLabel} 0 90u 60u 12u "$(DLG_PASS2)"
  Pop $Label2

  ${NSD_CreatePassword} 62u 88u 100u 12u $Pass2_text
  Pop $Pass2

  ;env vars
  ${NSD_CreateCheckBox} 62u 120u 100% 12u "$(DLG_ENVVAR)"
  Pop $checkBoxEnvVar
  ${NSD_SetState} $checkBoxEnvVar $isEnvVar

  GetFunctionAddress $0 getServerDataFromDlg
  nsDialogs::OnBack $0

  nsDialogs::Show
FunctionEnd

Function getFreeMemory
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
  Pop $0 # HWND
  Push $4
FunctionEnd

Function makeOptimization
  Call getFreeMemory
  Pop $AllMem ;get all mem
  StrCpy $FreeMem $5 ;- free mem

  ;intop don't work on > 2gb
  ;IntOp $FreeMem $FreeMem / 1048576 ;in MB
  ;IntOp $AllMem $AllMem / 1048576 ;in MB
  Math::Script "R0 = $AllMem / 1048576"
  StrCpy $AllMem $R0

  Math::Script "R0 = $FreeMem / 1048576"
  StrCpy $FreeMem $R0

  ;2 options set: shared_buffers and work_mem
  ;1024MB = 131072 = 1073741824
  ;768MB = 98304 = 805306368
  ;512MB = 65536 = 536870912
  ;256MB = 32768 = 268435456

  ${if} $AllMem > 4090 ;>4gb
    StrCpy $work_mem "128MB"
    StrCpy $shared_buffers "512MB"
    return
  ${endif}
  ${if} $AllMem > 2040 ;>2gb
    StrCpy $work_mem "64MB"
    StrCpy $shared_buffers "256MB"
    return
  ${endif}
  ${if} $AllMem >  1020 ;1gb
    StrCpy $work_mem "32MB"
    StrCpy $shared_buffers "128MB"
  ${endif}
FunctionEnd

Function nsDialogOptimization
  ${Unless} ${SectionIsSelected} ${sec1}
    Abort
  ${EndUnless}
  ${if} $isDataDirExist != 0 ;exist PG data dir
    Abort
  ${endif}

  Call makeOptimization
  ${if} $shared_buffers == "" ;No optimization
    Abort
  ${endif}

  nsDialogs::Create 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 0 100% 50u "$(DLG_OPT1)"
  Pop $Label

  ${NSD_CreateRadioButton} 0 50u 200u 24U "$(DLG_OPT2)"
  Pop $rButton2

  ${NSD_CreateRadioButton} 0 70u 200u 24U "$(DLG_OPT3)"
  Pop $rButton1

  ${if} $needOptimiztion == "1"
    ${NSD_SetState} $rButton2  ${BST_CHECKED}
  ${else}
    ${NSD_SetState} $rButton1  ${BST_CHECKED}
  ${endif}

  GetFunctionAddress $0 nsDialogsOptimizationPageLeave
  nsDialogs::OnBack $0

  nsDialogs::Show
FunctionEnd

Function nsDialogsOptimizationPageLeave
  ${NSD_GetState} $rButton2 $0
  ${if} $0 == ${BST_CHECKED}
    StrCpy  $needOptimiztion "1"
  ${else}
    StrCpy $needOptimiztion "0"
  ${endif}
FunctionEnd

Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY ;select language
  StrCpy $PG_OLD_DIR ""
  StrCpy $DATA_DIR "$INSTDIR\data"

  StrCpy $TextPort_text "${PG_DEF_PORT}"
  StrCpy $UserName_text "${PG_DEF_SUPERUSER}"

  StrCpy $ServiceAccount_text "${PG_DEF_SERVICEACCOUNT}"
  StrCpy $ServiceID_text "${PG_DEF_SERVICEID}"
  StrCpy $Version_text "${PG_DEF_VERSION}"
  StrCpy $Branding_text "${PG_DEF_BRANDING}"

  StrCpy $checkNoLocal_state ${BST_CHECKED}
  StrCpy $isEnvVar ${BST_UNCHECKED} ;${BST_CHECKED}

  StrCpy $Coding_text "UTF8" ;"UTF-8"

  UserMgr::GetCurrentDomain
  Pop $0
  UserMgr::GetCurrentUserName
  Pop $1
  StrCpy $loggedInUser  "$0\$1"

  StrCpy $loggedInUserShort "$1"

  ;AccessControl::GetCurrentUserName
  ;Pop $0 ; or "error"
  ;MessageBox MB_OK "$0"
  StrCpy $needOptimiztion "1"

  StrCpy $isDataDirExist 0

  StrCpy $IsTextPortInIni 0
  ; Get options from ini file
  ${GetParameters} $R0
  ${GetOptions} $R0 /init= $0
  ${if} $0 == ""
    return
  ${endif}
  ;check for path
  ${GetParent} "$0" $5
  ${if} $5 == ""
    StrCpy $0 "$EXEDIR\$0"
  ${endif}
  ClearErrors

  ReadINIStr $1 $0 options installdir
  ${if} "$1" != ""
    StrCpy $INSTDIR "$1"
    StrCpy $DATA_DIR "$INSTDIR\data"
  ${endif}

  ReadINIStr $1 $0 options datadir
  ${if} "$1" != ""
    StrCpy $DATA_DIR "$1"
  ${endif}

  ReadINIStr $1 $0 options port
  ${if} "$1" != ""
    StrCpy $TextPort_text "$1"
    StrCpy $IsTextPortInIni 1
  ${endif}

  ReadINIStr $1 $0 options superuser
  ${if} "$1" != ""
    StrCpy $UserName_text "$1"
  ${endif}

  ReadINIStr $1 $0 options password
  ${if} "$1" != ""
    StrCpy $Pass1_text "$1"
    StrCpy $Pass2_text "$1"
  ${endif}

  ReadINIStr $1 $0 options noextconnections
  ${if} "$1" != ""
    StrCpy $checkNoLocal_state ""
  ${endif}

  ReadINIStr $1 $0 options coding
  ${if} "$1" != ""
    StrCpy $Coding_text "$1"
  ${endif}

  ReadINIStr $1 $0 options locale
  ${if} "$1" != ""
    StrCpy $Locale_text "$1"
  ${endif}

  ; Sections
  ReadINIStr $1 $0 options vcredist
  ${if} "$1" == "no"
    SectionGetFlags ${secMS} $3
    IntOp $3 $3 & ${SECTION_OFF}
    SectionSetFlags ${secMS} $3
  ${endif}

  ReadINIStr $1 $0 options service
  ${if} "$1" == "no"
    SectionGetFlags ${secService} $3
    IntOp $3 $3 & ${SECTION_OFF}
    SectionSetFlags ${secService} $3
  ${endif}
   ${if} "$1" == "yes"
    StrCpy $service "YES"
  ${endif}

   ReadINIStr $1 $0 options pgserver
  ${if} "$1" == "no"
    SectionGetFlags ${sec1} $3
    IntOp $3 $3 & ${SECTION_OFF}
    SectionSetFlags ${sec1} $3
  ${endif}

  ReadINIStr $1 $0 options envvar
  ${if} "$1" != ""
    StrCpy $isEnvVar $1
  ${endif}
FunctionEnd

Function func1
  ${if} $PG_OLD_DIR != "" ;exist PG install
    Abort
  ${endif}
  SectionGetFlags ${sec1} $2

  IntCmp $2 1 is5
  Abort
  is5:
FunctionEnd

Function dirPre
  ${Unless} ${SectionIsSelected} ${sec1}
    Abort
  ${EndUnless}
  ${if} $PG_OLD_DIR != "" ;exist PG install
    Abort
  ${endif}
FunctionEnd
