# Installing Cloud Pak for Data 4.5 using the Cloud Pak Deployer tool

These are steps to install Cloud Pak for Data 4.5 on a VPC cluster using the Cloud Pak Deployer tool

## Create the OpenShift cluster

Create a VPC cluster with OpenShift 4.10 installed that is at least 6 nodes of type 16x64.  There are a couple methods to create this:

- Using [Cloud Pak Sandbox Automation](https://github.com/ibm-build-labs/cloud-pak-sandboxes/tree/main/terraform/roks_with_odf)

- Using [Tech Zone Automation](./README_TECH_ZONE.md)


## Install Cloud Pak For Data 4.5 using the Cloud Pak Deployer

### 1. Install the deployer utility as follows:
a. Make sure `podman` is installed and running
   ```
   brew install podman
   podman machine init
   podman machine start
   ```
b. Clone the deployer utility directory
   ```
   git clone https://github.com/IBM/cloud-pak-deployer.git
   ```
c. Build the image:
   ```
   cd cloud-pak-deployer
   ./cp-deploy.sh build
   ``` 

See https://ibm.github.io/cloud-pak-deployer/cp-deploy/install for more information

### 2. Set the CP4D entitlement key, create a Config folder and Status folder (not in the cp-deployer folder):

    export CP_ENTITLEMENT_KEY=<your_cp_entitlement_key>
    # Retrieve from https://myibm.ibm.com/products-services/containerlibrary
    export STATUS_DIR=/tmp/data/deploy/status/sample
    mkdir -p $STATUS_DIR
    export CONFIG_DIR=/tmp/data/deploy/config/sample
    mkdir -p $CONFIG_DIR
    mkdir -p $CONFIG_DIR/defaults
    mkdir -p $CONFIG_DIR/inventory

### 3. Create a `$CONFIG_DIR/config/ocp-config.yaml` file with the following:
   ```yaml
   ---
   global_config:
     environment_name: sample
     cloud_platform: existing-ocp

   openshift:
   - name: "cp4d45-cluster"
     ocp_version: 4.10
     cluster_name: "c104-e"
     domain_name: ca-tor.containers.cloud.ibm.com
     openshift_storage: ocs-storagecluster-ceph-rbd
     - storage_name: nfs-storage
       storage_type: nfs
   ```
   Customize the `name`, `ocp_version`, `cluster_name`, `domain_name` and `openshift_storage`.

### 4. Copy and customize cp4d configuration file

    cp ./sample-configurations/roks-ocs-cp4d/cp4d-450.yaml $CONFIG_DIR/config

Edit `/tmp/data/config/sample/cp4d-450.yaml` to
- Accept the license
- Turn on any services to install (mark their state as `installed`)
- Set `openshift_cluster_name` to the value of `cluster_name` from the `ocp-config.yaml` in previous step
  
### 5. Login to the OpenShift cluster:

a. Login

    ibmcloud login -sso
    ibmcloud ks cluster config -c <cluster name or id> --admin

b. Store Kube config

    ./cp-deploy.sh vault set \
    --vault-secret kubeconfig \
    --vault-secret-file ~/.kube/config

    ./cp-deploy.sh vault set \
    -vs cp4d45-cluster-oc-login \
    -vsv "oc login --token=sha256~LnsX4GCe0zcL3RlRrJMqRqeTWvnlamczxm1HAFy7230 --server=https://c104-e.ca-tor.containers.cloud.ibm.com:30259 --insecure-skip-tls-verify"
    


More information [here](https://ibm.github.io/cloud-pak-deployer/cp-deploy/run/existing-openshift).

### 6. Run the Deployer:
   ```
   ./cp-deploy.sh env apply --accept-all-licenses -v
   ```
    Use the -v flag to show more debug statements.

### 7. Verify that the desired CP4D services have installed on your cluster