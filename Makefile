IRODS_CLIENT_REST_IMAGE=irods_client_rest
IRODS_CLIENT_REST_DOCKERFILE=Dockerfile

.EXPORT_ALL_VARIABLES:

.PHONY: image
image:
	docker build -t $(IRODS_CLIENT_REST_IMAGE):latest -f $(IRODS_CLIENT_REST_DOCKERFILE) .

.PHONY: run
run:
	docker run -ti --name $(IRODS_CLIENT_REST_IMAGE) $(IRODS_CLIENT_REST_IMAGE):latest /bin/bash