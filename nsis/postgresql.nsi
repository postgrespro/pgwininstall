
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
!include "Ports.nsh"
!include "x64.nsh"
!include "StrContains.nsh"
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

Var DATA_DIR      ; path to data
Var OLD_DATA_DIR  ; path to old data

Var TextPort_text
Var IsTextPortInIni
Var checkNoLocal_state
Var Locale_text
Var Coding_text
Var UserName_text
Var Pass1_text
Var Pass2_text

Var Chcp_text

Var ServiceAccount_text
Var ServiceID_text
Var Version_text
Var Branding_text

Var OldServiceAccount_text
Var OldServiceID_text
Var OldUserName_text
Var OldBranding_text

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
Var needOptimization
Var rButton1
Var rButton2

; set env variables
Var checkBoxEnvVar
Var isEnvVar

Var LogFile
Var effective_cache_size

Var checkBoxDataChecksums
Var isDataChecksums

Var checkBoxMoreOptions
Var isShowMoreOptions

Var servicePassword_text
Var servicePassword_editor

Var ServiceAccount_editor
Var ServiceID_editor

Var Collation_editor
Var Collation_text

Var currCommand

; Set 'install service' variable
;Var service


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

!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_WELCOME
; !insertmacro MUI_PAGE_LICENSE "License.txt"
!insertmacro MUI_PAGE_LICENSE $(myLicenseData)


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
Page custom nsDialogMore nsDialogsMorePageLeave

;Start Menu Folder Page Configuration
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${PG_DEF_BRANDING}"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${PRODUCT_DIR_REGKEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
!define MUI_PAGE_CUSTOMFUNCTION_PRE dirPre
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_TITLE_3LINES
!insertmacro MUI_UNPAGE_WELCOME
;!insertmacro MUI_UNPAGE_COMPONENTS
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages
!insertmacro MUI_LANGUAGE "English" ;first language is the default language
!insertmacro MUI_LANGUAGE "Russian"

!include translates.nsi

!ifndef myLicenseFile_ru
!define  myLicenseFile_ru "license.txt"
!endif
!ifndef myLicenseFile_en
!define  myLicenseFile_en "license.txt"
!endif



LicenseLangString myLicenseData ${LANG_RUSSIAN} ${myLicenseFile_ru}
LicenseLangString myLicenseData ${LANG_ENGLISH} ${myLicenseFile_en}
LicenseData $(myLicenseData)


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

SectionGroup /e $(PostgreSQLString) serverGroup



Section $(componentClient) secClient

  /*${If} ${FileExists} "$INSTDIR\*.*"
  ${orif} ${FileExists} "$INSTDIR"
    MessageBox MB_OK|MB_ICONINFORMATION 'Can not install clients components to this path! The installation was found on the path "$PG_OLD_DIR" '
    Return
  ${EndIf} */

  ;MessageBox MB_OK|MB_ICONINFORMATION "pg_old_dir: $PG_OLD_DIR"
  ;Call ChecExistInstall ;get port number for  psql
  var /GLOBAL isStopped
  StrCpy $isStopped 0
  

  ${if} $PG_OLD_DIR != "" ; exist PG install
    MessageBox MB_YESNO|MB_ICONQUESTION  "$(MESS_STOP_SERVER)" IDYES doitStop IDNO noyetStop
    noyetStop:
    Return
    doitStop:
    DetailPrint "Stop the server ..."
    ${if} $OLD_DATA_DIR != ""
      nsExec::Exec '"$PG_OLD_DIR\bin\pg_ctl.exe" stop -D "$OLD_DATA_DIR" -m fast -w'
      pop $0
      DetailPrint "pg_ctl.exe stop return $0"
      StrCpy $isStopped 1
    ${endif}
    ;unregister
  ${endif}



  !include allclient_list.nsi
  ;SetOutPath "$INSTDIR\bin"
  ;File /r ${PG_INS_SOURCE_DIR}\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\bin\*.*
  ;SetOutPath "$INSTDIR\doc"
  ;File /r ${PG_INS_SOURCE_DIR}\doc\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\include\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\lib\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\share\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\symbols\*.*

  ;File "License.txt"
  SetOutPath $INSTDIR
  ;File /nonfatal "/oname=$INSTDIR\License.txt"  ${myLicenseFile_ru}
  File ${myLicenseFile_ru}
  File ${myLicenseFile_en}

  File "3rd_party_licenses.txt"

  CreateDirectory "$INSTDIR\scripts"
  File  "/oname=$INSTDIR\scripts\pg-psql.ico" "pg-psql.ico"
  CreateDirectory "$INSTDIR\doc"
  File  "/oname=$INSTDIR\doc\pg-help.ico" "pg-help.ico"

  ;Store installation folder
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" $INSTDIR


  WriteUninstaller "$INSTDIR\Uninstall.exe"
  Call writeUnistallReg
  Call createRunPsql

  ;for all users
  SetShellVarContext all
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

  ;Create shortcuts
  ; create common shortcuts for client and server
  CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

  ${if} ${FileExists} "$INSTDIR\scripts\runpgsql.bat"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\SQL Shell (psql).lnk" "$INSTDIR\scripts\runpgsql.bat" "" "$INSTDIR\scripts\pg-psql.ico" "0" "" "" "PostgreSQL command line utility"
  ${else}
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\SQL Shell (psql).lnk" "$INSTDIR\bin\psql.exe" "-h localhost -U $UserName_text -d postgres -p $TextPort_text" "" "" "" "" "PostgreSQL command line utility"
  ${endif}


  ReadRegStr $0 HKCU "Console\SQL Shell (psql)" "FaceName"
  ${if} $0 == ""
    WriteRegStr HKCU "Console\SQL Shell (psql)" "FaceName" "Consolas"
    WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontWeight" "400"
    WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontSize" "917504"
    WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontFamily" "54"
  ${endif}


  CreateDirectory "$SMPROGRAMS\$StartMenuFolder\Documentation"

  !insertmacro CreateInternetShortcut \
    "$SMPROGRAMS\$StartMenuFolder\Documentation\${PRODUCT_NAME} documentation (EN)" \
    "$INSTDIR\doc\postgresql-en.chm" \
    "$INSTDIR\doc\pg-help.ico" "0"

  !insertmacro CreateInternetShortcut \
    "$SMPROGRAMS\$StartMenuFolder\Documentation\${PRODUCT_NAME} documentation (RU)" \
    "$INSTDIR\doc\postgresql-ru.chm" \
    "$INSTDIR\doc\pg-help.ico" "0"

  !insertmacro MUI_STARTMENU_WRITE_END

  ${if} $isStopped = 1
        ;SectionGetFlags ${sec1} $1
        ; start server
        call IsServerSection
        pop $0
        ${if} $0 == "0"
                DetailPrint "Start server ..."
                Sleep 1000
                nsExec::ExecToStack /TIMEOUT=60000 'sc start "$ServiceID_text"'
                Sleep 5000
                StrCpy $isStopped 0
        ${endif}

  ${endif}

SectionEnd

Section $(componentServer) sec1


  ${if} $PG_OLD_DIR != "" ; exist PG install
   ${if} $isStopped == 0
    MessageBox MB_YESNO|MB_ICONQUESTION  "$(MESS_STOP_SERVER)" IDYES doitStop IDNO noyetStop
    noyetStop:
    Return
    doitStop:
    DetailPrint "Stop the server ..."
    ${if} $OLD_DATA_DIR != ""
      nsExec::Exec '"$PG_OLD_DIR\bin\pg_ctl.exe" stop -D "$OLD_DATA_DIR" -m fast -w'
      pop $0
      DetailPrint "pg_ctl.exe stop return $0"
    ${endif}
   ${endif}
   
    ;unregister
    DetailPrint "Unregister the service ..."
    ${if} $OldServiceID_text != ""
     nsExec::Exec '"$PG_OLD_DIR\bin\pg_ctl.exe" unregister -N "$OldServiceID_text"'
      pop $0
      DetailPrint "pg_ctl.exe unregister return $0"
    ${endif}
  ${endif}

  !include allserver_list.nsi
  !include plperl_list.nsi
  !include plpython2_list.nsi

  ;SetOutPath "$INSTDIR"
  ;File /r ${PG_INS_SOURCE_DIR}\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\bin\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\doc\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\include\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\lib\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\share\*.*
  ;File /r ${PG_INS_SOURCE_DIR}\symbols\*.*

  ;File "License.txt"

  FileOpen $LogFile $INSTDIR\install.log w ;Opens a Empty File an fills it


  CreateDirectory "$INSTDIR\scripts"
  File  "/oname=$INSTDIR\scripts\pg-psql.ico" "pg-psql.ico"
  CreateDirectory "$INSTDIR\doc"
  File  "/oname=$INSTDIR\doc\pg-help.ico" "pg-help.ico"

  ;Store installation folder
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" $INSTDIR

  ;Create uninstaller
  FileWrite $LogFile "Create uninstaller$\r$\n"
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; write uninstall strings
  FileWrite $LogFile "Write to register\r$\n"

  Call writeUnistallReg

  /*
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
  */
  FileWrite $LogFile "Create BAT files$\r$\n"
  ClearErrors
  FileOpen $0 $INSTDIR\scripts\reload.bat w
  IfErrors creatBatErr
  FileWrite $0 'echo off$\r$\n"$INSTDIR\bin\pg_ctl.exe" reload -D "$DATA_DIR"$\r$\npause'
  FileClose $0
  creatBatErr:
  ClearErrors

  ;System::Call "kernel32::GetACP() i .r2"
  ;StrCpy $Codepage_text $2
  ;DetailPrint "Set codepage $Codepage_text"
