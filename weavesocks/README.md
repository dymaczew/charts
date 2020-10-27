# WeaveSocks demo 
This demo application is based on https://microservices-demo.github.io by WeaveWorks

As of Oct 27th it contains 3 instrumented microservices: Front-End (NodeJS), Users (go) and Orders (Java/Springboot)

To deploy on a Kubernetes cluster just run 

```sh
kubectl apply -f instrumented-demo.yaml
``` 

Tested on IKS 1.18 with cloud-native-monitoring from Cloud Pak for Multicloud Management 2.1


