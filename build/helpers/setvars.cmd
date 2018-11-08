REM LIBRARY VERSIONS
SET ICONV_VER=1.15
SET XSLT_VER=1.1.29
SET ZLIB_VER=1.2.11
SET XML_VER=2.9.7
SET OPENSSL_VER=1.0.2n
SET GETTEXT_VER=0.19.8
SET LIBSSH2_VER=1.6.0
SET WXWIDGETS_VER=3.0.2
SET EDITLINE_VER=2.205
SET ZSTD_RELEASE=1.1.0

SET PG_REPACK_VER=1.4.2
IF "%PG_MAJOR_VERSION%"=="9.5" SET PG_REPACK_VER=1.3.4
IF "%PG_MAJOR_VERSION%"=="11" SET PG_REPACK_VER=1.4.3

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
SET PERL5LIB=.

IF EXIST "%PERL32_BIN%" SET PATH=%PERL32_BIN%;%PATH%
IF EXIST "%PERL32_BIN%" SET PERL_EXE=%PERL32_BIN%\perl
IF EXIST "%PERL64_BIN%" SET PATH=%PERL64_BIN%;%PATH%
IF EXIST "%PERL64_BIN%" SET PERL_EXE=%PERL64_BIN%\perl

IF %ARCH% == X86 SET Platform=Win32
IF %ARCH% == X64 SET Platform=X64
IF %SDK% == SDK71 (
  SET REDIST_YEAR=2010
  SET PlatformToolset=v100
  CALL "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv" /xp /%ARCH% || GOTO :ERROR
  ECHO ON
)

IF %SDK% == MSVC2013 (
  SET REDIST_YEAR=2013
  SET PlatformToolset=v120
  IF %ARCH% == X86 CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall" x86 || GOTO :ERROR
  ECHO ON
  IF %ARCH% == X64 CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall" amd64 || GOTO :ERROR
  ECHO ON
)

IF %SDK% == MSVC2015 (
  SET REDIST_YEAR=2015
  SET PlatformToolset=v140
  IF %ARCH% == X86 CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall" x86 || GOTO :ERROR
  ECHO ON
  IF %ARCH% == X64 CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall" amd64 || GOTO :ERROR
  ECHO ON
)

REM As we use Msys2 for build we need to install useful packages we will use
@ECHO "Current PATH is:"
PATH
pacman --noconfirm --sync --needed flex bison tar wget patch git

ECHO %PG_PATCH_VERSION% | grep "^[0-9]." > nul && (
  SET PG_DEF_VERSION=%PG_MAJOR_VERSION%.%PG_PATCH_VERSION%
) || (
  SET PG_DEF_VERSION=%PG_MAJOR_VERSION%%PG_PATCH_VERSION%
)

SET PGVER=%PG_DEF_VERSION%
IF "%PGURL%"=="" (
   IF "%PRODUCT_NAME%"=="" SET PGURL="https://ftp.postgresql.org/pub/source/v%PGVER%/postgresql-%PGVER%.tar.bz2"
   IF "%PRODUCT_NAME%"=="PostgreSQL" SET PGURL="https://ftp.postgresql.org/pub/source/v%PGVER%/postgresql-%PGVER%.tar.bz2"
   IF "%PRODUCT_NAME%"=="PostgresPro" SET PGURL="http://repo.l.postgrespro.ru/pgpro-%PG_MAJOR_VERSION%-beta/src/postgrespro-standard-%PGVER%.tar.bz2"
)

REM Set useful directories paths so they're used in scripts
SET BUILD_DIR=%ROOT%\builddir
SET DEPENDENCIES_SRC_DIR=%BUILD_DIR%\dependencies_src
SET DEPENDENCIES_BIN_DIR=%BUILD_DIR%\dependencies
SET DEPS_ZIP=deps-%SDK%-%ARCH%.zip
SET DOWNLOADS_DIR=%BUILD_DIR%\downloads

REM Convert paths for Unix utilites
SET BUILD_UDIR=%BUILD_DIR:\=/%
SET DEPENDENCIES_SRC_UDIR=%DEPENDENCIES_SRC_DIR:\=/%
SET DEPENDENCIES_BIN_UDIR=%DEPENDENCIES_BIN_DIR:\=/%

REM Magic to set root directory of those scripts (Where Readme.md lies)

REM Let's use MP for nmake for parallel build
SET CL=/MP
