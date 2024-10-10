#!/bin/bash

# Чтение конфигурационного файла
CONFIG_FILE="config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Файл конфигурации не найден!"
  exit 1
fi

# Извлечение значений id и password из конфигурационного файла
ORG_ID=$(grep -oP '(?<="id": ")[^"]*' $CONFIG_FILE)
PASSWORD=$(grep -oP '(?<="password": ")[^"]*' $CONFIG_FILE)

# Проверяем, что id и пароль не пусты
if [ -z "$ORG_ID" ] || [ -z "$PASSWORD" ]; then
  echo "ID или пароль не найдены в конфигурации!"
  exit 1
fi

# Генерация signing key
echo "Генерация signing key..."
openssl ecparam -name prime256v1 -genkey -noout | \
openssl pkcs8 -topk8 -out ${ORG_ID}-signing.key -passout pass:${PASSWORD}

# Генерация encryption key
echo "Генерация encryption key..."
openssl ecparam -name prime256v1 -genkey -noout | \
openssl pkcs8 -topk8 -out ${ORG_ID}-encryption.key -passout pass:${PASSWORD}

# Генерация signing certificate
echo "Генерация signing сертификата..."
openssl req -new -x509 -days 1095 \
-key ${ORG_ID}-signing.key -passin pass:${PASSWORD} \
-out ${ORG_ID}-signing.crt \
-subj "/O=${ORG_ID}/CN=CFIP signing"

# Генерация encryption certificate
echo "Генерация encryption сертификата..."
openssl req -new -x509 -days 1095 \
-key ${ORG_ID}-encryption.key -passin pass:${PASSWORD} \
-out ${ORG_ID}-encryption.crt \
-subj "/O=${ORG_ID}/CN=CFIP encryption"

echo "Генерация завершена. Сертификаты и ключи созданы."
