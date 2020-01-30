# kerberos-ansible
Repository to be used with ansible-pull. It will kerberize a system. Currently supports Ubuntu 14, 16 and 18, Centos 6, 7 and 8, SLES 12. However only Centos 7 and 8 and Ubuntu 18 are currently in use, so older systems might have issues.

If used in push mode on our config server, /etc/krb5.keytab is generated as part of this process. If used in pull mode on a new machine, the key table has to be generated before using ansible. The kerberize script does that, and sets up the environment so the ansible scripts will work.

kerberos-boot.yml must be done first. Normally it only needs to be done once.

kerberos.yml is designed to be run again every time the software changes.

There are lots of configuration options in the hosts file. If you use the kerberize script to run this in pull mode, it will generate a hosts for based an a couple of questions asked in the script.

## Requirements for push-mode ansible
Uses a script to create host entries. That uses /etc/krb5.enroll.keytab with principal enroll/config.lcsr.rutgers.edu

That principal has role Rutgers add host
```
Privilege: Host Enrollment
This is a standard privilege, but we added some permissions to it. Here are all of them:
System: Add Hosts
System: Add krbPrincipalName to a Host
System: Enroll a Host
System: Manage Host Certificates
System: Manage Host Enrollment Password
System: Manage Host Keytab
System: Manage Host Principals
System: Manage Host SSH Public Keys
System: Add Services
System: Manage Service Keytab
System: Change User password
```

## Requirements for kerberize script
services.cs.rutgers.edu/krb5.kdc.pem must be set up. It's retrieved by the script using curl -o.

The kerberize script depends upon this:

```
User role: rutgers user add host
Privilege: Rutgers add host
System: Add Host
System: Enroll a Host
System: Manage Host Enrollment Password
```

Also depends upon an ACI
```
dn: cn=computers,cn=accounts,dc=cs,dc=rutgers,dc=edu
changetype: modify
add:aci
aci: (targetfilter=(objectClass=ipahost))(targetattr="managedby")
 (target="ldap:///cn=computers,cn=accounts,dc=cs,dc=rutgers,dc=edu") (version 3.0; acl "Modify Own ManagedBy";
 allow (all) (userattr="creatorsName#USERDN"); )
```

To automatically add new hosts to research netgroup:

```
ipa hostgroup-add research-user
ipa automember-add research-user --type=hostgroup 
ipa automember-add-condition research-user --type=hostgroup --key=nshostlocation --inclusive-regex='^research-user$'
ipa netgroup-add-member research-user-maint --hostgroup=research-user
```
