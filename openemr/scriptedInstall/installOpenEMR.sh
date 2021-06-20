#!/bin/bash

# Create openemr namespace
kubectl create -f 01-Namespace.yml

# Set permissions in openemr namespace
kubectl create -f 02-RoleBinding.yml

# Configure Helm for Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update

# Install Redis
helm install openemr-redis bitnami/redis --version 14.5.0 --namespace openemr --values 03-RedisValues.yml

# Install MariaDB (MySQL) and wait for it to be ready before continuing
helm install openemr-mysql bitnami/mariadb --version 9.3.14 --namespace openemr --values 04-MariaDBValues.yml --wait

# Install phpMyAdmin
helm install openemr-phpmyadmin bitnami/phpmyadmin --version 8.2.7 --namespace openemr --values 05-phpMyAdminValues.yml

# Create persistent volume claims for OpenEMR
kubectl create -f 06-OpenEMRPVC.yml

# Wait for claims to be bound
while [[ $(kubectl -n openemr get pvc letsencryptvolume -o 'jsonpath={..status.phase}') != "Bound" ]]; do echo "waiting for letsencryptvolume claim" && sleep 1; done
while [[ $(kubectl -n openemr get pvc sslvolume -o 'jsonpath={..status.phase}') != "Bound" ]]; do echo "waiting for sslvolume claim" && sleep 1; done
while [[ $(kubectl -n openemr get pvc websitevolume -o 'jsonpath={..status.phase}') != "Bound" ]]; do echo "waiting for websitevolume claim" && sleep 1; done

# Create OpenEMR Deployment
kubectl create -f 07-OpenEMRDeployment.yml

# OpenEMR can be scaled, but often has issues if the first pod hasn't fully started the initialization sequence before the
# next pods come online. So the deployment only has a single replica, then we can scale up a bit later. So we'll waith for the
# first pod to start and then give it 5 seconds to start the initialization sequence before scaling up.
while [[ $(kubectl -n openemr get pod -l=app=openemr -o 'jsonpath={..status.phase}') != "Running" ]]; do echo "waiting for OpenEMR container to startr" && sleep 1; done
echo "Give the first pod a 5 second head start before scaling up..."
sleep 5
kubectl scale deployment openemr -n openemr --replicas=5

# Create OpenEMR Service
kubectl create -f 08-OpenEMRService.yml
