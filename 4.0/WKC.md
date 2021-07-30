1. Define the SCC in the file wkc-iis-scc.yaml, as follows:

```bash
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: true
allowPrivilegedContainer: false
allowedCapabilities: null
apiVersion: security.openshift.io/v1
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
kind: SecurityContextConstraints
metadata:
  annotations:
    kubernetes.io/description: WKC/IIS provides all features of the restricted SCC
      but runs as user 10032.
  name: wkc-iis-scc
readOnlyRootFilesystem: false
requiredDropCapabilities:
- KILL
- MKNOD
- SETUID
- SETGID
runAsUser:
  type: MustRunAs
  uid: 10032
seLinuxContext:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
users:
- system:serviceaccount:$NAMESPACE:wkc-iis-sa
```

2. Replace `$NAMESPACE` with the value for the actual namespace where Watson Knowledge Catalog is to be installed.

3. If the custom SCC (wkc-iis-scc) already exists in the environment, delete the custom SCC that already exists and create a new custom SCC by using the YAML file from this step. Use the following command to delete the custom SCC: 
```bash
oc delete scc wkc-iis-scc
```

4. Run oc create to create the file:
```bash
oc create -f wkc-iis-scc.yaml
```
5. Run the following command to verify that the SCC was created:
```bash
oc get scc wkc-iis-scc
```

6. Install Python 2 where you issue the installation command:
```bash
brew install python2
```

7. Install pyyaml
```bash
pip3 install pyyaml
```

8. Install WKC
```bash
cat <<EOF |oc apply -f -
apiVersion: wkc.cpd.ibm.com/v1beta1
kind: WKC
metadata:
  name: wkc-cr     # This is the recommended name, but you can change it
  namespace: zen     # Replace with the project where you will install Watson Knowledge Catalog
spec:
  license:
    accept: true
    license: Enterprise     # Specify the license you purchased
  version: 4.0.0
  storageClass: ibmc-file-gold-gid     # See the guidance in "Information you need to complete this task"
  # install_wkc_core_only: true     # To install the core version of the service, remove the comment tagging from the beginning of the line.
  docker_registry_prefix: cp.icr.io/cp/cpd
  useODLM: true
EOF
```

9. Get the status of Watson Knowledge Catalog. It might take two to three hours to install Watson Knowledge Catalog. You can check the status of Watson Knowledge Catalog by running the following command:
```bash
oc get WKC wkc-cr -o jsonpath='{.status.wkcStatus} {"\n"}'
```
