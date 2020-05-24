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
- Добавлена папка [dockermonolith/infra](./dockermonolith/infra)
- С помощью Packer собран образ `docker-host`, содержащий установленный Docker
- С помощью Terraform можно запустить конфигурируемое переменной количество инстансов и разрешить трафик на порт 9292
- Ansible устанавливает необходимые для своей работы с докером плагины и запускает контейнер с приложение на каждом инстансе, полученном с помощью динамического inventory.
- Инструкции по запуску инфраструктуры можно найти в [infra README](./dockermonolith/infra/README.md)

### Примечания
- Для доступа к приложению нужно открыть порт `9292` (использовать скрипт [gcloud_add_firewall_rule_puma.sh](./docker-monolith/gcloud_add_firewall_rule_puma.sh)):
```bash
gcloud compute firewall-rules create reddit-app \
 --allow tcp:9292 \
 --target-tags=docker-machine \
 --description="Allow PUMA connections" \
 --direction=INGRESS
```
