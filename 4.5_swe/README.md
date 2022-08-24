# Installing Cloud Pak for Data 4.5 using the Software Everywhere automation

These are steps to install Cloud Pak for Data 4.5 on a VPC cluster using automation created by the Software Everywhere modules.

The automation resides in: 

https://github.com/IBM/automation-ibmcloud-infra-openshift

and

https://github.com/IBM/automation-data-foundation

This automation will be running within a container, for best results, make sure you have a license for Docker Desktop.

## Create the OpenShift cluster
NOTE: The scripts at the `automation-ibmcloud-infra-openshift` level will run the `1-quickstart` automation by default.  Therefore, do not run anything from the `1-quickstart` subdirectory

### Setup
The following steps are customized from the steps [here](https://github.com/IBM/automation-ibmcloud-infra-openshift/blob/main/README.md#setup):

1. Clone this repository to your local laptop or into a secure terminal. Open a shell into the cloned directory.
    ```shell
    git clone github.com/IBM/automation-ibmcloud-infra-openshift
    cd automation-ibmcloud-infra-openshift
    ```
2. Copy **credentials.template** to **credentials.properties**.
    ```shell
    cp credentials.template credentials.properties
    ```
3. Uncomment and provide value for the **TF_VAR_ibmcloud_api_key** variable (API key for the IBM Cloud account where the infrastructure will be provisioned) in **credentials.properties**.
4. Update **terraform.tfvars.template-quickstart** to uncomment and set for required infrastructure.  For example, for this exercise we are using: 
    ```
    cluster_subnets__count="1"
    worker_count="6"
    cluster_flavor="bx2.16x64"
    cluster_force_delete_storage="true"
    odf_namespace_name="odf"
    ```
6. Run 
    ```
    ./launch.sh 
    ```
    This will start a container image with the prompt opened in the `/terraform` directory, pointed to the repo directory.
6. Each automation you run will create a workspace that will be persisted as long as the Docker container is installed. Therefore, we need to create a new working copy of this automation terraform by running **./setup-workspace.sh**. This script has a number of optional arguments, run with -h to see all the options:
    ```bash
    ./setup-workspace.sh -n cp4d45 -r ca-tor -s odf
    ```
    This creates a "workspace" where you will run the terraform.
   **Note**: a resource group will be created and all resources will be prefixed from the -n value 
6. Change the directory to the current workspace where the automation was configured 
    ```
    cd /workspaces/current/
    ```
7. Inspect **cluster.tfvars** to see if there are any variables that should be changed. (The **setup-workspace.sh** script has generated this with default values based on the environment variables set above)

### Run only the OpenShift Cluster modules

From the **/workspace/current** directory, change directory into **105-ibm-vpc-openshift** and run:

```shell
cd /workspace/current/105-ibm-vpc-openshift
./apply.sh
```

## Install Data Foundation
Currently the Data Foundation automation just installs the Cloud Pak for Data Lite components.  

### Setup
The following steps are customized from the steps [here](https://github.com/IBM/automation-data-foundation#set-up-environment-credentials):

1. Clone this repository to your local SRE laptop or into a secure terminal. Open a shell into the cloned directory.
    ```shell
    git clone github.com/IBM/automation-data-foundation 
    cd automation-data-foundation 
    ```
2. Copy **credentials.template** to **credentials.properties**.
    ```shell
    cp credentials.template credentials.properties
    ```
3. Provide values for the variables in **credentials.properties** 

   For example:
      ```bash
      TF_VAR_ibmcloud_api_key=**********************
      TF_VAR_gitops_repo_host=github.com
      TF_VAR_gitops_repo_username=annumberhocker
      TF_VAR_gitops_repo_token=************************ # Go to your github profile->settings->developer settings, choose personal access token, choose `repo` and `delete_repo` permissions.
      TF_VAR_gitops_repo_org=ann-gitops # I created my own org under my private username to isolate the repos created by ArgoCD 
      TF_VAR_server_url=https://c104-e.ca-tor.containers.cloud.ibm.com:31655
      TF_VAR_cluster_login_token=******************
      TF_VAR_entitlement_key=****************************************

      ```
   Where
   - **TF_VAR_ibmcloud_api_key** - API key for account where cluster resides
   - **TF_VAR_gitops_repo_host** - (Optional) The host for the git repository (e.g. github.com, bitbucket.org). Supported Git servers are GitHub, Github Enterprise, Gitlab, Bitbucket, Azure DevOps, and Gitea. If this value is left commented out, the automation will default to using Gitea.
   - **TF_VAR_gitops_repo_username** - The username on git server host that will be used to provision and access the gitops repository. If the `gitops_repo_host` is blank this value will be ignored and the Gitea credentials will be used.
   - **TF_VAR_gitops_repo_token** - The personal access token that will be used to authenticate to the git server to provision and access the gitops repository. (The user should have necessary access in the org to create the repository and the token should have `delete_repo` permission.) If the host is blank this value will be ignored and the Gitea credentials will be used.
   - **TF_VAR_gitops_repo_org** - (Optional) The organization/owner/group on the git server where the gitops repository will be provisioned/found. If not provided the org will default to the username.
   - **TF_VAR_server_url** - The url for the OpenShift api server. Only the part starting with https
   - **TF_VAR_cluster_login_token** - Token used for authentication to the api server. Go to OpenShift console, click on top right menu and select Copy login command and click on Display Token
   - **TF_VAR_entitlement_key** - The entitlement key used to access the IBM software images in the container registry. Visit https://myibm.ibm.com/products-services/containerlibrary to get the key

4. Run **./launch.sh**. This will start a container image with the prompt opened in the `/terraform` directory, pointed to the repo directory.
    ```
    ./launch.sh 
    ```
6. Run **./setup-workspace.sh**. This will create a working copy of the terraform in `/workspaces/current` and sets up **terraform.tfvars**  populated with default values. The **setup-workspace.sh** script has a number of optional arguments run with -h to see all the options:

    ```bash
    ./setup-workspace.sh -s odf -n cp4d45 -p ibm
    ```
   **Note**: all resources will be installed in the `cp4d45` resource group and prefixed with `cp4d45`

6. Change the directory to the current workspace where the automation was configured (e.g. `/workspaces/current`).
7. Inspect **terraform.tfvars** to see if there are any variables that should be changed. (The **setup-workspace.sh** script has generated this with default values based on the environment variables set above)

### Run Data Foundation automation

From the **/workspace/current** directory, run the following:

```shell
./apply-all.sh
```

The script will run through each of the terraform layers in sequence to provision the entire infrastructure and will enable ODF as the storage solution and install Cloud Pak for Data 4.5 Control Plane

## Install Data Fabric

TBD

## Destroy Resources

To destroy created resources, change into the automation directory you created the resources from and exec into ibmcloud environment container:
```
cd automation-data-foundation
./launch.sh
```
Locate and change into the appropriate workspace under `/workspaces` in the container to find your configuration. If you ran all of the automation levels
:
```
cd /workspaces/workspace-*********
terraform init
./destroy-all.sh
```
If you only ran a sub automation:
```
cd /workspaces/workspace-*********/105-ibm-vpc-openshift
terraform init
./destroy.sh
```

## General Notes

- The `launch.sh` script stops the cloud environment container and restarts it, so if you are running another `launch.sh` in a different window, the process will be killed. Basically, you can't multitask with `launch.sh`.  

## Helpful Links
Link to the training on Software Everywhere Automation with Tim https://ibm.webex.com/ibm/ldr.php?RCID=b9355b6d3e3c577b7d9620263ce35653, (password: aWGcMAn3) if you want to rewatch it.

- Software Everywhere catalog https://modules.cloudnativetoolkit.dev/
- GitOps template https://github.com/cloud-native-toolkit/template-terraform-gitops
- Terraform module template https://github.com/cloud-native-toolkit/template-terraform-module
- `iascable` tool (Library and CLI used to generate Infrastructure as Code installable components composed from a catalog of modules.) https://github.com/cloud-native-toolkit/iascable
- BoMs https://github.com/cloud-native-toolkit/automation-solutions/tree/main/boms/
- BoM specific to OpenShift infrastructure https://github.com/cloud-native-toolkit/automation-solutions/tree/main/boms/infrastructure/ibmcloud/openshift/1-quickstart
- Resulting Terraform scripts output from above BOMs: https://github.com/IBM/automation-ibmcloud-infra-openshift
