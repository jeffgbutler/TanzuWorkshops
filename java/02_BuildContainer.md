# Build a Container

In this lab, we'll show two ways to build images for Spring Boot applications:

1. We will use Spring Boot's native support for building OCI images to build an image and test it locally in Docker
1. We will use Tanzu build service to build an image directly from a monitored GitHub repo

## Spring Boot Native Support

Spring Boot includes support for building OCI images natively. This save developers from building a bespoke DOCKER file
for each application. It also ensures that images are built in the most efficient manner - meaining they are
well layered for maximum reuse of fundamental layers.

Spring Boot's native image support is based on Paketo open source build packs (https://paketo.io/)

./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=workshop/payment-calculator

docker run -p 8080:8080 -t workshop/payment-calculator
