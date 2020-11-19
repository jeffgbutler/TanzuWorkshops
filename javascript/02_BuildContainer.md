# Build a Container

In this lab, we'll show two ways to build images for Node.js applications:

1. We will hand code a docker file and build the container with Docker commands
1. We will use cloud native buildpacks to build an image and test it locally in Docker

## Using Cloud Native Buildpacks and Paketo Buildpacks

1. Install the pack CLI: `brew install buildpacks/tap/pack`

1. List suggested builders: `pack suggest-builders`, see that Paketo build packs are listed. See that most
   buildpacks have support for Node.js applications.

1. `pack build nodejs-payment-calculator --builder paketobuildpacks/builder:base`

1. `docker run -d -p 8080:3000 -t nodejs-payment-calculator`

1. Exercise the app at http://localhost:8080

1. Stop the app...
   1. Get the container ID with `docker ps`
   1. Stop the container with `docker stop <container_id>`
