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

## Patches

Directory contains patches which are need to build PostgreSQL.

## Usage
You can specify several environmental variables depending on desirable result:

* ARCH=[X86/X64] -- architecture, default X64
* ONE_C=[YES/NO] -- apply 1C patches or not, default NO
* SDK=[SDK71/MSVC2013/MSVC2015] -- MSVC version, default SDK71
* PG_MAJOR_VERSION=[9.4/9.5/9.6/10] - major PostgreSQL version, default 10
* PG_PATCH_VERSION=[1/7] - minor PostgreSQL version, default 1
