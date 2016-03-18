CALL %ROOT%\build\helpers\setvars.cmd
GOTO :BUILD_PGADMIN
rm -rf %DEPENDENCIES_BIN_DIR%
IF EXIST %DOWNLOADS_DIR%\deps-SDK71-%ARCH%.zip (
  7z x %DOWNLOADS_DIR%\deps-SDK71-%ARCH%.zip -o%DEPENDENCIES_BIN_DIR% -y
) ELSE (
  ECHO "You need to build PostgreSQL dependencies first!"
  EXIT /B 1 || GOTO :ERROR
)

rm -rf %BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
IF EXIST %DOWNLOADS_DIR%\pgsql_%ARCH%_%PGVER%.zip (
  7z x %DOWNLOADS_DIR%\pgsql_%ARCH%_%PGVER%.zip -o%BUILD_DIR%\distr_%ARCH%_%PGVER% -y
) ELSE (
  ECHO "You need to build PostgreSQL first!"
  EXIT /B 1 || GOTO :ERROR
)
:BUILD_ALL

:BUILD_WXWIDGETS
TITLE Building wxWidgets...
CD /D %DOWNLOADS_DIR%
wget --no-check-certificate -c https://sourceforge.net/projects/wxwindows/files/%WXWIDGETS_VER%/wxWidgets-%WXWIDGETS_VER%.tar.bz2 -O wxWidgets-%WXWIDGETS_VER%.tar.bz2
rm -rf %DEPENDENCIES_BIN_DIR%\wxwidgets %DEPENDENCIES_SRC_DIR%\wxWidgets-%WXWIDGETS_VER%
MKDIR %DEPENDENCIES_BIN_DIR%\wxwidgets
tar xf wxWidgets-%WXWIDGETS_VER%.tar.bz2 -C %DEPENDENCIES_SRC_DIR% || GOTO :ERROR
CD /D %DEPENDENCIES_SRC_DIR%\wxWidgets-*

cp -v %ROOT%/patches/wxWidgets/wxWidgets-%WXWIDGETS_VER%-%SDK%.patch wxWidgets.patch
IF NOT EXIST wxWidgets.patch GOTO :DONE_WXWIDGETS_PATCH
patch -f -p0 < wxWidgets.patch || GOTO :ERROR
:DONE_WXWIDGETS_PATCH

IF %SDK% == SDK71 (
  IF %ARCH% == X86 msbuild build\msw\wx_vc10.sln  /m /p:Configuration="Release" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X86 msbuild build\msw\wx_vc10.sln  /m /p:Configuration="DLL Release" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X64 msbuild build\msw\wx_vc10.sln  /m /p:Configuration="Release" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X64 msbuild build\msw\wx_vc10.sln  /m /p:Configuration="DLL Release" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
)

IF %SDK% == MSVC2013 (
  IF %ARCH% == X86 msbuild build\msw\wx_vc12.sln  /m /p:Configuration="Release" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X86 msbuild build\msw\wx_vc12.sln  /m /p:Configuration="DLL Release" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X64 msbuild build\msw\wx_vc12.sln  /m /p:Configuration="Release" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X64 msbuild build\msw\wx_vc12.sln  /m /p:Configuration="DLL Release" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
)

IF %SDK% == MSVC2015 (
  IF %ARCH% == X86 msbuild build\msw\wx_vc12.sln  /m /p:Configuration="Release" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X86 msbuild build\msw\wx_vc12.sln  /m /p:Configuration="DLL Release" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X64 msbuild build\msw\wx_vc12.sln  /m /p:Configuration="Release" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X64 msbuild build\msw\wx_vc12.sln  /m /p:Configuration="DLL Release" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  REM Upgrade hhp2cached project to VS2015
  devenv utils\hhp2cached\hhp2cached_vc9.vcproj /Upgrade
  IF %ARCH% == X86 msbuild utils\hhp2cached\hhp2cached_vc9.vcxproj /m /p:Configuration="Release" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
  IF %ARCH% == X86 msbuild utils\hhp2cached\hhp2cached_vc9.vcxproj /m /p:Configuration="DLL Release" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
)

cp -va %DEPENDENCIES_SRC_DIR%/wxWidgets-3*/lib   %DEPENDENCIES_BIN_DIR%\wxwidgets  || GOTO :ERROR
cp -va %DEPENDENCIES_SRC_DIR%/wxWidgets-3*/utils  %DEPENDENCIES_BIN_DIR%\wxwidgets  || GOTO :ERROR
IF %ARCH% == X64 (
  mv -v %DEPENDENCIES_BIN_DIR%/wxwidgets/lib/vc_*dll   %DEPENDENCIES_BIN_DIR%\wxwidgets\lib\vc_dll  || GOTO :ERROR
  mv -v %DEPENDENCIES_BIN_DIR%/wxwidgets/lib/vc_*lib   %DEPENDENCIES_BIN_DIR%\wxwidgets\lib\vc_lib  || GOTO :ERROR
)
cp -va %DEPENDENCIES_SRC_DIR%/wxWidgets-3*/include  %DEPENDENCIES_BIN_DIR%\wxwidgets\include  || GOTO :ERROR


