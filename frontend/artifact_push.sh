#!/bin/bash
mkdir frontend-code
cp -r ../../../frontend/* frontend-code/
cd frontend-code

cat > .env << EOL
BASE_URL=$1
CDN_URL=$2
EOL

docker buildx build --tag carshub-frontend --file ./Dockerfile .
docker tag carshub-frontend:latest us-central1-docker.pkg.dev/orbital-bee-455915-h5/carshub-frontend/carshub-frontend:latest
docker push us-central1-docker.pkg.dev/orbital-bee-455915-h5/carshub-frontend/carshub-frontend:latest