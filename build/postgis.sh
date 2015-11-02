
set -e

ARCH=x64
PGVER=9.4.5

pacman -S gcc make diff wget tar unzip diffutils

cd /c/pg
unzip -x downloads/deps_${ARCH}.zip
unzip -x downloads/pgsql_${ARCH}_${PGVER}.zip


