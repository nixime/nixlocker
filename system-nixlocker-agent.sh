#!/usr/bin/sh
#
# Copyright 2019 NIXIME@GITHUB
#

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define our constants, paths and commands that will be needed
SPOOLDIR=/run/systemd/ask-password
DEVLBL=
PASSFILE=nixlocker.key
RAWDEV=
UUID=

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
RESPONSE=
#---------------------------------------------------------------

#
# getResponseValue
#	Get the passphrase from the DEVICE for responding to requests from cryptsetup
#
function setResponseValue()
{
    RESPONSE=""

    # Get the password response from the keyfile on the labeled device
    RAWDEV=$(${BLKID} --label ${DEVLBL})
    echo "RAWDEV: ${RAWDEV}"
    [ -z ${RAWDEV} ] && RAWDEV=$(${BLKID} --uuid ${UUID})
    echo "RAWDEV: ${RAWDEV}"
    [ -z ${RAWDEV} ] && echo "Device not found" && return -1

    tmpd=$(${MKTMP} -d)
    [ ! -d ${tmpd} ] && return -1

    dev=$(${READLINK} -f ${RAWDEV})
    [ $? -ne 0 ] && return -1

    ${GREP} -q "${dev}" /proc/mounts
    if [ $? -eq 0 ]; then
        mpt=$(${GREP} ${dev} /proc/mounts | ${AWK} '{print $2}')
        RESPONSE=$(${CAT} ${mpt}/${PASSFILE})
    else
        ${MOUNT} -o ro ${dev} ${tmpd} >&2
        [ $? -ne 0 ] && return -1
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
function processAskFile()
{
    askfile=$1
    
    echo "ASKFILE: ${askfile}"
    # If something beat us to the response
    [ ! -e ${askfile} ] && return 1

    # Get the socket for sending the response
    sockfn=$(${GREP} ^Socket= ${askfile} | ${CUT} -d= -f2)
    [ $? -ne 0 -o "x${sockfn}" == "x" ] && return 1

    # One last check before sending the response, then send the response to the socket
    echo "SEND Response: ${askfile}"
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
else
    ${ECHO} "Missing necessary tools" >&2
    exit 99
fi
#---------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Read configuration file for details on decryption logic
[ ! -f /etc/nixime/nixlocker.cfg ] && echo "Unable to find config" && exit 91
for kv in $(${CAT} /etc/nixime/nixlocker.cfg); do
    ${ECHO} "Config: ${kv}"
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
        ;;
    esac
done
#---------------------------------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo "Wait till RESPONSE is available"
while [ -z ${RESPONSE} ]; do
    setResponseValue
    ${SLEEP} 1s
done

echo "Start processing ${SPOOLDIR} ask files..."
echo "+Checking for existing ASK files"
for askfile in $(${FIND} ${SPOOLDIR} -name "ask\.*" -type f); do
    processAskFile ${askfile}
done

echo "+Start waiting for notifications"
${INWAIT} -mq -e close_write -e moved_to ${SPOOLDIR} | while read base event file 
do
    processAskFile "${SPOOLDIR}/${file}"
done

echo "End" >&2
#---------------------------------------------------------------


