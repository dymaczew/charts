
# Enabling cloud native monitoring in CP4MCM 2.0

## Prerequisites [following KC](https://www.ibm.com/support/knowledgecenter/pl/SSFC4F_2.0.0/icam/install_mcm_klusterlet_no_helm.html#configure_cnmon) 

1. (Optional) If you want to use a tweaked helm chart load it to the local helm repo

HINT: I have tweaked the helm chart to workaround a bug that prevented chart being deployed successfully on the Kubernetes cluster which has version with a '-' (dash) in name, like v1.18.1-6 or v1.14.0-gke

Download the helm chart from BOX (https://ibm.box.com/s/wcfya46jkpebgh1tjt4oa6000ds2yy3j)

Run `cloudctl login` against your cluster to authenticate, and then

```bash
cloudctl catalog load-chart --archive ibm-cp4mcm-cloud-native-monitoring-1.3.0.tgz
```


2. Edit the installation file to add the following section to the monitoring operand

Default setting is

```yaml
            cnmonitoringimagesource:
              deployMCMResources: true
```

If you want to use tweaked helm chart (from step 1) use the following

```yaml
            cnmonitoringimagesource:
              deployMCMResources: true
              helmRepo: https://cp-console.apps.<your-cluster-domain>/helm-repo/charts
```

Optionally you can also specify own registry for images and target namespaces on the managed clusters to be used for data collector deployment

```yaml
          cnmonitoringimagesource:
            deployMCMResources: true
            helmRepo: https://cp-console.apps.<your-cluster-domain>/helm-repo/charts
            targetClusterNS: cp4mcm-cloud-native-monitoring
            dockerReg: docker.io/cruxdaemon
```

**dockerReg:** should point to where you have images available (when not specifide the entitled registry cp.icr.io is used)

**helmRepo:** you can use the default one (https://raw.githubusercontent.com/IBM/charts/master/repo/entitled/) or if you want to enable monitoring of clusters on GKE use the tweaked one (https://cp-console.apps.your-cluster-domain/helm-repo/charts) that you loaded in step 1.


In the context it looks like this:

```yaml
  - config:
    - enabled: true
      name: ibm-management-monitoring
      spec:
        monitoringDeploy:
          cnmonitoringimagesource:
            deployMCMResources: true
            dockerReg: docker.io/cruxdaemon
            helmRepo: https://cp-console.apps.demo.ibmdte.net/helm-repo/charts
            targetClusterNS: cp4mcm-cloud-native-monitoring
          global:
            environmentSize: size0
            persistence:
              storageClassOption:
                cassandrabak: none
                cassandradata: default
                couchdbdata: default
                datalayerjobs: default
                elasticdata: default
                kafkadata: default
                zookeeperdata: default
              storageSize:
                cassandrabak: 50Gi
                cassandradata: 50Gi
                couchdbdata: 5Gi
                datalayerjobs: 5Gi
                elasticdata: 5Gi
                kafkadata: 10Gi
                zookeeperdata: 1Gi
        operandRequest: {}
    enabled: true
    name: monitoring
 ```

3. Update the docker credentials. Login to entitled registry or any other target registry that you want to use. Even if your images are in publicly available registry you need to update the secret with the docker config
   More detailed explanaition is in [IBM Cloud Pak Knowledge Center](https://www.ibm.com/support/knowledgecenter/pl/SSFC4F_2.0.0/icam/install_mcm_klusterlet_no_helm.html#configure_cnmon)

Make sure you have the following file `~/.docker/config.json` (it is automatically created after `docker login` command successful execution)

It will look similar to below example:

```json
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "d29ybGRvZndpZGdldHM6OGM3NzkxMzctZjhjNy00MjdlLTk3ZDQtM2M4MDMzZGIzZjJk"
    }
  }
}
```

Update the deployable with the secret

```bash
oc patch deployable.app.ibm.com/cnmon-pullsecret-deployable -p `echo {\"spec\":{\"template\":{\"data\":{\".dockerconfigjson\":\"$(cat $HOME/.docker/config.json | base64 -w 0)\"}}}}` \
--type merge -n management-monitoring`
```

4. Verify that the deployables are created and pointing to right places

```bash
oc get deployable.app.ibm.com -n management-monitoring
oc get channel.app.ibm.com -n management-monitoring cnmon-chl
oc get subscription.app.ibm.com -n management-monitoring cnmon-sub
oc get placementrule.app.ibm.com -n management-monitoring cnmon-pr
oc get monitoringdeploy $(oc get monitoringdeploy -n management-monitoring --no-headers | awk '{print $1}') -n management-monitoring -o yaml | grep 'helmRepo\|dockerReg'
```

## Deploying cloud native monitoring to a managed cluster

1. Import the managed cluster
2. Add the label `ibm.com/cloud-native-monitoring=enabled` to the managed cluster. You can do this in UI (Automate Infrastructure -> Clusters -> {Edit labels}) or via CLI. For example for the managed cluster named `microk8s` run

```bash
oc patch cluster microk8s -n microk8s -p '{"metadata":{"labels":{"ibm.com/cloud-native-monitoring":"enabled"}}}'
```

3. **IMPORTANT** Add the namespace that holds the cluster object (it is named the same as a managed cluster) as a managed resource to the team that owns the monitoring tenant.

Below there are commands that you would use for a managed cluster named `microk8s` and the default tenant ( *team id* and *account id* may be different at each installation)

```bash
[ibmuser@admin ~]$ cloudctl iam accounts
ID                     Name   
id-mycluster-account   mycluster Account   

[ibmuser@admin ~]$ cloudctl iam teams
ID                                                                 Name                                                                       Groups   Users   Account   
4bb981605258ecc3abe012c4fa0b98a40dc57961e21883f303e3114af1126c83   4bb981605258ecc3abe012c4fa0b98a40dc57961e21883f303e3114af1126c83-default   0        0       mycluster Account   
operations                                                         operations                                                                 1        1       mycluster Account   

[ibmuser@admin ~]$ cloudctl iam resources
CRN   
[.edited.]
crn:v1:icp:private:k8:mycluster:n/management-security-services:::   
crn:v1:icp:private:k8:mycluster:n/microk8s:::   
crn:v1:icp:private:k8:mycluster:n/nfs-storage:::   
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-repos:   
[edited.]

[ibmuser@admin ~]$ cloudctl iam resource-add 4bb981605258ecc3abe012c4fa0b98a40dc57961e21883f303e3114af1126c83 -r crn:v1:icp:private:k8:mycluster:n/microk8s::: 
Resource crn:v1:icp:private:k8:mycluster:n/microk8s::: added
OK
```

4. **IMPORTANT** Login as the used that was onboarded to the ICAM tenant and in the UI open the Monitoring-> Incidents (basically the ICAM UI) - which will trigger the process of deploying the Unified agent and k8sdc to the managed cluster
   
5. Verification on the managed cluster

```bash
ibmuser@microk8s:~$ kubectl get pods -n cp4mcm-cloud-native-monitoring
NAME                                  READY   STATUS      RESTARTS   AGE
agentoperator-76fc69fffb-lxh9g        1/1     Running     0          8m16s
agentoperator-btd89                   0/1     Completed   0          8m16s
job-ua-operator-zs658                 0/1     Completed   0          8m16s
k8sdc-cr-k8monitor-74bc44cc59-c9jjl   2/2     Running     0          119s
k8sdc-operator-59b66777cd-fqrgq       1/1     Running     0          8m16s
reloader-6fb459b9f7-bwfdk             1/1     Running     0          8m16s
ua-operator-6494df7db4-8rgnw          1/1     Running     0          8m16s
```

After all the pods are deployed it can take about 5 minutes before any data is reported back and shown on the Resources tab in UI




