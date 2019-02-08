LangString PostgreSQLString ${LANG_ENGLISH} "${PRODUCT_NAME_SHORT} server"
LangString PostgreSQLString ${LANG_RUSSIAN} "Сервер ${PRODUCT_NAME_SHORT}"

  LangString DATADIR_MESS ${LANG_ENGLISH} "Select a directory under which to store your data"
  LangString DATADIR_MESS ${LANG_RUSSIAN} "Базы данных будут установлены в следующий каталог"

  LangString DATADIR_TITLE ${LANG_ENGLISH} "Data directory"
  LangString DATADIR_TITLE ${LANG_RUSSIAN} "Каталог данных"

  LangString BROWSE_BUTTON ${LANG_ENGLISH} "Browse ..."
  LangString BROWSE_BUTTON ${LANG_RUSSIAN} "Обзор ..."

  LangString DESC_SecMS ${LANG_ENGLISH} "Install run-time components that are required to run C++ applications"
  LangString DESC_SecMS ${LANG_RUSSIAN} "Компоненты среды выполнения, необходимые для выполнения приложений C++"

  LangString DESC_Sec1 ${LANG_ENGLISH} "Install ${PRODUCT_NAME_SHORT} server components."
  LangString DESC_Sec1 ${LANG_RUSSIAN} "Установка файлов сервера ${PRODUCT_NAME_SHORT}."

  LangString DESC_PgAdmin ${LANG_ENGLISH} "Install pgAdmin tools for server administration."
  LangString DESC_PgAdmin ${LANG_RUSSIAN} "Установка pgAdmin для управления сервером."

  LangString DESC_Sec1dir ${LANG_ENGLISH} "Specify the directory where ${PRODUCT_NAME_SHORT} will be installed"
  LangString DESC_Sec1die ${LANG_RUSSIAN} "Задайте каталог, куда будет установлен ${PRODUCT_NAME_SHORT}"

  LangString SERVER_SET_TITLE ${LANG_ENGLISH} "Server options"
  LangString SERVER_SET_TITLE ${LANG_RUSSIAN} "Параметры сервера"

  LangString SERVER_SET_SUBTITLE ${LANG_ENGLISH} "Specify server options"
  LangString SERVER_SET_SUBTITLE ${LANG_RUSSIAN} "Задайте параметры сервера"

  LangString SERVER_EXIST_TITLE ${LANG_ENGLISH} "Existing Installation"
  LangString SERVER_EXIST_TITLE ${LANG_RUSSIAN} "Существующая инсталляция"

  LangString SERVER_EXIST_TEXT1 ${LANG_ENGLISH} "An existing ${PRODUCT_NAME_SHORT} installation has been found at "
  LangString SERVER_EXIST_TEXT1 ${LANG_RUSSIAN} "Найдена инсталляция сервера ${PRODUCT_NAME_SHORT} в каталоге "

  LangString SERVER_EXIST_TEXT2 ${LANG_ENGLISH} "This installation will be upgraded.$\n$\nServer restart is required to complete the upgrade. "
  LangString SERVER_EXIST_TEXT2 ${LANG_RUSSIAN} "Эта инсталляция будет обновлена.$\n$\nДля завершения обновления требуется перезапуск сервера. "

  LangString DATADIR_EXIST_TITLE ${LANG_ENGLISH} "Existing Data Directory"
  LangString DATADIR_EXIST_TITLE ${LANG_RUSSIAN} "Уже имеется каталог с данными"

  LangString DATADIR_EXIST_TEXT1 ${LANG_ENGLISH} "An existing data directory has been found at $DATA_DIR , port $TextPort_text . This directory will be used for this installation."
  LangString DATADIR_EXIST_TEXT1 ${LANG_RUSSIAN} "Уже имеется каталог с данными $DATA_DIR , порт $TextPort_text . Этот каталог будет использован для данной инсталляции сервера."

  LangString DATADIR_EXIST_ERROR1 ${LANG_ENGLISH} "An existing file with name $DATA_DIR has been found. Cannot create a directory with this name."
  LangString DATADIR_EXIST_ERROR1 ${LANG_RUSSIAN} "Найден файл с именем $DATA_DIR . Создать каталог с этим именем невозможно."

  LangString UNINSTALL_END ${LANG_ENGLISH} "${PRODUCT_NAME_SHORT} has been uninstalled.$\n$\nYou may need to restart your computer as service '$ServiceID_text' still exists.$\n$\nData directory has not been removed: "
  LangString UNINSTALL_END ${LANG_RUSSIAN} "Удаление завершено.$\n$\nВозможно, вам потребуется перезагрузить компьютер, так как существует служба '$ServiceID_text'.$\n$\nКаталог с данными не удалён: "


  LangString MESS_PASS1 ${LANG_ENGLISH} "Passwords do not match."
  LangString MESS_PASS1 ${LANG_RUSSIAN} "Введенные пароль и подтверждение различаются."

  LangString MESS_PASS2 ${LANG_ENGLISH} "You have not entered the password. Do you want to continue without a password?"
  LangString MESS_PASS2 ${LANG_RUSSIAN} "Вы не ввели пароль.$\n$\nПодтверждаете установку без пароля?"

  LangString MESS_PASS3 ${LANG_ENGLISH} "You have entered a password with non-Latin characters. Do you want to use this password?"
  LangString MESS_PASS3 ${LANG_RUSSIAN} "Вы использовали в пароле нелатинские символы. Это может вызвать  \
   проблемы с вводом пароля. Продолжить?"

  LangString MESS_UNSUPPORTED_WINDOWS ${LANG_ENGLISH}  "Your Windows version is too old. At least Windows 2008 Server or Windows 7 SP1 is required to run this product." 
  LangString MESS_UNSUPPORTED_WINDOWS ${LANG_RUSSIAN} "Ваша версия Windows не поддерживается. Для данного продукта требуется Windows 2008 Server или Windows 7 SP1 и выше."

  LangString DLG_PORT ${LANG_ENGLISH} "Port:"
  LangString DLG_PORT ${LANG_RUSSIAN} "Порт:"

  LangString DLG_ADR1 ${LANG_ENGLISH} "Addresses:"
  LangString DLG_ADR1 ${LANG_RUSSIAN} "Адреса:"

  LangString DLG_ADR2 ${LANG_ENGLISH} "Allow connections from any IP address"
  LangString DLG_ADR2 ${LANG_RUSSIAN} "Разрешать подключения с любых IP-адресов"

  LangString DLG_LOCALE ${LANG_ENGLISH} "Locale:"
  LangString DLG_LOCALE ${LANG_RUSSIAN} "Локаль:"

  LangString DLG_SUPERUSER ${LANG_ENGLISH} "Superuser:"
  LangString DLG_SUPERUSER ${LANG_RUSSIAN} "Суперпользователь:"

  LangString DLG_PASS1 ${LANG_ENGLISH} "Password:"
  LangString DLG_PASS1 ${LANG_RUSSIAN} "Пароль:"

  LangString DLG_PASS2 ${LANG_ENGLISH} "Confirm:"
  LangString DLG_PASS2 ${LANG_RUSSIAN} "Подтверждение:"

  LangString DLG_OPT1 ${LANG_ENGLISH} "Server performance can be optimized based on the amount of memory installed: $AllMem MB. \
This setting allocates more memory to the server. \
Configuration parameters are written to the $DATA_DIR\postgresql.conf file."

  LangString DLG_OPT1 ${LANG_RUSSIAN} "Можно провести оптимизацию производительности сервера, исходя из объёма установленной памяти $AllMem МБ. \
Серверу будет выделено больше оперативной памяти. \
Параметры будут записаны в файл $DATA_DIR\postgresql.conf"

  LangString DLG_ENVVAR ${LANG_ENGLISH} "Set up environment variables"
  LangString DLG_ENVVAR ${LANG_RUSSIAN} "Настроить переменные среды"



  LangString DLG_OPT2 ${LANG_ENGLISH} "Tune configuration parameters"
  LangString DLG_OPT2 ${LANG_RUSSIAN} "Провести оптимизацию параметров"

  LangString DLG_OPT3 ${LANG_ENGLISH} "Use default settings"
  LangString DLG_OPT3 ${LANG_RUSSIAN} "Использовать параметры по умолчанию"

  LangString DEF_LOCALE_NAME ${LANG_ENGLISH} "Default"
  LangString DEF_LOCALE_NAME ${LANG_RUSSIAN} "Настройка ОС"



  LangString MESS_STOP_SERVER ${LANG_ENGLISH} "Previous installation was found.$\n$\nTo complete the upgrade, the service needs to restart.$\n$\nDo you want to continue?"
  LangString MESS_STOP_SERVER ${LANG_RUSSIAN} "Обнаружена предыдущая инсталляция.$\n$\nДля обновления требуется перезапуск службы.$\n$\nПродолжить?"

  LangString MESS_ERROR_SERVER ${LANG_ENGLISH} "An error occurred while initializing the server. Server service may have failed to start."
  LangString MESS_ERROR_SERVER ${LANG_RUSSIAN} "При инициализации сервера произошла ошибка. Возможно, служба сервера не смогла запуститься."

  LangString MESS_ERROR_INITDB ${LANG_ENGLISH} "An error occurred while initializing the database."
  LangString MESS_ERROR_INITDB ${LANG_RUSSIAN} "При инициализации базы данных произошла ошибка."

  LangString MESS_ERROR_INITDB2 ${LANG_ENGLISH} "An error occurred while initializing the database. Make sure that Microsoft Visual C++ Redistributable is installed."
  LangString MESS_ERROR_INITDB2 ${LANG_RUSSIAN} "При инициализации базы данных произошла ошибка. Убедитесь, что установлен пакет Microsoft Visual C ++ Redistributable."