/*
  ${If} ${AtLeastWin2008}
    StrCpy $Chcp_text "chcp 65001"
  ${Else}
    StrCpy $Chcp_text ""
  ${Endif}

  ${if} ${PRODUCT_NAME} == "PostgreSQL"
    StrCpy $Chcp_text ""

    DetailPrint "Language settings:"
    DetailPrint "LANG_RUSSIAN=${LANG_RUSSIAN}"
    DetailPrint "LANG_ENGLISH=${LANG_ENGLISH}"
    DetailPrint "LANGUAGE=$LANGUAGE"

    ${if} $LANGUAGE == ${LANG_RUSSIAN}
      StrCpy $Chcp_text "chcp 1251"
    ${endif}
  ${endif}
  
  FileOpen $0 $INSTDIR\scripts\runpgsql.bat w
  IfErrors creatBatErr2
  FileWrite $0 '@echo off$\r$\n$Chcp_text$\r$\nPATH $INSTDIR\bin;%PATH%$\r$\nif not exist "%APPDATA%\postgresql" md "%APPDATA%\postgresql"$\r$\npsql.exe -h localhost -U "$UserName_text" -d postgres -p $TextPort_text $\r$\npause'
  FileClose $0

  creatBatErr2:
*/
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
  FileWrite $0 '@echo off$\r$\nif "%PGDATA%"=="" set PGDATA=%~1$\r$\nif "%PGDATA%"=="" set PGDATA=$DATA_DIR$\r$\nPATH $INSTDIR\bin;%PATH%$\r$\nrem if exist "$INSTDIR\bin\pgpro_upgrade" sh.exe "$INSTDIR\bin\pgpro_upgrade"$\r$\n'
  FileClose $0

  creatBatErr6:
  ;for all users
  SetShellVarContext all
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

  FileWrite $LogFile "Create shortcuts$\r$\n"

  ;Create shortcuts
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
  
  !insertmacro MUI_STARTMENU_WRITE_END
  ; Create data dir begin
  FileWrite $LogFile "Create data dir begin$\r$\n"

  ${if} $isDataDirExist == 0
    CreateDirectory "$DATA_DIR"
    ;AccessControl::GrantOnFile "$DATA_DIR" "(BU)" "FullAccess" ;GenericWrite
    ;Pop $0 ;"ok" or "error" + error details

    FileWrite $LogFile "GRANT Access $\r$\n"

    DetailPrint "GRANT FullAccess ON $DATA_DIR TO $loggedInUser"
    AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUser" "FullAccess" ;GenericWrite
    DetailPrint "GRANT FullAccess ON $DATA_DIR TO $loggedInUserShort"
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
    DetailPrint "GRANT FullAccess ON $DATA_DIR TO $0"
    AccessControl::GrantOnFile "$DATA_DIR" "$0" "FullAccess" ;GenericWrite
    Pop $0 ;"ok" or "error" + error details
    System::Call 'Kernel32::SetEnvironmentVariable(t, t)i ("LC_MESSAGES", "C").r0'	

    FileWrite $LogFile "Database initialization ...$\r$\n"


    StrCpy $currCommand '"$INSTDIR\bin\initdb.exe" $tempVar \
        --encoding=$Coding_text -U "$UserName_text" \
        -D "$DATA_DIR"'
    ${if} $isDataChecksums == ${BST_CHECKED}
          StrCpy $currCommand '$currCommand --data-checksums'
    ${endif}

    ${if} "$Locale_text" != "$(DEF_LOCALE_NAME)"
          StrCpy $currCommand '$currCommand --locale="$Locale_text"'
    ${endif}
    FileWrite $LogFile '$currCommand $\r$\n'
      ; Initialise the database cluster, and set the appropriate permissions/ownership
      nsExec::ExecToLog /TIMEOUT=90000 '$currCommand'

    pop $0
    Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}

    ${if} $0 != 0
      DetailPrint "initdb.exe return $0"
      ;DetailPrint "Output: $1"
      FileWrite $LogFile "initdb.exe return $0 $\r$\n"
      FileWrite $LogFile "Output: $1 $\r$\n"
      FileClose $LogFile ;Closes the filled file

      ${if} $0 != 1
	IfSilent +2
            MessageBox MB_OK|MB_ICONINFORMATION $(MESS_ERROR_INITDB2)
      ${else}
	IfSilent +2
            MessageBox MB_OK|MB_ICONINFORMATION $(MESS_ERROR_INITDB)
     ${endif}

      Abort
    ${else}
      DetailPrint "Database initialization OK"
      FileWrite $LogFile "Database initialization OK $\r$\n"
    ${endif}
    ;Delete the password file
    ${if} "$Pass1_text" != ""
      ${If} ${FileExists} "$tempFileName"
        Delete "$tempFileName"
      ${EndIf}
    ${EndIf}
  ${endif}
  ; Create data dir end
  FileWrite $LogFile "Create postgresql.conf $\r$\n"
  ${if} $isDataDirExist == 0
    ${if} $checkNoLocal_state == ${BST_CHECKED}
      !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#listen_addresses = 'localhost'" "listen_addresses = '*'"
	  ; Add line to pg_hba.conf
	  ${ConfigWrite} "$DATA_DIR\pg_hba.conf"  "host$\tall$\tall$\t" "0.0.0.0/0$\tmd5" $R0
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

    ${if} $needOptimization == "1"
      ${if} $shared_buffers != ""
        ${ConfigWrite} "$DATA_DIR\postgresql.conf" "shared_buffers = " "$shared_buffers$\t$\t# min 128kB" $R0
      ${endif}
      ${if} $work_mem != ""
        ;#work_mem = 4MB				# min 64kB
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#work_mem = 4MB" "work_mem = $work_mem"
      ${endif}
      ${if} $effective_cache_size != ""
        ;#work_mem = 4MB				# min 64kB
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#effective_cache_size = 4GB" "effective_cache_size = $effective_cache_size"
      ${endif}
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#temp_buffers = 8MB" "temp_buffers = 32MB"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#maintenance_work_mem = 64MB" "maintenance_work_mem = 128MB"

        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#autovacuum_max_workers = 3" "autovacuum_max_workers = 6"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#autovacuum_naptime = 1min" "autovacuum_naptime = 20s"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#autovacuum_vacuum_cost_limit = -1" "autovacuum_vacuum_cost_limit = 400"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#bgwriter_delay = 200ms" "bgwriter_delay = 20ms"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#bgwriter_lru_multiplier = 2.0" "bgwriter_lru_multiplier = 4.0"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#bgwriter_lru_maxpages = 100" "bgwriter_lru_maxpages = 400"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#synchronous_commit = on" "synchronous_commit = off"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#checkpoint_completion_target = 0.5" "checkpoint_completion_target = 0.9"

        ;!insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#effective_io_concurrency = 0" "effective_io_concurrency = 2"

        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#random_page_cost = 4.0" "random_page_cost = 1.5"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "max_connections = 100" "max_connections = 500"
        !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#max_locks_per_transaction = 64" "max_locks_per_transaction = 256"
        ;!insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#shared_preload_libraries = ''" "shared_preload_libraries = 'online_analyze, plantuner'"
        ;!insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "" ""

        ${if} ${WITH_1C} == "TRUE"
               !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#escape_string_warning = on" "escape_string_warning = off"
               !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#standard_conforming_strings = on" "standard_conforming_strings = off"
               ClearErrors
               FileOpen $0 $DATA_DIR\postgresql.conf a
               IfErrors ErrFileCfg1
               FileSeek $0 0 END
               FileWrite $0 "shared_preload_libraries = 'online_analyze, plantuner'$\r$\n"
               FileWrite $0 "online_analyze.table_type = 'temporary'$\r$\n"
               FileWrite $0 "online_analyze.verbose = 'off'$\r$\n"
               FileWrite $0 "online_analyze.local_tracking = 'on'$\r$\n"
               FileWrite $0 "plantuner.fix_empty_table = 'on'  $\r$\n"
               FileWrite $0 "online_analyze.enable = on$\r$\n"
               FileClose $0
        ${else}
               ClearErrors
               FileOpen $0 $DATA_DIR\postgresql.conf a
               IfErrors ErrFileCfg1
               FileSeek $0 0 END
               FileWrite $0 "#Options for 1C:$\r$\n"
               FileWrite $0 "#escape_string_warning = off$\r$\n"
               FileWrite $0 "#standard_conforming_strings = off$\r$\n"
               FileWrite $0 "#shared_preload_libraries = 'online_analyze, plantuner'$\r$\n"
               FileWrite $0 "#online_analyze.table_type = 'temporary'$\r$\n"
               FileWrite $0 "#online_analyze.verbose = 'off'$\r$\n"
               FileWrite $0 "#online_analyze.local_tracking = 'on'$\r$\n"
               FileWrite $0 "#plantuner.fix_empty_table = 'on'  $\r$\n"
               FileWrite $0 "#online_analyze.enable = on$\r$\n"

               ;debug for unstarted server:
               ;FileWrite $0 "effective_io_concurrency = 2$\r$\n"

               FileClose $0

        ${endif}
        ErrFileCfg1:

    ${endif}
  ${EndIf}
  Delete "$DATA_DIR\postgresql.conf.old"
  
  ;# Add line to pg_hba.conf
  Call WriteInstallOptions
  DetailPrint "Service $ServiceID_text registration ..."
  FileWrite $LogFile "Service $ServiceID_text registration ... $\r$\n"

  StrCpy $currCommand '"$INSTDIR\bin\pg_ctl.exe" register -N "$ServiceID_text" -U "$ServiceAccount_text" -D "$DATA_DIR" -w'
  ;save without password here
  FileWrite $LogFile '$currCommand $\r$\n'
  ${if} $servicePassword_text != ""
        StrCpy $currCommand '$currCommand -P "$servicePassword_text"'
  ${endif}
  ;FileWrite $LogFile '$currCommand $\r$\n'
  nsExec::ExecToLog /TIMEOUT=60000 '$currCommand'

  Pop $0 # return value/error/timeout
  Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}

  ${if} $0 != 0
    DetailPrint "pg_ctl.exe register return $0"
    DetailPrint "Output: $1"
    FileWrite $LogFile "pg_ctl.exe register return $0 $\r$\n"
    FileWrite $LogFile "Output: $1 $\r$\n"

    Sleep 5000
  ${else}
    DetailPrint "Service registration OK"
    FileWrite $LogFile "Service registration OK $\r$\n"
  ${endif}

  ;Write the DisplayName manually
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\$ServiceID_text" "DisplayName" "$ServiceID_text - PostgreSQL Server ${PG_MAJOR_VERSION}"
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\$ServiceID_text" "Description" "Provides relational database storage."

  DetailPrint "GRANT FullAccess ON $DATA_DIR TO $ServiceAccount_text"
  AccessControl::GrantOnFile "$DATA_DIR" "$ServiceAccount_text" "FullAccess"
  Pop $0 ;"ok" or "error" + error details

  DetailPrint "GRANT GenericRead + GenericExecute ON $INSTDIR TO $ServiceAccount_text"
  AccessControl::GrantOnFile "$INSTDIR" "$ServiceAccount_text" "GenericRead + GenericExecute"
  Pop $0 ;"ok" or "error" + error details

  DetailPrint "GRANT FullAccess ON $DATA_DIR\postgresql.conf TO $ServiceAccount_text"
  AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$ServiceAccount_text" "FullAccess"
  Pop $0 ;"ok" or "error" + error details
  DetailPrint "GRANT FullAccess ON $DATA_DIR\postgresql.conf TO $loggedInUser"
  AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$loggedInUser" "FullAccess"
  Pop $0 ;"ok" or "error" + error details
  DetailPrint "GRANT FullAccess ON $DATA_DIR\postgresql.conf TO $loggedInUserShort"
  AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$loggedInUserShort" "FullAccess"
  Pop $0 ;"ok" or "error" + error details

  DetailPrint "GRANT FullAccess ON $INSTDIR\scripts TO $loggedInUser"
  AccessControl::GrantOnFile "$INSTDIR\scripts" "$loggedInUser" "FullAccess"
  DetailPrint "GRANT GenericRead + GenericExecute ON $INSTDIR\scripts\pgpro_upgrade.cmd TO $loggedInUser"
  AccessControl::GrantOnFile "$INSTDIR\scripts\pgpro_upgrade.cmd" "$loggedInUser" "GenericRead + GenericExecute"
  Pop $0 ;"ok" or "error" + error details
  
  ${if} $isDataDirExist == 1
    ; there exist data directory. We need to stop service,
    ; run pgpro-upgrade script and
    
    DetailPrint "Performing catalog upgradeon $DATA_DIR"
    nsExec::ExecToStack /TIMEOUT=120000 '"$INSTDIR\scripts\pgpro_upgrade.cmd" "$DATA_DIR"'
    Pop $0
    DetailPrint "pgpro_upgrade return $0"
    Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
    DetailPrint "$1"

    ; write log
    FileOpen $R0 "$INSTDIR\scripts\pgpro_upgrade.log" w
    FileWrite $R0 $1
    FileClose $R0
    
    ; Don't work with empty password:
    ; StrCpy $1 $ServiceAccount_text
    ; StrCpy $2 ""
    ; StrCpy $3 '"$INSTDIR/scripts/pgpro_upgrade" "$DATA_DIR"'
    ; StrCpy $4 0
    ; System::Call 'RunAs::RunAsW(w r1, w r2, w r3, *w .r4) i .r0 ? u'
    ; pop $0
    ; DetailPrint "pgpro_upgrade over runas return $0"
  ${endif}

  DetailPrint "Start server service..."
  FileWrite $LogFile "Start server service... $\r$\n"
  FileWrite $LogFile 'sc start "$ServiceID_text" $\r$\n'

  Sleep 1000

  nsExec::ExecToStack /TIMEOUT=60000 'sc start "$ServiceID_text"'
  Sleep 5000
  Pop $0 # return value/error/timeout
  Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}

  ${if} $0 != 0
    DetailPrint "Start service return $0"
    DetailPrint "Output: $1"
    FileWrite $LogFile "Start service return $0 $\r$\n"
    FileWrite $LogFile "Output: $1 $\r$\n"
    Sleep 5000
  ${else}
    DetailPrint "Start service OK"
    FileWrite $LogFile "Start service OK $\r$\n"

  ${endif}
  
  ;check that service is running
  ;sc query "postgrespro-X64-10" | find "RUNNING"

  DetailPrint "Check service is running ..."
  call checkServiceIsRunning
  pop $0
  ${if} $0 == ""
        Sleep 7000
        call checkServiceIsRunning
        pop $0
        ${if} $0 == ""
              DetailPrint "Error: service is not running!"
              FileWrite $LogFile "Error: service $ServiceID_text is not running!$\r$\n"
              FileClose $LogFile
	      IfSilent +2
              MessageBox MB_OK|MB_ICONSTOP "$(MESS_ERROR_SERVER)"
              Abort
        ${endif}
  ${endif}
  

  ;check connection to the server
 ${if} $OLD_DATA_DIR == "" ;if server war running we do not know password

  DetailPrint "Check connection ..."
  Sleep 1000

  FileWrite $LogFile "Check connection ... $\r$\n"
  FileWrite $LogFile '"$INSTDIR\bin\psql.exe" -p $TextPort_text -U "$UserName_text" -c "SELECT 1;" postgres $\r$\n'

  ;send password to Environment Variable PGPASSWORD
  ${if} "$Pass1_text" != ""
        StrCpy $R0 $Pass1_text
        System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PGPASSWORD", R0).r0'
  ${endif}

  nsExec::ExecToStack /TIMEOUT=10000 '"$INSTDIR\bin\psql.exe" -p $TextPort_text -U "$UserName_text" -c "SELECT 1;" postgres'
  
  pop $0
  pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
  ${if} $0 != 0
      DetailPrint "Checking connection has return $0"
      DetailPrint "Output: $1"
      FileWrite $LogFile "Checking connection has return $0 $\r$\n"
      FileWrite $LogFile "Output: $1 $\r$\n"
      FileClose $LogFile

      ;MessageBox MB_OK "Create adminpack error: $1"
      IfSilent +2
	MessageBox MB_OK|MB_ICONSTOP "$(MESS_ERROR_SERVER)"
      Abort
  ${else}
      DetailPrint "Checking connection is OK"
      FileWrite $LogFile "Checking connection is OK $\r$\n"
  ${endif}
  
  
  ${if} "$Pass1_text" != ""
      StrCpy $R0 ""
      System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PGPASSWORD", R0).r0'
  ${endif}
  ;end check connection to the server

  ${if} $isDataDirExist == 0
    ;send password to Environment Variable PGPASSWORD
    ${if} "$Pass1_text" != ""
      StrCpy $R0 $Pass1_text
      System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PGPASSWORD", R0).r0'
    ${endif}

    DetailPrint "Create adminpack ..."
    FileWrite $LogFile "Create adminpack ... $\r$\n"
    FileWrite $LogFile '"$INSTDIR\bin\psql.exe" -p $TextPort_text -U "$UserName_text" -c "CREATE EXTENSION adminpack;" postgres $\r$\n'
    Sleep 5000
    nsExec::ExecToStack /TIMEOUT=60000 '"$INSTDIR\bin\psql.exe" -p $TextPort_text -U "$UserName_text" -c "CREATE EXTENSION adminpack;" postgres'
    pop $0
    Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
    ${if} $0 != 0
      DetailPrint "Create adminpack return $0"
      DetailPrint "Output: $1"
      FileWrite $LogFile "Create adminpack return $0 $\r$\n"
      FileWrite $LogFile "Output: $1 $\r$\n"

      ;MessageBox MB_OK "Create adminpack error: $1"
     IfSilent +2
      MessageBox MB_OK|MB_ICONSTOP "$(MESS_ERROR_SERVER)"
    ${else}
      DetailPrint "Create adminpack OK"
      FileWrite $LogFile "Create adminpack OK $\r$\n"
    ${endif}
    ${if} "$Pass1_text" != ""
      StrCpy $R0 ""
      System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PGPASSWORD", R0).r0'
    ${endif}
  ${endif}
  
 ${endif} ; end: if server war running we do not know password?
  
  
  ${if} $isEnvVar == ${BST_CHECKED}
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGDATA" "$DATA_DIR"
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGDATABASE" "postgres"
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGUSER" "$UserName_text"
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGPORT" "$TextPort_text"
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PGLOCALEDIR" "$INSTDIR\share\locale\"
    AddToPath::AddToPath "$INSTDIR\bin"
  ${endif}
  FileClose $LogFile ;Closes the filled file

SectionEnd

Section $(componentDeveloper) secDev
!include devel_list.nsi
SectionEnd

SectionGroupEnd




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
  ;Delete "$INSTDIR\license.txt"
  Delete "$INSTDIR\${myLicenseFile_ru}"
  Delete "$INSTDIR\${myLicenseFile_en}"

  
  Delete "$INSTDIR\3rd_party_licenses.txt"
  Delete "$INSTDIR\install.log"


  RMDir /r "$INSTDIR\bin"
  RMDir /r "$INSTDIR\doc"
  RMDir /r "$INSTDIR\include"
  RMDir /r "$INSTDIR\lib"
  RMDir /r "$INSTDIR\share"
  RMDir /r "$INSTDIR\symbols"
  RMDir /r "$INSTDIR\StackBuilder"
  RMDir /r "$INSTDIR\scripts"

 


  RMDir "$INSTDIR"

  nsisFirewall::RemoveAuthorizedApplication "$INSTDIR\bin\postgres.exe"

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
!insertmacro MUI_DESCRIPTION_TEXT ${secClient} $(DESC_componentClient)
!insertmacro MUI_DESCRIPTION_TEXT ${secDev} $(DESC_componentDeveloper)



;!insertmacro MUI_DESCRIPTION_TEXT ${SecService} $(DESC_SecService)
!insertmacro MUI_FUNCTION_DESCRIPTION_END


Function writeUnistallReg
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

FunctionEnd

Function createRunPsql
    StrCpy $Chcp_text ""

    DetailPrint "Language settings:"
    DetailPrint "LANG_RUSSIAN=${LANG_RUSSIAN}"
    DetailPrint "LANG_ENGLISH=${LANG_ENGLISH}"
    DetailPrint "LANGUAGE=$LANGUAGE"

    ${if} $LANGUAGE == ${LANG_RUSSIAN}
      StrCpy $Chcp_text "chcp 1251"
    ${endif}

  FileOpen $0 $INSTDIR\scripts\runpgsql.bat w
  IfErrors +2 0
  FileWrite $0 '@echo off$\r$\n$Chcp_text$\r$\nPATH $INSTDIR\bin;%PATH%$\r$\nif not exist "%APPDATA%\postgresql" md "%APPDATA%\postgresql"$\r$\npsql.exe -h localhost -U "$UserName_text" -d postgres -p $TextPort_text $\r$\npause'
  FileClose $0
