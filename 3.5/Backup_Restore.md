# Back up and Restore CP4D Volume

## CP4D Volume Backup and Restore Using cpdbr 2.0

You need to carry out this pre-req step befor upgrading CP4D services. The following steps describes how to perform off-line backup and restore of data volumes using the CPD backup utility cpdbr.  To provide data consistency, cpdbr quiesces services before performing a backup.

The cpdbr 2.0 CLI released for CPD 3.5 is encapsulated by a top-level CLI called cpd-cli.  cpd-cli invokes cpdbr internally as an executable plugin to perform backup and restore.  The equivalent of running cpdbr <command> is cpd-cli backup-restore <command>.

### Installing cpdbr

1.	Install cpdbr 2.0

  cpdbr consists of a CLI utility and docker image.

  Download the “cpd-cli” CLI

  ```bash
  wget https://github.com/IBM/cpd-cli/releases/download/v3.5.0/cpd-cli-linux-EE-3.5.1.tgz
  tar xvf cpd-cli-linux-EE-3.5.1.tgz
  ```

Check cpdbr version

  ```bash
  ./cpd-cli backup-restore version
  ```

  ```console
  backup-restore
          Version: 2.0.0
          Build Date: 2020-10-28T23:00:47
          Build Number: 730
          CPD Release Version: 3.5.1
  ```

2. Get the `BUILD_NUM` for cpdbr image

  ```bash
  BUILD_NUM=`./cpd-cli backup-restore version | grep "Build Number" |cut -d : -f 2 | xargs`
  ```

3. Save the image using docker/podman commands

  ```bash
  docker pull ibmcom/cpdbr:2.0.0-730-x86_64
  docker save ibmcom/cpdbr:2.0.0-730-x86_64 > cpdbr-img-2.0.0-730-x86_64.tar
  ```

4. Push the image to the internal registry
  ```bash
  IMAGE_REGISTRY=`oc get route -n openshift-image-registry | grep image-registry | awk '{print $2}'`
  echo $IMAGE_REGISTRY
  NAMESPACE=`oc project -q`
  echo $NAMESPACE
  CPU_ARCH=`uname -m`
  echo $CPU_ARCH
  BUILD_NUM=<build-number>
  echo $BUILD_NUM
 
  # Pull cpdbr image from Docker Hub
  docker pull \ docker.io/ibmcom/cpdbr:2.0.0-${BUILD_NUM}-${CPU_ARCH}
  # Push image to internal registry
  docker login -u kubeadmin -p $(oc whoami -t) $IMAGE_REGISTRY --tls-verify=false
  docker tag docker.io/ibmcom/cpdbr:2.0.0-${BUILD_NUM}-${CPU_ARCH} $IMAGE_REGISTRY/$NAMESPACE/cpdbr:2.0.0-${BUILD_NUM}-${CPU_ARCH}
  docker push $IMAGE_REGISTRY/$NAMESPACE/cpdbr:2.0.0-${BUILD_NUM}-${CPU_ARCH} --tls-verify=false
  ```
5. Check that the image tag has the same build number as the cpdbr CLI version (e.g. 747):

  ```bash
  oc get is | grep cpdbr
  ```

### Set up cpdbr

1. Create a shared volume PVC

cpdbr requires a shared volume PVC to be created and bounded for use in its init command.  When local storage is specified,  the PVC is used to store backups.

Use the following yaml file to create an NFS volume named cpdbr-pvc. Name the yaml file cpdbr-pvc.yaml.

  ```yaml
  apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cpdbr-pvc 
spec:
  storageClassName: ibmc-file-gold 
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 200Gi
  ```

Replace Project with the project where the IBM Cloud Pak for Data control plane is installed

  ```bash
  oc apply -f cpdbr-pvc.yaml --namespace Project
  ```

2. Create a secret to store backup credentials

For cpdbr volume backup/restore, a repository secret named `cpdbr-repo-secret` needs to be created before issuing the cpd-cli backup-restore init command.

•	RESTIC_PASSWORD - the restic password to use to create the repository

  ```bash
  echo -n 'restic' > RESTIC_PASSWORD

  oc create secret generic -n cp4d cpdbr-repo-secret \
      --from-file=./RESTIC_PASSWORD
  ```

### Backup

1.	Bring down services

Before performing a backup, scale down deployments/statefulsets in the namespace using cpdbr.

    ```bash
    ./cpd-cli backup-restore quiesce -n cp4d --log-level=debug --verbose
    ```

2.	Backup secrets in the namespace
Create a directory and run the following script to back up secrets.  Create a tar archive of the directory containing the yaml files.  This is needed at restore time.

    ```bash
    for n in $(kubectl get -o=name secret)
    do
        kubectl get -o=yaml --export $n > $(dirname $n)_$(basename $n).yaml
    done
    ```

3.	Run cpdbr volume backup

Initialize cpdbr with the PVC name.

    ```bash
    ./cpd-cli backup-restore init -n cp4d --pvc-name cpdbr-pvc --image-prefix=image-registry.openshift-image-registry.svc:5000/cp4d --log-level=debug --verbose --provider=local
    ```

