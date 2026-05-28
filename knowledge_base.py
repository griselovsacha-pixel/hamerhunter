FIXES = {
    "SQL Injection": "Используйте параметризованные запросы (Prepared Statements). Для PHP – PDO, для Python – SQLAlchemy.",
    "XSS": "Экранируйте вывод (HTML entities). Применяйте Content-Security-Policy.",
    "Command Injection": "Избегайте вызова системных команд с пользовательским вводом. Используйте subprocess с shell=False и белые списки аргументов.",
    "Missing CSP": "Добавьте заголовок Content-Security-Policy: default-src 'self'; script-src 'self'",
    "Missing HSTS": "Добавьте заголовок Strict-Transport-Security: max-age=31536000; includeSubDomains",
    "Missing X-Frame-Options": "Добавьте заголовок X-Frame-Options: DENY",
    "Weak TLS Ciphers": "Обновите конфигурацию TLS, отключите устаревшие протоколы и используйте современные наборы шифров.",
    "Secret in JS": "Никогда не храните секреты в клиентском коде. Используйте переменные окружения на сервере.",
    "SSTI Injection": "Не используйте шаблонизаторы с eval, изолируйте пользовательский ввод.",
    "LFI Injection": "Используйте белые списки файлов, не передавайте пути напрямую из пользовательского ввода.",
    "XXE Injection": "Отключите внешние сущности в парсере XML."
}
