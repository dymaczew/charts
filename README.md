# IBM Cloud Pak for Multicloud Management demo applications

This is the repository containg artifacts used to install Bookinfo app for demonstrating the capabilities of monitoring module (former name: IBM Cloud App Management) of IBM Cloud Pak for Multicloud Management.

- [IBM Cloud Pak for Multicloud Management demo applications](#ibm-cloud-pak-for-multicloud-management-demo-applications)
  - [Installation as native Mulicluster app](#installation-as-native-mulicluster-app)
  - [Prerequisite for installation on Cloud Pak for MCM 1.3.x](#prerequisite-for-installation-on-cloud-pak-for-mcm-13x)
  - [Legacy method 1: helm chart installation](#legacy-method-1-helm-chart-installation)
    - [Creating the namespace and imagepolicy](#creating-the-namespace-and-imagepolicy)
    - [Adding helm repo](#adding-helm-repo)
    - [Helm chart installation](#helm-chart-installation)
  - [Legacy method 2: helm based MCM app (helm chart a single deployable)](#legacy-method-2-helm-based-mcm-app-helm-chart-a-single-deployable)
  - [Troubleshooting](#troubleshooting)
  - [References & Useful Links](#references--useful-links)

Bookinfo app is based on sample app from [Istio samples](https://github.com/istio/istio/tree/master/samples/bookinfo)

![](images/2020-01-24-17-36-47.png)


## Installation as native multi-cluster app

To install bookinfo as MCM native app you need a cluster with IBM CloudPak for Multicloud Management 1.2 or newer.

For IBM Cloud Pak for Multicloud Management 2.x you want to first deploy cloud native monitoring on a managed cluster. Some hints how to do this you can find [here](How%20to%20install%20cloud%20native%20monitoring%20on%20managed%20clusters.md)

1. Clone this repo to your local workstation

   ```sh
   git clone https://github.com/dymaczew/charts.git
   cd charts
   ```

   If you are installing on CP4MCM 2.x use bookinfo-multicluster-2020.2.1

   ```sh
   oc apply -f bookinfo-multicluster-2020.2.1
   ```

1. Below you can find the explanantion of the content of the files in this directory:
   
   - **00-bookinfo-prereq.yaml**
   contains definition of namespaces **bookinfo**, **bookinfo-source** and **bookinfo-project** and ImagePolicy (in case you have the admission controller installed)

   - **files named 01-.. to 05-..**
   contain definition of deployables for Bookinfo microservices

   - **06-bookinfo-ns-channel.yaml**
   contains definition of channel pointing at the namespace *bookinfo-source*

   - **07-bookinfo-placementrules.yaml**
   contains the placement rule by default targeting the cluster with label `environment=Dev`

   - **08-bookinfo-multicluster.yaml**
   contains the definiton of application and subscription

   - **10-load-generator.yaml**
   contains the definiton of simple load generator that generates traffic against bookinfo app

2. By default the `01-productpage-deployable.yaml` includes the deployable for ingress  with "/bookinfo" path. You may wish to customize or add the route deployable for deployments on OpenShift clusters
   
HINT: Target cluster should have a ICAM klusterlet deployed. In order to see a service deployment topology you need to generate some traffic against the application. 

## Prerequisite for installation on Cloud Pak for MCM 1.3.x

This app to function correctly on version prior to 2.0 requires ICAM configuration secret created in a target namespace (bookinfo by default) according to the ICAM Knowledge Center: 

[Obtaining the server configuration information](https://www.ibm.com/support/knowledgecenter/en/SSFC4F_1.3.0/icam/dc_config_server_info.html)

Go to the ibm-cloud-apm-dc-configpack directory where you extract the configuration package and run the following command to create a secret to connect to the server, for example, name it as icam-server-secret.
```
kubectl -n bookinfo create secret generic icam-server-secret \
--from-file=keyfiles/keyfile.jks \
--from-file=keyfiles/keyfile.p12 \
--from-file=keyfiles/keyfile.kdb \
--from-file=keyfiles/ca.pem \
--from-file=keyfiles/cert.pem \
--from-file=keyfiles/key.pem \
--from-file=global.environment
```

When the secret is created apply the files located in the **bookinfo-multicluster**

```sh
oc apply -f bookinfo-multicluster
```

## Legacy method 1: helm chart installation

### Creating the namespace and imagepolicy
To create a bookinfo namespace and authorize required images with the image policy run the following command:
```
kubectl apply -f prereqs.yaml
```

### Adding helm repo
To add the helm repo as bookinfo-charts run
```
helm init
helm repo add bookinfo-charts https://raw.githubusercontent.com/dymaczew/charts/master/repo/incubator/
```
### Helm chart installation
To install the chart with default values run
```
helm install --name bookinfo --namespace bookinfo bookinfo --set ingress.host=bookinfo.<your_ingress_ip>.nip.io --tls
```
## Legacy method 2: helm based MCM app (helm chart a single deployable)

To install bookinfo as MCM app you need a cluster with IBM CloudPak for Multicluster Management 1.2 or newer

1. Create namespaces **bookinfo-entitlement** and **bookinfo-project**. 

```
kubectl create namespace bookinfo-entitlement
kubectl create namespace bookinfo-project
```

2. Create a bookinfo channel:
```
kubectl apply -f bookinfo-channel.yaml
```

3. Create a bookinfo application, subscription and placementrule CRDs:

Edit bookinfo-app.yaml to modify chart version (as of Jan 24, 2020 it's 1.0.8), ingress host name, target namespace and helm release name:

<pre>
spec:
  channel: bookinfo-entitlement/bookinfo-channel
  source: https://raw.githubusercontent.com/dymaczew/charts/master/repo/incubator/ 
  name: bookinfo
  packageFilter:
    version: <b>1.0.8</b>
  placement:
    placementRef:
      name: demo-placementrule
      kind: PlacementRule
  overrides:
  - clusterName: "/"
    clusterOverrides:
    - path: "metadata.namespace"
      value: <b>bookinfo</b>
  packageOverrides:
  - packageName: bookinfo
    packageOverrides:
    - path: spec.releaseName
      value: <b>bookinfo-demo</b>
    - path: spec.values
      value: |
        ingress:
          host: <b>bookinfo.apps.9.30.119.120.nip.io</b>
        details:
          replicaCount: 2
        reviews:
          replicaCount: 3
        ratings:
          replicaCount: 1
        productpage:
          replicaCount: 2
        mysqldb:
          replicaCount: 1
</pre>

You can customize the number of replicas for each microservice - if you want the smallest footprint change all values to 1. In order to generate slow response time events you can scale mysqldb to 0. 

Apply the configuration with the following command:
```
kubectl apply -f bookinfo-app.yaml
```
This command will automatically install the bookinfo chart to any managed cluster that has label environment=Demo

To change the behavior edit the bookinfo-app.yaml (e.g. to specify the correct ingress.host value for your environment)

## Troubleshooting

[Jan 24th, 2020] In a current version, python data collector embedded in productpage microservice is crashing with error 500 if it cannot find the working icam-server-secret. 


## References & Useful Links

[Create a public Helm chart repository with GitHub Pages](https://medium.com/@mattiaperi/create-a-public-helm-chart-repository-with-github-pages-49b180dbb417)

