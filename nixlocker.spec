#
# Copyright 2019 NIXIME@GITHUB
#

Name:       nixlocker
Version:    %{_iv_pkg_version}
Release:    %{_iv_pkg_release}%{?dist}
Summary:    LUKS unlocker for SDCard
License:    The Artistic License
Group:      Nixime          
Source:     nixlocker.tgz
BuildRoot:  %{_tmppath}/%{name}-%{version}-build
Requires:   socat inotify-tools util-linux
Conflicts:  plymouth

%description
This package provides the nixlocker systemd scripts and associated generation scripts to 
setup a LUKs unmounting at boot time from and external USB device.

%prep
%setup -q -c -n nixlocker

%install
mkdir -p %{buildroot}/etc/nixime
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}/etc/systemd/system/sysinit.target.wants
mkdir -p %{buildroot}/etc/dracut.conf.d
mkdir -p %{buildroot}/etc/udev/rules.d
mkdir -p %{buildroot}/usr/local/bin

# Configurations
install -m 644 99-nixlocker.conf %{buildroot}/etc/dracut.conf.d/99-nixlocker.conf
install -m 640 nixlocker.cfg %{buildroot}/etc/nixime/nixlocker.cfg

# Scripts
install -m 755 nixlocker-gen %{buildroot}/usr/local/bin/nixlocker-gen
install -m 755 system-nixlocker-agent.sh %{buildroot}/etc/systemd/system/system-nixlocker-agent.sh

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

%config(noreplace) /etc/nixime/nixlocker.cfg

%changelog

