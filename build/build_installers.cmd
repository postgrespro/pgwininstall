REM Required
REM 1. NSIS
REM 2. UsrMgr Plugin for NSIS
REM 3. AccessControl Plugin for NSIS
REM 4. Visual Studio 2010 Redistibutable (x86, x64) [Place it to nsis directory]
REM 5. PostgreSQL and PgAdmin3 binaries
REM 6. 7z for making ZIP files

REM Set your NSIS installation directory
SET NSIS_PATH="C:\Program Files (x86)\NSIS"
REM Set your Msys2 installation directory
SET MSYS2_PATH="C:\msys32\usr\bin"
REM Set your 7z path
SET ZPATH="C:\Program Files\7-Zip"
REM Add NSIS and MSYS2 to your PATH
SET PATH=%PATH%;%NSIS_PATH%;%MSYS2_PATH%;%ZPATH%

SET PG_DEF_VERSION_SHORT=9.4
SET PG_DEF_VERSION=9.4.5
SET PGADMIN_VERSION=1.20
SET PG_ARCH=X64

SET BUILD_SCRIPTS_DIR=%~dp0
SET BUILD_SCRIPTS_DIR=%BUILD_SCRIPTS_DIR:~0,-1%

REM Download VC Redistibutable packages
rm -rf "c:\pg\vcredist"
MKDIR "c:\pg\vcredist"
wget https://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe -O "c:\pg\vcredist\vcredist_x86.exe" || GOTO :ERROR
wget https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe -O "c:\pg\vcredist\vcredist_x64.exe" || GOTO :ERROR

REM Make directory for installers
MKDIR "c:\pg\installers"



call %BUILD_SCRIPTS_DIR%\nsis_installer.cmd || GOTO :ERROR
call %BUILD_SCRIPTS_DIR%\make_zip.cmd || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
