REM Required
REM 1. NSIS
REM 2. UsrMgr Plugin for NSIS http://nsis.sourceforge.net/UserMgr_plug-in
REM 3. AccessControl Plugin for NSIS http://nsis.sourceforge.net/AccessControl_plug-in
REM 4. Copy AddToPath.dll to %programfiles(x86)%\NSIS\Plugins
REM 4. Visual Studio 2010 Redistibutable (x86, x64) [Place it to nsis directory]
REM 5. PostgreSQL and PgAdmin3 binaries

REM Set your NSIS installation directory
SET NSIS_PATH="%programfiles(x86)%\NSIS"
REM Add NSIS to your PATH
SET PATH=%PATH%;%NSIS_PATH%
REM Also, you need to make defines if you use x64 version of PostgreSQL
REM You need to uncomment this line: ;!define PG_64bit

REM ----------------------------------------------------------------------------
REM Assume, you have your PostgreSQL and PgAdmin3 build in C:\pg\distr_X86_9.4.4
REM For PostgreSQL you have 'postgresql' directory and
REM for PgAdmin3 you have 'pgadmin' directory
REM So you don't need to define PG_64bit in 'postgresql.nsi'
REM ----------------------------------------------------------------------------

REM Just run that script and installer will appear in the nsis directory

CD c:\pg\pgwininstall\nsis || GOTO :ERROR
makensis postgresql.nsi || GOTO :ERROR
makensis pgadmin.nsi || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
