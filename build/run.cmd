@ECHO OFF

REM What you need to build PostgreSQL
REM 1. .Net 4.0
REM 2. Microsoft Windows SDK 7.1, MSVC 2013 CE
REM 3. Active Perl <= 5.14
REM 4. Python 2.7
REM 5. MSYS2
REM 6. 7z

IF "%~1" == "1" GOTO :OK
IF "%~1" == "2" GOTO :OK
IF "%~1" == "3" GOTO :OK
IF "%~1" == "all" GOTO :OK
SET USG=1
IF DEFINED USG (
  ECHO Usage:
  ECHO run.cmd [args: 1,2,3, all]
  ECHO 1: Build dependencies
  ECHO 2: Build PostgreSQL and PgAdmin3
  ECHO 3: Build installers
  PAUSE
  EXIT /b 1
)

:OK

REM Set SDK
SET SDK=MSVC2013
IF SDK == SDK71 PlatformToolset=v100
IF SDK == MSVC2013 PlatformToolset=v120

REM Set build architecture: X86 or X64
SET ARCH=X64

REM Path vars
SET PERL32_PATH=C:\Perl
SET PERL64_PATH=C:\Perl64
SET PERL32_BIN=%PERL32_PATH%\bin
SET PERL64_BIN=%PERL64_PATH%\bin
SET PYTHON32_PATH=C:\Python27x86
SET PYTHON64_PATH=C:\Python27x64
SET ZIP_PATH=C:\Program Files\7-Zip;C:\Program Files (x86)\7-Zip
SET NSIS_PATH=C:\Program Files (x86)\NSIS
SET MSYS2_PATH=C:\msys32\usr\bin;C:\msys64\usr\bin
SET PATH=%PATH%;%ZIP_PATH%;%MSYS2_PATH%;%NSIS_PATH%
IF %ARCH% == X86 SET PATH=%PERL32_BIN%;%PATH%
IF %ARCH% == X64 SET PATH=%PERL64_BIN%;%PATH%

IF %SDK% == SDK71 CALL "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv" /%ARCH% || GOTO :ERROR
IF %SDK% == MSVC2013 (
  IF %ARCH% == X86 CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall" x86 || GOTO :ERROR
  IF %ARCH% == X64 CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall" amd64 || GOTO :ERROR
)

REM As we use Msys2 for build we need to install useful packages we will use
pacman --noconfirm --sync flex bison tar wget patch git

REM Set PostgreSQL version
SET PG_DEF_VERSION_SHORT=9.5
SET PATCH_VERSION=0
ECHO %PATCH_VERSION% | grep "^[0-9]." > nul && (
  SET PG_DEF_VERSION=%PG_DEF_VERSION_SHORT%.%PATCH_VERSION%
) || (
  SET PG_DEF_VERSION=%PG_DEF_VERSION_SHORT%%PATCH_VERSION%
)

SET PGVER=%PG_DEF_VERSION%

REM Set ONE_C for 1C Patching
SET ONE_C=NO

REM Set PgAdmin3 Version
SET PGADMIN_VERSION=1.20.0

REM Set useful directories paths so they're used in scripts
SET BUILD_DIR=c:\pg
SET DEPENDENCIES_SRC_DIR=%BUILD_DIR%\dependencies_src
SET DEPENDENCIES_BIN_DIR=%BUILD_DIR%\dependencies
SET DOWNLOADS_DIR=%BUILD_DIR%\downloads
REM Magic to set root directory of those scripts (Where Readme.md lies)
@echo off&setlocal
FOR %%i in ("%~dp0..") do set "ROOT=%%~fi"

REM LIBRARY VERSIONS
SET ICONV_VER=1.14
SET XSLT_VER=1.1.28
SET ZLIB_VER=1.2.8
SET XML_VER=2.7.3
SET OPENSSL_VER=1.0.2e
SET GETTEXT_VER=0.19.4
SET LIBSSH2_VER=1.4.3
SET WXWIDGETS_VER=3.0.2

REM Let's use MP for nmake for parallel build
SET CL=/MP

IF "%~1"=="1" (
  TITLE Building dependencies
  CALL %ROOT%\build\helpers\dependencies.cmd
)

IF "%~1"=="2" (
  TITLE Building PostgreSQL
  CALL %ROOT%\build\helpers\postgres_and_pgadmin.cmd
)

IF "%~1"=="3" (
  TITLE Building installers
  CALL %ROOT%\build\helpers\installers.cmd
)

IF "%~1"=="all" (
  TITLE Building all
  TITLE Building dependencies
  CALL %ROOT%\build\helpers\dependencies.cmd
  TITLE Building PostgreSQL
  CALL %ROOT%\build\helpers\postgres_and_pgadmin.cmd
  TITLE Building installers
  CALL %ROOT%\build\helpers\installers.cmd
)
