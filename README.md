# nshvyryaev_microservices [![Build Status](https://travis-ci.com/Otus-DevOps-2020-02/nshvyryaev_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2020-02/nshvyryaev_microservices)
nshvyryaev microservices repository

## ДЗ12 - Docker 2
- Настроены репозиторий и Travis
- Использованы базовые команды для работы с контейнерами: run, start, create, commit, inspect, ps
- (*) Выполнено сравнение вывода команды inspect для контейнера и образа
- Образ запушен в Docker Hub
```
docker tag reddit:latest nikitagsh/otus-reddit:1.0
docker push nikitagsh/otus-reddit:1.0
```

### Как запустить проект
- Предварительно нужно авторизовать приложения с помощью команды `gcloud auth application-default login`
- Для запуска docker host в GCP выполнить команду
 ```
 docker-machine create --driver google  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts  --google-machine-type n1-standard-1  --google-zone europe-west1-b  docker-host
 ```
- Начать использовать docker host можно командой `eval $(docker-machine env docker-host)`
- Для сборки образа выполнить команду `docker build -t reddit:latest .` в папке `dockermonolith`
- Для запуска контейнера из собранного образа - `docker run --name reddit -d --network=host reddit:latest`
- Запустить локально из запушенного образа - `docker run --name reddit -d -p 9292:9292 --rm nikitagsh/otus-reddit:1.0`

### (*) Создание окружения с помощью Packer, Terraform, Ansible
- Добавлена папка [dockermonolith/infra](docker-monolith/infra)
- С помощью Packer собран образ `docker-host`, содержащий установленный Docker
- С помощью Terraform можно запустить конфигурируемое переменной количество инстансов и разрешить трафик на порт 9292
- Ansible устанавливает необходимые для своей работы с докером плагины и запускает контейнер с приложение на каждом инстансе, полученном с помощью динамического inventory.
- Инструкции по запуску инфраструктуры можно найти в [infra README](docker-monolith/infra/README.md)

### Примечания
- Для доступа к приложению нужно открыть порт `9292` (использовать скрипт [gcloud_add_firewall_rule_puma.sh](./docker-monolith/gcloud_add_firewall_rule_puma.sh)):
```bash
gcloud compute firewall-rules create reddit-app \
 --allow tcp:9292 \
 --target-tags=docker-machine \
 --description="Allow PUMA connections" \
 --direction=INGRESS
```

## ДЗ №13 - Docker 3
- Скопирован код микросервисов
- Созданы Dockerfile для каждого сервиса:
  - [post](src/post-py/Dockerfile)
  - [comment](src/comment/Dockerfile)
  - [ui](src/ui/Dockerfile)
- Все файлы пропущены через линтер командой `docker run --rm -i hadolint/hadolint < Dockerfile`
- Найденые проблемы исправлены
- Выполнена сборка образов командами
  - `docker build -t nikitagsh/post:1.0 ./post-py`
  - `docker build -t nikitagsh/comment:1.0 ./comment`
  - `docker build -t nikitagsh/ui:1.0 ./ui`
  - Сборка ui началась с шага копирования Gemfile
- Запущено приложение командами, запущено приложение, проверена работоспособность
- (★) Запуск с другими алиасами:
  - Остановить все контейнеры `docker kill $(docker ps -q)`
  - `docker run -d --network=reddit --network-alias=post_db_alt --network-alias=comment_db_alt mongo:latest`
  - `docker run -d --network=reddit --network-alias=post_alt -e POST_DATABASE_HOST=post_db_alt nikitagsh/post:1.0`
  - `docker run -d --network=reddit --network-alias=comment_alt -e COMMENT_DATABASE_HOST=comment_db_alt nikitagsh/comment:1.0`
  - `docker run -d --network=reddit -e POST_SERVICE_HOST=post_alt -e COMMENT_SERVICE_HOST=comment_alt -p 9292:9292 nikitagsh/ui:1.0`
- Изменен образ UI, сборка началась с 1 шага, так как изменился базовый образ
- (★) Образ UI собран из ruby:alpine, понадобилось добавить build-base для сборки приложения.
  - Образ на основе `FROM ruby:2.2-alpine` с удалением `build-base` вышел 162 Mb, но теперь установка пакетов не кэшируется
  - Образ собранный из `FROM alpine:3.11.6` без удаления `build-base` весит 253 Mb ([Dockerfile.1](src/ui/Dockerfile.1))
- Создан Volume `docker volume create reddit_db`
- Созданный volume подключен к базе с помощью флага `-v reddit_db:/data/db`. Теперь посты переживают перезапуск контейнеров.

### Как запустить
- Команды для запуска:
  - `docker network create reddit`
  - `docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest`
  - `docker run -d --network=reddit --network-alias=post nikitagsh/post:1.0`
  - `docker run -d --network=reddit --network-alias=comment nikitagsh/comment:1.0`
  - `docker run -d --network=reddit -p 9292:9292 nikitagsh/ui:3.0`

### Как проверить
- Выполнить `docker-machine ls` для получени IP адреса docker-host
- Зайти на `http://<docker-host-ip>:9292/`
- Написать пост
