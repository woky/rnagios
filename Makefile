N = rchainops/rnagios
V = $(shell git describe --tags)

.PHONY: all
all: build

.PHONY: build
build:
	docker build -t $(N):$(V) .
	docker tag $(N):$(V) $(N):latest

.PHONY: push
push: build
	docker push $(N):$(V)
	docker push $(N):latest
