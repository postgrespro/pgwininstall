Использование скриптов

Используйте RUN.CMD для скачивания исходников и исполняемых файлов postgreSQL, скачивания и сборки pg_probackup
Для этого файла используйте переменные среды:

--- stable или dev ---
SET ISDEV=1 для dev версии postgres
SET ISDEV= для стабильной версии postgres

-- версия PostgreSQL ---
SET PG_MAJOR_VERSION=11
SET PG_PATCH_VERSION=1.1

-- версия PRO продукта, используется для вычисления ветки реестра, куда записывается путь к PostgreSQL ---
SET PRODUCT_NAME=PostgresPro
или
SET PRODUCT_NAME=PostgresProEnterprise

--- версия pg_probackup ---
SET APPVERSION=2.0.26



Используйте build_separate.bat для скачивания и сборки pg_probackup без загрузки postgreSQL 

В начале этого файла надо настроить переменные:

--- путь к исходным кодам и к бинарным файлам PostgrSQL ---
SET PGDIRSRC=...
SET PGDIR=...

--- Версию pg_probackup ---
SET APPVERSION=2.0.26

Для создания инсталлятора требуются следующие переменные среды:

--- ветка реестра, в которую пишется путь к установке PostgresPro. ---
SET PG_REG_KEY=SOFTWARE\PostgresPro\X64\PostgresProEnterprise\11\Installations\postgresql-11
(не используется при создании автономного инсталлятора)

--- используется при сообщении, что инсталляция продукта не найдена: ---
SET PG_DEF_BRANDING=PostgresPro Enterprise 11

--- в этом случае используется только как первая часть в имени файла инсталлятора ---
SET PRODUCT_NAME=PostgresProEnterprise

--- используется для имени фйла инсталлтора ---
SET BITS=64bit

--- используется для имени фйла инсталлтора ---
SET PGVER=11.1.1