FunctionEnd


;check existing install
;if exist then get install options to vars
Function ChecExistInstall
  StrCpy $Locale_text "$(DEF_LOCALE_NAME)"

  ; check old previous major version params
  ; ReadRegStr $1 HKLM "${PG_OLD_PREV_REG_KEY}" "Version"
  ; ${if} $1 != "" ;we have install
  ;   ;get exist options
  ;   ReadRegStr $PG_OLD_VERSION HKLM "${PG_OLD_PREV_REG_KEY}" "Version"
  ;   ReadRegStr $PG_OLD_DIR HKLM "${PG_OLD_PREV_REG_KEY}" "Base Directory"
  ;   ReadRegStr $OLD_DATA_DIR HKLM "${PG_OLD_PREV_REG_KEY}" "Data Directory"

  ;   ReadRegStr $OldServiceAccount_text HKLM "${PG_OLD_PREV_REG_KEY}" "Service Account"
  ;   ReadRegStr $OldServiceID_text HKLM "${PG_OLD_PREV_REG_KEY}" "Service ID"
  ;   ReadRegStr $OldUserName_text HKLM "${PG_OLD_PREV_REG_KEY}" "Super User"
  ;   ReadRegStr $OldBranding_text HKLM "${PG_OLD_PREV_REG_KEY}" "Branding"

  ;   ; StrCpy $PG_OLD_DIR $INSTDIR
  ; ${endif}

  ; ReadRegDWORD $1 HKLM "${PG_OLD_PREV_REG_SERVICE_KEY}" "Port"
  ; ${if} $1 != "" ;we have install
  ;   StrCpy $TextPort_text $1
  ; ${endif}

  ; ReadRegStr $1 HKLM "${PG_OLD_PREV_REG_SERVICE_KEY}" "Locale"
  ; ${if} $1 != ""
  ;   StrCpy $Locale_text $1
  ; ${endif}
  
  ; check old major version params
  ReadRegStr $1 HKLM "${PG_OLD_REG_KEY}" "Version"
  ${if} $1 != "" ;we have install
    ;get exist options
    ReadRegStr $PG_OLD_VERSION HKLM "${PG_OLD_REG_KEY}" "Version"
    ReadRegStr $PG_OLD_DIR HKLM "${PG_OLD_REG_KEY}" "Base Directory"
    ReadRegStr $OLD_DATA_DIR HKLM "${PG_OLD_REG_KEY}" "Data Directory"

    ReadRegStr $OldServiceAccount_text HKLM "${PG_OLD_REG_KEY}" "Service Account"
    ReadRegStr $OldServiceID_text HKLM "${PG_OLD_REG_KEY}" "Service ID"
    ReadRegStr $OldUserName_text HKLM "${PG_OLD_REG_KEY}" "Super User"
    ReadRegStr $OldBranding_text HKLM "${PG_OLD_REG_KEY}" "Branding"

    ; StrCpy $PG_OLD_DIR $INSTDIR
  ${endif}

  ReadRegDWORD $1 HKLM "${PG_OLD_REG_SERVICE_KEY}" "Port"
  ${if} $1 != "" ;we have install
    StrCpy $TextPort_text $1
  ${endif}

  ReadRegStr $1 HKLM "${PG_OLD_REG_SERVICE_KEY}" "Locale"
  ${if} $1 != ""
    StrCpy $Locale_text $1
  ${endif}

  ; check previous major version params
  ; ReadRegStr $1 HKLM "${PG_PREV_REG_KEY}" "Version"

  ; ${if} $1 != "" ;we have install
  ;   ;get exist options
  ;   ReadRegStr $PG_OLD_VERSION HKLM "${PG_PREV_REG_KEY}" "Version"
  ;   ReadRegStr $PG_OLD_DIR HKLM "${PG_PREV_REG_KEY}" "Base Directory"
  ;   ReadRegStr $OLD_DATA_DIR HKLM "${PG_PREV_REG_KEY}" "Data Directory"

  ;   ReadRegStr $OldServiceAccount_text HKLM "${PG_PREV_REG_KEY}" "Service Account"
  ;   ReadRegStr $OldServiceID_text HKLM "${PG_PREV_REG_KEY}" "Service ID"
  ;   ReadRegStr $OldUserName_text HKLM "${PG_PREV_REG_KEY}" "Super User"
  ;   ReadRegStr $OldBranding_text HKLM "${PG_PREV_REG_KEY}" "Branding"

  ;   ; StrCpy $PG_OLD_DIR $INSTDIR
  ; ${endif}

  ; ReadRegDWORD $1 HKLM "${PG_PREV_REG_SERVICE_KEY}" "Port"
  ; ${if} $1 != "" ;we have install
  ;   StrCpy $TextPort_text $1
  ; ${endif}

  ; ReadRegStr $1 HKLM "${PG_PREV_REG_SERVICE_KEY}" "Locale"
  ; ${if} $1 != ""
  ;   StrCpy $Locale_text $1
  ; ${endif}

  ; check current major version params
  ReadRegStr $1 HKLM "${PG_REG_KEY}" "Version"

  ${if} $1 != "" ;we have install
    ;get exist options
    ReadRegStr $PG_OLD_VERSION HKLM "${PG_REG_KEY}" "Version"
    ReadRegStr $PG_OLD_DIR HKLM "${PG_REG_KEY}" "Base Directory"
    ReadRegStr $OLD_DATA_DIR HKLM "${PG_REG_KEY}" "Data Directory"

    ReadRegStr $OldServiceAccount_text HKLM "${PG_REG_KEY}" "Service Account"
    ReadRegStr $OldServiceID_text HKLM "${PG_REG_KEY}" "Service ID"
    ReadRegStr $OldUserName_text HKLM "${PG_REG_KEY}" "Super User"
    ReadRegStr $OldBranding_text HKLM "${PG_REG_KEY}" "Branding"

    ; inherits
    StrCpy $DATA_DIR $OLD_DATA_DIR
    StrCpy $ServiceAccount_text $OldServiceAccount_text
    StrCpy $ServiceID_text $OldServiceID_text
    StrCpy $UserName_text $OldUserName_text
    StrCpy $Branding_text $OldBranding_text
    StrCpy $INSTDIR $PG_OLD_DIR
    
  ${endif}

  ReadRegDWORD $1 HKLM "${PG_REG_SERVICE_KEY}" "Port"
  ${if} $1 != "" ;we have install
    StrCpy $TextPort_text $1
  ${endif}

  ReadRegStr $1 HKLM "${PG_REG_SERVICE_KEY}" "Locale"
  ${if} $1 != ""
    StrCpy $Locale_text $1
  ${endif}

  ; calculate free num port - use EnumRegKey
  ; ${if} $TextPort_text == ""
  ;   ; todo: compatibility with pg-installers family
  ;   StrCpy $0 0
  ;   StrCpy $2 5432

  ;   ;SetRegView 32
  ;   SetRegView 64
  ;   ${While} 1 = 1
  ;     EnumRegKey $1 HKLM "SOFTWARE\PostgreSQL\Services" $0
  ;     ${if} $1 == ""
  ;       ${ExitWhile}
  ;     ${endif}
  ;     ReadRegDWORD $3 HKLM "SOFTWARE\PostgreSQL\Services\$1" "Port"
  ;     ${if} $3 >= $2
  ;       IntOp $2 $3 + 1
  ;     ${endif}
  ;     IntOp $0 $0 + 1
  ;   ${EndWhile}
  ;   SetRegView 32
  ;   StrCpy $0 0
  ;   ${While} 1 = 1
  ;     EnumRegKey $1 HKLM "SOFTWARE\PostgreSQL\Services" $0
  ;     ${if} $1 == ""
  ;       ${ExitWhile}
  ;     ${endif}
  ;     ReadRegDWORD $3 HKLM "SOFTWARE\PostgreSQL\Services\$1" "Port"
  ;     ${if} $3 >= $2
  ;       IntOp $2 $3 + 1
  ;     ${endif}

  ;     IntOp $0 $0 + 1
  ;   ${EndWhile}

  ;   ${if} $IsTextPortInIni != 1 ;port can be send in ini file
  ;     StrCpy $TextPort_text $2
  ;   ${endif}
  ; ${endif}

FunctionEnd

;write to PG_REG_KEY - "SOFTWARE\PostgreSQL\Installations\postgresql-${PG_MAJOR_VERSION}"
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

  ReadRegStr $1 HKLM "${PG_OLD_REG_KEY}" "Version"
  ${if} $1 != "" ;we have old install
  	DeleteRegValue HKLM "${PG_OLD_REG_KEY}" "Version"
  	DeleteRegValue HKLM "${PG_OLD_REG_KEY}" "Base Directory"
  	DeleteRegValue HKLM "${PG_OLD_REG_KEY}" "Data Directory"
  	DeleteRegValue HKLM "${PG_OLD_REG_KEY}" "Service Account"
  	DeleteRegValue HKLM "${PG_OLD_REG_KEY}" "Service ID"
  	DeleteRegValue HKLM "${PG_OLD_REG_KEY}" "Super User"
	DeleteRegValue HKLM "${PG_OLD_REG_KEY}" "Branding"
  	DeleteRegValue HKLM "${PG_OLD_REG_SERVICE_KEY}" "Port"
  	DeleteRegValue HKLM "${PG_OLD_REG_SERVICE_KEY}" "Locale"
  	;for compatibility
  	DeleteRegValue HKLM "${PG_OLD_REG_SERVICE_KEY}" "Data Directory"
  	DeleteRegValue HKLM "${PG_OLD_REG_SERVICE_KEY}" "Database Superuser"
	DeleteRegValue HKLM "${PG_OLD_REG_SERVICE_KEY}" "Display Name"
  	DeleteRegValue HKLM "${PG_OLD_REG_SERVICE_KEY}" "Product Code"
  	DeleteRegValue HKLM "${PG_OLD_REG_SERVICE_KEY}" "Service Account"
	DeleteRegKey /ifempty HKLM "${PG_OLD_REG_KEY}"
  	DeleteRegKey /ifempty HKLM "${PG_OLD_REG_SERVICE_KEY}"
  ${endif}
FunctionEnd

