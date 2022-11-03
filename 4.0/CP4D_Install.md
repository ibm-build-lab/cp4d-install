# General CP4D Install on ROKS Cluster

## Creating projects (namespaces) on ROKS cluster
1. Create these projects:

    a. ibm-common-services project

    b. zen project

2. Create the operator group for Express installation or visit step 3 under [Procedure](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-projects-namespaces) for specialized installation:
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: operatorgroup
  namespace: ibm-common-services
spec:
  targetNamespaces:
  - ibm-common-services
EOF
```

## Configuring your cluster to pull software images
1. Determine whether there is an existing global image pull secret:
```bash
oc extract secret/pull-secret -n openshift-config
```
This command generates a JSON file called .dockerconfigjson in the current directory.

If the file is empty, checkout step 2 under [Configuring the global image pull secret](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-configuring-your-cluster-pull-images) or else proceed with the following steps:

2. Encode the username and password using Base64 encoding.
```bash
echo -n "cp:$ENTITLEMENT_KEY" | base64
```
Replace `$ENTITLEMENT_KEY` with your entitlement key.

3. Add an entry for the registry to the auths section in the JSON file. In the following example,  1  is the new entry and  2  is the existing entry:

```
{
   "auths":{
       1 "cp.icr.io":{
         "auth":"base64-encoded-credentials",
         "email":"not-used"
      },
       2 "myregistry.example.com":{
         "auth":"b3Blb=",
         "email":"not-used"
      }
   }
}
```
Replace **base64-encoded-credentials** with the the encoded credentials that you generated in the previous step. For example, cmVnX3VzZXJuYW1lOnJlZ19wYXNzd29yZAo=.

4. Apply the new configuration:
```bash
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=.dockerconfigjson
```

5. Reload the worker nodes in your cluster for the changes to take effect.

Wait until all the nodes are Ready before you proceed to the next step. For example, if you see Ready,SchedulingDisabled, wait for the process to complete:
```
NAME            STATUS   ROLES           AGE   VERSION
10.188.91.201   Ready    master,worker   91m   v1.19.0+b00ba52
10.188.91.205   Ready    master,worker   92m   v1.19.0+b00ba52
10.188.91.218   Ready    master,worker   92m   v1.19.0+b00ba52
10.188.91.251   Ready    master,worker   92m   v1.19.0+b00ba52
```

6. Create the IBM Operator catalog source.
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: "IBM Operator Catalog" 
  publisher: IBM
  sourceType: grpc
  image: icr.io/cpopen/ibm-operator-catalog:latest
  updateStrategy:
    registryPoll:
      interval: 45m
EOF
```

7. Create the following catalog source to ensure that dependencies can be installed:
```bash
cat <<EOF |oc apply -f -
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-ccs-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-ccs-operator-catalog@sha256:34854b0b5684d670cf1624d01e659e9900f4206987242b453ee917b32b79f5b7
  imagePullPolicy: Always
  displayName: CPD Common Core Services
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-datarefinery-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-datarefinery-operator-catalog@sha256:27c6b458244a7c8d12da72a18811d797a1bef19dadf84b38cedf6461fe53643a
  imagePullPolicy: Always
  displayName: Cloud Pak for Data IBM DataRefinery
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-db2aaservice-cp4d-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-db2aaservice-cp4d-operator-catalog@sha256:a0d9b6c314193795ec1918e4227ede916743381285b719b3d8cfb05c35fec071
  imagePullPolicy: Always
  displayName: IBM Db2aaservice CP4D Catalog
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-iis-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-iis-operator-catalog@sha256:3ad952987b2f4d921459b0d3bad8e30a7ddae9e0c5beb407b98cf3c09713efcc
  imagePullPolicy: Always
  displayName: CPD IBM Information Server
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-wml-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: Cloud Pak for Data Watson Machine Learning
  publisher: IBM
  sourceType: grpc
  imagePullPolicy: Always
  image: icr.io/cpopen/ibm-cpd-wml-operator-catalog@sha256:d2da8a2573c0241b5c53af4d875dbfbf988484768caec2e4e6231417828cb192
  updateStrategy:
    registryPoll:
      interval: 45m

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-ws-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-ws-operator-catalog@sha256:bf6b42df3d8cee32740d3273154986b28dedbf03349116fba39974dc29610521
  imagePullPolicy: Always
  displayName: CPD IBM Watson Studio
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencontent-elasticsearch-dev-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/opencontent-elasticsearch-operator-catalog@sha256:bc284b8c2754af2eba81bb1edf6daa59dc823bf7a81fe91710c603f563a9a724
  displayName: IBM Opencontent Elasticsearch Catalog
  publisher: CloudpakOpen
  updateStrategy:
    registryPoll:
      interval: 45m

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-rabbitmq-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: IBM RabbitMQ operator Catalog
  publisher: IBM
  sourceType: grpc
  image: icr.io/cpopen/opencontent-rabbitmq-operator-catalog@sha256:c3b14816eabc04bcdd5c653eaf6e0824adb020ca45d81d57059f50c80f22964f
  updateStrategy:
    registryPoll:
      interval: 45m

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cloud-databases-redis-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: ibm-cloud-databases-redis-operator-catalog
  publisher: IBM
  sourceType: grpc
  image: icr.io/cpopen/ibm-cloud-databases-redis-catalog@sha256:980e4182ec20a01a93f3c18310e0aa5346dc299c551bd8aca070ddf2a5bf9ca5

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-ws-runtimes-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-ws-runtimes-operator-catalog@sha256:c1faf293456261f418e01795eecd4fe8b48cc1e8b37631fb6433fad261b74ea4
  imagePullPolicy: Always
  displayName: CPD Watson Studio Runtimes
  publisher: IBM
EOF
```

