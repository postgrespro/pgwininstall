@ECHO OFF

REM What you need to build PostgreSQL and PgAdmin
REM 1. Microsoft Windows SDK 7.1, MSVC 2013-2013
REM 2. Active Perl <= 5.14
REM 3. Python 2.7
REM 4. MSYS2
REM 5. 7z

IF "%~1" == "1" GOTO :OK
IF "%~1" == "2" GOTO :OK
IF "%~1" == "3" GOTO :OK
IF "%~1" == "4" GOTO :OK

SET USG=1

IF DEFINED USG (
  ECHO Usage:
  ECHO run.cmd [args: 1,2,3, all]
  ECHO 1: Build dependencies
  ECHO 2: Build PostgreSQL
  ECHO 3: Build PgAdmin3
  ECHO 4: Build installers
  PAUSE
  EXIT /b 1
)

:OK

REM Set PostgreSQL version
SET PG_DEF_VERSION_SHORT=9.5
SET PATCH_VERSION=0

REM Set PgAdmin3 Version
SET PGADMIN_VERSION=1.22.0

REM Set ONE_C for 1C Patching
IF "%ONE_C%"=="" SET ONE_C=NO

REM Set SDK
REM Possible: SDK71, MSVC2013, MSVC2015
IF "%SDK%"=="" SET SDK=SDK71

REM Set build architecture: X86 or X64
IF "%ARCH%"=="" SET ARCH=X64

IF "%~1"=="1" (
  TITLE Building dependencies
  CALL %ROOT%\build\helpers\dependencies.cmd
)

IF "%~1"=="2" (
  TITLE Building PostgreSQL
  CALL %ROOT%\build\helpers\postgres.cmd
)

IF "%~1"=="3" (
  TITLE Building PostgreSQL
  CALL %ROOT%\build\helpers\pgadmin.cmd
)

IF "%~1"=="4" (
  TITLE Building installers
  CALL %ROOT%\build\helpers\installers.cmd
)
