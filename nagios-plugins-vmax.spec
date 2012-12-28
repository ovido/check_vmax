Name:		nagios-plugins-vmax
Version:	1.0
Release:	1%{?dist}
Summary:	EMC Symmetrix VMAX monitoring plugin for Nagios/Icinga

Group:		Applications/System
License:	GPLv2+
URL:		https://labs.ovido.at/monitoring
Source0:	check_vmax-%{version}.tar.gz
BuildRoot:	%{_tmppath}/check_vmax-%{version}-%{release}-root

%description
This plugin for Icinga/Nagios is used to monitor RF and FA adapters,
Power Supply stati and thin pool usage of EMC VMAX storages.

%prep
%setup -q -n check_vmax-%{version}

%build
%configure --prefix=%{_libdir}/nagios/plugins \
	   --with-nagios-user=nagios \
	   --with-nagios-group=nagios \
	   --with-pnp-dir=%{_datadir}/nagios/html/pnp4nagios

make all


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT INSTALL_OPTS=""

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(0755,nagios,nagios)
%{_libdir}/nagios/plugins/check_vmax
%{_datadir}/nagios/html/pnp4nagios/templates/check_vmax.php
%doc README INSTALL NEWS ChangeLog COPYING



%changelog
* Fri Dec 28 2012 Rene Koch <r.koch@ovido.at> 1.0-1
- Initial build.

* Fri Dec 14 2012 Rene koch <r.koch@ovido.at> 0.2-1
- Initial build.

* Tue Nov 6 2012 Rene Koch <r.koch@ovido.at> 0.1-1
- Initial build.

