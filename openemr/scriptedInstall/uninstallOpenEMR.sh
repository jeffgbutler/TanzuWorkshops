#!/bin/bash

# Delete OpenEMR Service
kubectl delete -f 06-OpenEMRService.yml

# Delete OpenEMR Deployment
kubectl delete -f 05-OpenEMRDeployment.yml

# Delete persistent volume claims for OpenEMR
kubectl delete -f 04-OpenEMRPVC.yml

# Delete phpMyAdmin
helm uninstall openemr-phpmyadmin --namespace openemr

# Delete MariaDB (MySQL)
helm uninstall openemr-mysql --namespace openemr

# Delete Redis
helm uninstall openemr-redis --namespace openemr

# Uninstall the NFS External provisioner
helm uninstall nfs-subdir-external-provisioner --namespace openemr

# Delete openemr namespace
kubectl delete -f ../clusterPreparation/01-Namespace.yml

echo "Remember to remove the NFS File Server!"
