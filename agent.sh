#!/bin/bash

# === Проверка наличия config.json ===
CONFIG_FILE="config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Файл конфигурации config.json не найден!"
  exit 1
fi

# === Извлечение значений из config.json ===
ORG_ID=$(grep -oP '(?<="id": ")[^"]*' $CONFIG_FILE)
PASSWORD=$(grep -oP '(?<="password": ")[^"]*' $CONFIG_FILE)

# === Генерация случайного соли из 16 символов ===
ORG_SALT=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)

# === Распаковка файлов ===
for archive in agent.* agent-conf.*; do
  if [[ -f $archive ]]; then
    case $archive in
      *.zip) unzip "$archive" ;;
      *.tgz) tar -xzf "$archive" ;;
      *) echo "Неизвестный формат: $archive"; exit 1 ;;
    esac
  fi
done

# === Загрузка Docker-образа ===
if [ -f "agent.tar" ]; then
  docker load -i agent.tar
else
  echo "Файл agent.tar не найден!"
  exit 1
fi

# === Копирование сертификатов ===
if [ -d "certs" ] && [ -d "agent/certs" ]; then
  cp -R certs/* agent/certs/
else
  echo "Папка certs или agent/certs не найдена!"
  exit 1
fi

# === Обработка файла agent/private.yaml ===
PRIVATE_YAML="agent/private.yaml"
if [ ! -f "$PRIVATE_YAML" ]; then
  echo "Файл agent/private.yaml не найден!"
  exit 1
fi

# Создаем обновленную версию private.yaml с замененными значениями
sed -i \
  -e "s|<org>|$ORG_ID|g" \
  -e "s|<org-signing.key password>|$PASSWORD|g" \
  -e "s|<org-encryption.key secret>|$PASSWORD|g" \
  -e "s|<org secret salt>|$ORG_SALT|g" \
  "$PRIVATE_YAML"

echo "Скрипт успешно завершен."