LangString componentServer ${LANG_ENGLISH} "Server components"
LangString componentServer ${LANG_RUSSIAN} "Компоненты сервера"


LangString componentClient ${LANG_ENGLISH} "Client components"
LangString componentClient ${LANG_RUSSIAN} "Компоненты клиента"

LangString componentDeveloper ${LANG_ENGLISH} "Developer components"
LangString componentDeveloper ${LANG_RUSSIAN} "Компоненты разработчика"

LangString DESC_componentClient ${LANG_ENGLISH} "Install ${PRODUCT_NAME_SHORT} client components and documentation"
LangString DESC_componentClient ${LANG_RUSSIAN} "Установка файлов клиента ${PRODUCT_NAME_SHORT} и документации."

LangString DESC_componentDeveloper ${LANG_ENGLISH} "Install ${PRODUCT_NAME_SHORT} developer components"
LangString DESC_componentDeveloper ${LANG_RUSSIAN} "Установка файлов ${PRODUCT_NAME_SHORT} для разработчика."


LangString DLG_data-checksums ${LANG_ENGLISH} "Enable data checksums"
LangString DLG_data-checksums ${LANG_RUSSIAN} "Включить контрольные суммы для страниц"


LangString DEF_COLATE_NAME ${LANG_ENGLISH} "Default"
LangString DEF_COLATE_NAME ${LANG_RUSSIAN} "По умолчанию"

LangString MORE_WINUSER ${LANG_ENGLISH} "Windows existing user name:"
LangString MORE_WINUSER ${LANG_RUSSIAN} "Существующий пользователь Windows:"


LangString MORE_WINPASS ${LANG_ENGLISH} "Windows user password:"
LangString MORE_WINPASS ${LANG_RUSSIAN} "Пароль пользователя Windows:"

LangString MORE_SERVICE_TITLE ${LANG_ENGLISH} "System service settings"
LangString MORE_SERVICE_TITLE ${LANG_RUSSIAN} "Параметры системной службы"

LangString MORE_SERVICE_NAME ${LANG_ENGLISH} "System service name:"
LangString MORE_SERVICE_NAME ${LANG_RUSSIAN} "Имя системной службы:"

LangString MORE_COLATION ${LANG_ENGLISH} "Collation provider:"
LangString MORE_COLATION ${LANG_RUSSIAN} "Провайдер правил сортировки:"

LangString MORE_SHOW_MORE ${LANG_ENGLISH} "Show advanced options..."
LangString MORE_SHOW_MORE ${LANG_RUSSIAN} "Показать дополнительные параметры ..."
