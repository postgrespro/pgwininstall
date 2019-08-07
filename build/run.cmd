@ECHO OFF

REM What do you need to build PostgreSQL and PgAdmin
REM 1. Microsoft Windows SDK 7.1 or MSVC2013 and Visual Studio 2015 for PgAdmin
REM 2. Active Perl 5.x
REM 3. Python 2.7 or 3.5
REM 4. MSYS2
REM 5. 7z

IF "%~1" == "1" GOTO :OK
IF "%~1" == "2" GOTO :OK
IF "%~1" == "3" GOTO :OK
IF "%~1" == "4" GOTO :OK
IF "%~1" == "5" GOTO :OK
IF "%~1" == "6" GOTO :OK
IF "%~1" == "7" GOTO :OK
IF "%~1" == "8" GOTO :OK
IF "%~1" == "9" GOTO :OK

SET USG=1

IF DEFINED USG (
  ECHO Usage:
  ECHO run.cmd [args: 1,2,3,4,5]
  ECHO 1: Build dependencies
  ECHO 2: Build PostgreSQL
  ECHO 3: Build installer PostgreSQL
  ECHO 4: Build PgAdmin3
  ECHO 5: Build installer PgAdmin3
  ECHO 6: Make PostgreSQL and PgAdmin3 archives
  ECHO 7: Build pgbouncer
  ECHO 8: Build pg_probackup
  ECHO 9: Build pg_probackup installer
  PAUSE
  EXIT /b 1
)

:OK

REM Set PostgreSQL version
IF "%PG_MAJOR_VERSION%"=="" SET PG_MAJOR_VERSION=10
IF "%PG_PATCH_VERSION%"=="" SET PG_PATCH_VERSION=1

REM Set PgAdmin3 Version
SET PGADMIN_VERSION=1.22.1
SET PGADMIN_TAG=REL-1_22_1

REM Set ONE_C for 1C Patching
IF "%ONE_C%"=="" SET ONE_C=NO

REM Set build architecture: X86 or X64
IF "%ARCH%"=="" SET ARCH=X64
IF "%ARCH%"=="x86" SET ARCH=X86
IF "%ARCH%"=="x64" SET ARCH=X64

REM Set PGBouner Version
SET PGBOUNCER_VERSION=1.7

@echo off&setlocal
FOR %%i in ("%~dp0..") do set "ROOT=%%~fi"

IF "%~1"=="1" (
  TITLE Building dependencies
  IF "%SDK%"=="" SET SDK=SDK71
  CMD.EXE /C %ROOT%\build\helpers\dependencies.cmd || GOTO :ERROR
)

IF "%~1"=="2" (
  TITLE Building PostgreSQL
  IF "%SDK%"=="" SET SDK=SDK71
  CMD.EXE /C %ROOT%\build\helpers\postgres.cmd || GOTO :ERROR
)

IF "%~1"=="3" (
  TITLE Building PostgreSQL installer
  IF "%SDK%"=="" SET SDK=SDK71
  CMD.EXE /C %ROOT%\build\helpers\postgres_installer.cmd || GOTO :ERROR
)

IF "%~1"=="4" (
  TITLE Building PgAdmin
  IF "%SDK%"=="" SET SDK=SDK71
  CMD.EXE /C %ROOT%\build\helpers\pgadmin.cmd || GOTO :ERROR
)

IF "%~1"=="5" (
  TITLE Building PgAdmin installer
  IF "%SDK%"=="" SET SDK=SDK71
  CMD.EXE /C %ROOT%\build\helpers\pgadmin_installer.cmd || GOTO :ERROR
)

IF "%~1"=="6" (
    TITLE Making Archives
    CMD.EXE /C %ROOT%\build\helpers\make_zip.cmd || GOTO :ERROR
)

IF "%~1"=="7" (
    TITLE Build PGBouncer
    CMD.EXE /C %ROOT%\build\helpers\pgbouncer.cmd || GOTO :ERROR
)

IF "%~1"=="8" (
    TITLE Build PG_PROBACKUP
    CMD.EXE /C %ROOT%\build\helpers\probackup.cmd || GOTO :ERROR
)

IF "%~1"=="9" (
    TITLE Build PG_PROBACKUP installer
    CMD.EXE /C %ROOT%\build\helpers\probackup_installer.cmd || GOTO :ERROR
)

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
