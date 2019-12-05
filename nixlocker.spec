#
# Copyright 2019 NIXIME@GITHUB
#

Name:       nixlocker
Version:    %{_iv_pkg_version}
Release:    %{_iv_pkg_release}%{?dist}
Summary:    LUKS unlocker for SDCard
License:    The Artistic License 2.0
Group:      Nixime          
Source:     nixlocker.tgz
BuildRoot:  %{_tmppath}/%{name}-%{version}-build
Requires:   socat inotify-tools
Conflicts:  plymouth

%description
This package provides the nixlocker systemd scripts and associated generation scripts to 
setup a LUKs unmounting at boot time from and external USB device.

%prep
%setup -q -c -n nixlocker

%install
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}/etc/systemd/system/sysinit.target.wants
mkdir -p %{buildroot}/etc/dracut.conf.d
mkdir -p %{buildroot}/usr/local/bin

install -m 755 system-nixlocker-agent.sh %{buildroot}/etc/systemd/system/system-nixlocker-agent.sh
install -m 644 99-nixlocker.conf %{buildroot}/etc/dracut.conf.d/99-nixlocker.conf
install -m 755 nixlocker-gen %{buildroot}/usr/local/bin/nixlocker-gen

# Install the service
install -m 644 system-nixlocker-agent.service %{buildroot}/etc/systemd/system/system-nixlocker-agent.service
/bin/ln -sf ../system-nixlocker-agent.service %{buildroot}/etc/systemd/system/sysinit.target.wants/system-nixlocker-agent.service

# Install the path watcher
install -m 644 system-nixlocker-agent.path %{buildroot}/etc/systemd/system/system-nixlocker-agent.path
/bin/ln -sf ../system-nixlocker-agent.path %{buildroot}/etc/systemd/system/sysinit.target.wants/system-nixlocker-agent.path


%post
echo "Rebuilding initramfs, please wait..."
dracut -fq


%postun
echo "Rebuilding initramfs, please wait..."
dracut -fq


%files
%defattr(-,root,root)
/etc/systemd/system/system-nixlocker-agent.sh
/etc/systemd/system/system-nixlocker-agent.path
/etc/systemd/system/system-nixlocker-agent.service 
/etc/systemd/system/sysinit.target.wants/system-nixlocker-agent.path
/etc/systemd/system/sysinit.target.wants/system-nixlocker-agent.service
/etc/dracut.conf.d/99-nixlocker.conf
/usr/local/bin/nixlocker-gen

#%dir %attr(0640,root,root) %ghost /etc/nixime/nixlocker.cfg

%changelog

