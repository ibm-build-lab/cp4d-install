1. Create a custom resource with the following format.

```bash
cat <<EOF |oc apply -f -
apiVersion: databases.cpd.ibm.com/v1
kind: Db2whService
metadata:
  name: db2wh-cr     # This is the recommended name, but you can change it
  namespace: zen     # Replace with the project where you will install Db2 Warehouse
spec:
  license:
    accept: true
    license: Enterprise     # Specify the license you purchased
EOF
```

2. Provision the service via the CP4D web client. If the provision fails, apply the following patch and wait for the pod to restart:
```bash
oc patch sts c-db2wh-1626472917219167-db2u -p='{"spec":{"template":{"spec":{"containers":[{"name":"db2u","tty":false}]}}}}}'
```
