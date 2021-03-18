# Cloud Pak for Data 3.5 Installation Quick Start Guide

Instructions to install CP 4 Data 3.5 onto ROKS 4.6 using *cpd-cli* installer

## Create appropriate sized OpenShift Cluster

See [system requirements for IBM Cloud Pak for Data](https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.5.0/cpd/plan/rhos-reqs.html?view=kc) for more information

## Log in to OpenShift cluster

    ibmcloud login -sso
    ibmcloud target -r <region> -g <resource_group>
    ibmcloud oc clusters
    ibmcloud oc cluster config -c <cluster_name> –-admin

## [Set up Portworx (optional)](./portworx-setup.md)

## Run preinstallation script

    git clone https://github.ibm.com/hcbt/cp4d-install
    <git clone directory>/cp4d-install/preInstall.sh <namespace> <cluster_name>

## Obtain Command Line Installer installation files. Go [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_latest/cpd/install/installation-files.html) for more information

Download [latest](https://github.com/IBM/cpd-cli/releases) installer.

Extract into working directory

    tar xvf cpd-cli-***.tgz

**NOTE**: for all `cpd-cli` commands, run from the `cpd-cli-***` extracted subdirectory.

## Determine Image Registry information

Run this command:

    oc get route -n openshift-image-registry 

*<Registry_location>* referenced in all install commands is comprised of the **HOST/PORT** value listed for **image-registry** combined with \<namespace\>:

    image-registry-openshift-image-registry.jah-test31-data-cluster-c0b572361ba41c9eef42d4d51297b04b-0000.us-east.containers.appdomain.cloud/<namespace>

## Set up cluster and install control plane. Go [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_latest/cpd/install/service_accts.html) for more information

Set up cluster:

    ./cpd-cli adm \
    --repo repo.yaml \
    --assembly lite \
    --namespace <namespace> \
    --apply

Run the following command (add `--dry-run` to preview first) to install:

    ./cpd-cli install \
    --repo ./repo.yaml \
    --assembly lite \
    --namespace <namespace> \
    --storageclass ibmc-file-gold-gid \
    --transfer-image-to <Registry_location> \
    --cluster-pull-prefix $(oc registry info)/<namespace> \
    --ask-push-registry-credentials \
    --latest-dependency

**NOTE**: If using Portworx, make sure `portworx-shared-gp3` storage class is created and listed instead of `ibmc-file-gold-gid`. Go [here](https://www.ibm.com/support/producthub/icpdata/docs/content/SSQNUZ_latest/cpd/install/portworx-storage-classes.html)
 for details

## Install/Upgrade Assemblies

To determine supported storage classes for each assembly, go [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.5.0/sys-reqs/services_prereqs.html#services_prereqs__hw-reqs).

Increase size of `openshift-image-registry`

    <git clone directory>/cp4d-install/modifyVol.sh 400

Some services are hosted in separate repositories. If you plan to install any of the services listed, add the appropriate entries the `repo.yaml` file.  Go [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.5.0/cpd/install/installation-files.html) for more information.

### To see what components are installed, run

    ./cpd-cli status --namespace <namespace>

### [Install Watson Discovery](./WD_README.md)

### [Install Watson Knowledge Studio](./WKS_README.md)

### [Install Data Virtualization](./DV_README.md)

### [Upgrade Watson Knowledge Catalog](./Upgrading_WKC.md)

### [Configure SSO with Okta or similar IDP](./SSO_README.md)
