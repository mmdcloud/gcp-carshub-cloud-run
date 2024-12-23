#!/bin/bash
mkdir code
cp -r ../backend/api/* code/
cd code

docker buildx build --tag carshub-backend --file ./Dockerfile .
docker tag carshub-backend:latest us-central1-docker.pkg.dev/nodal-talon-445602-m1/carshub-backend/carshub-backend:latest
docker push us-central1-docker.pkg.dev/nodal-talon-445602-m1/carshub-backend/carshub-backend:latest