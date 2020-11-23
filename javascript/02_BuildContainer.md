# Build a Container

In this lab, we'll show two ways to build images for Node.js applications:

1. We will hand code a docker file and build the container with Docker commands
1. We will use cloud native buildpacks to build an image and test it locally in Docker

## Hand Code a Docker File

This is adapted from instructions here: https://nodejs.org/en/docs/guides/nodejs-docker-webapp/

Note the instructions state that this method is not for production. That is a handy disclaimer that basically means "building proper containers is a very complicated task and should be left to experts".

1. Create a file called `Dockerfile` in the root directory of your application and set the contents to the following:

   ```dockerfile
   FROM node:14

   WORKDIR /usr/src/app

   # Install app dependencies
   # A wildcard is used to ensure both package.json AND package-lock.json are copied
   # where available (npm@5+)
   COPY package*.json ./

   RUN npm install
   # If you are building your code for production
   # RUN npm ci --only=production

   # Bundle app source
   COPY . .

   EXPOSE 3000

   CMD [ "node", "./bin/www" ]
   ```

1. Create a file called `.dockerignore` in the root directory of your application and set the contents to the following:

   ```gitignore
   node_modules
   .git
   .gitignore
   ```

1. Build the image: `docker build -t df-nodejs-payment-calculator .`

1. Run the container: `docker run -p 3030:3000 --env MY_INSTANCE_NAME=df_docker -d df-nodejs-payment-calculator`

   This will expose the container http://localhost:3030. You can use that URL in the traffic similator. What
   happens when you crash the app?

1. Stop the app...
   1. Get the container ID with `docker ps`
   1. Stop the container with `docker stop <container_id>`

## Using Cloud Native Buildpacks and Paketo Buildpacks

1. Create a file called `project.toml` in the project root and set the contents to the following:

   ```gitignore
   [build]
   exclude = [
       ".git",
       ".gitignore"
   ]
   ```
   
1. Install the pack CLI: `brew install buildpacks/tap/pack`

1. List suggested builders: `pack suggest-builders`, see that Paketo build packs are listed. See that most
   buildpacks have support for Node.js applications.

1. `pack build nodejs-payment-calculator --builder paketobuildpacks/builder:base`

1. `docker run -d -p 3040:3000 --env MY_INSTANCE_NAME=bp_docker -t nodejs-payment-calculator`

1. Exercise the app at http://localhost:3040

1. Stop the app...
   1. Get the container ID with `docker ps`
   1. Stop the container with `docker stop <container_id>`

