# Description

Nixlocker, is a utility designed for use on Linux systems to unlock LUKS encrypted partitions using a key file stored on an external USB device key.

# Design

This package was designed and tested on an OpenSUSE Leap based system. In theory it should work with other distributions as nothing should be specific to the OpenSUSE environment; however the SPEC file likely lists package names that might be specific to OpenSUSE.

# Installation
Run the Makefile and install the resulting RPM. After installation you will need to perform a manual configuration following the configuration examples.

# Configuration
The locker utility works off a configuration file "/etc/nixime/nixlocker.cfg". This file contains the information about the external device and LUKS partitions.

<code>
LABEL=NIXIME
LUKSDEV=/dev/sda2|0
UUID=AAAA-BBBB
DEBUG=true
</code>

Elements used for defining the external USB device containing the lock file
* LABEL; Defines the label of the external USB device.
* UUID; Defines the UUID of the external USB device. This is only used if the USB cannot be found based on the LABEL 

Elements used for script operation:
* LUKSDEV; Current not used
* DEBUG; If this entry exists then the script will print trace information to stderr. *WARNING* This will print the password into your journald logs and may be visible to unintended users.

#Issues

1. This service is not the quickest. When your system boots up you may see the prompt for a password for a period of time before this service kicks in. At this time, unknown why this is the case.
2. Cannot determine the appropriate systemd settings to block the starting of this service until the external usb devices are populated.



