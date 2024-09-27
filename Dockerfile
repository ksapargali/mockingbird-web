# Builder stage
FROM node:20-bullseye as builder

# Support custom branches of the react-sdk and js-sdk.
ARG USE_CUSTOM_SDKS=false
ARG REACT_SDK_REPO="https://github.com/matrix-org/matrix-react-sdk.git"
ARG REACT_SDK_BRANCH="master"
ARG JS_SDK_REPO="https://github.com/matrix-org/matrix-js-sdk.git"
ARG JS_SDK_BRANCH="master"

# Установка необходимых пакетов (git, dos2unix)
RUN apt-get update && apt-get install -y git dos2unix && rm -rf /var/lib/apt/lists/*

# Устанавливаем рабочую директорию
WORKDIR /src

# Копируем package.json и yarn.lock для более быстрого кэширования установки зависимостей
COPY package.json yarn.lock /src/

# Устанавливаем зависимости с помощью yarn
RUN yarn --network-timeout=200000 install

# Копируем остальной исходный код
COPY . /src

# Преобразуем скрипты и запускаем сборку
RUN dos2unix /src/scripts/docker-link-repos.sh /src/scripts/docker-package.sh \
    && bash /src/scripts/docker-link-repos.sh

# Запуск сборки приложения
RUN bash /src/scripts/docker-package.sh

# Копируем пример конфигурации
RUN cp /src/config.sample.json /src/webapp/config.json

# App stage
FROM nginx:alpine-slim

# Копируем сборку из builder stage
COPY --from=builder /src/webapp /app

# Заменяем конфигурацию nginx
COPY /nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# Удаляем дефолтную директорию nginx и создаем символьную ссылку на /app
RUN rm -rf /usr/share/nginx/html && ln -s /app /usr/share/nginx/html

# Экспонируем порт (опционально, если требуется)
EXPOSE 80

# Запуск nginx
CMD ["nginx", "-g", "daemon off;"]
