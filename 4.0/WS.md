1. Create the appropriate operator subscription for your environment:

```bash
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  annotations:
  name: ibm-cpd-ws-operator-catalog-subscription
  namespace: zen    # Pick the project that contains the Cloud Pak for Data operator
spec:
  channel: v2.0
  installPlanApproval: Automatic
  name: ibm-cpd-wsl
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

2. Create a custom resource with the following format.

```bash
cat <<EOF |oc apply -f -
apiVersion: ws.cpd.ibm.com/v1beta1
kind: WS
metadata:
  name: ws-cr     # This is the recommended name, but you can change it
  namespace: zen     # Replace with the project where you will install Watson Studio
spec:
  docker_registry_prefix: cp.icr.io/cp/cpd
  license:
    accept: true
    license: Enterprise     # Specify the license you purchased
  version: 4.0.0
  storageVendor: ""
  storageClass: ibmc-file-gold-gid          #if you use a different storage class, replace it with the appropriate storage class                   
EOF
```