7. Create the Db2U catalog source if you plan to install one of the following services:
Data Virtualization
Db2®
Db2 Big SQL
Db2 Warehouse
OpenPages® (required only if you want OpenPages to automatically provision a Db2 database)
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-db2uoperator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: docker.io/ibmcom/ibm-db2uoperator-catalog:latest
  imagePullPolicy: Always
  displayName: IBM Db2U Catalog
  publisher: IBM
  updateStrategy:
    registryPoll:
      interval: 45m
EOF
```

## Creating operator subscriptions
1. Create the appropriate operator subscription for the scheduling service:
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  annotations:
  labels:
    operators.coreos.com/ibm-cpd-scheduling-operator.aks: ""
    velero.io/exclude-from-backup: "true"
  name: ibm-cpd-scheduling-catalog-subscription
  namespace: ibm-common-services    # Pick the project that contains the Cloud Pak for Data operator
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: ibm-cpd-scheduling-operator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

2. Create the Cloud Pak for Data operator subscription
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cpd-operator
  namespace: ibm-common-services # Pick the project that contains the Cloud Pak for Data operator
spec:
  channel: stable-v1
  installPlanApproval: Automatic
  name: cpd-platform-operator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

## Creating operator subscriptions for services (Optional & choose the services you plan to install)
### Data Virtualization
1. Create the appropriate operator subscription for your environment:
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-dv-operator-catalog-subscription
  namespace: ibm-common-services # Pick the project that contains the Cloud Pak for Data operator
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-dv-operator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

### Db2 Data Management Console
1. Create the appropriate operator subscription for your environment:
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-dmc-operator-subscription
  namespace: ibm-common-services # Pick the project that contains the Cloud Pak for Data operator
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-dmc-operator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

### Db2 Warehouse
1. Create the Db2U operator subscription:
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-db2uoperator-catalog-subscription
  namespace: ibm-common-services    # Pick the project that contains the Cloud Pak for Data operator
spec:
  channel: v1.1
  name: db2u-operator
  installPlanApproval: Automatic
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

2. Create the Db2 Warehouse operator subscription.
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-db2wh-cp4d-operator-catalog-subscription
  namespace: ibm-common-services    # Pick the project that contains the Cloud Pak for Data operator
spec:
  channel: v1.0
  name: ibm-db2wh-cp4d-operator
  installPlanApproval: Automatic
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

### Watson Knowledge Catalog
1. Create the appropriate operator subscription for your environment:
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    app.kubernetes.io/instance:  ibm-cpd-wkc-operator-catalog-subscription
    app.kubernetes.io/managed-by: ibm-cpd-wkc-operator
    app.kubernetes.io/name:  ibm-cpd-wkc-operator-catalog-subscription
  name: ibm-cpd-wkc-operator-catalog-subscription
  namespace: ibm-common-services # Pick the project that contains the Cloud Pak for Data operator
spec:
    channel: v1.0
    installPlanApproval: Automatic
    name: ibm-cpd-wkc
    source: ibm-operator-catalog
    sourceNamespace: openshift-marketplace
EOF
```

