#!/bin/bash

while true; do
    read -p "Have you created the NFS file server? [yn]" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Create openemr namespace
kubectl create -f ../clusterPreparation/01-Namespace.yml

# Set permissions in openemr namespace
kubectl create -f ../clusterPreparation/02-RoleBinding.yml

# Configure Helm for Bitnami and the NFS external provisioner
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

helm repo update

# Install and configure the NFS External provisioner (for enabling ReadWriteMany access mode)
helm install nfs-subdir-external-provisioner --namespace openemr nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -f ../clusterPreparation/03-NfsProvisionerValues.yml

# Install Redis
helm install openemr-redis bitnami/redis --version 14.5.0 --namespace openemr --values 01-RedisValues.yml

# Install MariaDB (MySQL) and wait for it to be ready before continuing
helm install openemr-mysql bitnami/mariadb --version 9.3.14 --namespace openemr --values 02-MariaDBValues.yml --wait

# Install phpMyAdmin
helm install openemr-phpmyadmin bitnami/phpmyadmin --version 8.2.7 --namespace openemr --values 03-phpMyAdminValues.yml

# Create persistent volume claims for OpenEMR
kubectl create -f 04-OpenEMRPVC.yml

# Wait for claims to be bound
while [[ $(kubectl -n openemr get pvc letsencryptvolume -o 'jsonpath={..status.phase}') != "Bound" ]]; do echo "waiting for letsencryptvolume claim" && sleep 1; done
while [[ $(kubectl -n openemr get pvc sslvolume -o 'jsonpath={..status.phase}') != "Bound" ]]; do echo "waiting for sslvolume claim" && sleep 1; done
while [[ $(kubectl -n openemr get pvc websitevolume -o 'jsonpath={..status.phase}') != "Bound" ]]; do echo "waiting for websitevolume claim" && sleep 1; done

# Create OpenEMR Deployment
kubectl create -f 05-OpenEMRDeployment.yml

# OpenEMR can be scaled, but often has issues if the first pod hasn't fully started the initialization sequence before the
# next pods come online. So the deployment only has a single replica, then we can scale up a bit later.
echo "Give the first pod a 60 second head start before scaling up..."
sleep 60
kubectl scale deployment openemr -n openemr --replicas=5

# Create OpenEMR Service
kubectl create -f 06-OpenEMRService.yml
