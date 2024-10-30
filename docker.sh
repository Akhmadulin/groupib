#!/bin/bash

# Обновляем список пакетов и устанавливаем необходимые зависимости
sudo apt update
sudo apt install -y curl ca-certificates gnupg lsb-release

# Создаём директорию для ключей (если ещё не создана)
sudo mkdir -m 0755 -p /etc/apt/keyrings

# Добавляем официальный GPG-ключ Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавляем Docker в список репозиториев APT
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Обновляем список пакетов
sudo apt update

# Устанавливаем Docker Engine и необходимые плагины
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Проверяем, существует ли группа docker, и создаём её при необходимости
if ! getent group docker > /dev/null; then
  sudo groupadd docker
fi

# Добавляем текущего пользователя в группу docker
sudo usermod -aG docker $USER

# Устанавливаем Docker Compose (если нужна отдельная установка)
DOCKER_COMPOSE_VERSION="v2.20.2"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Docker и Docker Compose установлены. Перезагрузите систему для применения изменений."
