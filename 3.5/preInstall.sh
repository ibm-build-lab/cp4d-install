#!/bin/bash

JOB_NAMESPACE=$1
JOB_CLUSTER_NAME=$2

if [[ ${#JOB_NAMESPACE} -eq 0 ]] || [[ ${#JOB_NAMESPACE} -gt 8 ]]; then
  echo "The project name cannot be empty or longer than 8 characters"
  exit 1
fi

if [[ ${JOB_NAMESPACE} == "default" ]] || [[ ${JOB_NAMESPACE} ==  "kube-"* ]] || [[ $JOB_NAMESPACE} == "openshift"* ]] || [[ $JOB_NAMESPACE} == "calico-"* ]] || [[ $JOB_NAMESPACE} == "ibm-"* ]] || [[ $JOB_NAMESPACE} == "tigera-operator" ]]; then
  echo "The project name cannot be default cluster namespaces"
  exit 1
fi

## Verify Ingress domain is created or not
for ((time=0;time<30;time++)); do
  oc get route -n openshift-ingress | grep 'router-default' > /dev/null 
  if [ $? == 0 ]; then
     break
  fi
  echo "Waiting up to 30 minutes for public Ingress subdomain to be created: $time minute(s) have passed."
  sleep 60
done


# Quits installation if Ingress public subdomain is still not set after 30 minutes
oc get route -n openshift-ingress | grep 'router-default'
if  [ $? != 0 ]; then
  echo -e "\e[1m Exiting installation as public Ingress subdomain is still not set after 30 minutes.\e[0m"
  exit 1
fi


##Identify the cluster type VPC or Classic
clusterType=""
oc get sc | awk '{print $2}' | grep "ibm.io/ibmc-file" > /dev/null
if [[ $? == 0 ]]; then
clusterType="classic"
fi

oc get sc | awk '{print $2}' | grep "vpc.block.csi.ibm.io" > /dev/null
if [[ $? == 0 ]]; then
clusterType="VPC"
fi

echo cluster is  $clusterType
zones=`ibmcloud ks cluster get -c $JOB_CLUSTER_NAME | grep "Worker Zones" | awk '{print $3 $4}'`
IFS=","
read -a zoneslist <<< "$zones"
if [[ ${#zoneslist[*]} > 1 ]]; then
echo "Cluster is Multi zone"
  if ! oc get sc | awk '{print $2}' | grep -q 'kubernetes.io/portworx-volume'; then
     echo -e "\e[1m Portworx storage is not configured on this cluster. Please configure portworx first and try installing \e[0m"
     exit 1
  fi
fi 
oc create sa cpdinstall -n kube-system
oc create sa cpdinstall -n ${JOB_NAMESPACE}

oc create -f - << EOF
allowHostDirVolumePlugin: false
allowHostIPC: true
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
allowedCapabilities:
- '*'
allowedFlexVolumes: null
apiVersion: security.openshift.io/v1
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
groups:
- cluster-admins
kind: SecurityContextConstraints
metadata:
  annotations:
    kubernetes.io/description: ${JOB_NAMESPACE}-zenuid provides all features of the restricted SCC but allows users to run with any UID and any GID.
  name: ${JOB_NAMESPACE}-zenuid
priority: 10
readOnlyRootFilesystem: false
requiredDropCapabilities: null
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny  
users: []
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
EOF
oc adm policy add-scc-to-user ${JOB_NAMESPACE}-zenuid system:serviceaccount:${JOB_NAMESPACE}:cpdinstall
oc adm policy add-scc-to-user anyuid system:serviceaccount:${JOB_NAMESPACE}:icpd-anyuid-sa
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:${JOB_NAMESPACE}:cpdinstall
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:kube-system:cpdinstall

checkVolLimits() {

ibmcloud sl file volume-limits
if [[ $(ibmcloud sl file volume-limits | awk '$1 == "global" {print $2-$3}') -lt  50 ]]; then
echo -e "\e[1m The Storage volumes available on this account may not be sufficient to install all the supported services with IBM Cloud File Storage. Please make sure you have enough storage volumes to provision.\e[0m"
else
 echo "Sufficient File Storage volumes are available in the account"
fi

}


increaseRegistryStorage() {
#Increase storage for docker registry
registry_pv=`oc get pvc -n openshift-image-registry | grep "image-registry-storage" | awk '{print $3}'`
volid=`oc describe pv $registry_pv -n openshift-image-registry | grep volumeId`
IFS='='
read -ra vol <<< "$volid"
volume=${vol[1]}
echo volume id is $volume

ibmcloud sl file volume-detail $volume

if [[ $? -eq 0 ]]; then
capval=`ibmcloud sl file volume-detail $volume | awk '$1=="Capacity" {print $3}'`
  if [[ $capval < 200 ]]; then
     ibmcloud sl file volume-modify $volume --new-size 200 --force
     for i in {1..10}; do
       cap=`ibmcloud sl file volume-detail $volume | awk '$1=="Capacity" {print $3}'`
       if [[ $cap == 200 ]]; then
         echo "Image registry Volume is modified"
         break
       else
         sleep 30
       fi
      echo -e "\e[1m Looks like it is taking time to reflect the updated size for Image Regsitry volume. please confirm, size is modified and start the CP4D installation. \e[0m"
     done
  fi
else
echo -e "\e[1m The logged in user does not have privilege to modify the storage. Before proceeding with install, please make sure the registry volume size is modified and account has sufficient storage volumes to provision. \e[0m"
exit 0
fi
}

if [[ $clusterType == "classic" ]]; then

increaseRegistryStorage
checkVolLimits

fi
echo "SCRIPT EXECUTION COMPLETED"

