%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)

Name:           ldap-acl-syncer
Version:        0.1
Release:        1%{?dist}
Summary:        This package helps you to organize security policies by access lists using ldap.

Group:          System Tools
License:        BSD
URL:            https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer
Source0:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/bin/ldap-acl-syncer.pl
Source1:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/lib/ldap-acl-syncer/ldap_acl_syncer.pm
Source2:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/lib/ldap-acl-syncer/ldap_acl_syncer_logger.pm
Source3:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/etc/ldap-acl-syncer.conf
Source4:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/docs/README.md
Source5:        http://ftp.netbsd.org/pub/NetBSD/NetBSD-current/src/external/bsd/openldap/dist/contrib/slapd-modules/nssov/ldapns.schema
Source6:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/docs/ldap-acl-syncer.spec
Source7:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/cron.d/ldap-acl-syncer
Source8:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/docs/examples/ldap_structure.txt

BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires:       perl-LDAP
Requires:       perl-Clone
Requires:       perl

AutoReqProv:	no
%description


%prep

%install
rm -rf $RPM_BUILD_ROOT
install -d -m755 $RPM_BUILD_ROOT
install -d -m755 $RPM_BUILD_ROOT/usr/bin
install -d -m755 $RPM_BUILD_ROOT/etc
install -d -m755 $RPM_BUILD_ROOT/etc/cron.d
install -d -m755 $RPM_BUILD_ROOT%{perl_vendorlib}/ldap_acl_syncer
install -d -m755 $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}
install -d -m755 $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/examples

install %{SOURCE0} $RPM_BUILD_ROOT/usr/bin/
install %{SOURCE1} $RPM_BUILD_ROOT%{perl_vendorlib}/ldap_acl_syncer/
install %{SOURCE2} $RPM_BUILD_ROOT%{perl_vendorlib}/ldap_acl_syncer/
install %{SOURCE3} $RPM_BUILD_ROOT/etc/
install %{SOURCE4} $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/
install %{SOURCE5} $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/
install %{SOURCE6} $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/
install %{SOURCE7} $RPM_BUILD_ROOT/etc/cron.d/
install %{SOURCE8} $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/examples


%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%dir %{perl_vendorlib}/ldap_acl_syncer
/usr/bin/%{name}.pl
%{perl_vendorlib}/ldap_acl_syncer/ldap_acl_syncer.pm
%{perl_vendorlib}/ldap_acl_syncer/ldap_acl_syncer_logger.pm
%attr(644, root, root)/etc/cron.d/%{name}
%config(noreplace) /etc/ldap-acl-syncer.conf
%doc /usr/share/doc/%{name}-%{version}/README.md 
%doc /usr/share/doc/%{name}-%{version}/ldapns.schema 
%doc /usr/share/doc/%{name}-%{version}/ldap-acl-syncer.spec
%doc /usr/share/doc/%{name}-%{version}/examples/ldap_structure.txt

%changelog
* Thu Apr 19 2013 Andrii Grytsenko <andrii.grytsenko@gmail.com> 0.1-1
- created new package
