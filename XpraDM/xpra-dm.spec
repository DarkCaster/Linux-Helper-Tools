#
# spec file for package xpra-dm
#

Name:           xpra-dm
Version:        0.1
Release:        0
Summary:        Display manager for xpra
License:        MIT
Group:          Productivity/Networking/System
Source1:        xpra_dm
Source2:        xpra_lxdm
Source3:        xpra_x11
Source4:        xpra_xvfb
Source5:        sysconfig.xpra-dm
Source6:        xpra_dm.dm_script
Source7:        xpra-dm.service
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
# packaging stuff
BuildRequires:  fdupes
BuildRequires:  systemd-rpm-macros
BuildRequires:  systemd
# native stuff
Requires:       acl
Requires:       bash
Requires:       python-xpra
Requires:       xorg-x11-server
Requires:       xf86-video-dummy
Requires:       lxdm
Requires(post): %fillup_prereq
PreReq:         /usr/sbin/useradd /usr/sbin/groupadd
BuildArch:      noarch
%{?systemd_requires}

%description
Start display manager (lxdm for now) inside xpra remote desktop software.

%prep

%build

%install
mkdir -p "%{buildroot}%{_bindir}"
cp %{S:1} "%{buildroot}%{_bindir}"
cp %{S:2} "%{buildroot}%{_bindir}"
cp %{S:3} "%{buildroot}%{_bindir}"
cp %{S:4} "%{buildroot}%{_bindir}"
chmod 755 "%{buildroot}%{_bindir}"/*
mkdir -p "%{buildroot}%{_prefix}/lib/X11/displaymanagers"
cp %{S:6} "%{buildroot}%{_prefix}/lib/X11/displaymanagers/xpra_dm"
mkdir -p "%{buildroot}%{_unitdir}"
cp %{S:7} "%{buildroot}%{_unitdir}"
%if 0%{?sle_version} && 0%{?sle_version} < 150000
mkdir -p "%{buildroot}/var/adm/fillup-templates"
cp %{S:5} "%{buildroot}/var/adm/fillup-templates"
%else
mkdir -p "%{buildroot}%{_fillupdir}"
cp %{S:5} "%{buildroot}%{_fillupdir}"
%endif
%fdupes "%{buildroot}%{_prefix}"

%pre
/usr/sbin/groupadd -r xpra_x11 2> /dev/null ||:
/usr/sbin/useradd -r -g xpra_x11 -G audio,video -s /bin/false -c "User for running xpra x11 session" \
 -d /var/run/xpra_x11 xpra_x11 2> /dev/null ||:
%service_add_pre xpra-dm.service

%post
%fillup_only
%service_add_post xpra-dm.service

%preun
%service_del_preun xpra-dm.service

%postun
%service_del_postun xpra-dm.service

%files
%defattr(-,root,root)
%{_bindir}/xpra_*
%{_prefix}/lib/X11/displaymanagers
%if 0%{?sle_version} && 0%{?sle_version} < 150000
/var/adm/fillup-templates/sysconfig.xpra-dm
%else
%{_fillupdir}/sysconfig.xpra-dm
%endif
%{_unitdir}/xpra-dm.service

%changelog
* Sat Feb 17 2018 fwdsbs.to.11df@xoxy.net
- xpra-dm package
