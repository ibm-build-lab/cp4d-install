# Installing Cloud Pak for Data 4.5 using the Cloud Pak Deployer tool

These are steps to install Cloud Pak for Data 4.5 on a VPC cluster using the Cloud Pak Deployer tool

## Create the OpenShift cluster

Create a VPC cluster with OpenShift 4.10 and ODF installed that is at least 6 nodes of type 16x64.  There are a couple methods to create this:

- Using [Cloud Pak Sandbox Automation](https://github.com/ibm-build-labs/cloud-pak-sandboxes/tree/main/terraform/roks_with_odf/README.md)

- Using [Tech Zone Accelerator Toolkit](./README_TECH_ZONE.md)


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
   NOTE: if running from a MacOS, you may need to fix the `cp-deploy.sh` script to remove the `:z` from paths on lines 726, 730. See https://github.com/containers/podman/issues/13631
   
c. Build the image:
   ```
   cd cloud-pak-deployer
   ./cp-deploy.sh build
   ``` 

See https://ibm.github.io/cloud-pak-deployer/cp-deploy/install for more information

### 2. Set the CP4D entitlement key, create a Config folder and Status folder (not in the cp-deployer folder):

    export IBM_CLOUD_API_KEY=<account api key>
    export CP_ENTITLEMENT_KEY=<your_cp_entitlement_key>
    # Retrieve from https://myibm.ibm.com/products-services/containerlibrary
    export STATUS_DIR=~/data/deploy/status/sample
    mkdir -p $STATUS_DIR
    export CONFIG_DIR=~/data/deploy/config/sample
    mkdir -p $CONFIG_DIR/config
    mkdir -p $CONFIG_DIR/defaults
    mkdir -p $CONFIG_DIR/inventory

### 3. Create an OpenShift config file with your existing cluster information
Create `$CONFIG_DIR/config/ocp-config.yaml` file with the following:
   ```yaml
   ---
   global_config:
     environment_name: sample
     cloud_platform: existing-ocp

   openshift:
   - name: "cp4d45-cluster"
     ocp_version: "4.10"
     cluster_name: "c104-e"
     domain_name: ca-tor.containers.cloud.ibm.com
     openshift_storage:
     - storage_name: ocs-storagecluster-ceph-rbd
       storage_type: ocs
   ```
   Customize the `name`, `ocp_version`, `cluster_name`, `domain_name` and `openshift_storage`.

### 4. Create a cp4d config file
Copy and customize the following configuration file

    cp ./sample-configurations/roks-ocs-cp4d/config/cp4d-450.yaml $CONFIG_DIR/config

Edit `$CONFIG_DIR/config/cp4d-450.yaml` to
- Set `openshift_cluster_name` to the name of the cluster
- Accept the license
- Turn on any services to install (mark their state as `installed`)
   ```
   - project: zen-45
     openshift_cluster_name: "cp4d45-cluster"
     cp4d_version: 4.5.0
     olm_utils: True
     use_case_files: True
     accept_licenses: True
  ```
  
### 5. Login to the OpenShift cluster:

a. Login and download the cluster config

    ibmcloud login -sso
    ibmcloud ks cluster config -c <cluster name or id> --admin

b. Store cluster config file or OpenShift login credentials

    ./cp-deploy.sh vault set \
    --vault-secret kubeconfig \
    --vault-secret-file ~/.kube/config
    
or
c. Retrieve the cluster login command from the OpenShift UI and save that in the vault

    ./cp-deploy.sh vault set \
    --vault-secret cp4d45-cluster-oc-login \
    --vault-secret-value "oc login --token=<sha token> --server=https://c104-e.ca-tor.containers.cloud.ibm.com:30259 --insecure-skip-tls-verify"

More information [here](https://ibm.github.io/cloud-pak-deployer/cp-deploy/run/existing-openshift).

### 6. Run the Deployer:
   ```
   ./cp-deploy.sh env apply --accept-all-licenses -v
   ```
Use the -v flag to show more debug statements.

### 7. Verify that the desired CP4D services have been installed on your cluster

User: 
"admin"

Route, run:
```
oc get route -n zen-45 cpd -o json | jq -r .spec.host
```
Password, run:
```
oc -n zen-45 get secret admin-user-details -o jsonpath='{.data.initial_admin_password}' | base64 -d && echo
```
### 8. Post run changes

Follow the steps in https://ibm.github.io/cloud-pak-deployer/cp-deploy/post-run to update the Vault passwords

### 9. Enable SSO

For steps to enable SSO for this application go [here](./SSO_README.md)
