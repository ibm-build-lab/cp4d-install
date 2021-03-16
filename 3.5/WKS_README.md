# Installing Watson Knowledge Studio

Go [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.5.0/svc-wks/knowledge-studio-install-overview.html) for full Watson Knowledge Studio installation information 

1. Append `repo.yaml` with the following. More info [here](https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.5.0/cpd/install/installation-files.html):

    ```yaml
    - url: cp.icr.io
        username: cp
        apikey: entitlement-key
        namespace: "cp/knowledge-studio"
        name: wks-registry
    - url: cp.icr.io
        username: "cp"
        apikey: entitlement-key
        namespace: "cp"
        name: prod-entitled-registry
    - url: cp.icr.io
        username: cp
        apikey: entitlement-key
        namespace: "cp"
        name: entitled-registry
    - url: cp.icr.io
        username: cp
        apikey: entitlement-key
        namespace: "cp/cpd"
        name: databases-registry
    ```

2. Get image-registry-location:

    `oc get route -n openshift-image-registry`

3. Prepare the cluster and install:

    ```bash
    cpd-cli adm --repo repo.yaml \
    --assembly watson-ks \
    --namespace <namespace> \
    --apply

    Replace <image-registry-location> from step 2 and run the installation command

    cpd-cli adm --repo repo.yaml \
    --assembly watson-ks \
    --arch x86_64 \
    --namespace cp4d-datahub \
    --storageclass portworx-shared-gp3 \
    --transfer-image-to <image-registry-location>/${NAMESPACE} \
    --cluster-pull-prefix $(oc registry info)/<namespace> \
    --latest-dependency \
    --cluster-pull-username=kubeadmin \
    --cluster-pull-password=$(oc whoami -t) \
    --insecure-skip-tls-verify \
    --target-registry-username=$(oc whoami) \
    --target-registry-password=$(oc whoami -t) \
    --verbose
    ```

## Uninstall

```bash
./cpd-cli uninstall \
--assembly watson-ks \
--namespace <namespace> \
--include-dependent-assemblies
```
