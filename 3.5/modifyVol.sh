#!/bin/bash
#Increase storage for docker registry
registry_pv=`oc get pvc -n openshift-image-registry | grep "image-registry-storage" | awk '{print $3}'`
volid=`oc describe pv $registry_pv -n openshift-image-registry | grep volumeId`
IFS='='
read -ra vol <<< "$volid"
volume=${vol[1]}
echo volume id is $volume
echo requested size is $1
NEW_SIZE=$1

ibmcloud sl file volume-detail $volume

if [[ $? -eq 0 ]]; then
  capval=`ibmcloud sl file volume-detail $volume | awk '$1=="Capacity" {print $3}'`
  if [[ $capval < $NEW_SIZE ]]; then
     ibmcloud sl file volume-modify $volume --new-size $NEW_SIZE --force
     for i in {1..10}; do
       cap=`ibmcloud sl file volume-detail $volume | awk '$1=="Capacity" {print $3}'`
       if [[ $cap == $NEW_SIZE ]]; then
         echo "Image registry Volume is modified"
         break
       else
         sleep 30
       fi
      echo "Looks like it is taking time to reflect the updated size for Image Regsitry volume. please confirm that the size has been modified and start the CP4D installation"
     done
  fi
else
echo "The logged-in user does not have the privilege required to modify the storage. Before proceeding with the install, please make sure the registry volume size has been modified"
fi

ibmcloud sl file volume-list | grep $volume
