# Creating an OpenShift Cluster using Tech Zone Automation

The following steps have been customized from [Tech Zone Automation](https://github.com/IBM/automation-ibmcloud-infra-openshift).

NOTE: The scripts at the `automation-ibmcloud-infra-openshift` level will run the `1-quickstart` automation by default.  Therefore, do not run anything from the `1-quickstart` subdirectory

## Set up environment

1. Clone repository to your local laptop or into a secure terminal. Open a shell into the cloned directory.
    ```shell
    git clone github.com/IBM/automation-ibmcloud-infra-openshift
    cd automation-ibmcloud-infra-openshift
    ```
2. Copy **credentials.template** to **credentials.properties**.
    ```shell
    cp credentials.template credentials.properties
    ```
3. Uncomment and provide values for the **TF_VAR_** variables **credentials.properties**.
4. Update **terraform.tfvars.template-quickstart** to uncomment and set for required infrastructure.  For example, for this exercise we are using: 
    ```
    cluster_subnets__count="1"
    worker_count="6"
    cluster_flavor="bx2.16x64"
    cluster_force_delete_storage="true"
    odf_namespace_name="odf"
    ```
5. Launch container that will be used to run automation:
    ```
    ./launch.sh 
    ```
    This will start a container image with the prompt opened in the `/terraform` directory, pointed to the repo directory.
6. Create workspace 
   
   Each automation you run will create a workspace that will be persisted as long as the Docker container is installed. Therefore, we need to create a new working copy of this automation terraform by running **./setup-workspace.sh**. This script has a number of optional arguments, run with -h to see all the options:
    ```bash
    ./setup-workspace.sh -n cp4d45 -r ca-tor -s odf
    ```
    This creates a "workspace" where you will run the terraform.
   **Note**: a resource group will be created and all resources will be prefixed from the -n value 
7. Change the directory to the current workspace where the automation was configured 
    ```
    cd /workspaces/current/
    ```
8. Inspect **cluster.tfvars** to see if there are any variables that should be changed. (The **setup-workspace.sh** script has generated this with default values based on the environment variables set above)

## Run the automation

Time to actually start the automation.  To do so simply run:
   ```shell
   ./apply.sh
   ```

   If you choose to only run some of the subcomponents, delete the directories that you don't want installed.