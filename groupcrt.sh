#!/bin/bash

# Чтение имени организации из config.json
ORG_NAME=$(jq -r '.id' config.json)
PASSWORD=$(jq -r '.password' config.json)

# Определение CMS файла
CMS_FILE=$(ls *.p7s 2>/dev/null | head -n 1)

if [ -z "$CMS_FILE" ]; then
    echo "Файл с расширением .p7s не найден." >&2
    exit 1
fi

# Определение сертификата лидера в зависимости от имени файла CMS
if [[ "$CMS_FILE" == group1* ]]; then
    LEADER_CERT="IYB-signing.crt"
elif [[ "$CMS_FILE" == group2* ]]; then
    LEADER_CERT="BRB-signing.crt"
else
    echo "Неизвестный префикс для файла $CMS_FILE. Не удалось определить сертификат лидера." >&2
    exit 1
fi

# Переменные для последующих шагов
OUTPUT_CMS_DECRYPTED="${CMS_FILE%.p7s}.p7e"
ORG_PRIVATE_KEY="${ORG_NAME}-encryption.key"
GROUP_NAME="group_${ORG_NAME}" # Динамическое название группы на основе имени организации

# Шаг 1: Проверка CMS-контейнера с использованием сертификата подписи лидера
echo "Проверка CMS-контейнера с сертификатом подписи лидера ($LEADER_CERT)..."
openssl cms -verify -inform PEM -noverify \
    -signer "$LEADER_CERT" \
    -in "$CMS_FILE" \
    -out "$OUTPUT_CMS_DECRYPTED"

if [ $? -eq 0 ]; then
    echo "Проверка CMS прошла успешно"
else
    echo "Проверка CMS не удалась" >&2
    exit 1
fi

# Шаг 2: Расшифровка CMS-файла с использованием закрытого ключа организации
echo "Расшифровка CMS-файла..."
GROUP_PFX="${GROUP_NAME}.pfx"
openssl cms -decrypt -inform PEM \
    -in "$OUTPUT_CMS_DECRYPTED" \
    -inkey "$ORG_PRIVATE_KEY" \
    -out "$GROUP_PFX"

if [ $? -eq 0 ]; then
    echo "Расшифровка успешна"
else
    echo "Ошибка расшифровки" >&2
    exit 1
fi

# Шаг 3: Извлечение закрытого ключа группы в формате PKCS#8
echo "Извлечение закрытого ключа группы..."
GROUP_KEY="${GROUP_NAME}-encryption.key"
openssl pkcs12 -info -nocerts -passin pass:"$PASSWORD" \
    -in "$GROUP_PFX" \
    -out "$GROUP_KEY"

if [ $? -eq 0 ]; then
    echo "Извлечение ключа группы успешно"
else
    echo "Ошибка извлечения ключа" >&2
    exit 1
fi

# Шаг 4: Извлечение сертификата шифрования группы
echo "Извлечение сертификата шифрования группы..."
GROUP_CERT="${GROUP_NAME}-encryption.crt"
openssl pkcs12 -info -nokeys -passin pass:"$PASSWORD" \
    -in "$GROUP_PFX" \
    -out "$GROUP_CERT"

if [ $? -eq 0 ]; then
    echo "Извлечение сертификата группы успешно"
else
    echo "Ошибка извлечения сертификата" >&2
    exit 1
fi

echo "Все шаги успешно выполнены."