# Db2 on Cloud Pak for Data 4.5 on VPC cluster

https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=services-spss-modeler

https://www.ibm.com/docs/en/cloud-paks/cp-data/4.5.x?topic=db2-preparing-install

## Setting up dedicated nodes for Db2 deployment

Follow the steps [here](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.5.x?topic=install-setting-up-dedicated-nodes) to `taint` a dedicated node

Use `icp4data=database-db2oltp` as the label.

## Install and deploy DB2

DB2 can easily be deployed using the Cloud Pak Sandbox TF example [here](https://github.com/ibm-build-labs/terraform-ibm-cloud-pak/tree/main/examples/Db2)

### Clone repo
```
git clone https://github.com/ibm-build-labs/terraform-ibm-cloud-pak.git
cd modules/db2
```
### Add Node affinity and toleration to run on dedicated node labeled in step above
Edit the `templates/db2u_cluster.yaml.tmpl` file to include the node affinity descriptor for dedicated node:
```
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: icp4data
            operator: In
            values:
            - database-db2oltp
  tolerations:
  - key: "icp4data"
    operator: "Equal"
    value: "database-db2oltp"
    effect: "NoSchedule"
```
### Run example
```
cd ../../example/db2
```
Create a `terraform.tfvars` file that looks similar to this: 
```
ibmcloud_api_key             = "*************************"
resource_group               = "cp4d45-trng"
region                       = "ca-tor"
cluster_id                   = "ccgujsmr0jnj59ad6j2g"
db2_admin_username           = "db2inst1"
db2_admin_user_password      = "Passw0rd"
entitled_registry_key        = "*********************"
entitled_registry_user_email = "ann.umberhocker@ibm.com"
db2_instance_version	       = "11.5.7.0-cn5"
operatorVersion              = "db2u-operator.v2.0.0"
db2_name		                 = "CP4DDB"
operatorChannel		           = "v2.0"
db2_rwx_storage_class        = "ocs-storagecluster-cephfs"
db2_rwo_storage_class        = "ibmc-vpc-block-10iops-tier"
```
## References:
- Db2 versions for different Cloud Pak for Data versions
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.5.x?topic=install-db2-versions-different-cloud-pak-data-versions

- Db2 Operators and their associated Db2 engines
https://www.ibm.com/docs/en/db2/11.5?topic=deployments-db2-red-hat-openshift

- Setting up dedicated nodes for your Db2 deployment
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.5.x?topic=install-setting-up-dedicated-nodes

- Creating a database deployment on the cluster (Db2)
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.5.x?topic=setup-creating-database-deployment#provision-db-aese

- Deploying Db2 using the Db2uCluster custom resource
https://www.ibm.com/docs/en/db2/11.5?topic=db2-deploying-using-db2ucluster-cr

- Kubernetes Taints and Tolerations
https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/


