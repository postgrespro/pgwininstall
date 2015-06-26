  !include "MUI2.nsh"
  !include "logiclib.nsh"
!include "FileFunc.nsh"
!include "common_macro.nsh"

Var Dialog
Var Label
Var rButton1
Var rButton2
Var rButton3

Name "Test optimization"
OutFile "Test_optimization.exe"

  !define MUI_HEADERIMAGE
  ;!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\win.bmp" ; optional
  !define MUI_HEADERIMAGE_BITMAP "pp_header.bmp" ; optional
  !define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\win-install.ico"
  !define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\win-uninstall.ico"


  !define MUI_ABORTWARNING

ShowInstDetails show
ShowUnInstDetails show


Page custom nsDialogOptimization nsDialogsOptimizationPageLeave

Section "Opt" Opt1
SectionEnd


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

         DetailPrint "Structure size: $2 bytes"
         DetailPrint "Memory load: $3%"
         DetailPrint "Total physical memory: $4 bytes"
         DetailPrint "Free physical memory: $5 bytes"
         DetailPrint "Total page file: $6 bytes"
         DetailPrint "Free page file: $7 bytes"
         DetailPrint "Total virtual: $8 bytes"
         DetailPrint "Free virtual: $9 bytes"
	 Pop $0 # HWND
	 
	 Push $4


	 ;MessageBox MB_OK "Total physical memory: $4 bytes"

FunctionEnd

Var binExe

Var AllMem
Var FreeMem
Var shared_buffers
Var work_mem
Var needOptimiztion


;проблема - postgres.exe не запускаетс€ от администратора
;эта функци€ не работает
Function pgTest


         ;runas /user:"NT AUTHORITY\NetworkService" "postgres.exe --boot -F -x0 -c max_connections=100 -c shared_buffers=32768 -c dynamic_shared_memory_type=none"
         ;pg_ctl.exe start -D "C:\Program Files\PostgreSQL\9.5\data" -o "--boot -x0 -F   -c max_connections=100 -c shared_buffers=32768 -c dynamic_shared_memory_type=none"

         pop $0 ;size for test in blocks (8192)
         
         ;max_connections надо будет считывать из cfg или не передавать...
         nsExec::ExecToStack /TIMEOUT=6000 '"$INSTDIR\bin\postgres.exe"' '--boot -x0 -F \
        -c max_connections=100 \
        -c shared_buffers=$0  \
        -c dynamic_shared_memory_type=none '





FunctionEnd


Function makeOptimizationOld

       ;StrCpy $R0 C
       ;System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("LANG", R0).r0'

        Call getFreeMemory
        Pop $AllMem ;get all mem
        StrCpy $FreeMem $5 ;- free mem
        IntOp $FreeMem $FreeMem / 1048576 ;in MB
        IntOp $AllMem $AllMem / 1048576 ;in MB

	;2 options set: shared_buffers and work_mem
	;провер€ть из набора:
        ; дл€ проверки надо переводить в блоки по 8192

        ;StrCpy $binExe "C:\Program Files\PostgreSQL\9.5\bin\postgres.exe"
        StrCpy $INSTDIR "C:\Program Files\PostgreSQL\9.5"
	;1024MB = 131072 = 1073741824
	;768MB = 98304 = 805306368
	;512MB = 65536 = 536870912
	;256MB = 32768 = 268435456
	
	;проблема с длиной int  сравниваем в

	${if} $AllMem > 4090 ;>4gb
              StrCpy $work_mem "128MB"
              push 131072
              Call pgTest
              pop $0
              ;pop $1
              ${if} $0 == 0
                    StrCpy $shared_buffers "1024MB"
                    MessageBox MB_OK "$shared_buffers = 1024MB"
                    return
              ${endif}


              ;MessageBox MB_OK "$0 - $1"

	${endif}
	

	${if} $AllMem > 2040 ;>2gb
              StrCpy $work_mem "64MB"
              push 65536
              Call pgTest
              pop $0
              pop $1
              ${if} $0 == 0
                    StrCpy $shared_buffers "512MB"
                    MessageBox MB_OK "$shared_buffers = 512MB"
                    return
              ${endif}
              MessageBox MB_OK "$0 - $1"

	${endif}


	${if} $AllMem >  1020 ;1gb
              StrCpy $work_mem "32MB"
              push 32768
              Call pgTest
              pop $0
              ${if} $0 == 0
                    StrCpy $shared_buffers "256MB"
                    MessageBox MB_OK "$shared_buffers = 256MB"
                    return
              ${endif}
              MessageBox MB_OK "$0"
	${endif}
	
	MessageBox MB_OK "No optimiztions!"



FunctionEnd


