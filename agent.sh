#!/bin/bash

# === Проверка наличия config.json ===
CONFIG_FILE="config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Файл конфигурации config.json не найден!"
  exit 1
fi

# === Извлечение значений из config.json ===
ORG_ID=$(grep -oP '(?<="id": ")[^"]*' "$CONFIG_FILE")
PASSWORD=$(grep -oP '(?<="password": ")[^"]*' "$CONFIG_FILE")
BINCODES=$(grep -oP '(?<="bincodes": \[)[^\]]*' "$CONFIG_FILE" | tr -d '"' | tr ',' ' ')

# === Генерация случайной соли из 16 символов ===
ORG_SALT=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)

# === Распаковка файлов ===
for archive in agent-conf.*; do
  if [[ -f $archive ]]; then
    case $archive in
      *.zip) unzip "$archive" ;;
      *.tgz) tar -xzf "$archive" ;;
      *) echo "Неизвестный формат: $archive"; exit 1 ;;
    esac
  fi
done

# === Загрузка Docker-образа ===
if [ -f "agent.tar.gz" ]; then
  docker load < agent.tar.gz
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
  -e "s|<group>|$ORG_ID|g" \
  -e "s|<org-signing.key password>|$PASSWORD|g" \
  -e "s|<org-signing.key secret>|$PASSWORD|g" \
  -e "s|<org-encryption.key secret>|$PASSWORD|g" \
  -e "s|<group-encryption.key password>|$PASSWORD|g" \
  -e "s|<org secret salt>|$ORG_SALT|g" \
  "$PRIVATE_YAML"

# === Проверка и добавление строки в config.yaml ===
CONFIG_YAML="agent/config.yaml"
if [ -f "$CONFIG_YAML" ]; then
  if ! grep -q "id: $ORG_ID" "$CONFIG_YAML"; then
    echo "Строка с id: $ORG_ID не найдена. Добавляем в config.yaml..."
    cat <<EOF >> "$CONFIG_YAML"

    - id: $ORG_ID
      title: $ORG_ID
      signing-certificate-file: certs/${ORG_ID}-signing.crt
EOF
  else
    echo "Строка с id: $ORG_ID уже присутствует в config.yaml."
  fi
else
  echo "Файл config.yaml не найден!"
  exit 1
fi

# === Переход в каталог agent ===
cd agent || { echo "Каталог agent не найден!"; exit 1; }

# === Извлечение версии из docker-compose.yml или .yaml ===
if [ -f "docker-compose.yml" ]; then
  VERSION=$(grep -oP '(?<=agent:)[^"]+' docker-compose.yml | tr -d ' :')
elif [ -f "docker-compose.yaml" ]; then
  VERSION=$(grep -oP '(?<=agent:)[^"]+' docker-compose.yaml | tr -d ' :')
else
  echo "Файл docker-compose не найден!"
  exit 1
fi

# === Вывод версии и запуск Docker-команд ===
echo "Используемая версия: $VERSION"

# Фильтр изображений с нужной версией
docker images --filter=reference="harbor.sbcommon.gibdev.net/sb/cfip/agent:$VERSION"

# Запуск контейнера
docker compose up -d agent

echo "Скрипт успешно завершен."