4. Create a backup of volumes used in the namespace (with services already terminated).  The name of the backup should include the namespace, to avoid collision with other namespaces.

    ```bash
    ./cpd-cli backup-restore volume-backup create --namespace cp4d mycp4dbackup1 --skip-quiesce=true --log-level=debug --verbose
    ```

5. List volume backups

    ```bash
    ./cpd-cli backup-restore volume-backup list -n cp4d --log-level=debug --verbose
    ```

6.  Check volume backup status

    ```bash
    ./cpd-cli backup-restore volume-backup status --namespace cp4d mycp4dbackup1 --log-level=debug --verbose
    ```

7. Check volume backup logs

    ```bash
    ./cpd-cli backup-restore volume-backup logs mycp4dbackup1 --namespace=cp4d --log-level=debug --verbose
    ```

8.	Bring up services

After the off-line backup is complete, you may choose to bring the services online by scaling up the deployments/statefulsets.

    ```bash
    ./cpd-cli backup-restore unquiesce -n cp4d --log-level=debug --verbose
    ```

9. Terminate cpdbr (for clean-up purposes; run before upgrade)

    ```bash
    ./cpd-cli backup-restore reset --namespace cp4d --force --log-level=debug --verbose
    ```

###	Restore

1.	 On the target cluster, install the cpd-cli CLI and cpdbr-aux assembly.

2.	Create a shared volume PVC for cpdbr

  ```bash
  oc apply -f cpdbr-pvc.yaml --namespace Project
  ```

3.	Recreate the cpdbr repository secret, with the same credentials used for the backup

  ```bash
  echo -n 'restic' > RESTIC_PASSWORD

  oc create secret generic -n cp4d cpdbr-repo-secret \
      --from-file=./RESTIC_PASSWORD
  ```

4.	Apply secrets from source cluster
(* In case restore needs to be rolled back, consider backing up the secrets of the target cluster first.)

Extract the tar file containing the yaml files from the source cluster.  Apply the secrets to the target cluster.

    ```bash
    oc apply -f <directory>
    ```

5. Bring down services

Before performing a restore, scale down deployments/statefulsets in the namespace using cpdbr.

    ```bash
    ./cpd-cli backup-restore quiesce -n cp4d --log-level=debug --verbose
    ```

6. Initialize cpdbr with the shared volume PVC

    ```bash
    ./cpd-cli backup-restore init -n cp4d --pvc-name cpdbr-pvc --image-prefix=image-registry.openshift-image-registry.svc:5000/cp4d --log-level=debug --verbose --provider=local
    ```

7. Upload the backup archive to the shared volume PVC

    ```bash
    ./cpd-cli backup-restore volume-backup upload --namespace cp4d –f cpd-volbackups-mycp4dbackup1-data.tar
    ```

8. Create a volume restore from the backup
(* In case restore needs to be rolled back, consider performing a volume backup of the target cluster first.)

Since services are not running at this point, volume data can be restored.

    ```bash
    ./cpd-cli backup-restore volume-restore create --from-backup mycp4dbackup1 --namespace cp4d mycp4drestore1 --skip-quiesce=true --log-level=debug --verbose
    ```

9. List volume restores

    ```bash
    ./cpd-cli backup-restore volume-restore list --namespace=cp4d --log-level=debug --verbose
    ```

10.  Check volume restore status

    ```bash
    ./cpd-cli backup-restore volume-restore status --namespace cp4d mycp4drestore1
    ```

11.  Check volume restore logs

    ```bash
    ./cpd-cli backup-restore volume-restore logs mycp4drestore1 --namespace=cp4d --log-level=debug --verbose
    ```

12.	Edit the target namespace and change the following annotations to have the same values as the source namespace.

oc edit namespace cp4d

openshift.io/sa.scc.mcs: s0:c25,c10
openshift.io/sa.scc.supplemental-groups: 1000660000/10000
openshift.io/sa.scc.uid-range: 1000660000/10000


13.	Bring up services

Bring the services online by scaling up the deployments/statefulsets.
  
    ```bash
    ./cpd-cli backup-restore unquiesce -n cp4d --log-level=debug --verbose
    ```

14.	 Commands when cleanup is needed

14a.  Delete volume restore (for cleanup purposes only)

    ```bash
    ./cpd-cli backup-restore volume-restore delete mycp4drestore1 --namespace=cp4d --log-level=debug --verbose
    ```

14b.  Terminate cpdbr (for cleanup purposes; run before upgrade)

    ```bash
    ./cpd-cli backup-restore reset --namespace cp4d --force --log-level=debug --verbose
    ```

###	 Troubleshooting

1.	 Cleanup After Stopping A Backup Or Restore In Progress

A backup or restore job can be deleted by calling the volume-backup / volume-restore delete command. If the job is deleted before completion, subsequent backup or restore operations may fail since a lock file is still present. In the backup or restore pod, there is an error with the message:
 
[ERROR] A backup/restore operation for zen is in progress.  Wait for the operation to complete.
cpdbr/cmd.checkLockFile
 
If this is the case, and there are no backup or restore pods still running, run the unlock command to remove the lock file. e.g.
 
./cpd-cli backup-restore volume-backup unlock NAME -n zen --log-level=debug --verbose
 
NAME is a backup name, or if one does not exist, a random name. Afterwards, retry the backup or restore operation.
