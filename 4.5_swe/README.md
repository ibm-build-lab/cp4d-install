# Installing Cloud Pak for Data 4.5 using the Software Everywhere utilities

These are steps to install Cloud Pak for Data 4.5 on a VPC cluster using automation created by the Software Everywhere modules.

The automation resides in: 

https://github.com/IBM/automation-ibmcloud-infra-openshift

and

https://github.com/IBM/automation-data-foundation

This automation will be running within a container, for best results, make sure you have a license for Docker Desktop.

## Create the OpenShift container
NOTE: The scripts at the `automation-ibmcloud-infra-openshift` level will run the `1-quickstart` automation by default.  Therefore, do not run anything from the `1-quickstart` subdirectory

### Setup
The following steps are customized from the steps [here](https://github.com/IBM/automation-ibmcloud-infra-openshift/blob/main/README.md#setup):

1. Clone this repository to your local SRE laptop or into a secure terminal. Open a shell into the cloned directory.
    ```shell
    git clone github.com/IBM/automation-ibmcloud-infra-openshift
    cd automation-ibmcloud-infra-openshift
    ```
2. Copy **credentials.template** to **credentials.properties**.
    ```shell
    cp credentials.template credentials.properties
    ```
3. Uncomment and provide value for the **TF_VAR_ibmcloud_api_key** variable (API key for the IBM Cloud account where the infrastructure will be provisioned) in **credentials.properties**.
4. Run **./launch.sh**. This will start a container image with the prompt opened in the `/terraform` directory, pointed to the repo directory.
5. Create a working copy of the terraform by running **./setup-workspace.sh**. 
    ```bash
    ./setup-workspace.sh -s odf -n cp4d45 -r ca-tor # Note, a resource group will be created and all resources will be prefixed from the -n value   
    ```
6. Change the directory to the current workspace where the automation was configured 
    ```
    cd /workspaces/current/
    ```
7. Inspect **cluster.tfvars** and **gitops.tfvars** to see if there are any variables that should be changed. (The **setup-workspace.sh** script has generated these with default values based on the environment variables set above and can be used without updates, if desired.)

### Run only the OpenShift Cluster modules

From the **/workspace/current** directory, change directory into **105-ibm-vpc-openshift** and run:

```shell
./apply.sh
```

## Install Data Foundation

Currently the Data Foundation automation just installs the Cloud Pak for Data Lite components.  Eventually, it will add additional services on.

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
      TF_VAR_ibmcloud_api_key=<api key for account 2058805>
      TF_VAR_gitops_repo_host=github.com
      TF_VAR_gitops_repo_username=annumberhocker
      TF_VAR_gitops_repo_token=************************ # Go to profiles settings, developer settings, choose `repo` and `delete_repo` permissions.
      TF_VAR_gitops_repo_org=ann-gitops # I created my own org under my private username to isolate the repos created by ArgoCD 
      TF_VAR_server_url=
      TF_VAR_cluster_login_token=******************
      TF_VAR_entitlement_key=****************************************

      ```
   Where
   - **TF_VAR_gitops_repo_host** - (Optional) The host for the git repository (e.g. github.com, bitbucket.org). Supported Git servers are GitHub, Github Enterprise, Gitlab, Bitbucket, Azure DevOps, and Gitea. If this value is left commented out, the automation will default to using Gitea.
   - **TF_VAR_gitops_repo_username** - The username on git server host that will be used to provision and access the gitops repository. If the `gitops_repo_host` is blank this value will be ignored and the Gitea credentials will be used.
   - **TF_VAR_gitops_repo_token** - The personal access token that will be used to authenticate to the git server to provision and access the gitops repository. (The user should have necessary access in the org to create the repository and the token should have `delete_repo` permission.) If the host is blank this value will be ignored and the Gitea credentials will be used.
   - **TF_VAR_gitops_repo_org** - (Optional) The organization/owner/group on the git server where the gitops repository will be provisioned/found. If not provided the org will default to the username.
   - **TF_VAR_server_url** - The url for the OpenShift api server. Only the part starting with https
   - **TF_VAR_cluster_login_token** - Token used for authentication to the api server. Go to OpenShift console, click on top right menu and select Copy login command and click on Display Token
   - **TF_VAR_entitlement_key** - The entitlement key used to access the IBM software images in the container registry. Visit https://myibm.ibm.com/products-services/containerlibrary to get the key

4. Run **./launch.sh**. This will start a container image with the prompt opened in the `/terraform` directory, pointed to the repo directory.
5. Create a working copy of the terraform by running **./setup-workspace.sh**. The script makes a copy of the terraform in `/workspaces/current` and set up "cluster.tfvars" and "gitops.tfvars" files populated with default values. The **setup-workspace.sh** script has a number of optional arguments.

    ```bash
    ./setup-workspace.sh -s odf -n cp4d45 -r ca-tor # Note, a resource group will be created and all resources will be prefixed from the -n value   
    ```
    
6. Change the directory to the current workspace where the automation was configured (e.g. `/workspaces/current`).
7. Inspect **cluster.tfvars** to see if there are any variables that should be changed. (The **setup-workspace.sh** script has generated **cluster.tfvars** with default values based on the environment variables set above and can be used without updates, if desired.)
#### Run all the Terraform layers automatically

From the **/workspace/current** directory, run the following:

```shell
./apply-all.sh
```

The script will run through each of the terraform layers in sequence to provision the entire infrastructure.
## Helpful Links
Link to the training on Software Everywhere Automation with Tim https://ibm.webex.com/ibm/ldr.php?RCID=b9355b6d3e3c577b7d9620263ce35653, (password: aWGcMAn3) if you want to rewatch it.

- Software Everywhere catalog https://modules.cloudnativetoolkit.dev/
- GitOps template https://github.com/cloud-native-toolkit/template-terraform-gitops
- Terraform module template https://github.com/cloud-native-toolkit/template-terraform-module
- `iascable` tool (Library and CLI used to generate Infrastructure as Code installable components composed from a catalog of modules.) https://github.com/cloud-native-toolkit/iascable
- BoMs https://github.com/cloud-native-toolkit/automation-solutions/tree/main/boms/
- BoM specific to OpenShift infrastructure https://github.com/cloud-native-toolkit/automation-solutions/tree/main/boms/infrastructure/ibmcloud/openshift/1-quickstart
- Resulting Terraform scripts output from above BOMs: https://github.com/IBM/automation-ibmcloud-infra-openshift
