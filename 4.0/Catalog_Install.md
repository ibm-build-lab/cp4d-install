# Notes for installing CP4D on ROKS via catalog
1. Use `zen` as the project name

2. Get the URL of the Cloud Pak for Data web client once `lite` assembly is installed
```bash
oc get ZenService lite-cr -o jsonpath="{.status.url}{'\n'}"
```

3. Get the initial password for the admin user:
```bash
oc extract secret/admin-user-details --keys=initial_admin_password --to=-
```

4. Log in to the CP4D web client and verify that the `lite` assembly is installed along with the services that you chose.

5. WKC installation might still be running because `c-db2oltp-wkc-db2u` is stuck. Look at the output of
```bash
oc get pods | grep wkc
```
The output should be something like this with the `c-db2oltp-wkc-db2u` in 0/1 phase
```
c-db2oltp-wkc-db2u-0                                         0/1     Running     63         18h
c-db2oltp-wkc-instdb-2c4dp                                   0/1     Completed   0          18h
wkc-base-roles-init-p5cv6                                    0/1     Completed   0          9h
wkc-db2u-init-q52bt                                          1/1     Running     0          44m
wkc-extensions-translations-init-jbjkl                       0/1     Completed   0          9h
wkc-glossary-service-5dd4858b55-b5d72                        0/1     Running     0          9h
wkc-gov-ui-5db6978fbf-t4dts                                  1/1     Running     0          9h
wkc-metadata-imports-ui-576cb5dfd5-cblsh                     1/1     Running     0          9h
wkc-roles-init-xk9jb                                         0/1     Completed   0          9h
wkc-search-7868b8b867-774vk                                  1/1     Running     0          20h
wkc-workflow-service-dd7cf699d-fgnsk                         0/1     Running     8          9h
```

6. Run the patch so that `c-db2oltp-wkc-db2u` can come up clean
```bash
oc patch sts c-db2oltp-wkc-db2u -p='{"spec":{"template":{"spec":{"containers":[{"name":"db2u","tty":false}]}}}}}'
```

7. Similarly for IIS also, we need db2 sts patch for `c-db2oltp-iis-db2u`. This will come after WKC so it might take another hour
```bash
oc patch sts c-db2oltp-iis-db2u -p='{"spec":{"template":{"spec":{"containers":[{"name":"db2u","tty":false}]}}}}}'
```