### Watson Studio
1. Create the appropriate operator subscription for your environment:
```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  annotations:
  name: ibm-cpd-ws-operator-catalog-subscription
  namespace: ibm-common-services    # Pick the project that contains the Cloud Pak for Data operator
spec:
  channel: v2.0
  installPlanApproval: Automatic
  name: ibm-cpd-wsl
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

## Create custom SCC
The following services require custom security context constraints:
- Watson™ Knowledge Catalog
- Db2®
- Db2 Warehouse
- Db2 Big SQL
- Data Virtualization
- OpenPages®

When you install Db2, the Db2 operator creates the custom SCC, service accounts, roles, and role bindings. Db2 Warehouse, Db2 Big SQL, Data Virtualization, and OpenPages use the SCC capabilities in Db2.

When you install Watson Knowledge Catalog, you must create the [custom SCCs manually](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=sccs-creating-custom-in-watson-knowledge-catalog).


## Specify node settings
The following services require specific node settings:
- Data Virtualization
- Db2
- Db2 Big SQL
- Db2 Warehouse
- Jupyter Notebooks with Python 3.7 for GPU
- OpenPages
- Watson Knowledge Catalog
- Watson Machine Learning Accelerator
- Watson Studio

1. Load balancer timeout settings
Use the following command to set the server-side timeout for the HAProxy route to 360 seconds:
```bash
oc annotate route zen-cpd --overwrite haproxy.router.openshift.io/timeout=360s
```

2. Kernel parameter settings
- The kernel.sem value for SEMMNS must be 1024000 for Watson Knowledge Catalog service.
- The kernel.sem value for SEMOPM must be at least 100 for Data Virtualization service.

2.a Create a custom node-level tune with the following content.
```bash
cat <<EOF |oc apply -f -
apiVersion: tuned.openshift.io/v1
kind: Tuned
metadata:
  name: cp4d-wkc-ipc
  namespace: openshift-cluster-node-tuning-operator
spec:
  profile:
  - name: cp4d-wkc-ipc
    data: |
      [main]
      summary=Tune IPC Kernel parameters on OpenShift Worker Nodes running WKC Pods
      [sysctl]
      kernel.shmall = 33554432
      kernel.shmmax = 68719476736
      kernel.shmmni = 32768
      kernel.sem = 250 1024000 100 32768
      kernel.msgmax = 65536
      kernel.msgmnb = 65536
      kernel.msgmni = 32768
      vm.max_map_count = 262144
  recommend:
  - match:
    - label: node-role.kubernetes.io/worker
    priority: 10
    profile: cp4d-wkc-ipc
EOF
```

2.b Configure kubelet to allow Db2U to make syscalls as needed. Update all of the nodes to use a custom KubletConfig:

    ```bash
    cat << EOF | oc apply -f -
    apiVersion: machineconfiguration.openshift.io/v1
    kind: KubeletConfig
    metadata:
    name: db2u-kubelet
    spec:
    machineConfigPoolSelector:
        matchLabels:
        db2u-kubelet: sysctl
    kubeletConfig:
        allowedUnsafeSysctls:
        - "kernel.msg*"
        - "kernel.shm*"
        - "kernel.sem"
    EOF
```

2.c Update the label on the machineconfigpool:
```bash
oc label machineconfigpool 10.185.199.39 db2u-kubelet=sysctl
```

```Error from server (NotFound): machineconfigpools.machineconfiguration.openshift.io "worker" not found```

2.d Wait for the cluster to reboot. Then, run the following command to verify that the machineconfigpool is updated:
```bash
oc get machineconfigpool
```

## Installation
1. Express Installation (Follow doc for [Specialized Installation](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=installing-cloud-pak-data))
Create an operand request to grant permission to the IBM Cloud Pak for Data platform operator and the IBM Cloud Pak foundational services operator to manage the project where you plan to install Cloud Pak for Data:

```bash
cat <<EOF |oc apply -f -
apiVersion: operator.ibm.com/v1alpha1
kind: OperandRequest
metadata:
  name: empty-request
  namespace: zen        # Replace with the project where you will install Cloud Pak for Data
spec:
  requests: []
EOF
```

`error: unable to recognize "STDIN": no matches for kind "OperandRequest" in version "operator.ibm.com/v1alpha1"`

2. Create a custom resource to install Cloud Pak for Data.
Create a custom resource with the following format:
```bash
cat <<EOF |oc apply -f -
apiVersion: cpd.ibm.com/v1
kind: Ibmcpd
metadata:
  name: ibmcpd-cr                                     # This is the recommended name, but you can change it
  namespace: zen                             # Replace with the project where you will install Cloud Pak for Data
spec:
  license:
    accept: true
    license: Enterprise                      # Specify the Cloud Pak for Data license you purchased
  storageClass: ibmc-file-gold-gid                     # Replace with the name of a RWX storage class
  zenCoreMetadbStorageClass: ibmc-file-gold-gid        # (Recommended) Replace with the name of a RWO storage class
  version: "4.0.1"
EOF
```

## Verifying the installation
1. Change to the project where you installed Cloud Pak for Data. For example:
```bash
oc project zen
```

2. Get the status of the control plane (lite-cr):
```bash
oc get ZenService lite-cr -o jsonpath="{.status.zenStatus}{'\n'}"
```
The Cloud Pak for Data control plane is ready when the command returns Completed.

3. Get the URL of the Cloud Pak for Data web client:
```bash
oc get ZenService lite-cr -o jsonpath="{.status.url}{'\n'}"
```

4. Get the initial password for the admin user:
```bash
oc extract secret/admin-user-details --keys=initial_admin_password --to=-
```
