;Unicode fALSE
;NSIS Modern User Interface
;PostgeSQL install Script
;Written by Victor Spirin for Postgrespro.ru
;used plugins: AccessControl, UserMgr
;внес изменения в файл Russian.nsh:
;!insertmacro LANGFILE "Russian" = "Русский" = ;"Russkij"
;!insertmacro LANGFILE "Czech" = "Cestina" =
!define PG_64bit

!ifdef PG_64bit
!include "postgres64.nsh"
!else
!include "postgres32.nsh"
!endif

!define PG_EDB 
;!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
;!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; Adempiere defines
;!define SOURCE_FILE_DIR "..\..\AdempiereFiles"
;!define INSTALLER_SOURCE_DIR "."
;!define OUT_DIR ${SOURCE_FILE_DIR}

; JDK defines
;!define JDK_DEFAULT_DIR "$PROGRAMFILES\Java"
;!define JDK_INSTALLER "java6.exe"

; PostgreSQL defines
;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "logiclib.nsh"

;!include "FileFunc.nsh"
!include "WordFunc.nsh"
!include "TextFunc.nsh"
; !insertmacro Locate
; ${FILEFUNC_VERBOSE} 4   # all verbosity
;!include "StrFunc.nsh"

!include "StrRep.nsh"

;!include "StrFunc.nsh"

!include "ReplaceInFile.nsh"
!include "common_macro.nsh"
!include "Utf8Converter.nsh"
!include "x64.nsh"
;!include "StrStrAdvFunc.nsh"
!include "add_to_path.nsh"

 !insertmacro VersionCompare



;--------------------------------
;General
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "${PRODUCT_NAME}_${PG_DEF_VERSION_SHORT}_${PG_INS_SUFFIX}"

!ifdef PG_64bit
InstallDir "$PROGRAMFILES64\${PRODUCT_NAME}\${PG_DEF_VERSION_SHORT}"
!else
InstallDir "$PROGRAMFILES32\${PRODUCT_NAME}\${PG_DEF_VERSION_SHORT}"
!endif
BrandingText "PostgresPRO.ru"


;Get installation folder from registry if available
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""

;ShowInstDetails show
;ShowUnInstDetails show
;Request application privileges for Windows Vista
RequestExecutionLevel admin

;Var pgRegKey ;"SOFTWARE\PostgreSQL\Installations\postgresql-9.4"
Var Dialog
Var Label
Var Label2
Var TextPort
Var checkNoLocal
Var Locale
Var Coding
Var UserName
Var Pass1
Var Pass2

Var DATA_DIR  ;path to data
Var ADMIN_DIR ;path to pgAdmin

Var TextPort_text
Var IsTextPortInIni
Var checkNoLocal_state
Var Locale_text
Var Coding_text
Var UserName_text
Var Pass1_text
Var Pass2_text

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

/*
!include x64.nsh
And use this if:

${If} ${RunningX64}
    # 64 bit code
${Else}
    # 32 bit code
${EndIf}
*/

;MUI_COMPONENTSPAGE_SMALLDESC or MUI_COMPONENTSPAGE_NODESC
 !define MUI_COMPONENTSPAGE_SMALLDESC

;--------------------------------
;Interface Settings

  !define MUI_HEADERIMAGE
  ;!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\win.bmp" ; optional
  !define MUI_HEADERIMAGE_BITMAP "pp_header.bmp" ; optional
  !define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\win-install.ico"
  !define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\win-uninstall.ico"
  !define MUI_WELCOMEFINISHPAGE_BITMAP "265px-African_Bush_Elephant.bmp"
  !define MUI_UNWELCOMEFINISHPAGE_BITMAP "64985_slon_druzya_devochka-1024x787.bmp"


  !define MUI_ABORTWARNING

;--------------------------------
;Pages
	;Page custom nsDialogsPage


   !insertmacro MUI_PAGE_WELCOME
  ;!insertmacro MUI_PAGE_LICENSE "License.txt" ComponentShow




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

  ;PageEx directory
  ; PageCallbacks dirPreAdmin
  ; DirVar $ADMIN_DIR
  ; DirText "$(dirAdminDesc)" "Каталог для установки pgAdmin III" "Обзор"
  ;PageExEnd


Page custom nsDialogServer nsDialogsServerPageLeave
Page custom nsDialogOptimization nsDialogsOptimizationPageLeave


  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM"
  ;PRODUCT_DIR_REGKEY "Software\PostgresPro\PostgreSQL\9.5"
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
;Installer Sections

Section "Microsoft Visual C++ 2013 Redistibutable" secMS


	GetTempFileName $1
!ifdef PG_64bit
	File /oname=$1 vcredist_x64.exe
!else
	File /oname=$1 vcredist_x86.exe
!endif

	ExecWait "$1  /passive /norestart" $0
        DetailPrint "Visual C++ Redistributable Packages return $0"
        Delete $1

SectionEnd

Section "PostgreSQL Server" sec1



        ;MessageBox MB_OK $TextPort_text
        ;Abort

!ifdef PG_EDB
       ;переключаем вывод консольных приложений на английский, так как есть проблемы с отображением
       StrCpy $R0 C
       System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("LANG", R0).r0'
!endif


        ${if} $PG_OLD_DIR != "" ;exist PG install
		MessageBox MB_YESNO|MB_ICONQUESTION  "$(MESS_STOP_SERVER)" IDYES doitStop IDNO noyetStop ;"Вы не ввели пароль!$\n$\nПодтверждаете установку без пароля?"
		noyetStop:
  		       Return
		doitStop:


              ;stop server
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

        CreateDirectory "$INSTDIR\scripts"
        
        File  "/oname=$INSTDIR\scripts\pg-psql.ico" "pg-psql.ico"
        File  "/oname=$INSTDIR\doc\pg-help.ico" "pg-help.ico"
        

