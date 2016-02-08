CALL %ROOT%\build\helpers\setvars.cmd

:BUILD_ALL

:BUILD_PGBOUNCER
TITLE Building PgBouncer...
pacman -S gcc make libenvent-devel
CD %DOWNLOADS_DIR%
wget --no-check-certificate https://pgbouncer.github.io/downloads/files/%PGBOUNCER_VERSION%/pgbouncer-%PGBOUNCER_VERSION%.tar.gz -O pgbouncer.tar.gz || GOTO :ERROR
rm -rf %BUILD_DIR%\pgbouncer
MKDIR %BUILD_DIR%\pgbouncer
tar xf pgbouncer.tar.gz -C %BUILD_DIR%\pgbouncer
CD %BUILD_DIR%\pgbouncer\*%PGBOUNCER_VERSION%*
./configure || GOTO :ERROR
make || GOTO :ERROR
rm -rf %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgbouncer
MKDIR %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgbouncer

xcopy /Y pgbouncer.exe %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgbouncer
xcopy /Y %MSYS2_PATH%\msys-2.0.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgbouncer
xcopy /Y %MSYS2_PATH%\msys-crypto*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgbouncer
xcopy /Y %MSYS2_PATH%\msys-ssl-1*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgbouncer
xcopy /Y %MSYS2_PATH%\msys-event*.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgbouncer
xcopy /Y %MSYS2_PATH%\msys-z.dll %BUILD_DIR%\distr_%ARCH%_%PGVER%\pgbouncer

GOTO :DONE

:ERROR
ECHO Failed with error #%errorlevel%.
PAUSE
EXIT /b %errorlevel%

:DONE
ECHO Done.
PAUSE
