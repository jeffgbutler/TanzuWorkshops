# Installing Tanzu Build Service on AWS

Good tutorial: https://tanzu.vmware.com/content/practitioners-blog/getting-started-with-vmware-tanzu-build-service-1-0

## Create a TKG Cluster on AWS using TMC

- Name: jgb-aws-tbs
- Cluster Group: jgb-clustergroup
- Region us-east-2
- Single node control plane

## Install TBS

Download build service TAR, untar

cd ~/Downloads/build-service-1.0.2

docker login registry.pivotal.io
docker login --username=jeffgbutler

kbld relocate -f build-service-1.0.2/images.lock --lock-output build-service-1.0.2/images-relocated.lock --repository jeffgbutler/build-service

export KUBECONFIG=kubeconfig-jgb-aws-tbs.yml

ytt -f build-service-1.0.2/values.yaml \
 -f build-service-1.0.2/manifests/ \
 -v docker_repository="jeffgbutler" \
 -v docker_username="jeffgbutler" \
 -v docker_password="kjLBni7BzEJy" \
 | kbld -f build-service-1.0.2/images-relocated.lock -f- \
 | kapp deploy -a tanzu-build-service -f- -y

kp import -f descriptor-100.0.22.yaml (had to run this several times)

## Setup a Build

Setup dockerhub secret:
kp secret create my-dockerhub-creds --dockerhub jeffgbutler (kjLBni7BzEJy)

kp image create spring-petclinic --tag index.docker.io/jeffgbutler/spring-petclinic --git https://github.com/jeffgbutler/spring-petclinic.git --git-revision main

kp build logs spring-petclinic (tails the build log)

watch kp build list spring-petclinic

## Deploy to K8S

kubectl create deployment spring-petclinic --image=jeffgbutler/spring-petclinic

kubectl expose deployment spring-petclinic --name=spring-petclinic-service --type=LoadBalancer --port 80 --target-port 8080

(get the URL from kubectl get svc - takes a few minutes to provision)
http://a2c608077797649cdabddb13eac4c966-1744668637.us-east-2.elb.amazonaws.com/

## Update the App

watch kp build list spring-petclinic

Update /src/main/resources/messages.properties

Push change, build starts a few seconds later. Much faster this time! Then...

kubectl set image deployment/spring-petclinic spring-petclinic=jeffgbutler/spring-petclinic:latest

kubectl set image deployment/spring-petclinic spring-petclinic=jeffgbutler/spring-petclinic:b3.20201007.133237



See the app has been updated

## Clean Up

kubectl delete service spring-petclinic-service
kubectl delete deployment spring-petclinic
kp image delete spring-petclinic

Reset the welcome message on the Spring app
