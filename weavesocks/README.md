# WeaveSocks demo 
This demo application is based on https://microservices-demo.github.io by WeaveWorks

As of Nov 3rd, 2020 it contains the following instrumented microservices: 
- Front-End (NodeJS), 
- Users (go), 
- Orders (Java/Springboot)
- Catalogue (Java/Springboot)
- Cart (go)
- Queue-master (Java/Springboot)
- Shipping (go)
and few database backends/queue manager:
- users-db (MongoDB)
- cart-db (MongoDB)
- orders-db (MongoDB)
- catalog-db (MySQL)
- rabbitmq

To deploy on a Kubernetes/OCP cluster just run 

```sh
kubectl apply -f ocp-sock-shop.yaml
``` 

To expose the application on OCP run:

```sh
oc expose svc front-end -n sock-shop
oc get route front-end -n sock-shop -o custom-columns=URL:.spec.host
```

To run the simulated user traffic against the application, run

```sh
kubectl apply -f loadtest-dep.yaml
```

Tested on IKS 1.18 & OCP 4.3 with cloud-native-monitoring from Cloud Pak for Multicloud Management 2.1