Function makeOptimization

         ;${CheckForAscii} $0 "вит€"
         push "~!@!@#xyz"
         Call CheckForAscii
         pop $0
         MessageBox MB_OK "CheckForAscii: $0"


       ;StrCpy $R0 C
       ;System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("LANG", R0).r0'

	;Math::Script "R0 = 2+2"
        ;MessageBox MB_OK "$R0"
        Call getFreeMemory
        Pop $AllMem ;get all mem
        StrCpy $FreeMem $5 ;- free mem

        
        ;IntOp $FreeMem $FreeMem / 1048576 ;in MB
        ;IntOp $AllMem $AllMem / 1048576 ;in MB
        Math::Script "R0 = $AllMem / 1048576"
        StrCpy $AllMem $R0
        
        

	;2 options set: shared_buffers and work_mem
	;провер€ть из набора:
        ; дл€ проверки надо переводить в блоки по 8192

        ;StrCpy $binExe "C:\Program Files\PostgreSQL\9.5\bin\postgres.exe"
        StrCpy $INSTDIR "C:\Program Files\PostgreSQL\9.5"
	;1024MB = 131072 = 1073741824
	;768MB = 98304 = 805306368
	;512MB = 65536 = 536870912
	;256MB = 32768 = 268435456

	;проблема с длиной int  сравниваем в

	${if} $AllMem > 4090 ;>4gb
              StrCpy $work_mem "128MB"
              StrCpy $shared_buffers "1024MB"
              MessageBox MB_OK "$shared_buffers"
              return

	${endif}
	${if} $AllMem > 2040 ;>2gb
              StrCpy $work_mem "64MB"
              StrCpy $shared_buffers "512MB"
              MessageBox MB_OK "$shared_buffers"
              return
	${endif}


	${if} $AllMem >  1020 ;1gb
              StrCpy $work_mem "32MB"
              StrCpy $shared_buffers "256MB"
              MessageBox MB_OK "$shared_buffers"

	${endif}

	MessageBox MB_OK "No optimiztions!"



FunctionEnd


Function nsDialogOptimization1


        Call makeOptimization
        ${if} $shared_buffers == "" ;No optimization
              ;Abort
        ${endif}

	;!insertmacro MUI_HEADER_TEXT $(SERVER_SET_TITLE) $(SERVER_SET_SUBTITLE)
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		;Abort
	${EndIf}


	${NSD_CreateLabel} 0 0 100% 50u "ћожно провести оптимизацию производительности сервера исход€ из объема установленной пам€ти $AllMem Mb. \
        Cерверу будет выделено больше оперативной пам€ти. \
        ѕараметры будут записаны в файл postgresql.conf"
	Pop $Label
        ${NSD_CreateRadioButton} 0 50u 200u 24U "»спользовать параметры по умолчанию"
        Pop $rButton1

        ${NSD_CreateRadioButton} 0 70u 200u 24U "ѕровести оптимизацию параметров"
        Pop $rButton2


        ${NSD_SetState} $rButton1  ${BST_CHECKED} 
        
        ;GetFunctionAddress $0 getServerDataFromDlg
	;nsDialogs::OnBack $0

	nsDialogs::Show

FunctionEnd

Function nsDialogsOptimizationPageLeave

         ${NSD_GetState} $rButton2 $0
         ${if} $0 == ${BST_CHECKED}
               StrCpy  $needOptimiztion 1
         ${else}
                StrCpy $needOptimiztion ""
         ${endif}
         
         MessageBox MB_OK $needOptimiztion
         

FunctionEnd


Function nsDialogOptimization

        Call makeOptimization
        Call getFreeMemory
        Pop $0


	;!insertmacro MUI_HEADER_TEXT $(SERVER_SET_TITLE) $(SERVER_SET_SUBTITLE)
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}



	;128 = 16384

	;запуск
	/*
		snprintf(cmd, sizeof(cmd),
				 "\"%s\" --boot -x0 %s "
				 "-c max_connections=%d "
				 "-c shared_buffers=%d "
				 "-c dynamic_shared_memory_type=none "
				 "< \"%s\" > \"%s\" 2>&1",
				 backend_exec, boot_options,
				 n_connections, test_buffs,
				 DEVNULL, DEVNULL);
		status = system(cmd);
		if (status == 0)
			break;


	*/


	;max we can get after initdb 128MB

	IntOp $0 $0 / 1048576 ;in MB
	IntOp $R0 $0 / 32
	IntOp $R1 $0 / 8



	${NSD_CreateLabel} 0 0 100% 60u "Total physical memory: $AllMem MBytes, optimal value for shared_buffers from $R0MB to $R1MB"

	Pop $Label

	${NSD_CreateLabel} 0 65u 100% 100% "Structure size: $2 bytes$\n Memory load: $3%$\nTotal physical memory: $4 bytes$\n \
        Free physical memory: $5 bytes$\nTotal page file: $6 bytes$\nTotal virtual: $8 bytes$\nFree virtual: $9 bytes"
	Pop $Label


        ;GetFunctionAddress $0 getServerDataFromDlg
	;nsDialogs::OnBack $0

	nsDialogs::Show

FunctionEnd



Section "Uninstall"
SectionEnd

Function .onInit
 ${GetParameters} $R0
 MessageBox MB_OK "Options: $R0"
  ClearErrors
  ${GetOptions} $R0 /init= $0
  ${if} $0 != ""
        ;check for path
        ${GetParent} "$0" $5
        ${if} $5 == ""
              StrCpy $0 "$EXEDIR\$0"
        ${endif}

        MessageBox MB_OK "INIT: $0"

        ClearErrors
        ReadINIStr $1 $0 paths installdir
        ;IfErrors 0 +1
        ;MessageBox MB_OK "Error $error"
        MessageBox MB_OK "InstallDir: $1"

  ${endif}
  
  
FunctionEnd