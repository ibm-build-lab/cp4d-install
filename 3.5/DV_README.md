# Installing Data Virtualization

Go [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.5.0/svc-dv/install-dv.html) for the full Data Virtualization Installation documentation

## Install

1. Ensure that you have run the `modifyVol.sh` to extend the image registry before this step. Go [here](https://github.com/ibm-hcbt/cp4d-install/tree/main/3.5#install-additional-assemblies) for more details.

2. Create a file `setkernelparams.yaml` with the following content

```yaml
 apiVersion: apps/v1
 kind: DaemonSet
 metadata:
   name: kernel-optimization
   namespace: kube-system
   labels:
     tier: management
     app: kernel-optimization
 spec:
   selector:
     matchLabels:
       name: kernel-optimization
   template:
     metadata:
       labels:
         name: kernel-optimization
     spec:
       hostNetwork: true
       hostPID: true
       hostIPC: true
       initContainers:
         - command:
             - sh
             - -c
             - sysctl -w kernel.sem="250 1024000 100 16384"; sysctl -w kernel.msgmax="65536"; sysctl -w kernel.msgmnb="65536"; sysctl -w kernel.msgmni="32768"; sysctl -w kernel.shmmni="16384"; sysctl -w vm.max_map_count="262144"; sysctl -w kernel.shmall="33554432"; sysctl -w kernel.shmmax="68719476736"; sysctl -p;
           image: alpine:3.6
           imagePullPolicy: IfNotPresent
           name: sysctl
           resources: {}
           securityContext:
             privileged: true
             capabilities:
               add:
                 - NET_ADMIN
           volumeMounts:
             - name: modifysys
               mountPath: /sys
       containers:
         - resources:
             requests:
               cpu: 0.01
           image: alpine:3.6
           name: sleepforever
           command: ["/bin/sh", "-c"]
           args:
             - >
               while true; do
                 sleep 100000;
               done
       tolerations:
       - operator: Exists
       volumes:
         - name: modifysys
           hostPath:
             path: /sys
   ```

3. Set the kernel parameters

    `oc apply -f setkernelparams.yaml -n kube-system`

4. Create a file `norootsquash.yaml` with the following content

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: norootsquash
  namespace: kube-system
  labels:
    tier: management
    app: norootsquash
spec:
  selector:
    matchLabels:
      name: norootsquash
  template:
    metadata:
      labels:
        name: norootsquash
    spec:
      hostNetwork: true
      hostPID: true
      hostIPC: true
      containers:
        - resources:
            requests:
              cpu: 0.01
          name: systemdutil01
          image: cp.icr.io/cp/cpd/norootsquash:3.0-amd64
          imagePullPolicy: Always
          args: ["-option", "restart", "-service", "nfs-idmapd.service"]
          volumeMounts:
          - mountPath: /host/etc
            name: host-etc
          - mountPath: /host/var/log
            name: host-log
            readOnly: true
          - mountPath: /run/systemd
            name: host-systemd
          - mountPath: /host/sys
            name: host-sys
      imagePullSecrets:
      - name: cpregistrysecret
      tolerations:
      - operator: Exists
      volumes:
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-log
        hostPath:
          path: /var/log
      - name: host-systemd
        hostPath:
          path: /run/systemd
      - name: host-sys
        hostPath:
          path: /sys
```

5. Enable norootsquash

    `oc apply -f norootsquash.yaml -n kube-system`

6. Set the parameters

    ```bash
    export STORAGE_CLASS=ibmc-file-gold-gid
    export NAMESPACE=<Namespace>
    ```

7. Get image-registry-location:

    `oc get route -n openshift-image-registry`

8. Prep cluster for `dv`:

    ```bash
    ./cpd-cli adm \
    --repo ./repo.yaml \
    --assembly dv \
    --namespace <namespace>
    ```

    Run it again with `--apply` flag

9. Install `dv` :

    Update <image-registry-location> from step 7 and run the installation command

    ```bash
    ./cpd-cli install \
    --repo ./repo.yaml \
    --assembly dv \
    --namespace ${NAMESPACE} \
    --storageclass ${STORAGE_CLASS} \
    --transfer-image-to <image-registry-location>/${NAMESPACE} \
    --cluster-pull-prefix image-registry.openshift-image-registry.svc:5000/${NAMESPACE}  \
    --target-registry-username $(oc whoami) --target-registry-password $(oc whoami -t) --insecure-skip-tls-verify \
    --latest-dependency \
    --dry-run
    ```

    Run it again without `--dry-run` flag

## Uninstall


    ./cpd-cli uninstall \
    --assembly dv \
    --namespace ${NAMESPACE} \
    --include-dependent-assemblies \
    --dry-run
