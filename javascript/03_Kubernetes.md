# Run the Container in Kubernetes

## Pre-Requisites

For ease of use, these instructions assume you are running Kubernetes with Docker desktop. Docker desktop
includes load balancer support so services can easily be exposed on "localhost". Docker desktop also allows
you to easily run images that are on your local machine only.

Working with Kubernetes is done via the Kubernetes CLI called `kubectl`. You can install Kubectl via instructions
here: https://kubernetes.io/docs/tasks/tools/install-kubectl/

For MacOS, we recommend install via homebrew:

```bash
brew install kubectl
```

## Run the Application

1. Create a file called `payment-calculator.yml` in the project root directory and set the contents to the following:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: payment-calculator
     labels:
       app: payment-calculator
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: payment-calculator
     template:
       metadata:
         labels:
           app: payment-calculator
       spec:
         containers:
         - name: nodejs-payment-calculator
           image: nodejs-payment-calculator
           imagePullPolicy: Never
           env:
           - name: MY_INSTANCE_NAME
             valueFrom:
               fieldRef:
                 fieldPath: metadata.name
           resources:
             limits:
               memory: "128Mi"
               cpu: "500m"
           ports:
           - containerPort: 3000
   ---
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       app: payment-calculator
     name: payment-calculator
   spec:
     ports:
     - port: 3000
       protocol: TCP
       targetPort: 3000
     selector:
       app: payment-calculator
     type: LoadBalancer
     sessionAffinity: None
   status:
     loadBalancer: {}
   ```

1. Run the command `kubectl create -f payment-calculator.yml`

Important notes:

1. This will create the deployment on Kubernetes with three instances of the app.
1. Note the use of `imagePullPolicy: Never` - this will run the image from your local registry and not try to
   download the image from Docker hub.
1. The service uses `type:LoadBalancer` which works well for Kubernetes in Docker desktop. But typically load
   balancers are only supported on more advanced Kubernetes installs

You can now execrise the application with the traffic simulator at http://localhost:3000

Some things to look for:

- Do you see the load balancer routing traffic among the three instances?
- Why aren't the hit counters consistent?
- What happens when you crash the app?

## Clean Up

Kubernetes takes quite a few resources to run, so I usually stop it after I am finished. This is a controlled
shutdown:

1. Delete the service: `kubectl delete service payment-calculator`
1. Delete the deployment `kubectl delete deployment payment-calculator`
1. Stop the Kubernetes service in Docker desktop
