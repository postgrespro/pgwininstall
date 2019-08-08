CALL %ROOT%\build\helpers\setvars.cmd

echo.
echo Building PG_PROBACKUP Installer...

SET BIN_DIR=%BUILD_DIR%\pg_probackup_%PG_MAJOR_VERSION%_%PROBACKUP_VERSION%_%ARCH%
SET WIXDIR=C:\Program Files (x86)\WiX Toolset v3.11\bin
SET PRODUCT_NAME=""

IF %PROBACKUP_EDITION% == vanilla (
   SET PRODUCT_NAME=PostgreSQL
   SET PG_DEF_BRANDING=PostgreSQL%PG_MAJOR_VERSION%
   SET PG_REG_KEY=SOFTWARE\Postgres Professional\%ARCH%\%PRODUCT_NAME%\%PG_MAJOR_VERSION%\Installations\postgresql-%PG_MAJOR_VERSION%
)

IF %PROBACKUP_EDITION% == std (
  SET PRODUCT_NAME=PostgresPro
  SET PG_DEF_BRANDING=PostgresPro%PG_MAJOR_VERSION%
  SET PG_REG_KEY=SOFTWARE\Postgres Professional\%ARCH%\%PRODUCT_NAME%\%PG_MAJOR_VERSION%\Installations\postgresql-%PG_MAJOR_VERSION%
)

IF %PRODUCT_NAME% == "" (
	ECHO Invalid PROBACKUP_EDITION: %PROBACKUP_EDITION%
	GOTO :ERROR
)


rm -rf %BUILD_DIR%\pg_probackup\installer || GOTO :ERROR
MKDIR %BUILD_DIR%\pg_probackup\installer

CD /D %ROOT%\wix
cp -av pg_probackup/* %BUILD_DIR%\pg_probackup\installer || GOTO :ERROR
CD /D %BUILD_DIR%\pg_probackup\installer

echo.
echo Building Full Installer...

>Files.wxs  ECHO ^<^?xml version="1.0" encoding="UTF-8"?^>
>>Files.wxs  ECHO ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
>>Files.wxs  ECHO ^<^?include Variables.wxi?^>
>>Files.wxs  ECHO ^<Fragment^>
>>Files.wxs  ECHO ^<DirectoryRef Id = "INSTALLLOCATION"^>
>>Files.wxs  ECHO     		^<^Component Id="ProductComponent" Guid="$(var.ComponentCode)" Win64="$(var.Win64)"^>
perl genfilelist.pl %BIN_DIR%/*.* Files.wxs
>>Files.wxs  ECHO 		^<^/Component^>
>>Files.wxs  ECHO ^<^/DirectoryRef^>
>>Files.wxs  ECHO ^<^/Fragment^>
>>Files.wxs  ECHO ^<^/Wix^>
"%WIXDIR%\candle" -nologo  -dAPPVERSION="%PROBACKUP_VERSION%" -dPG_REG_KEY="%PG_REG_KEY%" -dPG_DEF_BRANDING="%PG_DEF_BRANDING%" Product_separate.wxs Files.wxs || goto :ERROR

SET INS_FILE=pg-probackup-%PROBACKUP_EDITION%-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION%-standalone-en.msi

"%WIXDIR%\light" -sice:ICE03 -sice:ICE25 -sice:ICE82 -sw1101 -nologo -ext WixUIExtension -cultures:en-us -o %INS_FILE% Files.wixobj Product_separate.wixobj || goto :ERROR

cp -av pg-probackup-%PROBACKUP_EDITION%-%PG_MAJOR_VERSION%-%PROBACKUP_VERSION%-standalone-en.msi %BUILD_DIR%\installers\ || goto :ERROR

goto :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
EXIT /b %errorlevel%

:DONE
ECHO Done.