Function un.ChecExistInstall
  ReadRegStr $1 HKLM "${PG_REG_KEY}" "Version"
  ${if} $1 != "" ;we have install
    ;get exist options
    ReadRegStr $PG_OLD_VERSION HKLM "${PG_REG_KEY}" "Version"
    ReadRegStr $0 HKLM "${PG_REG_KEY}" "Base Directory"
    ${if} $0 != ""
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


  ${NSD_GetState} $checkBoxDataChecksums $isDataChecksums


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
  ${AndUnless} ${SectionIsSelected} ${secClient}
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

  ${NSD_CreateLabel} 0 2u 70u 12u "$(DLG_PORT)"
  Pop $Label

  ${NSD_CreateText} 72u 0 100u 12u "$TextPort_text"
  Pop $TextPort

  ${NSD_CreateLabel} 0 16u 70u 12u "$(DLG_ADR1)"
  Pop $Label2

  ${NSD_CreateCheckBox} 72u 15u 100% 12u "$(DLG_ADR2)"

  Pop $checkNoLocal
  ${NSD_SetState} $checkNoLocal $checkNoLocal_state

  ${NSD_CreateLabel} 0 32u 70u 12u "$(DLG_LOCALE)"
  Pop $Label2

  ${NSD_CreateDropList} 72u 30u 100u 12u ""
  Pop $Locale

  ${NSD_CB_AddString} $Locale "$(DEF_LOCALE_NAME)"
  ${if} ${PG_MAJOR_VERSION} >= "10"
    ;; Source URL: https://www.microsoft.com/resources/msdn/goglobal/default.mspx (windows 7)
    ${NSD_CB_AddString} $Locale "af"         ; 0x0036	af	Afrikaans	Afrikaans	Afrikaans	1252	850	ZAF	AFK
    ${NSD_CB_AddString} $Locale "af-ZA"      ; 0x0436	af-ZA	Afrikaans (South Africa)	Afrikaans	Afrikaans (Suid Afrika)	1252	850	ZAF	AFK
    ${NSD_CB_AddString} $Locale "sq"         ; 0x001C	sq	Albanian	Albanian	shqipe	1250	852	ALB	SQI
    ${NSD_CB_AddString} $Locale "sq-AL"      ; 0x041C	sq-AL	Albanian (Albania)	Albanian	shqipe (Shqipëria)	1250	852	ALB	SQI
    ${NSD_CB_AddString} $Locale "gsw"        ; 0x0084	gsw	Alsatian	Alsatian	Elsässisch	1252	850	FRA	GSW
    ${NSD_CB_AddString} $Locale "gsw-FR"     ; 0x0484	gsw-FR	Alsatian (France)	Alsatian	Elsässisch (Frànkrisch)	1252	850	FRA	GSW
    ${NSD_CB_AddString} $Locale "am"         ; 0x005E	am	Amharic	Amharic	አማርኛ	0	1	ETH	AMH
    ${NSD_CB_AddString} $Locale "am-ET"      ; 0x045E	am-ET	Amharic (Ethiopia)	Amharic	አማርኛ (ኢትዮጵያ)	0	1	ETH	AMH
    ${NSD_CB_AddString} $Locale "ar"         ; 0x0001	ar	Arabic‎	Arabic	العربية‏	1256	720	SAU	ARA
    ${NSD_CB_AddString} $Locale "ar-DZ"      ; 0x1401	ar-DZ	Arabic (Algeria)‎	Arabic	العربية (الجزائر)‏	1256	720	DZA	ARG
    ${NSD_CB_AddString} $Locale "ar-BH"      ; 0x3C01	ar-BH	Arabic (Bahrain)‎	Arabic	العربية (البحرين)‏	1256	720	BHR	ARH
    ${NSD_CB_AddString} $Locale "ar-EG"      ; 0x0C01	ar-EG	Arabic (Egypt)‎	Arabic	العربية (مصر)‏	1256	720	EGY	ARE
    ${NSD_CB_AddString} $Locale "ar-IQ"      ; 0x0801	ar-IQ	Arabic (Iraq)‎	Arabic	العربية (العراق)‏	1256	720	IRQ	ARI
    ${NSD_CB_AddString} $Locale "ar-JO"      ; 0x2C01	ar-JO	Arabic (Jordan)‎	Arabic	العربية (الأردن)‏	1256	720	JOR	ARJ
    ${NSD_CB_AddString} $Locale "ar-KW"      ; 0x3401	ar-KW	Arabic (Kuwait)‎	Arabic	العربية (الكويت)‏	1256	720	KWT	ARK
    ${NSD_CB_AddString} $Locale "ar-LB"      ; 0x3001	ar-LB	Arabic (Lebanon)‎	Arabic	العربية (لبنان)‏	1256	720	LBN	ARB
    ${NSD_CB_AddString} $Locale "ar-LY"      ; 0x1001	ar-LY	Arabic (Libya)‎	Arabic	العربية (ليبيا)‏	1256	720	LBY	ARL
    ${NSD_CB_AddString} $Locale "ar-MA"      ; 0x1801	ar-MA	Arabic (Morocco)‎	Arabic	العربية (المملكة المغربية)‏	1256	720	MAR	ARM
    ${NSD_CB_AddString} $Locale "ar-OM"      ; 0x2001	ar-OM	Arabic (Oman)‎	Arabic	العربية (عمان)‏	1256	720	OMN	ARO
    ${NSD_CB_AddString} $Locale "ar-QA"      ; 0x4001	ar-QA	Arabic (Qatar)‎	Arabic	العربية (قطر)‏	1256	720	QAT	ARQ
    ${NSD_CB_AddString} $Locale "ar-SA"      ; 0x0401	ar-SA	Arabic (Saudi Arabia)‎	Arabic	العربية (المملكة العربية السعودية)‏	1256	720	SAU	ARA
    ${NSD_CB_AddString} $Locale "ar-SY"      ; 0x2801	ar-SY	Arabic (Syria)‎	Arabic	العربية (سوريا)‏	1256	720	SYR	ARS
    ${NSD_CB_AddString} $Locale "ar-TN"      ; 0x1C01	ar-TN	Arabic (Tunisia)‎	Arabic	العربية (تونس)‏	1256	720	TUN	ART
    ${NSD_CB_AddString} $Locale "ar-AE"      ; 0x3801	ar-AE	Arabic (U.A.E.)‎	Arabic	العربية (الإمارات العربية المتحدة)‏	1256	720	ARE	ARU
    ${NSD_CB_AddString} $Locale "ar-YE"      ; 0x2401	ar-YE	Arabic (Yemen)‎	Arabic	العربية (اليمن)‏	1256	720	YEM	ARY
    ${NSD_CB_AddString} $Locale "hy"         ; 0x002B	hy	Armenian	Armenian	Հայերեն	0	1	ARM	HYE
    ${NSD_CB_AddString} $Locale "hy-AM"      ; 0x042B	hy-AM	Armenian (Armenia)	Armenian	Հայերեն (Հայաստան)	0	1	ARM	HYE
    ${NSD_CB_AddString} $Locale "as"         ; 0x004D	as	Assamese	Assamese	অসমীয়া	0	1	IND	ASM
    ${NSD_CB_AddString} $Locale "as-IN"      ; 0x044D	as-IN	Assamese (India)	Assamese	অসমীয়া (ভাৰত)	0	1	IND	ASM
    ${NSD_CB_AddString} $Locale "az"         ; 0x002C	az	Azeri	Azeri (Latin)	Azərbaycan­ılı	1254	857	AZE	AZE
    ${NSD_CB_AddString} $Locale "az-Cyrl"    ; 0x742C	az-Cyrl	Azeri (Cyrillic)	Azeri (Cyrillic)	Азәрбајҹан дили	1251	866	AZE	AZC
    ${NSD_CB_AddString} $Locale "az-Cyrl-AZ" ; 0x082C	az-Cyrl-AZ	Azeri (Cyrillic, Azerbaijan)	Azeri (Cyrillic)	Азәрбајҹан (Азәрбајҹан)	1251	866	AZE	AZC
    ${NSD_CB_AddString} $Locale "az-Latn"    ; 0x782C	az-Latn	Azeri (Latin)	Azeri (Latin)	Azərbaycan­ılı	1254	857	AZE	AZE
    ${NSD_CB_AddString} $Locale "az-Latn-AZ" ; 0x042C	az-Latn-AZ	Azeri (Latin, Azerbaijan)	Azeri (Latin)	Azərbaycan­ılı (Azərbaycan)	1254	857	AZE	AZE
    ${NSD_CB_AddString} $Locale "ba"         ; 0x006D	ba	Bashkir	Bashkir	Башҡорт	1251	866	RUS	BAS
    ${NSD_CB_AddString} $Locale "ba-RU"      ; 0x046D	ba-RU	Bashkir (Russia)	Bashkir	Башҡорт (Россия)	1251	866	RUS	BAS
    ${NSD_CB_AddString} $Locale "eu"         ; 0x002D	eu	Basque	Basque	euskara	1252	850	ESP	EUQ
    ${NSD_CB_AddString} $Locale "eu-ES"      ; 0x042D	eu-ES	Basque (Basque)	Basque	euskara (euskara)	1252	850	ESP	EUQ
    ${NSD_CB_AddString} $Locale "be"         ; 0x0023	be	Belarusian	Belarusian	Беларускі	1251	866	BLR	BEL
    ${NSD_CB_AddString} $Locale "be-BY"      ; 0x0423	be-BY	Belarusian (Belarus)	Belarusian	Беларускі (Беларусь)	1251	866	BLR	BEL
    ${NSD_CB_AddString} $Locale "bn"         ; 0x0045	bn	Bengali	Bengali	বাংলা	0	1	IND	BNG
    ${NSD_CB_AddString} $Locale "bn-BD"      ; 0x0845	bn-BD	Bengali (Bangladesh)	Bengali	বাংলা (বাংলাদেশ)	0	1	BGD	BNB
    ${NSD_CB_AddString} $Locale "bn-IN"      ; 0x0445	bn-IN	Bengali (India)	Bengali	বাংলা (ভারত)	0	1	IND	BNG
    ${NSD_CB_AddString} $Locale "bs"         ; 0x781A	bs	Bosnian	Bosnian (Latin)	bosanski	1250	852	BIH	BSB
    ${NSD_CB_AddString} $Locale "bs-Cyrl"    ; 0x641A	bs-Cyrl	Bosnian (Cyrillic)	Bosnian (Cyrillic)	босански (Ћирилица)	1251	855	BIH	BSC
    ${NSD_CB_AddString} $Locale "bs-Cyrl-BA" ; 0x201A	bs-Cyrl-BA	Bosnian (Cyrillic, Bosnia and Herzegovina)	Bosnian (Cyrillic)	босански (Босна и Херцеговина)	1251	855	BIH	BSC
    ${NSD_CB_AddString} $Locale "bs-Latn"    ; 0x681A	bs-Latn	Bosnian (Latin)	Bosnian (Latin)	bosanski (Latinica)	1250	852	BIH	BSB
    ${NSD_CB_AddString} $Locale "bs-Latn-BA" ; 0x141A	bs-Latn-BA	Bosnian (Latin, Bosnia and Herzegovina)	Bosnian (Latin)	bosanski (Bosna i Hercegovina)	1250	852	BIH	BSB
    ${NSD_CB_AddString} $Locale "br"         ; 0x007E	br	Breton	Breton	brezhoneg	1252	850	FRA	BRE
    ${NSD_CB_AddString} $Locale "br-FR"      ; 0x047E	br-FR	Breton (France)	Breton	brezhoneg (Frañs)	1252	850	FRA	BRE
    ${NSD_CB_AddString} $Locale "bg"         ; 0x0002	bg	Bulgarian	Bulgarian	български	1251	866	BGR	BGR
    ${NSD_CB_AddString} $Locale "bg-BG"      ; 0x0402	bg-BG	Bulgarian (Bulgaria)	Bulgarian	български (България)	1251	866	BGR	BGR
    ${NSD_CB_AddString} $Locale "ca"         ; 0x0003	ca	Catalan	Catalan	català	1252	850	ESP	CAT
    ${NSD_CB_AddString} $Locale "ca-ES"      ; 0x0403	ca-ES	Catalan (Catalan)	Catalan	català (català)	1252	850	ESP	CAT
    ${NSD_CB_AddString} $Locale "zh"         ; 0x7804	zh	Chinese	Chinese (Simplified)	中文	936	936	CHN	CHS
    ${NSD_CB_AddString} $Locale "zh-Hans"    ; 0x0004	zh-Hans	Chinese (Simplified)	Chinese (Simplified)	中文(简体)	936	936	CHN	CHS
    ${NSD_CB_AddString} $Locale "zh-CN"      ; 0x0804	zh-CN	Chinese (Simplified, PRC)	Chinese (Simplified)	中文(中华人民共和国)	936	936	CHN	CHS
    ${NSD_CB_AddString} $Locale "zh-SG"      ; 0x1004	zh-SG	Chinese (Simplified, Singapore)	Chinese (Simplified)	中文(新加坡)	936	936	SGP	ZHI
    ${NSD_CB_AddString} $Locale "zh-Hant"    ; 0x7C04	zh-Hant	Chinese (Traditional)	Chinese (Traditional)	中文(繁體)	950	950	HKG	ZHH
    ${NSD_CB_AddString} $Locale "zh-HK"      ; 0x0C04	zh-HK	Chinese (Traditional, Hong Kong S.A.R.)	Chinese (Traditional)	中文(香港特別行政區)	950	950	HKG	ZHH
    ${NSD_CB_AddString} $Locale "zh-MO"      ; 0x1404	zh-MO	Chinese (Traditional, Macao S.A.R.)	Chinese (Traditional)	中文(澳門特別行政區)	950	950	MCO	ZHM
    ${NSD_CB_AddString} $Locale "zh-TW"      ; 0x0404	zh-TW	Chinese (Traditional, Taiwan)	Chinese (Traditional)	中文(台灣)	950	950	TWN	CHT
    ${NSD_CB_AddString} $Locale "co"         ; 0x0083	co	Corsican	Corsican	Corsu	1252	850	FRA	COS
    ${NSD_CB_AddString} $Locale "co-FR"      ; 0x0483	co-FR	Corsican (France)	Corsican	Corsu (France)	1252	850	FRA	COS
    ${NSD_CB_AddString} $Locale "hr"         ; 0x001A	hr	Croatian	Croatian	hrvatski	1250	852	HRV	HRV
    ${NSD_CB_AddString} $Locale "hr-HR"      ; 0x041A	hr-HR	Croatian (Croatia)	Croatian	hrvatski (Hrvatska)	1250	852	HRV	HRV
    ${NSD_CB_AddString} $Locale "hr-BA"      ; 0x101A	hr-BA	Croatian (Latin, Bosnia and Herzegovina)	Croatian (Latin)	hrvatski (Bosna i Hercegovina)	1250	852	BIH	HRB
    ${NSD_CB_AddString} $Locale "cs"         ; 0x0005	cs	Czech	Czech	čeština	1250	852	CZE	CSY
    ${NSD_CB_AddString} $Locale "cs-CZ"      ; 0x0405	cs-CZ	Czech (Czech Republic)	Czech	čeština (Česká republika)	1250	852	CZE	CSY
    ${NSD_CB_AddString} $Locale "da"         ; 0x0006	da	Danish	Danish	dansk	1252	850	DNK	DAN
    ${NSD_CB_AddString} $Locale "da-DK"      ; 0x0406	da-DK	Danish (Denmark)	Danish	dansk (Danmark)	1252	850	DNK	DAN
    ${NSD_CB_AddString} $Locale "prs"        ; 0x008C	prs	Dari‎	Dari	درى‏	1256	720	AFG	PRS
    ${NSD_CB_AddString} $Locale "prs-AF"     ; 0x048C	prs-AF	Dari (Afghanistan)‎	Dari	درى (افغانستان)‏	1256	720	AFG	PRS
    ${NSD_CB_AddString} $Locale "dv"         ; 0x0065	dv	Divehi‎	Divehi	ދިވެހިބަސް‏	0	1	MDV	DIV
    ${NSD_CB_AddString} $Locale "dv-MV"      ; 0x0465	dv-MV	Divehi (Maldives)‎	Divehi	ދިވެހިބަސް (ދިވެހި ރާއްޖެ)‏	0	1	MDV	DIV
    ${NSD_CB_AddString} $Locale "nl"         ; 0x0013	nl	Dutch	Dutch	Nederlands	1252	850	NLD	NLD
    ${NSD_CB_AddString} $Locale "nl-BE"      ; 0x0813	nl-BE	Dutch (Belgium)	Dutch	Nederlands (België)	1252	850	BEL	NLB
    ${NSD_CB_AddString} $Locale "nl-NL"      ; 0x0413	nl-NL	Dutch (Netherlands)	Dutch	Nederlands (Nederland)	1252	850	NLD	NLD
    ${NSD_CB_AddString} $Locale "en"         ; 0x0009	en	English	English	English	1252	437	USA	ENU
    ${NSD_CB_AddString} $Locale "en-AU"      ; 0x0C09	en-AU	English (Australia)	English	English (Australia)	1252	850	AUS	ENA
    ${NSD_CB_AddString} $Locale "en-BZ"      ; 0x2809	en-BZ	English (Belize)	English	English (Belize)	1252	850	BLZ	ENL
    ${NSD_CB_AddString} $Locale "en-CA"      ; 0x1009	en-CA	English (Canada)	English	English (Canada)	1252	850	CAN	ENC
    ${NSD_CB_AddString} $Locale "en-029"     ; 0x2409	en-029	English (Caribbean)	English	English (Caribbean)	1252	850	CAR	ENB
    ${NSD_CB_AddString} $Locale "en-IN"      ; 0x4009	en-IN	English (India)	English	English (India)	1252	437	IND	ENN
    ${NSD_CB_AddString} $Locale "en-IE"      ; 0x1809	en-IE	English (Ireland)	English	English (Ireland)	1252	850	IRL	ENI
    ${NSD_CB_AddString} $Locale "en-JM"      ; 0x2009	en-JM	English (Jamaica)	English	English (Jamaica)	1252	850	JAM	ENJ
    ${NSD_CB_AddString} $Locale "en-MY"      ; 0x4409	en-MY	English (Malaysia)	English	English (Malaysia)	1252	437	MYS	ENM
    ${NSD_CB_AddString} $Locale "en-NZ"      ; 0x1409	en-NZ	English (New Zealand)	English	English (New Zealand)	1252	850	NZL	ENZ
    ${NSD_CB_AddString} $Locale "en-PH"      ; 0x3409	en-PH	English (Republic of the Philippines)	English	English (Philippines)	1252	437	PHL	ENP
    ${NSD_CB_AddString} $Locale "en-SG"      ; 0x4809	en-SG	English (Singapore)	English	English (Singapore)	1252	437	SGP	ENE
    ${NSD_CB_AddString} $Locale "en-ZA"      ; 0x1C09	en-ZA	English (South Africa)	English	English (South Africa)	1252	437	ZAF	ENS
    ${NSD_CB_AddString} $Locale "en-TT"      ; 0x2C09	en-TT	English (Trinidad and Tobago)	English	English (Trinidad y Tobago)	1252	850	TTO	ENT
    ${NSD_CB_AddString} $Locale "en-GB"      ; 0x0809	en-GB	English (United Kingdom)	English	English (United Kingdom)	1252	850	GBR	ENG
    ${NSD_CB_AddString} $Locale "en-US"      ; 0x0409	en-US	English (United States)	English	English (United States)	1252	437	USA	ENU
    ${NSD_CB_AddString} $Locale "en-ZW"      ; 0x3009	en-ZW	English (Zimbabwe)	English	English (Zimbabwe)	1252	437	ZWE	ENW
    ${NSD_CB_AddString} $Locale "et"         ; 0x0025	et	Estonian	Estonian	eesti	1257	775	EST	ETI
    ${NSD_CB_AddString} $Locale "et-EE"      ; 0x0425	et-EE	Estonian (Estonia)	Estonian	eesti (Eesti)	1257	775	EST	ETI
    ${NSD_CB_AddString} $Locale "fo"         ; 0x0038	fo	Faroese	Faroese	føroyskt	1252	850	FRO	FOS
    ${NSD_CB_AddString} $Locale "fo-FO"      ; 0x0438	fo-FO	Faroese (Faroe Islands)	Faroese	føroyskt (Føroyar)	1252	850	FRO	FOS
    ${NSD_CB_AddString} $Locale "fil"        ; 0x0064	fil	Filipino	Filipino	Filipino	1252	437	PHL	FPO
    ${NSD_CB_AddString} $Locale "fil-PH"     ; 0x0464	fil-PH	Filipino (Philippines)	Filipino	Filipino (Pilipinas)	1252	437	PHL	FPO
    ${NSD_CB_AddString} $Locale "fi"         ; 0x000B	fi	Finnish	Finnish	suomi	1252	850	FIN	FIN
    ${NSD_CB_AddString} $Locale "fi-FI"      ; 0x040B	fi-FI	Finnish (Finland)	Finnish	suomi (Suomi)	1252	850	FIN	FIN
    ${NSD_CB_AddString} $Locale "fr"         ; 0x000C	fr	French	French	français	1252	850	FRA	FRA
    ${NSD_CB_AddString} $Locale "fr-BE"      ; 0x080C	fr-BE	French (Belgium)	French	français (Belgique)	1252	850	BEL	FRB
    ${NSD_CB_AddString} $Locale "fr-CA"      ; 0x0C0C	fr-CA	French (Canada)	French	français (Canada)	1252	850	CAN	FRC
    ${NSD_CB_AddString} $Locale "fr-FR"      ; 0x040C	fr-FR	French (France)	French	français (France)	1252	850	FRA	FRA
    ${NSD_CB_AddString} $Locale "fr-LU"      ; 0x140C	fr-LU	French (Luxembourg)	French	français (Luxembourg)	1252	850	LUX	FRL
    ${NSD_CB_AddString} $Locale "fr-MC"      ; 0x180C	fr-MC	French (Monaco)	French	français (Principauté de Monaco)	1252	850	MCO	FRM
    ${NSD_CB_AddString} $Locale "fr-CH"      ; 0x100C	fr-CH	French (Switzerland)	French	français (Suisse)	1252	850	CHE	FRS
    ${NSD_CB_AddString} $Locale "fy"         ; 0x0062	fy	Frisian	Frisian	Frysk	1252	850	NLD	FYN
    ${NSD_CB_AddString} $Locale "fy-NL"      ; 0x0462	fy-NL	Frisian (Netherlands)	Frisian	Frysk (Nederlân)	1252	850	NLD	FYN
    ${NSD_CB_AddString} $Locale "gl"         ; 0x0056	gl	Galician	Galician	galego	1252	850	ESP	GLC
    ${NSD_CB_AddString} $Locale "gl-ES"      ; 0x0456	gl-ES	Galician (Galician)	Galician	galego (galego)	1252	850	ESP	GLC
    ${NSD_CB_AddString} $Locale "ka"         ; 0x0037	ka	Georgian	Georgian	ქართული	0	1	GEO	KAT
    ${NSD_CB_AddString} $Locale "ka-GE"      ; 0x0437	ka-GE	Georgian (Georgia)	Georgian	ქართული (საქართველო)	0	1	GEO	KAT
    ${NSD_CB_AddString} $Locale "de"         ; 0x0007	de	German	German	Deutsch	1252	850	DEU	DEU
    ${NSD_CB_AddString} $Locale "de-AT"      ; 0x0C07	de-AT	German (Austria)	German	Deutsch (Österreich)	1252	850	AUT	DEA
    ${NSD_CB_AddString} $Locale "de-DE"      ; 0x0407	de-DE	German (Germany)	German	Deutsch (Deutschland)	1252	850	DEU	DEU
    ${NSD_CB_AddString} $Locale "de-LI"      ; 0x1407	de-LI	German (Liechtenstein)	German	Deutsch (Liechtenstein)	1252	850	LIE	DEC
    ${NSD_CB_AddString} $Locale "de-LU"      ; 0x1007	de-LU	German (Luxembourg)	German	Deutsch (Luxemburg)	1252	850	LUX	DEL
    ${NSD_CB_AddString} $Locale "de-CH"      ; 0x0807	de-CH	German (Switzerland)	German	Deutsch (Schweiz)	1252	850	CHE	DES
    ${NSD_CB_AddString} $Locale "el"         ; 0x0008	el	Greek	Greek	Ελληνικά	1253	737	GRC	ELL
    ${NSD_CB_AddString} $Locale "el-GR"      ; 0x0408	el-GR	Greek (Greece)	Greek	Ελληνικά (Ελλάδα)	1253	737	GRC	ELL
    ${NSD_CB_AddString} $Locale "kl"         ; 0x006F	kl	Greenlandic	Greenlandic	kalaallisut	1252	850	GRL	KAL
    ${NSD_CB_AddString} $Locale "kl-GL"      ; 0x046F	kl-GL	Greenlandic (Greenland)	Greenlandic	kalaallisut (Kalaallit Nunaat)	1252	850	GRL	KAL
    ${NSD_CB_AddString} $Locale "gu"         ; 0x0047	gu	Gujarati	Gujarati	ગુજરાતી	0	1	IND	GUJ
    ${NSD_CB_AddString} $Locale "gu-IN"      ; 0x0447	gu-IN	Gujarati (India)	Gujarati	ગુજરાતી (ભારત)	0	1	IND	GUJ
    ${NSD_CB_AddString} $Locale "ha"         ; 0x0068	ha	Hausa	Hausa (Latin)	Hausa	1252	437	NGA	HAU
    ${NSD_CB_AddString} $Locale "ha-Latn"    ; 0x7C68	ha-Latn	Hausa (Latin)	Hausa (Latin)	Hausa (Latin)	1252	437	NGA	HAU
    ${NSD_CB_AddString} $Locale "ha-Latn-NG" ; 0x0468	ha-Latn-NG	Hausa (Latin, Nigeria)	Hausa (Latin)	Hausa (Nigeria)	1252	437	NGA	HAU
    ${NSD_CB_AddString} $Locale "he"         ; 0x000D	he	Hebrew‎	Hebrew	עברית‏	1255	862	ISR	HEB
    ${NSD_CB_AddString} $Locale "he-IL"      ; 0x040D	he-IL	Hebrew (Israel)‎	Hebrew	עברית (ישראל)‏	1255	862	ISR	HEB
    ${NSD_CB_AddString} $Locale "hi"         ; 0x0039	hi	Hindi	Hindi	हिंदी	0	1	IND	HIN
    ${NSD_CB_AddString} $Locale "hi-IN"      ; 0x0439	hi-IN	Hindi (India)	Hindi	हिंदी (भारत)	0	1	IND	HIN
    ${NSD_CB_AddString} $Locale "hu"         ; 0x000E	hu	Hungarian	Hungarian	magyar	1250	852	HUN	HUN
    ${NSD_CB_AddString} $Locale "hu-HU"      ; 0x040E	hu-HU	Hungarian (Hungary)	Hungarian	magyar (Magyarország)	1250	852	HUN	HUN
    ${NSD_CB_AddString} $Locale "is"         ; 0x000F	is	Icelandic	Icelandic	íslenska	1252	850	ISL	ISL
    ${NSD_CB_AddString} $Locale "is-IS"      ; 0x040F	is-IS	Icelandic (Iceland)	Icelandic	íslenska (Ísland)	1252	850	ISL	ISL
    ${NSD_CB_AddString} $Locale "ig"         ; 0x0070	ig	Igbo	Igbo	Igbo	1252	437	NGA	IBO
    ${NSD_CB_AddString} $Locale "ig-NG"      ; 0x0470	ig-NG	Igbo (Nigeria)	Igbo	Igbo (Nigeria)	1252	437	NGA	IBO
    ${NSD_CB_AddString} $Locale "id"         ; 0x0021	id	Indonesian	Indonesian	Bahasa Indonesia	1252	850	IDN	IND
    ${NSD_CB_AddString} $Locale "id-ID"      ; 0x0421	id-ID	Indonesian (Indonesia)	Indonesian	Bahasa Indonesia (Indonesia)	1252	850	IDN	IND
    ${NSD_CB_AddString} $Locale "iu"         ; 0x005D	iu	Inuktitut	Inuktitut (Latin)	Inuktitut	1252	437	CAN	IUK
    ${NSD_CB_AddString} $Locale "iu-Latn"    ; 0x7C5D	iu-Latn	Inuktitut (Latin)	Inuktitut (Latin)	Inuktitut (Qaliujaaqpait)	1252	437	CAN	IUK
    ${NSD_CB_AddString} $Locale "iu-Latn-CA" ; 0x085D	iu-Latn-CA	Inuktitut (Latin, Canada)	Inuktitut (Latin)	Inuktitut	1252	437	CAN	IUK
    ${NSD_CB_AddString} $Locale "iu-Cans"    ; 0x785D	iu-Cans	Inuktitut (Syllabics)	Inuktitut (Syllabics)	ᐃᓄᒃᑎᑐᑦ (ᖃᓂᐅᔮᖅᐸᐃᑦ)	0	1	CAN	IUS
    ${NSD_CB_AddString} $Locale "iu-Cans-CA" ; 0x045D	iu-Cans-CA	Inuktitut (Syllabics, Canada)	Inuktitut (Syllabics)	ᐃᓄᒃᑎᑐᑦ (ᑲᓇᑕᒥ)	0	1	CAN	IUS
    ${NSD_CB_AddString} $Locale "ga"         ; 0x003C	ga	Irish	Irish	Gaeilge	1252	850	IRL	IRE
    ${NSD_CB_AddString} $Locale "ga-IE"      ; 0x083C	ga-IE	Irish (Ireland)	Irish	Gaeilge (Éire)	1252	850	IRL	IRE
    ${NSD_CB_AddString} $Locale "xh"         ; 0x0034	xh	isiXhosa	isiXhosa	isiXhosa	1252	850	ZAF	XHO
    ${NSD_CB_AddString} $Locale "xh-ZA"      ; 0x0434	xh-ZA	isiXhosa (South Africa)	isiXhosa	isiXhosa (uMzantsi Afrika)	1252	850	ZAF	XHO
    ${NSD_CB_AddString} $Locale "zu"         ; 0x0035	zu	isiZulu	isiZulu	isiZulu	1252	850	ZAF	ZUL
    ${NSD_CB_AddString} $Locale "zu-ZA"      ; 0x0435	zu-ZA	isiZulu (South Africa)	isiZulu	isiZulu (iNingizimu Afrika)	1252	850	ZAF	ZUL
    ${NSD_CB_AddString} $Locale "it"         ; 0x0010	it	Italian	Italian	italiano	1252	850	ITA	ITA
    ${NSD_CB_AddString} $Locale "it-IT"      ; 0x0410	it-IT	Italian (Italy)	Italian	italiano (Italia)	1252	850	ITA	ITA
    ${NSD_CB_AddString} $Locale "it-CH"      ; 0x0810	it-CH	Italian (Switzerland)	Italian	italiano (Svizzera)	1252	850	CHE	ITS
    ${NSD_CB_AddString} $Locale "ja"         ; 0x0011	ja	Japanese	Japanese	日本語	932	932	JPN	JPN
    ${NSD_CB_AddString} $Locale "ja-JP"      ; 0x0411	ja-JP	Japanese (Japan)	Japanese	日本語 (日本)	932	932	JPN	JPN
    ${NSD_CB_AddString} $Locale "kn"         ; 0x004B	kn	Kannada	Kannada	ಕನ್ನಡ	0	1	IND	KDI
    ${NSD_CB_AddString} $Locale "kn-IN"      ; 0x044B	kn-IN	Kannada (India)	Kannada	ಕನ್ನಡ (ಭಾರತ)	0	1	IND	KDI
    ${NSD_CB_AddString} $Locale "kk"         ; 0x003F	kk	Kazakh	Kazakh	Қазақ	0	1	KAZ	KKZ
    ${NSD_CB_AddString} $Locale "kk-KZ"      ; 0x043F	kk-KZ	Kazakh (Kazakhstan)	Kazakh	Қазақ (Қазақстан)	0	1	KAZ	KKZ
    ${NSD_CB_AddString} $Locale "km"         ; 0x0053	km	Khmer	Khmer	ខ្មែរ	0	1	KHM	KHM
    ${NSD_CB_AddString} $Locale "km-KH"      ; 0x0453	km-KH	Khmer (Cambodia)	Khmer	ខ្មែរ (កម្ពុជា)	0	1	KHM	KHM
    ${NSD_CB_AddString} $Locale "qut"        ; 0x0086	qut	K'iche	K'iche	K'iche	1252	850	GTM	QUT
    ${NSD_CB_AddString} $Locale "qut-GT"     ; 0x0486	qut-GT	K'iche (Guatemala)	K'iche	K'iche (Guatemala)	1252	850	GTM	QUT
    ${NSD_CB_AddString} $Locale "rw"         ; 0x0087	rw	Kinyarwanda	Kinyarwanda	Kinyarwanda	1252	437	RWA	KIN
    ${NSD_CB_AddString} $Locale "rw-RW"      ; 0x0487	rw-RW	Kinyarwanda (Rwanda)	Kinyarwanda	Kinyarwanda (Rwanda)	1252	437	RWA	KIN
    ${NSD_CB_AddString} $Locale "sw"         ; 0x0041	sw	Kiswahili	Kiswahili	Kiswahili	1252	437	KEN	SWK
    ${NSD_CB_AddString} $Locale "sw-KE"      ; 0x0441	sw-KE	Kiswahili (Kenya)	Kiswahili	Kiswahili (Kenya)	1252	437	KEN	SWK
    ${NSD_CB_AddString} $Locale "kok"        ; 0x0057	kok	Konkani	Konkani	कोंकणी	0	1	IND	KNK
    ${NSD_CB_AddString} $Locale "kok-IN"     ; 0x0457	kok-IN	Konkani (India)	Konkani	कोंकणी (भारत)	0	1	IND	KNK
    ${NSD_CB_AddString} $Locale "ko"         ; 0x0012	ko	Korean	Korean	한국어	949	949	KOR	KOR
    ${NSD_CB_AddString} $Locale "ko-KR"      ; 0x0412	ko-KR	Korean (Korea)	Korean	한국어 (대한민국)	949	949	KOR	KOR
    ${NSD_CB_AddString} $Locale "ky"         ; 0x0040	ky	Kyrgyz	Kyrgyz	Кыргыз	1251	866	KGZ	KYR
    ${NSD_CB_AddString} $Locale "ky-KG"      ; 0x0440	ky-KG	Kyrgyz (Kyrgyzstan)	Kyrgyz	Кыргыз (Кыргызстан)	1251	866	KGZ	KYR
    ${NSD_CB_AddString} $Locale "lo"         ; 0x0054	lo	Lao	Lao	ລາວ	0	1	LAO	LAO
    ${NSD_CB_AddString} $Locale "lo-LA"      ; 0x0454	lo-LA	Lao (Lao P.D.R.)	Lao	ລາວ (ສ.ປ.ປ. ລາວ)	0	1	LAO	LAO
    ${NSD_CB_AddString} $Locale "lv"         ; 0x0026	lv	Latvian	Latvian	latviešu	1257	775	LVA	LVI
    ${NSD_CB_AddString} $Locale "lv-LV"      ; 0x0426	lv-LV	Latvian (Latvia)	Latvian	latviešu (Latvija)	1257	775	LVA	LVI
    ${NSD_CB_AddString} $Locale "lt"         ; 0x0027	lt	Lithuanian	Lithuanian	lietuvių	1257	775	LTU	LTH
    ${NSD_CB_AddString} $Locale "lt-LT"      ; 0x0427	lt-LT	Lithuanian (Lithuania)	Lithuanian	lietuvių (Lietuva)	1257	775	LTU	LTH
    ${NSD_CB_AddString} $Locale "dsb"        ; 0x7C2E	dsb	Lower Sorbian	Lower Sorbian	dolnoserbšćina	1252	850	GER	DSB
    ${NSD_CB_AddString} $Locale "dsb-DE"     ; 0x082E	dsb-DE	Lower Sorbian (Germany)	Lower Sorbian	dolnoserbšćina (Nimska)	1252	850	GER	DSB
    ${NSD_CB_AddString} $Locale "lb"         ; 0x006E	lb	Luxembourgish	Luxembourgish	Lëtzebuergesch	1252	850	LUX	LBX
    ${NSD_CB_AddString} $Locale "lb-LU"      ; 0x046E	lb-LU	Luxembourgish (Luxembourg)	Luxembourgish	Lëtzebuergesch (Luxembourg)	1252	850	LUX	LBX
    ${NSD_CB_AddString} $Locale "mk-MK"      ; 0x042F	mk-MK	Macedonian (Former Yugoslav Republic of Macedonia)	Macedonian (FYROM)	македонски јазик (Македонија)	1251	866	MKD	MKI
    ${NSD_CB_AddString} $Locale "mk"         ; 0x002F	mk	Macedonian (FYROM)	Macedonian (FYROM)	македонски јазик	1251	866	MKD	MKI
    ${NSD_CB_AddString} $Locale "ms"         ; 0x003E	ms	Malay	Malay	Bahasa Melayu	1252	850	MYS	MSL
    ${NSD_CB_AddString} $Locale "ms-BN"      ; 0x083E	ms-BN	Malay (Brunei Darussalam)	Malay	Bahasa Melayu (Brunei Darussalam)	1252	850	BRN	MSB
    ${NSD_CB_AddString} $Locale "ms-MY"      ; 0x043E	ms-MY	Malay (Malaysia)	Malay	Bahasa Melayu (Malaysia)	1252	850	MYS	MSL
    ${NSD_CB_AddString} $Locale "ml"         ; 0x004C	ml	Malayalam	Malayalam	മലയാളം	0	1	IND	MYM
    ${NSD_CB_AddString} $Locale "ml-IN"      ; 0x044C	ml-IN	Malayalam (India)	Malayalam	മലയാളം (ഭാരതം)	0	1	IND	MYM
    ${NSD_CB_AddString} $Locale "mt"         ; 0x003A	mt	Maltese	Maltese	Malti	0	1	MLT	MLT
    ${NSD_CB_AddString} $Locale "mt-MT"      ; 0x043A	mt-MT	Maltese (Malta)	Maltese	Malti (Malta)	0	1	MLT	MLT
    ${NSD_CB_AddString} $Locale "mi"         ; 0x0081	mi	Maori	Maori	Reo Māori	0	1	NZL	MRI
    ${NSD_CB_AddString} $Locale "mi-NZ"      ; 0x0481	mi-NZ	Maori (New Zealand)	Maori	Reo Māori (Aotearoa)	0	1	NZL	MRI
    ${NSD_CB_AddString} $Locale "arn"        ; 0x007A	arn	Mapudungun	Mapudungun	Mapudungun	1252	850	CHL	MPD
    ${NSD_CB_AddString} $Locale "arn-CL"     ; 0x047A	arn-CL	Mapudungun (Chile)	Mapudungun	Mapudungun (Chile)	1252	850	CHL	MPD
    ${NSD_CB_AddString} $Locale "mr"         ; 0x004E	mr	Marathi	Marathi	मराठी	0	1	IND	MAR
    ${NSD_CB_AddString} $Locale "mr-IN"      ; 0x044E	mr-IN	Marathi (India)	Marathi	मराठी (भारत)	0	1	IND	MAR
    ${NSD_CB_AddString} $Locale "moh"        ; 0x007C	moh	Mohawk	Mohawk	Kanien'kéha	1252	850	CAN	MWK
    ${NSD_CB_AddString} $Locale "moh-CA"     ; 0x047C	moh-CA	Mohawk (Mohawk)	Mohawk	Kanien'kéha	1252	850	CAN	MWK
    ${NSD_CB_AddString} $Locale "mn"         ; 0x0050	mn	Mongolian (Cyrillic)	Mongolian (Cyrillic)	Монгол хэл	1251	866	MNG	MNN
    ${NSD_CB_AddString} $Locale "mn-Cyrl"    ; 0x7850	mn-Cyrl	Mongolian (Cyrillic)	Mongolian (Cyrillic)	Монгол хэл	1251	866	MNG	MNN
    ${NSD_CB_AddString} $Locale "mn-MN"      ; 0x0450	mn-MN	Mongolian (Cyrillic, Mongolia)	Mongolian (Cyrillic)	Монгол хэл (Монгол улс)	1251	866	MNG	MNN
    ${NSD_CB_AddString} $Locale "mn-Mong"    ; 0x7C50	mn-Mong	Mongolian (Traditional Mongolian)	Mongolian (Traditional Mongolian)	ᠮᠤᠨᠭᠭᠤᠯ ᠬᠡᠯᠡ	0	1	CHN	MNG
    ${NSD_CB_AddString} $Locale "mn-Mong-CN" ; 0x0850	mn-Mong-CN	Mongolian (Traditional Mongolian, PRC)	Mongolian (Traditional Mongolian)	ᠮᠤᠨᠭᠭᠤᠯ ᠬᠡᠯᠡ (ᠪᠦᠭᠦᠳᠡ ᠨᠠᠢᠷᠠᠮᠳᠠᠬᠤ ᠳᠤᠮᠳᠠᠳᠤ ᠠᠷᠠᠳ ᠣᠯᠣᠰ)	0	1	CHN	MNG
    ${NSD_CB_AddString} $Locale "ne"         ; 0x0061	ne	Nepali	Nepali	नेपाली	0	1	NEP	NEP
    ${NSD_CB_AddString} $Locale "ne-NP"      ; 0x0461	ne-NP	Nepali (Nepal)	Nepali	नेपाली (नेपाल)	0	1	NEP	NEP
    ${NSD_CB_AddString} $Locale "no"         ; 0x0014	no	Norwegian	Norwegian (Bokmål)	norsk	1252	850	NOR	NOR
    ${NSD_CB_AddString} $Locale "nb"         ; 0x7C14	nb	Norwegian (Bokmål)	Norwegian (Bokmål)	norsk (bokmål)	1252	850	NOR	NOR
    ${NSD_CB_AddString} $Locale "nn"         ; 0x7814	nn	Norwegian (Nynorsk)	Norwegian (Nynorsk)	norsk (nynorsk)	1252	850	NOR	NON
    ${NSD_CB_AddString} $Locale "nb-NO"      ; 0x0414	nb-NO	Norwegian, Bokmål (Norway)	Norwegian (Bokmål)	norsk, bokmål (Norge)	1252	850	NOR	NOR
    ${NSD_CB_AddString} $Locale "nn-NO"      ; 0x0814	nn-NO	Norwegian, Nynorsk (Norway)	Norwegian (Nynorsk)	norsk, nynorsk (Noreg)	1252	850	NOR	NON
    ${NSD_CB_AddString} $Locale "oc"         ; 0x0082	oc	Occitan	Occitan	Occitan	1252	850	FRA	OCI
    ${NSD_CB_AddString} $Locale "oc-FR"      ; 0x0482	oc-FR	Occitan (France)	Occitan	Occitan (França)	1252	850	FRA	OCI
    ${NSD_CB_AddString} $Locale "or"         ; 0x0048	or	Oriya	Oriya	ଓଡ଼ିଆ	0	1	IND	ORI
    ${NSD_CB_AddString} $Locale "or-IN"      ; 0x0448	or-IN	Oriya (India)	Oriya	ଓଡ଼ିଆ (ଭାରତ)	0	1	IND	ORI
    ${NSD_CB_AddString} $Locale "ps"         ; 0x0063	ps	Pashto‎	Pashto	پښتو‏	0	1	AFG	PAS
    ${NSD_CB_AddString} $Locale "ps-AF"      ; 0x0463	ps-AF	Pashto (Afghanistan)‎	Pashto	پښتو (افغانستان)‏	0	1	AFG	PAS
    ${NSD_CB_AddString} $Locale "fa"         ; 0x0029	fa	Persian‎	Persian	فارسى‏	1256	720	IRN	FAR
    ${NSD_CB_AddString} $Locale "fa-IR"      ; 0x0429	fa-IR	Persian‎	Persian	فارسى (ایران)‏	1256	720	IRN	FAR
    ${NSD_CB_AddString} $Locale "pl"         ; 0x0015	pl	Polish	Polish	polski	1250	852	POL	PLK
    ${NSD_CB_AddString} $Locale "pl-PL"      ; 0x0415	pl-PL	Polish (Poland)	Polish	polski (Polska)	1250	852	POL	PLK
    ${NSD_CB_AddString} $Locale "pt"         ; 0x0016	pt	Portuguese	Portuguese	Português	1252	850	BRA	PTB
    ${NSD_CB_AddString} $Locale "pt-BR"      ; 0x0416	pt-BR	Portuguese (Brazil)	Portuguese	Português (Brasil)	1252	850	BRA	PTB
    ${NSD_CB_AddString} $Locale "pt-PT"      ; 0x0816	pt-PT	Portuguese (Portugal)	Portuguese	português (Portugal)	1252	850	PRT	PTG
    ${NSD_CB_AddString} $Locale "pa"         ; 0x0046	pa	Punjabi	Punjabi	ਪੰਜਾਬੀ	0	1	IND	PAN
    ${NSD_CB_AddString} $Locale "pa-IN"      ; 0x0446	pa-IN	Punjabi (India)	Punjabi	ਪੰਜਾਬੀ (ਭਾਰਤ)	0	1	IND	PAN
    ${NSD_CB_AddString} $Locale "quz"        ; 0x006B	quz	Quechua	Quechua	runasimi	1252	850	BOL	QUB
    ${NSD_CB_AddString} $Locale "quz-BO"     ; 0x046B	quz-BO	Quechua (Bolivia)	Quechua	runasimi (Qullasuyu)	1252	850	BOL	QUB
    ${NSD_CB_AddString} $Locale "quz-EC"     ; 0x086B	quz-EC	Quechua (Ecuador)	Quechua	runasimi (Ecuador)	1252	850	ECU	QUE
    ${NSD_CB_AddString} $Locale "quz-PE"     ; 0x0C6B	quz-PE	Quechua (Peru)	Quechua	runasimi (Piruw)	1252	850	PER	QUP
    ${NSD_CB_AddString} $Locale "ro"         ; 0x0018	ro	Romanian	Romanian	română	1250	852	ROM	ROM
    ${NSD_CB_AddString} $Locale "ro-RO"      ; 0x0418	ro-RO	Romanian (Romania)	Romanian	română (România)	1250	852	ROM	ROM
    ${NSD_CB_AddString} $Locale "rm"         ; 0x0017	rm	Romansh	Romansh	Rumantsch	1252	850	CHE	RMC
    ${NSD_CB_AddString} $Locale "rm-CH"      ; 0x0417	rm-CH	Romansh (Switzerland)	Romansh	Rumantsch (Svizra)	1252	850	CHE	RMC
    ${NSD_CB_AddString} $Locale "ru"         ; 0x0019	ru	Russian	Russian	русский	1251	866	RUS	RUS
    ${NSD_CB_AddString} $Locale "ru-RU"      ; 0x0419	ru-RU	Russian (Russia)	Russian	русский (Россия)	1251	866	RUS	RUS
    ${NSD_CB_AddString} $Locale "smn"        ; 0x703B	smn	Sami (Inari)	Sami (Inari)	sämikielâ	1252	850	FIN	SMN
    ${NSD_CB_AddString} $Locale "smj"        ; 0x7C3B	smj	Sami (Lule)	Sami (Lule)	julevusámegiella	1252	850	SWE	SMK
    ${NSD_CB_AddString} $Locale "se"         ; 0x003B	se	Sami (Northern)	Sami (Northern)	davvisámegiella	1252	850	NOR	SME
    ${NSD_CB_AddString} $Locale "sms"        ; 0x743B	sms	Sami (Skolt)	Sami (Skolt)	sääm´ǩiõll	1252	850	FIN	SMS
    ${NSD_CB_AddString} $Locale "sma"        ; 0x783B	sma	Sami (Southern)	Sami (Southern)	åarjelsaemiengiele	1252	850	SWE	SMB
    ${NSD_CB_AddString} $Locale "smn-FI"     ; 0x243B	smn-FI	Sami, Inari (Finland)	Sami (Inari)	sämikielâ (Suomâ)	1252	850	FIN	SMN
    ${NSD_CB_AddString} $Locale "smj-NO"     ; 0x103B	smj-NO	Sami, Lule (Norway)	Sami (Lule)	julevusámegiella (Vuodna)	1252	850	NOR	SMJ
    ${NSD_CB_AddString} $Locale "smj-SE"     ; 0x143B	smj-SE	Sami, Lule (Sweden)	Sami (Lule)	julevusámegiella (Svierik)	1252	850	SWE	SMK
    ${NSD_CB_AddString} $Locale "se-FI"      ; 0x0C3B	se-FI	Sami, Northern (Finland)	Sami (Northern)	davvisámegiella (Suopma)	1252	850	FIN	SMG
    ${NSD_CB_AddString} $Locale "se-NO"      ; 0x043B	se-NO	Sami, Northern (Norway)	Sami (Northern)	davvisámegiella (Norga)	1252	850	NOR	SME
    ${NSD_CB_AddString} $Locale "se-SE"      ; 0x083B	se-SE	Sami, Northern (Sweden)	Sami (Northern)	davvisámegiella (Ruoŧŧa)	1252	850	SWE	SMF
    ${NSD_CB_AddString} $Locale "sms-FI"     ; 0x203B	sms-FI	Sami, Skolt (Finland)	Sami (Skolt)	sääm´ǩiõll (Lää´ddjânnam)	1252	850	FIN	SMS
    ${NSD_CB_AddString} $Locale "sma-NO"     ; 0x183B	sma-NO	Sami, Southern (Norway)	Sami (Southern)	åarjelsaemiengiele (Nöörje)	1252	850	NOR	SMA
    ${NSD_CB_AddString} $Locale "sma-SE"     ; 0x1C3B	sma-SE	Sami, Southern (Sweden)	Sami (Southern)	åarjelsaemiengiele (Sveerje)	1252	850	SWE	SMB
    ${NSD_CB_AddString} $Locale "sa"         ; 0x004F	sa	Sanskrit	Sanskrit	संस्कृत	0	1	IND	SAN
    ${NSD_CB_AddString} $Locale "sa-IN"      ; 0x044F	sa-IN	Sanskrit (India)	Sanskrit	संस्कृत (भारतम्)	0	1	IND	SAN
    ${NSD_CB_AddString} $Locale "gd"         ; 0x0091	gd	Scottish Gaelic	Scottish Gaelic	Gàidhlig	1252	850	GBR	GLA
    ${NSD_CB_AddString} $Locale "gd-GB"      ; 0x0491	gd-GB	Scottish Gaelic (United Kingdom)	Scottish Gaelic	Gàidhlig (An Rìoghachd Aonaichte)	1252	850	GBR	GLA
    ${NSD_CB_AddString} $Locale "sr"         ; 0x7C1A	sr	Serbian	Serbian (Latin)	srpski	1250	852	SRB	SRM
    ${NSD_CB_AddString} $Locale "sr-Cyrl"    ; 0x6C1A	sr-Cyrl	Serbian (Cyrillic)	Serbian (Cyrillic)	српски (Ћирилица)	1251	855	SRB	SRO
    ${NSD_CB_AddString} $Locale "sr-Cyrl-BA" ; 0x1C1A	sr-Cyrl-BA	Serbian (Cyrillic, Bosnia and Herzegovina)	Serbian (Cyrillic)	српски (Босна и Херцеговина)	1251	855	BIH	SRN
    ${NSD_CB_AddString} $Locale "sr-Cyrl-ME" ; 0x301A	sr-Cyrl-ME	Serbian (Cyrillic, Montenegro)	Serbian (Cyrillic)	српски (Црна Гора)	1251	855	MNE	SRQ
    ${NSD_CB_AddString} $Locale "sr-Cyrl-CS" ; 0x0C1A	sr-Cyrl-CS	Serbian (Cyrillic, Serbia and Montenegro (Former))	Serbian (Cyrillic)	српски (Србија и Црна Гора (Претходно))	1251	855	SCG	SRB
    ${NSD_CB_AddString} $Locale "sr-Cyrl-RS" ; 0x281A	sr-Cyrl-RS	Serbian (Cyrillic, Serbia)	Serbian (Cyrillic)	српски (Србија)	1251	855	SRB	SRO
    ${NSD_CB_AddString} $Locale "sr-Latn"    ; 0x701A	sr-Latn	Serbian (Latin)	Serbian (Latin)	srpski (Latinica)	1250	852	SRB	SRM
    ${NSD_CB_AddString} $Locale "sr-Latn-BA" ; 0x181A	sr-Latn-BA	Serbian (Latin, Bosnia and Herzegovina)	Serbian (Latin)	srpski (Bosna i Hercegovina)	1250	852	BIH	SRS
    ${NSD_CB_AddString} $Locale "sr-Latn-ME" ; 0x2C1A	sr-Latn-ME	Serbian (Latin, Montenegro)	Serbian (Latin)	srpski (Crna Gora)	1250	852	MNE	SRP
    ${NSD_CB_AddString} $Locale "sr-Latn-CS" ; 0x081A	sr-Latn-CS	Serbian (Latin, Serbia and Montenegro (Former))	Serbian (Latin)	srpski (Srbija i Crna Gora (Prethodno))	1250	852	SCG	SRL
    ${NSD_CB_AddString} $Locale "sr-Latn-RS" ; 0x241A	sr-Latn-RS	Serbian (Latin, Serbia)	Serbian (Latin)	srpski (Srbija)	1250	852	SRB	SRM
    ${NSD_CB_AddString} $Locale "nso"        ; 0x006C	nso	Sesotho sa Leboa	Sesotho sa Leboa	Sesotho sa Leboa	1252	850	ZAF	NSO
    ${NSD_CB_AddString} $Locale "nso-ZA"     ; 0x046C	nso-ZA	Sesotho sa Leboa (South Africa)	Sesotho sa Leboa	Sesotho sa Leboa (Afrika Borwa)	1252	850	ZAF	NSO
    ${NSD_CB_AddString} $Locale "tn"         ; 0x0032	tn	Setswana	Setswana	Setswana	1252	850	ZAF	TSN
    ${NSD_CB_AddString} $Locale "tn-ZA"      ; 0x0432	tn-ZA	Setswana (South Africa)	Setswana	Setswana (Aforika Borwa)	1252	850	ZAF	TSN
    ${NSD_CB_AddString} $Locale "si"         ; 0x005B	si	Sinhala	Sinhala	සිංහ	0	1	LKA	SIN
    ${NSD_CB_AddString} $Locale "si-LK"      ; 0x045B	si-LK	Sinhala (Sri Lanka)	Sinhala	සිංහ (ශ්‍රී ලංකා)	0	1	LKA	SIN
    ${NSD_CB_AddString} $Locale "sk"         ; 0x001B	sk	Slovak	Slovak	slovenčina	1250	852	SVK	SKY
    ${NSD_CB_AddString} $Locale "sk-SK"      ; 0x041B	sk-SK	Slovak (Slovakia)	Slovak	slovenčina (Slovenská republika)	1250	852	SVK	SKY
    ${NSD_CB_AddString} $Locale "sl"         ; 0x0024	sl	Slovenian	Slovenian	slovenski	1250	852	SVN	SLV
    ${NSD_CB_AddString} $Locale "sl-SI"      ; 0x0424	sl-SI	Slovenian (Slovenia)	Slovenian	slovenski (Slovenija)	1250	852	SVN	SLV
    ${NSD_CB_AddString} $Locale "es"         ; 0x000A	es	Spanish	Spanish	español	1252	850	ESP	ESN
    ${NSD_CB_AddString} $Locale "es-AR"      ; 0x2C0A	es-AR	Spanish (Argentina)	Spanish	Español (Argentina)	1252	850	ARG	ESS
    ${NSD_CB_AddString} $Locale "es-BO"      ; 0x400A	es-BO	Spanish (Bolivia)	Spanish	Español (Bolivia)	1252	850	BOL	ESB
    ${NSD_CB_AddString} $Locale "es-CL"      ; 0x340A	es-CL	Spanish (Chile)	Spanish	Español (Chile)	1252	850	CHL	ESL
    ${NSD_CB_AddString} $Locale "es-CO"      ; 0x240A	es-CO	Spanish (Colombia)	Spanish	Español (Colombia)	1252	850	COL	ESO
    ${NSD_CB_AddString} $Locale "es-CR"      ; 0x140A	es-CR	Spanish (Costa Rica)	Spanish	Español (Costa Rica)	1252	850	CRI	ESC
    ${NSD_CB_AddString} $Locale "es-DO"      ; 0x1C0A	es-DO	Spanish (Dominican Republic)	Spanish	Español (República Dominicana)	1252	850	DOM	ESD
    ${NSD_CB_AddString} $Locale "es-EC"      ; 0x300A	es-EC	Spanish (Ecuador)	Spanish	Español (Ecuador)	1252	850	ECU	ESF
    ${NSD_CB_AddString} $Locale "es-SV"      ; 0x440A	es-SV	Spanish (El Salvador)	Spanish	Español (El Salvador)	1252	850	SLV	ESE
    ${NSD_CB_AddString} $Locale "es-GT"      ; 0x100A	es-GT	Spanish (Guatemala)	Spanish	Español (Guatemala)	1252	850	GTM	ESG
    ${NSD_CB_AddString} $Locale "es-HN"      ; 0x480A	es-HN	Spanish (Honduras)	Spanish	Español (Honduras)	1252	850	HND	ESH
    ${NSD_CB_AddString} $Locale "es-MX"      ; 0x080A	es-MX	Spanish (Mexico)	Spanish	Español (México)	1252	850	MEX	ESM
    ${NSD_CB_AddString} $Locale "es-NI"      ; 0x4C0A	es-NI	Spanish (Nicaragua)	Spanish	Español (Nicaragua)	1252	850	NIC	ESI
    ${NSD_CB_AddString} $Locale "es-PA"      ; 0x180A	es-PA	Spanish (Panama)	Spanish	Español (Panamá)	1252	850	PAN	ESA
    ${NSD_CB_AddString} $Locale "es-PY"      ; 0x3C0A	es-PY	Spanish (Paraguay)	Spanish	Español (Paraguay)	1252	850	PRY	ESZ
    ${NSD_CB_AddString} $Locale "es-PE"      ; 0x280A	es-PE	Spanish (Peru)	Spanish	Español (Perú)	1252	850	PER	ESR
    ${NSD_CB_AddString} $Locale "es-PR"      ; 0x500A	es-PR	Spanish (Puerto Rico)	Spanish	Español (Puerto Rico)	1252	850	PRI	ESU
    ${NSD_CB_AddString} $Locale "es-ES"      ; 0x0C0A	es-ES	Spanish (Spain, International Sort)	Spanish	Español (España, alfabetización internacional)	1252	850	ESP	ESN
    ${NSD_CB_AddString} $Locale "es-US"      ; 0x540A	es-US	Spanish (United States)	Spanish	Español (Estados Unidos)	1252	850	USA	EST
    ${NSD_CB_AddString} $Locale "es-UY"      ; 0x380A	es-UY	Spanish (Uruguay)	Spanish	Español (Uruguay)	1252	850	URY	ESY
    ${NSD_CB_AddString} $Locale "es-VE"      ; 0x200A	es-VE	Spanish (Venezuela)	Spanish	Español (Republica Bolivariana de Venezuela)	1252	850	VEN	ESV
    ${NSD_CB_AddString} $Locale "sv"         ; 0x001D	sv	Swedish	Swedish	svenska	1252	850	SWE	SVE
    ${NSD_CB_AddString} $Locale "sv-FI"      ; 0x081D	sv-FI	Swedish (Finland)	Swedish	svenska (Finland)	1252	850	FIN	SVF
    ${NSD_CB_AddString} $Locale "sv-SE"      ; 0x041D	sv-SE	Swedish (Sweden)	Swedish	svenska (Sverige)	1252	850	SWE	SVE
    ${NSD_CB_AddString} $Locale "syr"        ; 0x005A	syr	Syriac‎	Syriac	ܣܘܪܝܝܐ‏	0	1	SYR	SYR
    ${NSD_CB_AddString} $Locale "syr-SY"     ; 0x045A	syr-SY	Syriac (Syria)‎	Syriac	ܣܘܪܝܝܐ (سوريا)‏	0	1	SYR	SYR
    ${NSD_CB_AddString} $Locale "tg"         ; 0x0028	tg	Tajik (Cyrillic)	Tajik (Cyrillic)	Тоҷикӣ	1251	866	TAJ	TAJ
    ${NSD_CB_AddString} $Locale "tg-Cyrl"    ; 0x7C28	tg-Cyrl	Tajik (Cyrillic)	Tajik (Cyrillic)	Тоҷикӣ	1251	866	TAJ	TAJ
    ${NSD_CB_AddString} $Locale "tg-Cyrl-TJ" ; 0x0428	tg-Cyrl-TJ	Tajik (Cyrillic, Tajikistan)	Tajik (Cyrillic)	Тоҷикӣ (Тоҷикистон)	1251	866	TAJ	TAJ
    ${NSD_CB_AddString} $Locale "tzm"        ; 0x005F	tzm	Tamazight	Tamazight (Latin)	Tamazight	1252	850	DZA	TZM
    ${NSD_CB_AddString} $Locale "tzm-Latn"   ; 0x7C5F	tzm-Latn	Tamazight (Latin)	Tamazight (Latin)	Tamazight (Latin)	1252	850	DZA	TZM
    ${NSD_CB_AddString} $Locale "tzm-Latn-DZ" ; 0x085F	tzm-Latn-DZ	Tamazight (Latin, Algeria)	Tamazight (Latin)	Tamazight (Djazaïr)	1252	850	DZA	TZM
    ${NSD_CB_AddString} $Locale "ta"         ; 0x0049	ta	Tamil	Tamil	தமிழ்	0	1	IND	TAM
    ${NSD_CB_AddString} $Locale "ta-IN"      ; 0x0449	ta-IN	Tamil (India)	Tamil	தமிழ் (இந்தியா)	0	1	IND	TAM
    ${NSD_CB_AddString} $Locale "tt"         ; 0x0044	tt	Tatar	Tatar	Татар	1251	866	RUS	TTT
    ${NSD_CB_AddString} $Locale "tt-RU"      ; 0x0444	tt-RU	Tatar (Russia)	Tatar	Татар (Россия)	1251	866	RUS	TTT
    ${NSD_CB_AddString} $Locale "te"         ; 0x004A	te	Telugu	Telugu	తెలుగు	0	1	IND	TEL
    ${NSD_CB_AddString} $Locale "te-IN"      ; 0x044A	te-IN	Telugu (India)	Telugu	తెలుగు (భారత దేశం)	0	1	IND	TEL
    ${NSD_CB_AddString} $Locale "th"         ; 0x001E	th	Thai	Thai	ไทย	874	874	THA	THA
    ${NSD_CB_AddString} $Locale "th-TH"      ; 0x041E	th-TH	Thai (Thailand)	Thai	ไทย (ไทย)	874	874	THA	THA
    ${NSD_CB_AddString} $Locale "bo"         ; 0x0051	bo	Tibetan	Tibetan	བོད་ཡིག	0	1	CHN	BOB
    ${NSD_CB_AddString} $Locale "bo-CN"      ; 0x0451	bo-CN	Tibetan (PRC)	Tibetan	བོད་ཡིག (ཀྲུང་ཧྭ་མི་དམངས་སྤྱི་མཐུན་རྒྱལ་ཁབ།)	0	1	CHN	BOB
    ${NSD_CB_AddString} $Locale "tr"         ; 0x001F	tr	Turkish	Turkish	Türkçe	1254	857	TUR	TRK
    ${NSD_CB_AddString} $Locale "tr-TR"      ; 0x041F	tr-TR	Turkish (Turkey)	Turkish	Türkçe (Türkiye)	1254	857	TUR	TRK
    ${NSD_CB_AddString} $Locale "tk"         ; 0x0042	tk	Turkmen	Turkmen	türkmençe	1250	852	TKM	TUK
    ${NSD_CB_AddString} $Locale "tk-TM"      ; 0x0442	tk-TM	Turkmen (Turkmenistan)	Turkmen	türkmençe (Türkmenistan)	1250	852	TKM	TUK
    ${NSD_CB_AddString} $Locale "uk"         ; 0x0022	uk	Ukrainian	Ukrainian	українська	1251	866	UKR	UKR
    ${NSD_CB_AddString} $Locale "uk-UA"      ; 0x0422	uk-UA	Ukrainian (Ukraine)	Ukrainian	українська (Україна)	1251	866	UKR	UKR
    ${NSD_CB_AddString} $Locale "hsb"        ; 0x002E	hsb	Upper Sorbian	Upper Sorbian	hornjoserbšćina	1252	850	GER	HSB
    ${NSD_CB_AddString} $Locale "hsb-DE"     ; 0x042E	hsb-DE	Upper Sorbian (Germany)	Upper Sorbian	hornjoserbšćina (Němska)	1252	850	GER	HSB
    ${NSD_CB_AddString} $Locale "ur"         ; 0x0020	ur	Urdu‎	Urdu	اُردو‏	1256	720	PAK	URD
    ${NSD_CB_AddString} $Locale "ur-PK"      ; 0x0420	ur-PK	Urdu (Islamic Republic of Pakistan)‎	Urdu	اُردو (پاکستان)‏	1256	720	PAK	URD
    ${NSD_CB_AddString} $Locale "ug"         ; 0x0080	ug	Uyghur‎	Uyghur	ئۇيغۇر يېزىقى‏	1256	720	CHN	UIG
    ${NSD_CB_AddString} $Locale "ug-CN"      ; 0x0480	ug-CN	Uyghur (PRC)‎	Uyghur	(ئۇيغۇر يېزىقى (جۇڭخۇا خەلق جۇمھۇرىيىتى‏	1256	720	CHN	UIG
    ${NSD_CB_AddString} $Locale "uz-Cyrl"    ; 0x7843	uz-Cyrl	Uzbek (Cyrillic)	Uzbek (Cyrillic)	Ўзбек	1251	866	UZB	UZB
    ${NSD_CB_AddString} $Locale "uz-Cyrl-UZ" ; 0x0843	uz-Cyrl-UZ	Uzbek (Cyrillic, Uzbekistan)	Uzbek (Cyrillic)	Ўзбек (Ўзбекистон)	1251	866	UZB	UZB
    ${NSD_CB_AddString} $Locale "uz"         ; 0x0043	uz	Uzbek (Latin)	Uzbek (Latin)	U'zbek	1254	857	UZB	UZB
    ${NSD_CB_AddString} $Locale "uz-Latn"    ; 0x7C43	uz-Latn	Uzbek (Latin)	Uzbek (Latin)	U'zbek	1254	857	UZB	UZB
    ${NSD_CB_AddString} $Locale "uz-Latn-UZ" ; 0x0443	uz-Latn-UZ	Uzbek (Latin, Uzbekistan)	Uzbek (Latin)	U'zbek (U'zbekiston Respublikasi)	1254	857	UZB	UZB
    ${NSD_CB_AddString} $Locale "vi"         ; 0x002A	vi	Vietnamese	Vietnamese	Tiếng Việt	1258	1258	VNM	VIT
    ${NSD_CB_AddString} $Locale "vi-VN"      ; 0x042A	vi-VN	Vietnamese (Vietnam)	Vietnamese	Tiếng Việt (Việt Nam)	1258	1258	VNM	VIT
    ${NSD_CB_AddString} $Locale "cy"         ; 0x0052	cy	Welsh	Welsh	Cymraeg	1252	850	GBR	CYM
    ${NSD_CB_AddString} $Locale "cy-GB"      ; 0x0452	cy-GB	Welsh (United Kingdom)	Welsh	Cymraeg (y Deyrnas Unedig)	1252	850	GBR	CYM
    ${NSD_CB_AddString} $Locale "wo"         ; 0x0088	wo	Wolof	Wolof	Wolof	1252	850	SEN	WOL
    ${NSD_CB_AddString} $Locale "wo-SN"      ; 0x0488	wo-SN	Wolof (Senegal)	Wolof	Wolof (Sénégal)	1252	850	SEN	WOL
    ${NSD_CB_AddString} $Locale "sah"        ; 0x0085	sah	Yakut	Yakut	саха	1251	866	RUS	SAH
    ${NSD_CB_AddString} $Locale "sah-RU"     ; 0x0485	sah-RU	Yakut (Russia)	Yakut	саха (Россия)	1251	866	RUS	SAH
    ${NSD_CB_AddString} $Locale "ii"         ; 0x0078	ii	Yi	Yi	ꆈꌠꁱꂷ	0	1	CHN	III
    ${NSD_CB_AddString} $Locale "ii-CN"      ; 0x0478	ii-CN	Yi (PRC)	Yi	ꆈꌠꁱꂷ (ꍏꉸꏓꂱꇭꉼꇩ)	0	1	CHN	III
    ${NSD_CB_AddString} $Locale "yo"         ; 0x006A	yo	Yoruba	Yoruba	Yoruba	1252	437	NGA	YOR
    ${NSD_CB_AddString} $Locale "yo-NG"      ; 0x046A	yo-NG	Yoruba (Nigeria)	Yoruba	Yoruba (Nigeria)	1252	437	NGA	YOR
  ${else}
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
  ${endif}
  ${NSD_CB_SelectString} $Locale $Locale_text

  ${NSD_CreateLabel} 0 59u 70u 24u "$(DLG_SUPERUSER)"
  Pop $Label2

  ${NSD_CreateText} 72u 57u 100u 12u "$UserName_text"
  Pop $UserName

  ${NSD_CreateLabel} 0 74u 70u 12u "$(DLG_PASS1)"
  Pop $Label2

  ${NSD_CreatePassword} 72u 72u 100u 12u $Pass1_text
  Pop $Pass1

  ${NSD_CreateLabel} 0 90u 70u 12u "$(DLG_PASS2)"
  Pop $Label2

  ${NSD_CreatePassword} 72u 88u 100u 12u $Pass2_text
  Pop $Pass2


  ${NSD_CreateCheckBox} 72u 105u 100% 12u "$(DLG_data-checksums)"
  Pop $checkBoxDataChecksums
  ${NSD_SetState} $checkBoxDataChecksums $isDataChecksums


  ;env vars
  ${NSD_CreateCheckBox} 72u 120u 100% 12u "$(DLG_ENVVAR)"
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
  ${if} $AllMem > 16000 ;>16gb
    StrCpy $work_mem "128MB"
!ifdef PG_64bit
    StrCpy $shared_buffers "1GB"
!else
    StrCpy $shared_buffers "768MB"
!endif

    StrCpy $effective_cache_size "16GB"
    return
  ${endif}

  ${if} $AllMem > 8090 ;>8gb
    StrCpy $work_mem "128MB"
    StrCpy $shared_buffers "768MB"
    StrCpy $effective_cache_size "8GB"
    return
  ${endif}
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

  ${if} $needOptimization == "1"
    ${NSD_SetState} $rButton2  ${BST_CHECKED}
  ${else}
    ${NSD_SetState} $rButton1  ${BST_CHECKED}
  ${endif}

  ${NSD_CreateCheckBox} 20u 100u 100% 12u "$(MORE_SHOW_MORE)"
  Pop $checkBoxMoreOptions
  ${NSD_SetState} $checkBoxMoreOptions $isShowMoreOptions


  GetFunctionAddress $0 nsDialogsOptimizationPageLeave
  nsDialogs::OnBack $0

  nsDialogs::Show
FunctionEnd

Function nsDialogsOptimizationPageLeave
  ${NSD_GetState} $rButton2 $0
  
  ${if} $0 == ${BST_CHECKED}
    StrCpy  $needOptimization "1"
  ${else}
    StrCpy $needOptimization "0"
  ${endif}
  
  ${NSD_GetState} $checkBoxMoreOptions $isShowMoreOptions
FunctionEnd

Function SetDefaultTcpPort
  ; tcp-port auto selector
  StrCpy $TextPort_text "${PG_DEF_PORT}"
  ${while} 1 = 1
    ${if} ${TCPPortOpen} $TextPort_text
      IntOp $TextPort_text $TextPort_text + 1
    ${else}
      ${exitwhile}
    ${endif}
  ${endwhile}
FunctionEnd

/*
!macro GetUIId UN
Function ${UN}GetUIId
  System::Call 'kernel32::GetUserDefaultUILanguage() i.r10'
  Push $R0
FunctionEnd
!macroend
!insertmacro GetUIId ""
!insertmacro GetUIId "un."
*/

Function .onInit
  Call CheckWindowsVersion
  Call SetDefaultTcpPort

!ifdef PG_64bit
${IfNot} ${RunningX64}
MessageBox MB_OK|MB_ICONSTOP "This version can be installed only on 64-bit Windows!"
Abort
${EndIf}
!endif
  IntOp $3 ${SF_SELECTED} | ${SF_RO}
  SectionSetFlags ${secClient} $3


  ;SectionSetFlags ${secClient} ${SF_RO}
/*  Call GetUIId
  pop $R0
  ${if} $R0 == "1049"
        !define MUI_LANGDLL_ALLLANGUAGES
        !insertmacro MUI_LANGDLL_DISPLAY ;select language
  ${endif}
*/
  CheckLang::CheckLang "0419"
  pop $R0
  ${if} $R0 == "1"
        !define MUI_LANGDLL_ALLLANGUAGES
        !insertmacro MUI_LANGDLL_DISPLAY ;select language
  ${endif}



  StrCpy $PG_OLD_DIR ""
  StrCpy $DATA_DIR "$INSTDIR\data"
  StrCpy $OLD_DATA_DIR ""

  StrCpy $UserName_text "${PG_DEF_SUPERUSER}"

  StrCpy $ServiceAccount_text "${PG_DEF_SERVICEACCOUNT}"
  StrCpy $ServiceID_text "${PG_DEF_SERVICEID}"
  StrCpy $Version_text "${PG_DEF_VERSION}"
  StrCpy $Branding_text "${PG_DEF_BRANDING}"

  StrCpy $checkNoLocal_state ${BST_CHECKED}
  StrCpy $isEnvVar ${BST_UNCHECKED} ;${BST_CHECKED}
  StrCpy $isDataChecksums ${BST_CHECKED} ;${BST_CHECKED}
  StrCpy $isShowMoreOptions ${BST_UNCHECKED} ;${BST_CHECKED}

  StrCpy $Coding_text "UTF8" ;"UTF-8"
  
  StrCpy $Collation_text $(DEF_COLATE_NAME)

  UserMgr::GetCurrentDomain
  Pop $0
  UserMgr::GetCurrentUserName
  Pop $1
  StrCpy $loggedInUser  "$0\$1"

  StrCpy $loggedInUserShort "$1"

  ;AccessControl::GetCurrentUserName
  ;Pop $0 ; or "error"
  ;MessageBox MB_OK "$0"
  StrCpy $needOptimization "1"

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

; ReadINIStr $1 $0 options service
;  ${if} "$1" == "no"
;   SectionGetFlags ${secService} $3
;   IntOp $3 $3 & ${SECTION_OFF}
;   SectionSetFlags ${secService} $3
; ${endif}
;  ${if} "$1" == "yes"
;   StrCpy $service "YES"
; ${endif}

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
  
  ReadINIStr $1 $0 options needoptimization
  ${if} "$1" != ""
    StrCpy $needOptimization "$1"
  ${endif}
  

  ReadINIStr $1 $0 options datachecksums
  ${if} "$1" != ""
    StrCpy $isDataChecksums "$1"
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
  ;${if} ${SectionIsSelected} ${secClient}
  ;      return
  ;${endif}
  
  ${Unless} ${SectionIsSelected} ${sec1}
  ${AndUnless} ${SectionIsSelected} ${secClient}
    Abort
  ${EndUnless}
  ${if} $PG_OLD_DIR != "" ;exist PG install
    Abort
  ${endif}
FunctionEnd

Function CheckWindowsVersion
  ${If} ${SDK} != "SDK71"
    ${Unless} ${AtLeastWin2008}
	MessageBox MB_OK|MB_ICONINFORMATION $(MESS_UNSUPPORTED_WINDOWS)
	Abort
    ${EndUnless}
  ${EndIf}
FunctionEnd


Function  .onSelChange
  ;MessageBox MB_OK|MB_ICONINFORMATION $0
  ${if} $0 == ${sec1}
  ${orif} $0 == ${serverGroup}
        SectionGetFlags ${sec1} $1
        ;IntOp $1 ${SF_SELECTED}
        ;SectionSetFlags 2 ${SF_SELECTED} | ${SF_RO}
        ${if} $1 == ${SF_SELECTED}
              IntOp $3 ${SF_SELECTED} | ${SF_RO}
              SectionSetFlags ${secClient} $3
              ;SectionSetFlags ${secClient} ${SF_RO}
        ${else}
              SectionSetFlags ${secClient} ${SF_SELECTED}
        ${endif}
         
  ${endif}
FunctionEnd

Function checkServiceIsRunning
  nsExec::ExecToStack /TIMEOUT=10000 'sc query "$ServiceID_text"'
  pop $0
  pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
  ${if} $0 != '0'
        push ""
        return
  ${endif}

  ${StrContains} $2 "RUNNING" "$1"
  ${if} $2 == ""
        push ""
        return
  ${endif}
  push "1"

FunctionEnd

Function IsServerSection
        SectionGetFlags ${sec1} $1
        ${if} $1 == ${SF_SELECTED}
              push "1"
        ${else}
               push "0"
        ${endif}

FunctionEnd


Function nsDialogMore

  ${Unless} ${SectionIsSelected} ${sec1}
    Abort
  ${EndUnless}

  ${if} $isShowMoreOptions != ${BST_CHECKED}
    Abort
  ${endif}

  nsDialogs::Create 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}

