CALL %ROOT%\build\helpers\setvars.cmd

REM Required
REM 1. NSIS
REM 2. UsrMgr Plugin for NSIS
REM 3. AccessControl Plugin for NSIS
REM 4. Visual Studio 2010 Redistibutable (x86, x64) [Place it to nsis directory]
REM 5. PostgreSQL and PgAdmin3 binaries
REM 6. 7z for making ZIP files

REM Download VC Redistibutable packages
TITLE Downloading VC Redistibutable packages
MKDIR "%BUILD_DIR%\vcredist"
IF %REDIST_YEAR% == 2010 (
wget -c https://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe -O "%BUILD_DIR%\vcredist\vcredist_x86_2010.exe" || GOTO :ERROR
wget -c https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe -O "%BUILD_DIR%\vcredist\vcredist_x64_2010.exe" || GOTO :ERROR
)

IF %REDIST_YEAR% == 2013 (
wget -c https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe -O "%BUILD_DIR%\vcredist\vcredist_x86_2013.exe" || GOTO :ERROR
wget -c https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe -O "%BUILD_DIR%\vcredist\vcredist_x64_2013.exe" || GOTO :ERROR
)

IF %REDIST_YEAR% == 2015 (
wget -c https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x86.exe -O "%BUILD_DIR%\vcredist\vcredist_x86_2015.exe" || GOTO :ERROR
wget -c https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe -O "%BUILD_DIR%\vcredist\vcredist_x64_2015.exe" || GOTO :ERROR
)

IF %REDIST_YEAR% == 2017 (
rem wget -c https://download.visualstudio.microsoft.com/download/pr/11100229/78c1e864d806e36f6035d80a0e80399e/VC_redist.x86.exe -O "%BUILD_DIR%\vcredist\vcredist_x86_2017.exe" || GOTO :ERROR
rem wget -c https://download.visualstudio.microsoft.com/download/pr/11100230/15ccb3f02745c7b206ad10373cbca89b/VC_redist.x64.exe -O "%BUILD_DIR%\vcredist\vcredist_x64_2017.exe" || GOTO :ERROR
rem VCToolsRedistDir=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Redist\MSVC\14.16.27012\
cp "%VCToolsRedistDir%vc_redist.x86.exe" "%BUILD_DIR%\vcredist\vcredist_x86_2017.exe"
cp "%VCToolsRedistDir%vc_redist.x64.exe" "%BUILD_DIR%\vcredist\vcredist_x64_2017.exe"
)

REM Make directory for installers
MKDIR "%BUILD_DIR%\installers"

TITLE Making NSIS installers
call %ROOT%\build\helpers\postgres_nsis_installer.cmd || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
