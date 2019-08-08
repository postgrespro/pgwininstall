## NSIS

Directory contains files needed for an installer.

## Build

Directory contains various build scripts.

### Build depends:

* Microsoft SDK 7.1 or MSVC2013 for build PostgreSQL
* Active Perl 5.x
* Python 2.7 or 3.5
* msys2
* 7-Zip
* NSIS
* HTML Help Workshop (for PgAdmin documentation, included in Visual Studio)
* .NET 3.5 (for pg_probackup only)
* WiX toolset (for pg_probackup only)

## Patches

Directory contains patches which are need to build PostgreSQL.

## Usage
You can specify several environmental variables depending on desirable result:

* ARCH=[X86/X64] -- architecture, default X64
* ONE_C=[YES/NO] -- apply 1C patches or not, default NO
* SDK=[SDK71/MSVC2013/MSVC2015] -- MSVC version, default SDK71
* PG_MAJOR_VERSION=[9.4/9.5/9.6/10] - major PostgreSQL version, default 10
* PG_PATCH_VERSION=[1/7] - minor PostgreSQL version, default 1

* NOLOAD_SRC=[1] -- if variable has any value we will not download source

If you want to use GIT:

* GIT_BRANCH=[git branch name] -- if you sets this variables we will download source from git
* GIT_PATH=[git path] -- git URL, git://git.postgresql.org/git/postgresql.git by default

### probackup build
You can specify several environmental variables depending on desirable result:

* PROBACKUP_VERSION=[2.1.3/2.1.5] - pg_probackup full version
* PROBACKUP_EDITION=[vanilla/std/enterprise] -- fork to build probackup for, default 'vanilla'
* PROBACKUP_PATCH_POSTGRESQL=[YES/NO] -- apply probackup specific patches, default NO

To build pg_probackup installer for vanilla PostgreSQL, run:

SET SDK=MSVC2013
SET PROBACKUP_VERSION=2.1.5
SET PG_MAJOR_VERSION=11
SET PG_PATCH_VERSION=4
SET PROBACKUP_EDITION=vanilla

To build pg_probackup installer for PostgresPro Standart, run:

SET SDK=MSVC2013
SET PROBACKUP_VERSION=2.1.5
SET PG_MAJOR_VERSION=11
SET PG_PATCH_VERSION=4
SET PROBACKUP_EDITION=std
SET GIT_PATH=https://git.postgrespro.ru/pgpro-dev/postgrespro.git
SET GIT_BRANCH=PGPRO11_4_1