LDAP ACL 
===

This package helps you to organize security policies by access lists using ldap. 

### Context:
1. LDAP Setup 
2. Script Setup
3. What does script do?
4. Host installation
5. Building RPM
6. Usage example
7. Where to download RPM package? 


LDAP Setup
---

To support host attribute you need to download and include [ldapns.schema](http://ftp.netbsd.org/pub/NetBSD/NetBSD-current/src/external/bsd/openldap/dist/contrib/slapd-modules/nssov/ldapns.schema) in **slapd.conf**: 

`include         /etc/openldap/schema/ldapns.schema`

In order to make first access list you have to create dedicated LDAP tree. And only then create group records like this:

```
dn: cn=developers,ou=ACL,dc=test,dc=com
cn: developers
gidNumber: 501
memberUid: developer
memberUid: developer2
memberUid: developer3
structuralObjectClass: posixGroup
host: !host1.qa.lan:g
host: *.qa.lan:g
objectClass: posixGroup
objectClass: top
objectClass: hostObject
```

where **memberUid** references to **cn** from People tree and **host** the hostname from */etc/ldap.conf*. Also host has some kind of extension like **g** or **p**. Where **g** stand for **group** and managed by access list and script. **p** is for **private** and managed manually.    
In this example we are allow users ( *developer*,*developer2*,*developer3* ) access all host in domain *.qa.lan* except *host1.qa.lan*.

Script Setup 
---

There is RPM spec file for script installation but you can just checkout repository and install it wherever you want. The default path for configuration is **/etc/ldap-acl-syncer.conf**. The configuration is pretty straightforward and self-explainable:

```
ldap_host       => ldap://127.0.0.1:389
base            => dc=test,dc=com
password        => test

bind            => cn=root,dc=test,dc=com
acl_tree        => ou=ACL,dc=test,dc=com
people_tree     => ou=People,dc=test,dc=com
interval_time   => 120
log_file        => /var/log/ldap-acl-syncer.log
```

where:   
**ldap_host** = url or host to you ldap server   
**base** = your ldap base   
**pass** = you bind password   
**bind** = you username to connect to ldap(has to be with write permissions)   
**acl_tree** = path to ACL tree 
**people_tree** = path to People tree
**interval_time** = depending of how often you going to run this script, set 60 if you are going to run it every minute by cron.

####Cron installation####
if you aren't going to use RPM package, then you are required to setup cron manually:    
`* * * * * /usr/bin/ldap-acl-syncer.pl`

What does script do ?
----

1. check if there were any updates in **acl_tree** in past **interval_time** seconds.
2. If so, clean up all **\*:g**(group hosts) records in users accounts.
3. Re-read **acl_tree** 
4. Applied groups hosts to users accounts 

After script run all **\*:g** entries from all acl's will be applied to appropriate accounts. 

Host installation
---

In addition to ldap authentication installation you need next rule to be added to **/etc/ldap.conf**:   
   
it could be as easy as:   
`pam_fileter |(host=andrii.prod.lan:*)(host=\*:*)`   
and as complex as:    
`pam_filter &(|(host=andrii.prod.lan:*)(host=\*:*))(!host=x\*:*)`


the last one allows all access for all users who have next value in ldap attibute **host**:   
**andrii.lan:\***   
**\*.prod.lan:\***   
**\*:\***   
and completely disallow everyone who have at least one of them    
**!andrii.lan:\***   
**!\*.prod.lan:\***   
**!\*:\***

Building RPM
----
In order to build rpm package checkout from repository latest version of script and spec file and run **rpmbuild**(be aware the you need perl-LDAP and perl-Clone package to run the script):
`git checkout git@github.com:AndriiGrytsenko/ldap-acl-syncer.git`

if you have **spectools** you don't need to download sources manually, just run:    
`cd $rpmbuild/SPECS && spectool -gf -C ../SOURCES/ openssh-ldap-publickey.spec`

then build RPM as usual:    
`rpmbuild -ba ldap-acl-syncer.spec`



Usage example
----

Taking access list **developers** from the **LDAP Setup**, we got next records for user developer2:
```
dn: cn=developers,ou=People,dc=test,dc=com
givenName: developers
sn: developers
cn: developers
uidNumber: 1000
gidNumber: 500
loginShell: /bin/bash
structuralObjectClass: inetOrgPerson
uid: developers
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
objectClass: hostObject
userPassword:: e01ENX0yRmVPMzRSWXpnYjd4YnQycFl4Y3BBPT0=
homeDirectory: /home/developer2
host: !host1.qa.lan:g
host: *.qa.lan:g
```
To extend his policies by adding access to some production hosts(*web1.prod.lan*, *web2.prod.lan*) and in the meantime deny him to login into *web3.qa.lan*. In order to fulfil this requirements we can use *private* entries:

```
...
host: web1.prod.lan:p
host: web2.prod.lan:p
host: web3.qa.lan:p
...
```
those attributes will not be managed by script, so this is something to keep in mind in the future. 

 
Where to download RPM package? 
----
You can find RPM packages [here](http://andriigrytsenko.net/repo/ldap-acl-syncer/)