#!define PG_DEF_SERVICEACCOUNT "NT AUTHORITY\NetworkService"
#!define PG_DEF_SERVICEID "postgrespro-enterprise-X64-9.6"
#isu

${NSD_CreateGroupBox} 0 0 100% 70u "$(MORE_SERVICE_TITLE)"
    Pop $0

  ${NSD_CreateLabel} 10u 12u 120u 16u "$(MORE_WINUSER)"
  Pop $Label

  ${NSD_CreateText} 130u 14u 160u 12u "$ServiceAccount_text"
  Pop $ServiceAccount_editor

  ${NSD_CreateLabel} 10u 32u 120u 12u "$(MORE_WINPASS)"
  Pop $Label

  ${NSD_CreatePassword} 130u 30u 160u 12u $servicePassword_text
  Pop $servicePassword_editor


  ${NSD_CreateLabel} 10u 52u 120u 16u "$(MORE_SERVICE_NAME)"
  Pop $Label

  ${NSD_CreateText} 130u 50u 160u 12u "$ServiceID_text"
  Pop $ServiceID_editor

;  ${if} ${PG_MAJOR_VERSION} >= "10"
;        ${NSD_CreateLabel} 10u 82u 120u 16u "$(MORE_COLATION)"
;        Pop $Label

;        ${NSD_CreateDropList} 130u 80u 100u 12u ""
;        Pop $Collation_editor
;        ${NSD_CB_AddString} $Collation_editor "$(DEF_COLATE_NAME)"
;        ${NSD_CB_AddString} $Collation_editor "icu"
;        ${NSD_CB_AddString} $Collation_editor "libc"
;        ${NSD_CB_SelectString} $Collation_editor $Collation_text
;  ${endif}

  nsDialogs::Show
  
FunctionEnd

Function nsDialogsMorePageLeave
  ${NSD_GetText} $ServiceAccount_editor $ServiceAccount_text
  ${NSD_GetText} $servicePassword_editor $servicePassword_text
  ${NSD_GetText} $ServiceID_editor $ServiceID_text
;  ${if} ${PG_MAJOR_VERSION} >= "10"
;      ${NSD_GetText} $Collation_editor $Collation_text
;  ${endif}


FunctionEnd

Function un.onInit
  CheckLang::CheckLang "0419"
  pop $R0
  ${if} $R0 == "1"
        !insertmacro MUI_LANGDLL_DISPLAY ;select language
  ${endif}

  /*Call un.GetUIId
  pop $R0
  ${if} $R0 == "1049"
        ;!define MUI_LANGDLL_ALLLANGUAGES
        !insertmacro MUI_LANGDLL_DISPLAY ;select language
  ${endif}*/

FunctionEnd