:BUILD_PGADMIN
TITLE Building PgAdmin3...
CD /D %DOWNLOADS_DIR%
REM wget --no-check-certificate -c https://github.com/postgres/pgadmin3/archive/%PGADMIN_TAG%.zip -O pgadmin3-%PGADMIN_VERSION%.zip
wget --no-check-certificate -c https://ftp.postgresql.org/pub/pgadmin3/release/v%PGADMIN_VERSION%/src/pgadmin3-%PGADMIN_VERSION%.tar.gz
rm -rf %BUILD_DIR%\pgadmin
MKDIR %BUILD_DIR%\pgadmin
REM 7z x pgadmin3-%PGADMIN_VERSION%.zip -o%BUILD_DIR%\pgadmin -y
tar xf pgadmin3-%PGADMIN_VERSION%.tar.gz -C %BUILD_DIR%\pgadmin
CD /D %BUILD_DIR%\pgadmin\pgadmin3-*
SET OPENSSL=%DEPENDENCIES_BIN_DIR%\openssl
SET WXWIN=%DEPENDENCIES_BIN_DIR%\wxwidgets
SET PGBUILD=%DEPENDENCIES_BIN_DIR%
SET PGDIR=%BUILD_DIR%\distr_%ARCH%_%PGVER%\postgresql
SET PROJECTDIR=

cp -a %DEPENDENCIES_BIN_DIR%/libssh2/include/libssh2_config.h pgadmin\include\libssh2 || GOTO :ERROR
cp -v %ROOT%/patches/pgadmin/libssh2-%SDK%.patch libssh2.patch
IF NOT EXIST libssh2.patch GOTO :DONE_PGADMIN_LIBSSH2_PATCH
patch -f -p0 < libssh2.patch || GOTO :ERROR
:DONE_PGADMIN_LIBSSH2_PATCH

REM This block is for building docs
SET PATH=%PATH%;%PYTHON64_PATH%;%PYTHON64_PATH%\Scripts
pip install sphinx
cd docs
createConf.vbs
REM Workaround ^_^
sed -i "s:ProgramFiles:ProgramFiles(x86):g" builddocs.bat
sed -i "s|EXIT 0|GOTO :DONE|g" builddocs.bat
>> builddocs.bat ECHO :DONE
>> builddocs.bat ECHO ECHO "Docs build success!"
CALL builddocs.bat
cd ..


IF %ARCH% == X64 sed -i 's/Win32/x64/g' xtra\png2c\png2c.vcxproj
IF %ARCH% == X64 sed -i 's/Win32/x64/g' pgadmin\pgAdmin3.vcxproj
sed -i "/<Bscmake>/,/<\/Bscmake>/d" pgadmin\pgAdmin3.vcxproj
IF %ARCH% == X86 msbuild xtra/png2c/png2c.vcxproj /m /p:Configuration="Release (3.0)" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
IF %ARCH% == X64 msbuild xtra/png2c/png2c.vcxproj /m /p:Configuration="Release (3.0)" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
cp -va xtra pgadmin || GOTO :ERROR
IF %ARCH% == X86 msbuild pgadmin/pgAdmin3.vcxproj /m /p:Configuration="Release (3.0)" /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR
IF %ARCH% == X64 msbuild pgadmin/pgAdmin3.vcxproj /m /p:Configuration="Release (3.0)" /p:Platform=x64 /p:PlatformToolset=%PlatformToolset% || GOTO :ERROR


rm -rf %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin
MKDIR %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\lib
MKDIR %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs
MKDIR %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\en_US
cp -va pgadmin/Release*/*.exe %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR
cp -va i18n c:/pg/distr_%ARCH%_%PGVER%/pgadmin/bin  || GOTO :ERROR

cp -va docs/cs_CZ %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\cs_CZ || GOTO :ERROR
cp -va docs/de_DE %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\de_DE || GOTO :ERROR
cp -va docs/es_ES %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\es_ES || GOTO :ERROR
cp -va docs/fi_FI %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\fi_FI || GOTO :ERROR
cp -va docs/fr_FR %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\fr_FR || GOTO :ERROR
cp -va docs/sl_SI %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\sl_SI || GOTO :ERROR
cp -va docs/zh_CN %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\zh_CN || GOTO :ERROR
cp -va docs/zh_TW %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\zh_TW || GOTO :ERROR
cp -va docs/zh_TW %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\zh_TW || GOTO :ERROR
cp -va docs/en_US/pgadmin3.css %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\en_US || GOTO :ERROR
cp -va docs/en_US/_build/htmlhelp/* %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\en_US\ || GOTO :ERROR
cp -va docs/en_US/hints %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin\Docs\en_US\hints || GOTO :ERROR

cp -va c:/pg/distr_%ARCH%_%PGVER%/postgresql/bin/*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR
cp -va %DEPENDENCIES_BIN_DIR%/wxwidgets/lib/vc_dll/*.dll  %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgadmin\bin  || GOTO :ERROR

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