;!ifdef PG_64bit
;        File /r ".\pgsql64\*.*"
;!else
;        File /r ".\pgsql\*.*"
;!endif

        
        ;Store installation folder
        WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" $INSTDIR
  
        ;Create uninstaller
        WriteUninstaller "$INSTDIR\Uninstall.exe"


        ; write uninstall strings
        ;лучше использовать PG_DEF_BRANDING вместо $StartMenuFolder? а имя $StartMenuFolder не запрашивать
        WriteRegExpandStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "InstallLocation" "$INSTDIR"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "DisplayName" "$StartMenuFolder"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "DisplayVersion" "${PG_DEF_VERSION}"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "Publisher" "PostgreSQL Global Development Group"
        WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "EstimatedSize" 1024

        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "HelpLink" "http://www.postgresql.org/docs"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "Comments" "The PostgreSQL RDBMS, version ${PG_DEF_VERSION}, packaged by PostgresPro.ru"
        WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}" "UrlInfoAbout" "http://www.postgresql.org/"


        ClearErrors
        FileOpen $0 $INSTDIR\scripts\reload.bat w
        IfErrors creatBatErr
        ;FileWrite $0 'echo off$\r$\nSET LANG=C$\r$\n"$INSTDIR\bin\pg_ctl.exe" reload -D "$DATA_DIR"$\r$\npause'
        FileWrite $0 'echo off$\r$\n"$INSTDIR\bin\pg_ctl.exe" reload -D "$DATA_DIR"$\r$\npause'
        FileClose $0
        creatBatErr:

        ClearErrors
        FileOpen $0 $INSTDIR\scripts\runpgsql.bat w
        IfErrors creatBatErr2
        
        ;FileWrite $0 'echo off$\r$\nSET LANG=C$\r$\nchcp 1251$\r$\n"$INSTDIR\bin\psql.exe" -h localhost -U "$UserName_text" -d postgres -p $TextPort_text $\r$\npause'
        FileWrite $0 'echo off$\r$\nchcp 1251$\r$\n"$INSTDIR\bin\psql.exe" -h localhost -U "$UserName_text" -d postgres -p $TextPort_text $\r$\npause'
        FileClose $0
        creatBatErr2:


        ClearErrors
        FileOpen $0 $INSTDIR\scripts\restart.bat w
        IfErrors creatBatErr3
        ;FileWrite $0 'echo off$\r$\nSET LANG=C$\r$\n"$INSTDIR\bin\pg_ctl.exe" stop -D "$DATA_DIR" -m fast $\r$\nsc start "$ServiceID_text" $\r$\npause'
        FileWrite $0 'echo off$\r$\n"$INSTDIR\bin\pg_ctl.exe" stop -D "$DATA_DIR" -m fast $\r$\nsc start "$ServiceID_text" $\r$\npause'
        FileClose $0
        creatBatErr3:

        ClearErrors
        FileOpen $0 $INSTDIR\scripts\stop.bat w
        IfErrors creatBatErr4
        ;FileWrite $0 'echo off$\r$\nSET LANG=C$\r$\n"$INSTDIR\bin\pg_ctl.exe" stop -D "$DATA_DIR" -m fast $\r$\npause'
        FileWrite $0 'echo off$\r$\n"$INSTDIR\bin\pg_ctl.exe" stop -D "$DATA_DIR" -m fast $\r$\npause'
        FileClose $0
        creatBatErr4:

        ClearErrors
        FileOpen $0 $INSTDIR\scripts\start.bat w
        IfErrors creatBatErr5
        ;FileWrite $0 'echo off$\r$\nSET LANG=C$\r$\nsc start "$ServiceID_text" $\r$\npause'
        FileWrite $0 'echo off$\r$\nsc start "$ServiceID_text" $\r$\npause'
        FileClose $0
        creatBatErr5:

        ;for all users
        SetShellVarContext all

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

    ${if} ${FileExists} "$INSTDIR\scripts\runpgsql.bat"
           CreateShortCut "$SMPROGRAMS\$StartMenuFolder\SQL Shell (psql).lnk" "$INSTDIR\scripts\runpgsql.bat" "" "$INSTDIR\scripts\pg-psql.ico" "0" "" "" "PostgreSQL command line utility"
           ; хотел бюы set NT_CONSOLE_PROPS for shortcut font Lucida Console
           ;You can set that in the registry under "HKEY_CURRENT_USER\Console", the value is "FaceName". If you are creating a desktop shortcut, 'IShellLink' along with 'IShellLinkDataList' will allow you to specify that in a NT_CONSOLE_PROPS structure.
           ;C:_Program Files_Far_Far.exe
           ;"C:_Program Files_PostgreSQL_9.5_scripts_runpgsql.bat"
    ${else}
           CreateShortCut "$SMPROGRAMS\$StartMenuFolder\SQL Shell (psql).lnk" "$INSTDIR\bin\psql.exe" "-h localhost -U $UserName_text -d postgres -p $TextPort_text" "" "" "" "" "PostgreSQL command line utility"
    ${endif}


    ReadRegStr $0 HKCU "Console\SQL Shell (psql)" "FaceName"
    ${if} $0 == ""
          WriteRegStr HKCU "Console\SQL Shell (psql)" "FaceName" "Lucida Console"
          WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontWeight" "400" ;обязательно
          WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontSize" "917504" ;не обязательно
          WriteRegDWORD HKCU "Console\SQL Shell (psql)" "FontFamily" "54" ;не обязательно
        
    ${endif}


    ;CreateShortCut "$SMPROGRAMS\$StartMenuFolder\pgAdmin III.lnk" "$INSTDIR\bin\pgAdmin3.exe" "" "" "" "" "" "PostgreSQL administration utility"


    ;C:\Windows\system32\cscript.exe //NoLogo "C:/Program Files (x86)/PostgreSQL/9.4\scripts\serverctl.vbs" reload wait
    ;iRet = DoCmd("""C:/Program Files (x86)/PostgreSQL/9.4\bin\pg_ctl.exe"" -D ""C:\Program Files (x86)\PostgreSQL\9.4\data"" reload")


    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Reload Configuration.lnk" "$INSTDIR\scripts\reload.bat" ""  "" "" "" "" "Reload PostgreSQL configuration"

    push "$SMPROGRAMS\$StartMenuFolder\Reload Configuration.lnk"
    call ShellLinkSetRunAs
    pop $0
    ;DetailPrint HR=$0


    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Restart Server.lnk" "$INSTDIR\scripts\restart.bat" ""  "" "" "" "" "Restart PostgreSQL server"

    push "$SMPROGRAMS\$StartMenuFolder\Restart Server.lnk"
    call ShellLinkSetRunAs
    pop $0
    ;DetailPrint HR=$0

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
    "$SMPROGRAMS\$StartMenuFolder\Documentation\PostgreSQL documentation" \
    "$INSTDIR\doc\postgresql\html\index.html" \
    "$INSTDIR\doc\pg-help.ico" "0"

    !insertmacro CreateInternetShortcut \
    "$SMPROGRAMS\$StartMenuFolder\Documentation\PostgreSQL release notes" \
    "$INSTDIR\doc\postgresql\html\release.html" \
    "$INSTDIR\doc\pg-help.ico" "0"

    ;CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Documentation\pgAdmin documentation (English).lnk" "$INSTDIR\pgAdmin III\docs\en_US\pgadmin3.chm"


    ;CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Reload Configuration.lnk" "$INSTDIR\bin\pg_ctl.exe" '-D "$DATA_DIR" reload'  "" "" "" "" "Reload PostgreSQL configuration"

  !insertmacro MUI_STARTMENU_WRITE_END


        ;AccessControl::GrantOnFile "$INSTDIR" "(BU)" "FullAccess" ; ;GenericWrite
        ;Pop $0 ;"ok" or "error" + error details
        
        ;;;AccessControl::GrantOnFile "$INSTDIR" "$ServiceAccount_text" "FullAccess"
        ;;;Pop $0 ;"ok" or "error" + error details
        ;;;AccessControl::GrantOnFile "$INSTDIR" "$loggedInUser" "FullAccess" ;"GenericRead + GenericExecute" ;GenericWrite
        ;;;Pop $0 ;"ok" or "error" + error details

        ;AccessControl::GetCurrentUserName
        ;Pop $Username ; or "error"
        ;MessageBox MB_OK "AccessControl::GetCurrentUserName: $Username"
        
        ;AccessControl::GrantOnFile [/NOINHERIT] <filename> <trustee> <permissions>
        ;AccessControl::SetFileOwner \ ;ok work
    ;"$INSTDIR\bin\readme.txt" "$ServiceAccount_text"

    ;ok work
    ;System::Call "advapi32::GetUserName(t .r0, *i ${NSIS_MAX_STRLEN} r1) i.r2"
    ;MessageBox MB_OK "User name: $0 | Number of characters: $1 | Return value (OK if non-zero): $2"
    
    ;check plugin
    ;MessageBox MB_OK $loggedInUser

        ;create data folder
        ;...

        /*${If} ${FileExists} "$DATA_DIR\*.*"
              ; file is a directory
              ;MessageBox MB_OK|MB_ICONINFORMATION "Папка для данных $DATA_DIR уже существуют!"
              DetailPrint "Папка для данных $DATA_DIR уже существуют!"
              ;надо бы номер порта из настроек взять
              
              StrCpy $isDataDirExist 1
        ${ElseIf} ${FileExists} "$DATA_DIR"
                 ; file is a file - error ?
                 ;MessageBox MB_OK|MB_ICONINFORMATION "Файл с именем $DATA_DIR уже существуют! Не могу создать папку!"
                 DetailPrint "Файл с именем $DATA_DIR уже существуют! Не могу создать папку!"
        ${Else}
           ; file is neither a file or a directory (i.e. it doesn't exist)
           CreateDirectory "$DATA_DIR"

        ${EndIf} */
        
        
   ; Create data dir begin
   ${if} $isDataDirExist == 0
        CreateDirectory "$DATA_DIR"

        ;AccessControl::GrantOnFile "$DATA_DIR" "(BU)" "FullAccess" ;GenericWrite
        ;Pop $0 ;"ok" or "error" + error details
        
        ;;;AccessControl::GrantOnFile "$DATA_DIR" "$ServiceAccount_text" "FullAccess"
        ;;;Pop $0 ;"ok" or "error" + error details
        ;;;AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUser" "FullAccess" ;GenericWrite
        ;;;Pop $0 ;"ok" or "error" + error details

        AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUserShort" "FullAccess" ;GenericWrite
        Pop $0 ;"ok" or "error" + error details


        ;cacls C:\OWS\DB\*.* /G Пользователи:F
        
        ;ExecWait 'cacls "$INSTDIR" /E /G "$ServiceAccount_text:R"' $0
        ;DetailPrint "some program returned $0"

        StrCpy $tempVar ""
        ${if} "$Pass1_text" != ""
                ;create file with password from $Pass1_text
                GetTempFileName $tempFileName "$INSTDIR\bin"
                ;StrCpy $tempFileName $INSTDIR\bin\pwddd.txt
                ;ClearErrors
                FileOpen $R0 $tempFileName w
                ;IfErrors erroropenfile
                ;need utf-8 проблема с паролем русскими буквами - в psql не проходят, в pgAdmin проходят
                ${AnsiToUtf8} $Pass1_text $0
                ;FileWrite $R0 $Pass1_text
                FileWrite $R0 $0
                FileClose $R0
                ;DetailPrint "Save password to $tempFileName"
                StrCpy $tempVar ' --pwfile "$tempFileName"  -A md5 '
        ${endif}


;if strLocale = "DEFAULT" Then
;    iRet = DoCmd("""" & strInstallDir & "\bin\initdb.exe"" --pwfile """ & strInitdbPass & """ --encoding=UTF-8 -A md5 -U " & strUsername & " -D """ & strDataDir & """")
;Else
;    iRet = DoCmd("""" & strInstallDir & "\bin\initdb.exe"" --pwfile """ & strInitdbPass & """ --locale=""" & strLocale & """ --encoding=UTF-8 -A md5 -U " & strUsername & " -D """ & strDataDir & """")
;End If


     DetailPrint "Database initialization ..."
     ;initdb запускается от имени текущего пользователя, а не от админитсратора, нужны права на папку с данными
     ;$loggedInUser с доменом не проходит, $loggedInUserShort проходит. надо тестировать со входом через домен
     AccessControl::GetCurrentUserName
     Pop $0 ; or "error"
     AccessControl::GrantOnFile "$DATA_DIR" "$0" "FullAccess" ;GenericWrite
     Pop $0 ;"ok" or "error" + error details

     ${if} "$Locale_text" == "$(DEF_LOCALE_NAME)"

        ; Initialise the database cluster, and set the appropriate permissions/ownership
        ;nsExec::ExecToStack '"$INSTDIR\bin\initdb.exe" --pwfile "$tempFileName"
        nsExec::ExecToStack '"$INSTDIR\bin\initdb.exe" $tempVar \
        --encoding=$Coding_text -U "$UserName_text" \
        -D "$DATA_DIR"'
     ${else}
        nsExec::ExecToStack /TIMEOUT=60000 '"$INSTDIR\bin\initdb.exe" $tempVar \
        --locale="$Locale_text" \
        --encoding=$Coding_text -U "$UserName_text" \
        -D "$DATA_DIR"'
     ${endif}

        
        pop $0
        Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
        DetailPrint "initdb.exe return $0"
        ${if} $0 != 0
              DetailPrint "Output: $1"
              Sleep 5000
        ${endif}

        ;--locale=
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
              ${else}
                     !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#listen_addresses = 'localhost'" "listen_addresses = 'localhost'"
              ${EndIf}
              !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#port = 5432" "port = $TextPort_text"
              !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#log_destination = 'stderr'" "log_destination = 'stderr'"
              !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#logging_collector = off" "logging_collector = on"
              !insertmacro _ReplaceInFile "$DATA_DIR\postgresql.conf" "#log_line_prefix = ''" "log_line_prefix = '%t '"
        ;${else}
                ;ConfigWrite do not use, need replace comment string
                ;${ConfigWrite} "$DATA_DIR\postgresql.conf" "port = " $TextPort_text $R0
                
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

        
        Call WriteInstallOptions


        DetailPrint "Service $ServiceID_text registration ..."
        nsExec::ExecToStack '"$INSTDIR\bin\pg_ctl.exe" register -N "$ServiceID_text" -U "$ServiceAccount_text" -D "$DATA_DIR" -w'
        Pop $0 # return value/error/timeout
        Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
        DetailPrint "pg_ctl.exe register return $0"
        ${if} $0 != 0
              DetailPrint "Output: $1"
              Sleep 5000
        ${endif}

        ;call for NT AUTHORITY\NetworkService without password
        ;ExecWait '"$INSTDIR\bin\pg_ctl.exe" register -N "$ServiceID_text" -U "$ServiceAccount_text" -D "$DATA_DIR" -w' $0
        ;DetailPrint "pg_ctl.exe register return $0"
        

        ;Write the DisplayName manually
        WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\$ServiceID_text" "DisplayName" "$ServiceID_text - PostgreSQL Server ${PG_DEF_VERSION_SHORT}"
        WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\$ServiceID_text" "Description" "Provides relational database storage."
        
        AccessControl::GrantOnFile "$DATA_DIR" "$ServiceAccount_text" "FullAccess"
        Pop $0 ;"ok" or "error" + error details
        AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUser" "FullAccess" ;GenericWrite
        Pop $0 ;"ok" or "error" + error details
        AccessControl::GrantOnFile "$DATA_DIR" "$loggedInUserShort" "FullAccess" ;GenericWrite
        Pop $0 ;"ok" or "error" + error details


        ;ExecWait 'CMD "$INSTDIR\bin\pg_ctl.exe" start -D "$DATA_DIR" -w /C' $0


        ;ExecWait '"$INSTDIR\bin\pg_ctl.exe" start -D "$DATA_DIR"' $0
        ;DetailPrint "pg_ctl.exe start return $0"

        ;AccessControl::GrantOnFile "$DATA_DIR\bin" "$loggedInUser" "GenericRead + GenericExecute" ;GenericWrite
        ;Pop $0 ;"ok" or "error" + error details

        ;на всякий случай даем права
        ;AccessControl::GrantOnFile "$INSTDIR" "(BU)" "FullAccess" ; ;GenericWrite
        ;Pop $0 ;"ok" or "error" + error details

        ;;;AccessControl::GrantOnFile "$INSTDIR" "$ServiceAccount_text" "FullAccess"
        ;;;Pop $0 ;"ok" or "error" + error details
        ;;;AccessControl::GrantOnFile "$INSTDIR" "$loggedInUser" "FullAccess" ;"GenericRead + GenericExecute" ;GenericWrite
        ;;;Pop $0 ;"ok" or "error" + error details

        AccessControl::GrantOnFile "$INSTDIR" "$ServiceAccount_text" "GenericRead + GenericExecute"
        Pop $0 ;"ok" or "error" + error details
        /*AccessControl::GrantOnFile "$INSTDIR" "$loggedInUser" "FullAccess" ;"GenericRead + GenericExecute" ;GenericWrite
        Pop $0 ;"ok" or "error" + error details
        */

        AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$ServiceAccount_text" "FullAccess"
        Pop $0 ;"ok" or "error" + error details
        AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$loggedInUser" "FullAccess" ;"GenericRead + GenericExecute" ;GenericWrite
        Pop $0 ;"ok" or "error" + error details
        AccessControl::GrantOnFile "$DATA_DIR\postgresql.conf" "$loggedInUserShort" "FullAccess" ;GenericWrite
        Pop $0 ;"ok" or "error" + error details

        AccessControl::GrantOnFile "$INSTDIR\scripts" "$loggedInUser" "FullAccess"
        Pop $0 ;"ok" or "error" + error details


        DetailPrint "Start server service..."
        Sleep 1000 ;на всякий случай, если регистрация сервера асинхронна
        ;nsExec::ExecToStack '"$INSTDIR\bin\pg_ctl.exe" start -D "$DATA_DIR" -w' ;start is running by cmd, service run needing
        ;nsExec::ExecToStack '"$INSTDIR\bin\pg_ctl.exe" runservice -D "$DATA_DIR" -w' ;error code 1063
        nsExec::ExecToStack 'sc start "$ServiceID_text"'
        Pop $0 # return value/error/timeout
        Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
        DetailPrint "Start service return $0"
        ${if} $0 != 0
                DetailPrint "Output: $1"
                Sleep 5000
        ${endif}
        
        ;ExecWait 'cscript //NoLogo "$INSTDIR\bin\startserver.vbs" "$ServiceID_text"' $0
        ;DetailPrint "startserver.vbs return $0"

        ;ExecWait 'cscript //NoLogo "$INSTDIR\bin\loadmodules.vbs" "$UserName_text" "$Pass1_text" "$INSTDIR" "$DATA_DIR" "$TextPort_text" ' $0
        ;DetailPrint "loadmodules.vbs return $0"


        ;Sleep 3000
        ;после этого остатется висеть окно, если закрыть, то сервер останавливается
        ;попробовать restart и sc
        ;exitcode = start_postmaster(); -p PATH-TO-POSTGRES    normally not necessary

        ;ExecWait 'sc start "$ServiceID_text"' $0
        ;DetailPrint "sc start return $0"

        ;sc start PostgreSQL
        ;"C:\Program Files\PostgreSQL\9.5\bin\pg_ctl.exe" start -D "C:\Program Files\PostgreSQL\9.5\data" -w
        ;"C:\Program Files\PostgreSQL\9.5\bin\pg_ctl.exe" unregister -N "postgresql-9.5" -

        ;временно - пока не разобрался, запрашивает пароль
        ;ExecWait '"$INSTDIR\bin\psql.exe" -p $TextPort_text -U "$UserName_text" -c "CREATE EXTENSION adminpack;" postgres' $0
        ;DetailPrint "psql.exe return $0"
        
        ;ReadEnvStr $R1 "PGPASSWORD"
        ;MessageBox MB_OK "Set PGPASSWORD: $R1"

        ${if} $isDataDirExist == 0
              ;send password to Environment Variable PGPASSWORD
              ${if} "$Pass1_text" != ""
                StrCpy $R0 $Pass1_text
                System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PGPASSWORD", R0).r0'
              ${endif}


              DetailPrint "Create adminpack ..."
              Sleep 5000 ;бывает сообщение об ошибке: ВАЖНО:  система баз данных запускается

!ifdef PG_EDB
!else
!endif
              
              nsExec::ExecToStack /TIMEOUT=60000 '"$INSTDIR\bin\psql.exe" -p $TextPort_text -U "$UserName_text" -c "CREATE EXTENSION adminpack;" postgres'
              pop $0
              Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
              DetailPrint "Create adminpack return $0"
              ${if} $0 != 0
                    DetailPrint "Output: $1"
                    ;MessageBox MB_OK "Create adminpack error: $1"
                    MessageBox MB_OK|MB_ICONSTOP "$(MESS_ERROR_SERVER)"
                    
                    
              

              ${endif}

              ${if} "$Pass1_text" != ""
                    StrCpy $R0 ""
                    System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PGPASSWORD", R0).r0'
              ${endif}

        ${endif}

        nsExec::ExecToStack /TIMEOUT=1000 'setx path "%path%;$INSTDIR\bin"'

        ;Push "$INSTDIR\bin"
        ;Call AddToPath
        ;${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR\bin"
        
        ;ExecWait '"$INSTDIR\bin\psql.exe" -p $TextPort_text -U "$UserName_text" -c "CREATE EXTENSION adminpack;" postgres' $0
        ;DetailPrint "psql.exe return $0"



        ;run server
        ;initdb -U postgres --pwfile=pf -A md5 -E UTF8 --locale=Russian_Russia -D C:\PostgreSQL\data

        ;pg_ctl register -N PostgreSQL -U postgres -P pwd -D C:\PostgreSQL\data -S auto
        ;sc start PostgreSQL
        
        ;pathman /as c:\PostgreSQL\bin
        ;...
        ;create database;


        ;AccessControl::GrantOnFile "$INSTDIR\bin" "$ServiceAccount_text" "GenericRead + GenericExecute" ;"FullAccess"
        ;Pop $0 ;"ok" or "error" + error details





SectionEnd

Section "PgAdmin III" sec2

; проблема в том, что готовой сборки PgAdmin III 64bit нет, нужен второй Visual C++ Redistributable Packages на 32 bit
!ifdef PG_64bit
        GetTempFileName $1
	File /oname=$1 vcredist_x86.exe
	ExecWait "$1  /passive /norestart" $0
        DetailPrint "Visual C++ Redistributable Packages 32 bit return $0"
        Delete $1
!endif
	GetTempFileName $0
	File /oname=$0 pgadmin3.msi
        ExecWait '"msiexec" /i "$0"'
        Delete $0


SectionEnd
/*
SectionGroup "Клиентские драйверы"
Section "ODBC" sec_odbc
SectionEnd
Section "JAVA" sec_java
SectionEnd
Section "DotNet" sec_dotnet
SectionEnd

SectionGroupEnd
*/



Function ComponentShow


    SectionSetText ${sec1} "12345";$(Name_Sec1)


FunctionEnd



;--------------------------------
;Descriptions

;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English" ;first language is the default language
  !insertmacro MUI_LANGUAGE "Russian"

  !include translates.nsi

  ;Language strings



  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMS} $(DESC_SecMS)
    !insertmacro MUI_DESCRIPTION_TEXT ${Sec1} $(DESC_Sec1)
    ;!insertmacro MUI_DESCRIPTION_TEXT ${Sec1a} $(DESC_Sec1a)
    !insertmacro MUI_DESCRIPTION_TEXT ${Sec2} $(DESC_Sec2)
    ;!insertmacro MUI_DESCRIPTION_TEXT ${Sec3} $(DESC_Sec3)
    ;!insertmacro MUI_DESCRIPTION_TEXT ${Sec4} $(DESC_Sec4)

  !insertmacro MUI_FUNCTION_DESCRIPTION_END


;--------------------------------
;Uninstaller Section

Section "Uninstall"
   ;${if} ${SectionIsSelected} sec1
        ;stop service  pg_ctl stop    [-W] [-t SECS] [-D DATADIR] [-s] [-m SHUTDOWN-MODE]
        
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

        RMDir /r "$INSTDIR\bin"
        RMDir /r "$INSTDIR\doc"
        RMDir /r "$INSTDIR\include"
        RMDir /r "$INSTDIR\lib"
        RMDir /r "$INSTDIR\share"
        ;RMDir /r "$INSTDIR\pgAdmin III"
        
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
                ;Delete "$SMPROGRAMS\$StartMenuFolder\pgAdmin III.lnk"
                Delete "$SMPROGRAMS\$StartMenuFolder\Reload Configuration.lnk"

                Delete "$SMPROGRAMS\$StartMenuFolder\Restart Server.lnk"
                Delete "$SMPROGRAMS\$StartMenuFolder\Stop Server.lnk"
                Delete "$SMPROGRAMS\$StartMenuFolder\Start Server.lnk"


                RMDir /r "$SMPROGRAMS\$StartMenuFolder\Documentation"

                ;DeleteRegKey HKLM "Software1\$StartMenuFolder"


                RMDir "$SMPROGRAMS\$StartMenuFolder"
        ${endif}

        ${if} "${PG_DEF_BRANDING}" != "" ;страшное дедо, а если пробел?
                DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PG_DEF_BRANDING}"
        ${endif}


        DeleteRegKey /ifempty HKLM "${PRODUCT_DIR_REGKEY}"
        ;${EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\bin"
        ; Remove install dir from PATH
         ;Push "$INSTDIR\bin"
         ;Call un.RemoveFromPath

   ;${else}
          MessageBox MB_OK|MB_ICONINFORMATION "$(UNINSTALL_END)$DATA_DIR" ;debug
   ;${endif}

SectionEnd


;check existing install
;if exist then get install options to vars
Function ChecExistInstall


  StrCpy $Locale_text "$(DEF_LOCALE_NAME)" ;для будушей настройки серрвера, в onInit еще не загружены тексты
         
  ReadRegStr $1 HKLM "${PG_REG_KEY}" "Version"

  ;MessageBox MB_ICONEXCLAMATION|MB_OK ": $1"
  ${if} $1 != "" ;we have ibstall
  
        ;$INSTDIR
          ;Var DATA_DIR
          ;Var ADMIN_DIR

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
    ;ReadRegStr $1 HKLM ${PG_REG_SERVICE_KEY} "C:\Program Files\PostgreSQL\9.2\data"
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
                 ;MessageBox MB_OK "SOFTWARE\PostgreSQL\Services\$1: $3"
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
                 ;MessageBox MB_OK "SOFTWARE\PostgreSQL\Services\$1: $3"
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

        ;ReadRegStr $INSTDIR HKLM ${PG_REG_KEY} "Base Directory"
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



;get data from dialog to variables
Function getServerDataFromDlg
	${NSD_GetText} $Pass1 $Pass1_text
	${NSD_GetText} $Pass2 $Pass2_text
	
	${NSD_GetText} $UserName $UserName_text
        ${NSD_GetState} $checkNoLocal $checkNoLocal_state
        ${NSD_GetText} $TextPort $TextPort_text

        ${NSD_GetText} $Locale $Locale_text
        ;${NSD_GetText} $Coding $Coding_text

FunctionEnd

Function nsDialogsServerPageLeave

         Call getServerDataFromDlg
	;MessageBox MB_OK|MB_ICONINFORMATION "$Pass1_text - $Pass2_text"


	${If} $Pass1_text != $Pass2_text
		MessageBox MB_OK|MB_ICONINFORMATION "$(MESS_PASS1)" ;"Введенные пароль и подтвтерждение различаются!"
		Abort

	${EndIf}

	${If} $Pass1_text == ""
		MessageBox MB_YESNO|MB_ICONQUESTION  "$(MESS_PASS2)" IDYES doit1 IDNO noyet1 ;"Вы не ввели пароль!$\n$\nПодтверждаете установку без пароля?"
		noyet1:
  		       Abort
		doit1:
        ${else}
               push "$Pass1_text"
               Call CheckForAscii
               pop $0
               ${if} $0 != ""
               		MessageBox MB_YESNO|MB_ICONQUESTION  "$(MESS_PASS3)" IDYES doit2 IDNO noyet2 ;"Вы не ввели пароль!$\n$\nПодтверждаете установку без пароля?"
		noyet2:
  		       Abort
		doit2:
               ${endif}

	${EndIf}







;ЖVar UserName_text

	;MessageBox MB_OK|MB_ICONINFORMATION "Enered Locale_text: $Locale_text"


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
  ;SERVER_EXIST_TEXT1
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
        ;DetailPrint "Папка для данных $DATA_DIR уже существуют!"
        ;надо бы номер порта из настроек взять

        StrCpy $isDataDirExist 1
  ${ElseIf} ${FileExists} "$DATA_DIR"
        ; file is a file - error ?
        ;MessageBox MB_OK|MB_ICONINFORMATION "Файл с именем $DATA_DIR уже существуют! Не могу создать папку!"
        ;DetailPrint "Файл с именем $DATA_DIR уже существуют! Не могу создать папку!"
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
        ;порт может быть записан по разному, ConfigRead не интеллектуален
        ${StrRep} '$0' '$R0' '=' ''
        ${StrRep} '$1' '$0' ' ' ''

        StrCpy $0 $1 5

        ${StrRep} '$1' '$0' '$\t' ''
        ${StrRep} '$0' '$1' '#' ''

        ;${StrStrAdv} $1 $0 "#" ">" "<" "0" "0" "0"
        
        StrCpy $TextPort_text $0
        
  ${Else}
         StrCpy $isDataDirExist 0
         Abort
  ${EndIf}

  ${if} $PG_OLD_DIR != "" ;exist PG install
        Abort
  ${endif}

  
  !insertmacro MUI_HEADER_TEXT $(DATADIR_EXIST_TITLE) ""
  ;SERVER_EXIST_TEXT1
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


  ;${if} $PG_OLD_DIR != "" ;exist PG install
  ;      Abort
  ;${endif}

  ;check existing install
 ;Call  ChecExistInstall
  ; Check if another PostgreSQL is installed
  ;EnumRegKey $1 HKLM SOFTWARE\PostgreSQL\Installations\ "0"

  ;${if} $1 != ""
  ;      ReadRegStr $PG_OLD_VERSION HKLM "SOFTWARE\PostgreSQL\Installations\$1" "Version"
  ;  	ReadRegStr $PG_OLD_DIR HKLM "SOFTWARE\PostgreSQL\Installations\$1" "Base Directory"
    	; if installed version is < 8.3 then abort
   ; 	${VersionCompare} $PG_OLD_VERSION "8.3" $0
;		${if} $0 == "2"
;		    MessageBox MB_ICONEXCLAMATION|MB_OK  $(LocS_PostgresOld)
;		 	Abort
;		${endif}
;		MessageBox MB_OKCANCEL|MB_ICONQUESTION "PostgreSQL $PG_OLD_VERSION is already installed on this computer. This installation will be used for ADempiere." IDOK pg_ok
;		Abort "Installation aborted!"
  ;      pg_ok:

   ;   ${endif}


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
	;, не только с localhost"
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


;MessageBox MB_OK "Locale_text= $Locale_text"


  ;при задании кодировки могут появиться несовместимые с локалью варианты и initdb выдает ошибку
  ;UTF-8 всем подходит, используем всегда эту кодировку

/*
	${NSD_CreateLabel} 0 40u 60u 12u "Кодировка:"
	Pop $Label2
	${NSD_CreateDropList} 62u 65U 100u 12u ""
	Pop $Coding

;список неверен надо win1251
${NSD_CB_AddString} $Coding "BIG5"
${NSD_CB_AddString} $Coding "EUC_CN"
${NSD_CB_AddString} $Coding "EUC_JIS_2004"
${NSD_CB_AddString} $Coding "EUC_JP"
${NSD_CB_AddString} $Coding "EUC_KR"
${NSD_CB_AddString} $Coding "EUC_TW"
${NSD_CB_AddString} $Coding "GB18030"
${NSD_CB_AddString} $Coding "GBK"
${NSD_CB_AddString} $Coding "ISO_8859_5"
${NSD_CB_AddString} $Coding "ISO_8859_6"
${NSD_CB_AddString} $Coding "ISO_8859_7"
${NSD_CB_AddString} $Coding "ISO_8859_8"
${NSD_CB_AddString} $Coding "JOHAB"
${NSD_CB_AddString} $Coding "KOI8R"
${NSD_CB_AddString} $Coding "KOI8U"
${NSD_CB_AddString} $Coding "LATIN1"
${NSD_CB_AddString} $Coding "LATIN10"
${NSD_CB_AddString} $Coding "LATIN2"
${NSD_CB_AddString} $Coding "LATIN3"
${NSD_CB_AddString} $Coding "LATIN4"
${NSD_CB_AddString} $Coding "LATIN5"
${NSD_CB_AddString} $Coding "LATIN6"
${NSD_CB_AddString} $Coding "LATIN7"
${NSD_CB_AddString} $Coding "LATIN8"
${NSD_CB_AddString} $Coding "LATIN9"
${NSD_CB_AddString} $Coding "MULE_INTERNAL"
${NSD_CB_AddString} $Coding "SHIFT_JIS_2004"
${NSD_CB_AddString} $Coding "SJIS"
${NSD_CB_AddString} $Coding "SQL_ASCII"
${NSD_CB_AddString} $Coding "UHC"
${NSD_CB_AddString} $Coding "UTF8"
${NSD_CB_AddString} $Coding "WIN1250"
${NSD_CB_AddString} $Coding "WIN1251"
${NSD_CB_AddString} $Coding "WIN1252"
${NSD_CB_AddString} $Coding "WIN1253"
${NSD_CB_AddString} $Coding "WIN1254"
${NSD_CB_AddString} $Coding "WIN1255"
${NSD_CB_AddString} $Coding "WIN1256"
${NSD_CB_AddString} $Coding "WIN1257"
${NSD_CB_AddString} $Coding "WIN1258"
${NSD_CB_AddString} $Coding "WIN866"
${NSD_CB_AddString} $Coding "WIN874"


	${NSD_CB_SelectString} $Coding $Coding_text
*/


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

         # print

         /*DetailPrint "Structure size: $2 bytes"
         DetailPrint "Memory load: $3%"
         DetailPrint "Total physical memory: $4 bytes"
         DetailPrint "Free physical memory: $5 bytes"
         DetailPrint "Total page file: $6 bytes"
         DetailPrint "Free page file: $7 bytes"
         DetailPrint "Total virtual: $8 bytes"
         DetailPrint "Free virtual: $9 bytes"
         */
	 Pop $0 # HWND

	 Push $4


	 ;MessageBox MB_OK "Total physical memory: $4 bytes"

FunctionEnd



Function makeOptimization

       ;StrCpy $R0 C
       ;System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("LANG", R0).r0'

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
	;проверять из набора:
        ; для проверки надо переводить в блоки по 8192

        ;StrCpy $binExe "C:\Program Files\PostgreSQL\9.5\bin\postgres.exe"


        ;;;StrCpy $INSTDIR "C:\Program Files\PostgreSQL\9.5"
        
	;1024MB = 131072 = 1073741824
	;768MB = 98304 = 805306368
	;512MB = 65536 = 536870912
	;256MB = 32768 = 268435456

	;проблема с длиной int  сравниваем в

	${if} $AllMem > 4090 ;>4gb
              StrCpy $work_mem "128MB"
              StrCpy $shared_buffers "512MB"
              ;MessageBox MB_OK "$shared_buffers"
              return

	${endif}
	${if} $AllMem > 2040 ;>2gb
              StrCpy $work_mem "64MB"
              StrCpy $shared_buffers "256MB"
              ;MessageBox MB_OK "$shared_buffers"
              return
	${endif}


	${if} $AllMem >  1020 ;1gb
              StrCpy $work_mem "32MB"
              StrCpy $shared_buffers "128MB"
              ;MessageBox MB_OK "$shared_buffers"

	${endif}

	;MessageBox MB_OK "No optimiztions!"



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

	;!insertmacro MUI_HEADER_TEXT $(SERVER_SET_TITLE) $(SERVER_SET_SUBTITLE)
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









;!define LOCALE_ILANGUAGE '0x1' ;System Language Resource ID
;!define LOCALE_SLANGUAGE '0x2' ;System Language & Country [Cool]
;!define LOCALE_SABBREVLANGNAME '0x3' ;System abbreviated language
;!define LOCALE_SNATIVELANGNAME '0x4' ;System native language name [Cool]
;!define LOCALE_ICOUNTRY '0x5' ;System country code
;!define LOCALE_SCOUNTRY '0x6' ;System Country
;!define LOCALE_SABBREVCTRYNAME '0x7' ;System abbreviated country name
;!define LOCALE_SNATIVECTRYNAME '0x8' ;System native country name [Cool]
;!define LOCALE_IDEFAULTLANGUAGE '0x9' ;System default language ID
;!define LOCALE_IDEFAULTCOUNTRY  '0xA' ;System default country code
;!define LOCALE_IDEFAULTCODEPAGE '0xB' ;System default oem code page

Function .onInit

;System::Call 'kernel32::GetSystemDefaultLangID() i .r0'
;System::Call 'kernel32::GetLocaleInfoA(i 1024, i ${LOCALE_SNATIVECTRYNAME}, t .r2, i ${NSIS_MAX_STRLEN}) i r0'
;System::Call 'kernel32::GetLocaleInfoA(i 1024, i ${LOCALE_SLANGUAGE}, t .r3, i ${NSIS_MAX_STRLEN}) i r0'
;System::Call 'kernel32::GetLocaleInfoA(i 1024, i ${LOCALE_SABBREVCTRYNAME}, t .r3, i ${NSIS_MAX_STRLEN}) i r0'

;MessageBox MB_OK|MB_ICONINFORMATION "Your System LANG Code is: $0. $\r$\nYour system language is: $1. $\r$\nYour system language is: $2. $\r$\nSystem Locale INFO: $3."


 	!insertmacro MUI_LANGDLL_DISPLAY ;выбор языка
!ifdef PG_64bit
   ${IfNot} ${RunningX64}
     MessageBox MB_OK|MB_ICONSTOP "This version can be installed only on 64-bit Windows!"
     Abort
   ${EndIf}
!endif

     

        StrCpy $PG_OLD_DIR ""
        StrCpy $DATA_DIR "$INSTDIR\data"
        
	StrCpy $TextPort_text "${PG_DEF_PORT}"
	StrCpy $UserName_text "${PG_DEF_SUPERUSER}"

        StrCpy $ServiceAccount_text "${PG_DEF_SERVICEACCOUNT}"
        StrCpy $ServiceID_text "${PG_DEF_SERVICEID}"
        StrCpy $Version_text "${PG_DEF_VERSION}"
        StrCpy $Branding_text "${PG_DEF_BRANDING}"
        
        StrCpy $checkNoLocal_state ${BST_CHECKED}


        ;StrCpy $Locale_text "$(DEF_LOCALE_NAME)" ;почему -то всегда по русски
        ;MessageBox MB_OK "$Locale_text $(DEF_LOCALE_NAME) $(DLG_OPT3)"
        
        StrCpy $Coding_text "UTF8" ;"UTF-8"
        
        UserMgr::GetCurrentDomain
        Pop $0
        UserMgr::GetCurrentUserName
        Pop $1
        StrCpy $loggedInUser  "$0\$1"
        
        StrCpy $loggedInUserShort "$1"
        ;MessageBox MB_OK "$loggedInUser,  $loggedInUserShort"

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
        ReadINIStr $1 $0 options pgadmin
        ${if} "$1" == "no"
        	SectionGetFlags ${Sec2} $3
	        IntOp $3 $3 & ${SECTION_OFF}
         	SectionSetFlags ${Sec2} $3
        ${endif}
        ReadINIStr $1 $0 options vcredist
        ${if} "$1" == "no"
        	SectionGetFlags ${secMS} $3
	        IntOp $3 $3 & ${SECTION_OFF}
         	SectionSetFlags ${secMS} $3
        ${endif}
        ReadINIStr $1 $0 options pgserver
        ${if} "$1" == "no"
        	SectionGetFlags ${sec1} $3
	        IntOp $3 $3 & ${SECTION_OFF}
         	SectionSetFlags ${sec1} $3
        ${endif}

        /*ReadINIStr $1 $0 options serviceaccount
        ${if} "$1" != ""
	      StrCpy $ServiceAccount_text "$1"
        ${endif}
        */
        # set section 'test' as selected and read-only

        ;IntOp $0 ${SF_SELECTED} | ${SF_RO}
        ;SectionSetFlags ${test_section_id} $0


FunctionEnd

Function .onSelChange
;MessageBox MB_OK|MB_ICONINFORMATION $(Name_Sec1)
FunctionEnd

Function func1 

  ${if} $PG_OLD_DIR != "" ;exist PG install
        Abort
  ${endif}

  ;StrCpy $DATA_DIR "$INSTDIR\data"
 
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

;Function dirPreAdmin
;StrCpy $ADMIN_DIR "$INSTDIR\pgAdmin III"
;  ${Unless} ${SectionIsSelected} ${sec2}
;    Abort
;  ${EndUnless}
;FunctionEnd
