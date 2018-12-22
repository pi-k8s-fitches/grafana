MACHINE=$(shell uname -m)
IMAGE=pi-k8s-fitches-grafana
VERSION=0.1
TAG=$(VERSION)-$(MACHINE)
ACCOUNT=gaf3
NAMESPACE=fitches
PORT=7069
VOLUMES=-v ${PWD}/storage:/var/lib/grafana -v ${PWD}/plugins:/var/lib/grafana/plugins -v ${PWD}/log:/var/log

ifeq ($(MACHINE),armv7l)
BASE=arm32v7/debian:stretch-slim
GRAFANA_URL=https://s3-us-west-2.amazonaws.com/grafana-releases/master/grafana-5.4.0-025d3032pre1.linux-armv7.tar.gz
else
BASE=debian:stretch-slim
GRAFANA_URL=https://s3-us-west-2.amazonaws.com/grafana-releases/master/grafana-5.4.0-025d3032pre1.linux-amd64.tar.gz
endif

.PHONY: build dirs shell start stop push volumes create update delete volumes-dev create-dev update-dev delete-dev

build:
	docker build . --build-arg BASE=$(BASE) --build-arg GRAFANA_URL=$(GRAFANA_URL) -t $(ACCOUNT)/$(IMAGE):$(TAG)

dirs:
	mkdir -p storage
	mkdir -p plugins
	mkdir -p log
	chmod a+w storage
	chmod a+w plugins
	chmod a+w log

shell:
	docker run -it $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(TAG) sh

start:
	docker run --privileged --name $(IMAGE)-$(VERSION) $(VARIABLES) $(VOLUMES) -d --rm -p 127.0.0.1:$(PORT):3000 -h $(IMAGE) $(ACCOUNT)/$(IMAGE):$(TAG)

stop:
	docker rm -f $(IMAGE)-$(VERSION)

push: build
	docker push $(ACCOUNT)/$(IMAGE):$(TAG)

volumes:
	sudo mkdir -p /var/lib/pi-k8s/grafana/storage
	sudo mkdir -p /var/lib/pi-k8s/grafana/plugins
	sudo mkdir -p /var/lib/pi-k8s/grafana/log
	sudo chmod a+w /var/lib/pi-k8s/grafana/storage
	sudo chmod a+w /var/lib/pi-k8s/grafana/plugins
	sudo chmod a+w /var/lib/pi-k8s/grafana/log

create:
	kubectl --context=pi-k8s create -f k8s/pi-k8s.yaml

delete:
	kubectl --context=pi-k8s delete -f k8s/pi-k8s.yaml

update: delete create

volumes-dev: volumes

create-dev:
	kubectl --context=minikube create -f k8s/minikube.yaml

delete-dev:
	kubectl --context=minikube delete -f k8s/minikube.yaml

update-dev: delete-dev create-dev
