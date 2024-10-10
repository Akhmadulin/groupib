#!/bin/bash

# Обновляем список пакетов и устанавливаем необходимые зависимости
sudo apt update
sudo apt install -y  curl ca-certificates curl gnupg lsb-release

# Добавляем официальный GPG-ключ Docker
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

# Добавляем Docker в список репозиториев APT
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Обновляем список пакетов и устанавливаем Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Добавляем текущего пользователя в группу docker для запуска Docker без sudo
sudo usermod -aG docker $USER

# Устанавливаем Docker Compose (если нужна отдельная установка)
DOCKER_COMPOSE_VERSION="v2.20.2"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Перезапускаем систему, чтобы применить изменения
echo "Docker и Docker Compose установлены. Перезагрузите систему для применения изменений."
