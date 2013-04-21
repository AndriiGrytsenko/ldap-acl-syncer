Name:           ldap-acl-syncer
Version:        0.1
Release:        1%{?dist}
Summary:        This package helps you to organize security policies by access lists using ldap.

Group:          System Tools
License:        BSD
URL:            https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer
Source0:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/bin/ldap-acl-syncer.pl
Source1:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/lib/ldap_acl_syncer.pm
Source2:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/lib/ldap_acl_syncer_logger.pm
Source3:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/etc/ldap-acl-syncer.conf
Source4:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/docs/README.md
Source5:        http://ftp.netbsd.org/pub/NetBSD/NetBSD-current/src/external/bsd/openldap/dist/contrib/slapd-modules/nssov/ldapns.schema
Source6:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/docs/ldap-acl-syncer.spec
Source7:        https://raw.github.com/AndriiGrytsenko/ldap-acl-syncer/master/crond./ldap-acl-syncer

BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires:       perl-LDAP, perl-Clone, perl

%description


%prep

%install
rm -rf $RPM_BUILD_ROOT
install -d -m755 $RPM_BUILD_ROOT
install -d -m755 $RPM_BUILD_ROOT/usr/bin
install -d -m755 $RPM_BUILD_ROOT/etc
install -d -m755 $RPM_BUILD_ROOT/etc/cron.d
install -d -m755 $RPM_BUILD_ROOT/usr/lib/%{name}
install -d -m755 $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}

install %{SOURCE0} $RPM_BUILD_ROOT/usr/bin/
install %{SOURCE1} $RPM_BUILD_ROOT/usr/lib/%{name}/
install %{SOURCE2} $RPM_BUILD_ROOT/usr/lib/%{name}/
install %{SOURCE3} $RPM_BUILD_ROOT/etc/
install %{SOURCE4} $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/
install %{SOURCE5} $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/
install %{SOURCE6} $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/
install %{SOURCE7} $RPM_BUILD_ROOT/etc/cron.d/


%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%dir /usr/lib/%{name}
/usr/bin/%{name}.pl
/usr/lib/%{name}/ldap_acl_syncer.pm
/usr/lib/%{name}/ldap_acl_syncer_logger.pm
%attr(644, root, root)/etc/cron.d/%{name}
%config(noreplace) /etc/ldap-acl-syncer.conf
%doc /usr/share/doc/%{name}-%{version}/README.md 
%doc /usr/share/doc/%{name}-%{version}/ldapns.schema 
%doc /usr/share/doc/%{name}-%{version}/ldap-acl-syncer.spec

%changelog
* Thu Apr 19 2013 Andrii Grytsenko <andrii.grytsenko@gmail.com> 0.1-1
- created new package
