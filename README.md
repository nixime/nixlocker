# Description

Patrick's locker, is a utility designed for use on Linux systems to unlock LUKS encrypted partitions using a key file stored on an external USB device key.

The source code of this utility isDistributed under The Artistic License 2.0*

# Components


# Design Docs

## Configuration
The locker utility works off a configuration file "/etc/nixime/plocker.cfg". This file contains the information about the external device and LUKS partitions.

<code>
LABEL=NIXIME<br>
LUKSDEV=/dev/sda2|0<br>
UUID=AAAA-BBBB<br>
DEBUG=true<br>
</code>

Elements used for defining the external USB device containing the lock file
* LABEL; Defines the label of the external USB device.
* UUID; Defines the UUID of the external USB device. This is only used if the USB cannot be found based on the LABEL 

Elements used for script operation:
* LUKSDEV; Current not used
* DEBUG; If this entry exists then the script will print trace information to stderr. *WARNING* This will print the password into your journald logs and may be visible to unintended users.

