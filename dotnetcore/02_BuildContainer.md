# Build a Container

In this lab, we'll show two ways to build images for .Net Core applications:

1. We will use cloud native buildpacks for building OCI images to build an image and test it locally in Docker
1. We will use Tanzu build service to build an image directly from a monitored GitHub repo

## Using Cloud Native Buildpacks and Paketo Buildpacks

1. Install the pack CLI: `brew install buildpacks/tap/pack`

1. List suggested builders: `pack suggest-builders`, see that Paketo build packs are listed.
   The `paketobuildpacks/builder:full` builder has support for .Net

1. `pack build csharp-payment-calculator --builder paketobuildpacks/builder:full`

1. `docker run -d -p 8080:8080 -t csharp-payment-calculator`

1. Exercise the app at http://localhost:8080

1. Stop the app...
   1. Get the container ID with `docker ps`
   1. Stop the container with `docker stop <container_id>`
