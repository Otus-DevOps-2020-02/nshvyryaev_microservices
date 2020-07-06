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
- Добавлена папка [docker-monolith/infra](docker/docker-monolith/infra)
- С помощью Packer собран образ `docker-host`, содержащий установленный Docker
- С помощью Terraform можно запустить конфигурируемое переменной количество инстансов и разрешить трафик на порт 9292
- Ansible устанавливает необходимые для своей работы с докером плагины и запускает контейнер с приложение на каждом инстансе, полученном с помощью динамического inventory.
- Инструкции по запуску инфраструктуры можно найти в [infra README](docker/docker-monolith/infra/README.md)

### Примечания
- Для доступа к приложению нужно открыть порт `9292` (использовать скрипт [gcloud_add_firewall_rule_puma.sh](docker/docker-monolith/gcloud_add_firewall_rule_puma.sh)):
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
  - Образ на основе `FROM ruby:2.2-alpine` с удалением `build-base` вышел 162 Mb, но теперь установка пакетов не кэшируется ([Dockerfile.1](src/ui/Dockerfile.1))
  - Образ собранный из `FROM alpine:3.11.6` без удаления `build-base` весит 253 Mb ([Dockerfile](src/ui/Dockerfile))
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

## ДЗ №14 - Docker 4: сети, docker-compose
- Выполнены эксперименты с запуском docker-контейнеров в сети с драйверами none, host, bridge

- Запуск больше одного контейнера nginx с `--network host` невозможен так как порт уже занят, возникает ошибка,
в случае запуска nginx с `--network none` все хорошо - каждый раз создаётся отдельный network namespace.

- Сервисы запущены через `docker run` с использование двух сетей `front_net` и `back_net`, так чтобы ui не имел доступа к mongodb.
При запуске докер может добавить только одну сеть, подсоединять новую надо отдельной командой `docker network connect front_net post`.

- Проведены исследования bridge-интерфейсов и сетей на docker-machine.

- Создан файл [docker-compose.yml](docker/docker-compose.yml)
  - Добавлен alias `comment_db` для базы, иначе сервис комментариев ее не видит. Можно так же подправить переменную окружения в docker-compose.yml для сервиса comment.
- Создан файл с переменными [.env](docker/.env), [docker-compose.yml](docker/docker-compose.yml) параметризован
- Созданные сущности имеют префикс `src` - название директории, в которой находится docker-compose.yml. Можно переопределить с помощью:
  - [COMPOSE_PROJECT_NAME](https://docs.docker.com/compose/reference/envvars/#compose_project_name)
  - Из командной строки с ключом [-p, --project-name NAME](https://docs.docker.com/compose/reference/overview/)
  - Примечание: ключ командной строки перебивает значение переменной.
- (★) Создан `docker-compose.override.yml` для запуска puma в режиме debug с двумя воркерами, а также с возможностью динамического редактирования кода
  - `docker-compose.override.yml` ломает запуск приложения на docker-host, так как на нем нет копии нужных файлов. Локально все работает.

### Как запустить
- docker-compose up -d
- docker-compose down

### Как проверить
- Выполнить `docker-machine ls` для получени IP адреса docker-host
- Зайти на `http://<docker-host-ip>:9292/`
- Написать пост

## ДЗ №15 - Gitlab 1: построение процесса непрерывной поставки
- Запущен docker-host в GCE
- Установлен gitlab
- Запущен docker runner для проекта
- Создан Gitlab-проект и настроен для использования CI/CD. Этот репозиторий запушен в него как в дополнительный remote.
- CI/CD сконфигурирован запускать тесты, ссылаться на динамические окружения с учетом требований к веткам и других ограничений (тэги, ручной запуск).

### Как запустить
#### Установка gitlab
- Выполнить [скрипт запуска docker-host в GCE](gitlab-ci/docker-machine/create.sh)
- Выполнить [скрипт установки Gitlab](gitlab-ci/docker-machine/install_gitlab.sh)
(выполнять из папки `gitlab-ci/docker-machine/`)
#### Запуск runner
- Используя docker-machine (`eval $(docker-machine env gitlab-ci)`)
- Выполнить
 ```
docker run -d --name gitlab-runner --restart always \
            -v /srv/gitlab-runner/config:/etc/gitlab-runner \
            -v /var/run/docker.sock:/var/run/docker.sock \
            gitlab/gitlab-runner:latest
```
- Для регистрации runner выполнить `docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false`

### Как проверить
- После установки Gitlab на VM можно перейти по http://VM_PUBLIC_IP. (Начальная инициализация Gitlab может занять несколько минут)
- Добавленные для проекта раннеры видны тут: http://VM_PUBLIC_IP/group/project/-/settings/ci_cd

## ДЗ №16 - Monitoring 1: Введение. Системы мониторинга
- Запущен docker-host в GCE: [команды тут](monitoring/docker-machine.md)
- Добалвен Docker образ для [Prometheus](monitoring/prometheus/Dockerfile)
- Собраны образы сервисов командами `bash docker_build.sh`
 в каждой из папок `src/ui`, `src/post-py`, `src/comment`
- Prometheus добавлен в [docker-compose.yml](docker/docker-compose.yml)
- Использован UI Prometheus для проверки состояния приложения
- Добавлен node_exporter
- Собранные образы запушены в [Docker Hub](https://hub.docker.com/u/nikitagsh)
- Добавлены экспортеры:
  - (★) Для MongoDB ( [github](https://github.com/percona/mongodb_exporter), [dockerhub](https://hub.docker.com/r/bitnami/mongodb-exporter) )
  - (★) black-box для контроля работы сервисов ([github](https://github.com/prometheus/blackbox_exporter), [dockerhub](https://hub.docker.com/r/prom/blackbox-exporter/))
- (★) Добавлен [Makefile](Makefile) для сборки образов и доставки их в Docker Registry

### Как запустить
- Создать инстанс в GCE: [команды тут](monitoring/docker-machine.md)
- Создать правила файервола: [script](monitoring/gcloud_add_firewall_rules_prometheus_puma.sh)
- Собрать все необходимые образы командой `make b_all`
- Запустить докер-инфраструктуру
```bash
cd ./docker
docker-compose -f docker-compose.yml up -d
```
- Запушить в Docker Registry можно командо `make p_all`

### Как проверить
- Получить IP адрес VM с запущенными сервисами `docker-machine ip docker-host`
- Приложение должно быть доступно по http://docker-host-ip:9292
- Prometheus должен быть доступен по http://docker-host-ip:9090

## ДЗ-19 "Введение в Kubernetes"

  - Kubernetes кластер развернут в GCP вручную, следуя туториалу
    [The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

    Выполненные шаги и заметки собраны [здесь](./kubernetes/the_hard_way/THE_HARD_WAY.md)

  - Проверено, что в созданном K8s-кластере заготовки деплойментов
    ([*-deployment.yml](./kubernetes/reddit)) применяются и поды создаются

### Как запустить проект:

  - Выполнить инстукции туториала The Hard Way

    _Чтобы учесть огрничение GCP в 4 IP-адресса,
     вместо 3 контроллеров и 3 воркеров,
     создаются 2 контролллера и 2 воркера.
     Команды из инструкции были скорректированы с учетом этого_

### Как проверить работоспособность:

  - Проверка работоспособности K8s-кластера выполняется шагом
    [Smoke Test](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/13-smoke-test.md)

  - Проверить запуск подов reddit-приложения можно командой

        kubectl get pods
