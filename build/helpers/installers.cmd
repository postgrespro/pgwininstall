CALL setvars.cmd

REM Required
REM 1. NSIS
REM 2. UsrMgr Plugin for NSIS
REM 3. AccessControl Plugin for NSIS
REM 4. Visual Studio 2010 Redistibutable (x86, x64) [Place it to nsis directory]
REM 5. PostgreSQL and PgAdmin3 binaries
REM 6. 7z for making ZIP files

REM Download VC Redistibutable packages
TITLE Downloading VC Redistibutable packages
MKDIR "c:\pg\vcredist"

IF %SDK% == "SDK71" (
  wget -c https://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe -O "c:\pg\vcredist\vcredist_x86.exe" || GOTO :ERROR
  wget -c https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe -O "c:\pg\vcredist\vcredist_x64.exe" || GOTO :ERROR
)

IF %SDK% == "MSVC2013" (
  wget -c https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe -O "c:\pg\vcredist\vcredist_x86.exe" || GOTO :ERROR
  wget -c https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe -O "c:\pg\vcredist\vcredist_x86.exe" || GOTO :ERROR
)

IF %SDK% == "MSVC2015" (
  wget -c https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x86.exe -O "c:\pg\vcredist\vcredist_x86.exe" || GOTO :ERROR
  wget -c https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe -O "c:\pg\vcredist\vcredist_x86.exe" || GOTO :ERROR
)

REM Make directory for installers
MKDIR "c:\pg\installers"

TITLE Making NSIS installers
call %ROOT%\build\helpers\nsis_installer.cmd || GOTO :ERROR
TITLE Making Zip archives
call %ROOT%\build\helpers\make_zip.cmd || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
