# Configure SSO for CP4D UI

## Board the CP4D Application using SSO Provisioner Tool
Launch [SSO Provisioner Tool](http://w3.ibm.com/tools/sso), choose `Register a w3id application`, fill out and submit form.

Use the following values:
- set `Home Page` to cp4d ui url (i.e. https://cpd-zen-45.cp4d45-cluster-2bef1f4b4097001da9502000c44fc2b2-0000.ca-tor.containers.appdomain.cloud)
- for `w3id Protocol Selection` choose `SAML 2.0`
- for `Select Identity Provider` choose `preproduction` or `production`
- for `Target Application URL` enter `<cp4d ui url>/auth/login/sso/callback`
- for `Entity ID` enter something unique like `buildlab-cpd`
- for `ACS HTTP Post URIs` enter same value as the `Target Application URL`
- for `MFA Access Policy` choose `Default policy (IBM-only)`

## Download the IDP Metadata File

Once the application is approved, go `Manage my SSO registrations` in the [SSO Provisioner Tool](http://w3.ibm.com/tools/sso), edit the application and download the **IDP Metadata File** located under `Identity Provider`

## Configure Single Sign On 

### Enable SAML 

Log into cluster
```
ibmcloud login -sso
ibmcloud ks cluster config -c <cluster_name> --admin
```
Run the following command to exec into user management pod and create a `samlConfig.json` file:
```
oc exec -it -n <namespace> $(oc get pod -n zen-45  -l component=usermgmt | tail -1 | cut -f1 -d\ ) \
-- bash -c "vi /user-home/_global_/config/saml/samlConfig.json"
```
Example of samlConfig.json:
```
{
   "entryPoint": "https://login.w3.ibm.com/saml/sps/saml20ip/saml20/login",
   "fieldToAuthenticate": "emailAddress",
   "spCert": "",
   "idpCert": "*************",        
   "issuer": "buildlab-latrng-cpd",   
   "identifierFormat": "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
   "callbackUrl": "https://cpd-zen-45.cp4d45-cluster-2bef1f4b4097001da9502000c44fc2b2-0000.ca-tor.containers.appdomain.cloud/auth/login/sso/callback" 
}
```
where:

_idpCert_ = `X509Certificate` from IDP Metadata File

_issuer_ = `Entity ID` from SSO Request form above

_callbackUrl_ = `Target Application URL` from SSO request form above

### Restart the pods
```
oc delete pods -l component=usermgmt -n <namespace>
```

## Create Users in CP4D Console

Log into the console using the `Admin` user.  Choose `Administration` then `Access control`.  

**NOTE:** Add users with their IBM SSO email address as the user id.

## For more information, see the following links:
- https://www.ibm.com/docs/en/cloud-paks/cp-data/4.5.x?topic=environment-configuring-sso
- SSO Provisioner Tool: http://w3.ibm.com/tools/sso
- Boarding instructions: https://w3.ibm.com/w3publisher/w3idsso/boarding
- https://w3.ibm.com/w3publisher/w3idsso/boarding/saml-boarding-troubleshooting
- https://ibm.ent.box.com/file/1003210631769 
- https://ibm.ent.box.com/s/asxizmc95kodf00x78en9bs8qgfp04h4
