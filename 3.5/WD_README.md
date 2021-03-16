# Installing Watson Discovery

Go [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.5.0/svc-discovery/discovery-install.html) for the full Watson Discovery Installation documentation

## Install

1. Append `repo.yaml` with the following. More info [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.5.0/cpd/install/installation-files.html):

   ```yaml
    # RMQ/Elasticsearch/Gateway/Minio Operator
    - url: cp.icr.io
    username: cp
    apikey: <entitlement-key>
    namespace: cp
    name: prod-entitled-registry
    # Etcd Operator
    - url: cp.icr.io
    username: cp
    apikey: <entitlement-key>
    namespace: cp
    name: entitled-registry
    # EDB Operator
    - url: cp.icr.io
    username: cp
    apikey: <entitlement-key>
    namespace: cp/cpd
    name: databases-registry
    # ModelTrain Classic
    - url: cp.icr.io
    username: cp
    apikey: <entitlement-key>
    namespace: cp/modeltrain
    name: modeltrain-classic-registry
    # Discovery
    - url: cp.icr.io
    username: cp
    apikey: <entitlement-key>
    namespace: cp/watson-discovery
    name: watson-discovery-registry
   ```

2. Create `wd-install-override.yaml` (optional):

   ```yaml
    wdRelease:
    deploymentType: Development
    enableContentIntelligence: false
    elasticsearch:
        clientNode:
        persistence:
            size: 1Gi
        dataNode:
        persistence:
            size: 40Gi
        masterNode:
        persistence:
            size: 2Gi
    etcd:
        storageSize: 10Gi
    minio:
        persistence:
        size: 100Gi
    postgres:
        database:
        storageRequest: 30Gi
        useSingleMountPoint: true
    rabbitmq:
        persistentVolume:
        size: 5Gi
   ```

3. Get image-registry-location:

    `oc get route -n openshift-image-registry`

4. Prep cluster and install `edb-operator`:

    ```bash
    ./cpd-cli adm \
    --repo ./repo.yaml \
    --assembly edb-operator \
    --arch x86_64 \
    --namespace <namespace> –apply 

    Replace <image-registry-location> from step 3 and run the installation command

    ./cpd-cli install \ 
    --repo ./repo.yaml \
    --assembly edb-operator \
    --optional-modules edb-pg-base:x86_64 \
    --arch x86_64 \
    --namespace <namespace> \
    --storageclass portworx-db-gp3-sc \
    --transfer-image-to <image-registry-location>/${NAMESPACE} \
    --cluster-pull-prefix $(oc registry info)/<namespace> \
    --latest-dependency \
    --cluster-pull-username=kubeadmin \
    --cluster-pull-password=$(oc whoami -t) \ 
    --insecure-skip-tls-verify \
    --target-registry-username=$(oc whoami) \
    --target-registry-password=$(oc whoami -t) \
    --override wd-install-override.yaml \
    --verbose
    ```

5. Prep cluster and install `watson-discovery`:

    ```bash
    ./cpd-cli adm \
    --repo ./repo.yaml \
    --assembly watson-discovery \
    --namespace <namespace> --apply

    Replace <image-registry-location> from step 3 and run the installation command

    ./cpd-cli install \
    --repo ./repo.yaml \
    --assembly watson-discovery \
    --arch x86_64 \
    --namespace <namespace> \
    --storageclass portworx-db-gp3-sc \
    --transfer-image-to <image-registry-location>/${NAMESPACE} \
    --cluster-pull-prefix $(oc registry info)/<namespace> \
    --latest-dependency \
    --cluster-pull-username=kubeadmin \
    --cluster-pull-password=$(oc whoami -t) \
    --target-registry-username=$(oc whoami) \
    --target-registry-password=$(oc whoami -t) \
    --insecure-skip-tls-verify \
    --verbose
    ```

## Uninstall

    ./cpd-cli uninstall \
    --assembly watson-discovery \
    --namespace cp4d-datahub \
    --include-dependent-assemblies

    oc delete pvc -l 'app.kubernetes.io/name in (discovery, wd)' --ignore-not-found # Clear cpd install status

    oc delete cm -n "$namespace" --ignore-not-found cpd-install-status 
    oc delete cm -n "$namespace" --ignore-not-found cpdinstall-a-watson-discovery-amd64 
    oc delete cm -n "$namespace" --ignore-not-found cpd-install-cr-modules-list 

