#!/usr/bin/sh
#
# Copyright 2019 NIXIME@GITHUB
#

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define our constants, paths and commands that will be needed
SPOOLDIR=/run/systemd/ask-password
PASSFILE=nixlocker.nixkey
DEVLBL=
RAWDEV=
UUID=
RESPONSE=""

# Define all the commands that we will be using. Make sure to do this so
# that this can be compared against the dracut config file otherwise the
# needed tools will be missing.
AWK=/usr/bin/awk
CAT=/usr/bin/cat
CUT=/usr/bin/cut
ECHO=/usr/bin/echo
FIND=/usr/bin/find
GREP=/usr/bin/grep
INWAIT=/usr/bin/inotifywait
MKTMP=/usr/bin/mktemp
MOUNT=/usr/bin/mount
READLINK=/usr/bin/readlink
SOCAT=/usr/bin/socat
UMOUNT=/usr/bin/umount
BLKID=/sbin/blkid
SLEEP=/usr/bin/sleep
#---------------------------------------------------------------

#
# getResponseValue
#    Get the passphrase from the DEVICE for responding to requests from cryptsetup.
#
# [in-global] DEVLBL
# [in-global] UUID
# [in-global] PASSFILE
#
# [out-global] RESPONSE
#
function setResponseValue()
{
    RESPONSE=""

    # Get the password response from the keyfile on the labeled device
    # NOTE: Attempted to use the disk-by-* method, but found that these where not created earlier enough
    #       to enable the finding of the necessary USB device. This approach uses blkid to find the item
    #       by label or uuid as a secondary.
    [ ! -z ${DEVLBL} ] && RAWDEV=$(${BLKID} --label ${DEVLBL})
    [ -z ${RAWDEV} -a ! -z ${UUID} ] && RAWDEV=$(${BLKID} --uuid ${UUID})
    [ -z ${RAWDEV} ] && ${ECHO} "Device not found" && return -1

    if [ -e /dev/nixlocker ]; then
        ${ECHO} "nixlocker device exists"
    fi

    tmpd=$(${MKTMP} -d)
    [ ! -d ${tmpd} ] && return -2

    dev=$(${READLINK} -f ${RAWDEV})
    [ $? -ne 0 ] && return -2

    ${GREP} -q "${dev}" /proc/mounts
    if [ $? -eq 0 ]; then
        mpt=$(${GREP} ${dev} /proc/mounts | ${AWK} '{print $2}')
        RESPONSE=$(${CAT} ${mpt}/${PASSFILE})
    else
        ${MOUNT} -o ro ${dev} ${tmpd} >&2
        [ $? -ne 0 ] && return -2
        RESPONSE=$(${CAT} ${tmpd}/${PASSFILE})
        ${UMOUNT} ${tmpd}
    fi

    return 0
}

#
# processAskFile
#   Process the provided Ask file by sending the password through the socket specified. This method assumes that
#   the response needed is already set. This should be properly set before calling this method.
#
# [in] askfile Full path to the askfile being used for the LUKS request
#
function processAskFile()
{
    askfile=$1
    
    ${ECHO} "ASKFILE: ${askfile}"
    for ln in $(${CAT} ${askfile}); do
        ${ECHO} "+ASKFILE: ${ln}"
    done
    
    # If something beat us to the response
    [ ! -e ${askfile} ] && return 1

    # Get the socket for sending the response
    sockfn=$(${GREP} ^Socket= ${askfile} | ${CUT} -d= -f2)
    [ $? -ne 0 -o "x${sockfn}" == "x" ] && return 1

    # One last check before sending the response, then send the response to the socket
    ${ECHO} "SEND Response: ${askfile}"
    [ -e ${askfile} ] && ${ECHO} -n "+$RESPONSE" | ${SOCAT} - "UNIX-SENDTO:${sockfn}" 
    [ $? -ne 0 ] && ${ECHO} Error using $SOCAT to send response to $regfn

    return 0
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Error handling
if [ -x ${FIND} -a -x ${GREP} -a -x ${CUT} -a -x ${ECHO} -a -x ${SOCAT} -a -x ${INWAIT} -a -x ${READLINK} -a -x ${MOUNT} ]; then
    ${ECHO} "Starting NIXIME locker" >&2    
elif [ ! -e ${SPOOLDIR} ]; then
    ${ECHO} "No spool dir ${SPOOLDIR} found" >&2
    exit 99
elif [ -e /tmp/nixskip ]; then
    ${ECHO} "Skipping execution" >&2
    exit 99
else
    ${ECHO} "Missing necessary tools" >&2
    exit 99
fi
#---------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Read configuration file for details on decryption logic
DBGFLAG=0
[ ! -f /etc/nixime/nixlocker.cfg ] && ${ECHO} "Unable to find config" && exit 91
for kv in $(${GREP} -v '^#' /etc/nixime/nixlocker.cfg); do
    key=$(${ECHO} "${kv}" | ${AWK} -F= '{print $1}')
    val=$(${ECHO} "${kv}" | ${AWK} -F= '{print $2}')
    case $key in
        LABEL) # Get the LABEL of the device containing the key file
            DEVLBL=${val}
        ;;

        UUID) # Get the UUID of the device containing the key file
            UUID=${val}
        ;;
        
        DEBUG) # Set Debug printing
            set -xv
            ${ECHO} > /tmp/nixskip
            DBGFLAG=1
        ;;
    esac
done

#---------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
setResponseValue
while [ -z ${RESPONSE} ]; do
    #
    # Wait for devices to become available, Don't use the monitor method as that will create an infinite wait and not exit out. Unless grabbing pids
    # and performing kills, which seems over burdensome for no real gain.
    #
    while read base event file; do
        ${ECHO} "/dev/${file}"
        setResponseValue
    done <<<$(${INWAIT} -q /dev)
done

for askfile in $(${FIND} ${SPOOLDIR} -name "ask\.*" -type f); do
    processAskFile ${askfile}
done

while read base event file; do
    processAskFile "${SPOOLDIR}/${file}"
done <<<$(${INWAIT} -mq -e close_write -e moved_to ${SPOOLDIR})

#
# The above command will never exit, and continue to monitor for ask files indefinetly. That is because of the "-m" option
# on the inotifywait.
# @TODO Consider if a timeout for waiting would be good or leave as infinite wait
#

#---------------------------------------------------------------


