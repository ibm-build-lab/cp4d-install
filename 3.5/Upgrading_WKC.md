# Upgrading WKC

1. Before upgrading WKC, you need to follow the instructions for [Backup and Restore](./Backup_Restore.md) to backup your services. 

2. Preparing to upgrade WKC

  ```bash
  ./cpd-cli adm \
  --repo ./repo.yaml \
  --assembly wkc \
  --namespace ${NAMESPACE} \
  --latest-dependency
  ```

  Run the above command again with the `--apply` flag

3. Get image-registry-location:

    `oc get route -n openshift-image-registry`

4. Upgrading WKC

  Replace <image-registry-location> from step 3 and run the upgrade command

  ```bash
  ./cpd-cli upgrade \
  --repo ./repo.yaml \
  --assembly wkc \
  --namespace ${NAMESPACE} \
  --transfer-image-to <image-registry-location>/${NAMESPACE} \
  --cluster-pull-prefix image-registry.openshift-image-registry.svc:5000/${NAMESPACE} \
  --target-registry-username $(oc whoami) --target-registry-password $(oc whoami -t) --insecure-skip-tls-verify \
  --latest-dependency \
  --dry-run
  ```

  Run the above upgrade command without the `--dry-run` flag
