###############################################
## One can change docker hub login with
## `make user="<login>" ...`
###############################################
user ?= nikitagsh
export USER_NAME=$(user)

###############################################
## Build images from sources
## and push them to docker hub
###############################################
default: b_all p_all

###############################################
## Build images
###############################################
b_all: b_src b_monitoring

b_src: b_ui b_comment b_post

b_monitoring: b_prometheus b_blackbox-exporter

# ---------------------------------------------- src
b_ui:
	@echo  Build docker image for: ui
	cd src/ui && ./docker_build.sh

b_comment:
	@echo  Build docker image for: comment
	cd src/comment && ./docker_build.sh

b_post:
	@echo  Build docker image for: post
	cd src/post-py && ./docker_build.sh

# ---------------------------------------------- monitoring
b_prometheus:
	@echo  Build docker image for: prometheus
	docker build -t $(user)/prometheus ./monitoring/prometheus

b_blackbox-exporter:
	@echo  Build docker image for: blackbox-exporter
	cd monitoring/blackbox-exporter && ./docker_build.sh

###############################################
## Push images to docker hub
###############################################

p_all: p_src p_monitoring

p_src: p_ui p_comment p_post

p_monitoring: p_prometheus p_blackbox-exporter

# ---------------------------------------------- src
p_ui:
	@echo  Push docker image of: ui
	docker push $(user)/ui

p_comment:
	@echo  Push docker image of: comment
	docker push $(user)/comment

p_post:
	@echo  Push docker image of: post
	docker push $(user)/post

# ---------------------------------------------- monitoring
p_prometheus:
	@echo  Push docker image of: prometheus
	docker push $(user)/prometheus

p_blackbox-exporter:
	@echo  Push docker image of: blackbox-exporter
	docker push $(user)/blackbox-exporter
