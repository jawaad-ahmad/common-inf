#!/bin/sh

ECHO=/bin/echo
MKDIR=/bin/mkdir
VBOXMANAGE=/usr/bin/vboxmanage

EXIT_SUCCESS=0
EXIT_INSUFFICIENT_ARGUMENTS=1
EXIT_DIRECTORY_ALREADY_EXISTS=2
EXIT_ERROR_OCCURRED=3


OS_TYPE=Debian_64
VMROOT="${HOME}/VirtualBox VMs"


#--------
usage() {
#--------

   cat << END_OF_FILE

NAME

   create-vbox-vm.sh

SYNOPSIS

   create-vbox-vm.sh vmname mac_addr ram_mb disksize_mb install_iso_path

DESCRIPTION

   Creates a VirtualBox virtual machine with standardized settings.

ARGUMENTS

   Specify "auto" for the mac_addr for it to be auto-generated. If manually
   providing it, make sure it is run together e.g. 123456789ABC.

END_OF_FILE

}


#------
log() {
#------
   ${ECHO} "${*}" 1>&2
}


#-------
logT() {
#-------
   log '[TRACE]' "${*}"
}


#-------
logD() {
#-------
   log '[DEBUG]' "${*}"
}


#-------
logI() {
#-------
   log '[ INFO]' "${*}"
}


#-------
logW() {
#-------
   log '[ WARN]' "${*}"
}


#-------
logE() {
#-------
   log '[ERROR]' "${*}"
}


#---
# Main
#---

   if [ \( "${1}" = '-h' \) -o \
        \( "${1}" = '-?' \) -o \
        \( "${1}" = '/h' \) -o \
        \( "${1}" = '/?' \) -o \
        \( "${1}" = '-help' \) -o \
        \( "${1}" = '--help' \) ]; then
      usage
      exit ${EXIT_SUCCESS}
   fi

   if [ ${#} -ne 5 ]; then
      logE 'Insufficient arguments'
      usage 1>&2
      exit ${EXIT_INSUFFICIENT_ARGUMENTS}
   fi

   vmname=${1}
   mac_addr=${2}
   ram_mb=${3}
   disksize_mb=${4}
   install_iso_path=${5}

   vmhome="${VMROOT}/${vmname}"

   if [ -d "${vmhome}" ]; then
      logE "Directory already exists: ${vmhome}"
      exit ${EXIT_DIRECTORY_ALREADY_EXISTS}
   fi

   ${MKDIR} --parents "${vmhome}"

   if [ ${?} -gt 0 ]; then
      logE "Error creating directory: ${vmhome}"
      exit ${EXIT_ERROR_OCCURRED}
   fi


   ${VBOXMANAGE} createhd --filename "${vmhome}/${vmname}.vdi" \
                          --size ${disksize_mb}

   if [ ${?} -gt 0 ]; then
      logE "Error creating virtual hard drive"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} createvm --name ${vmname} \
                          --ostype ${OS_TYPE} \
                          --basefolder "${VMROOT}"

   if [ ${?} -gt 0 ]; then
      logE "Error creating VM"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} registervm "${vmhome}/${vmname}.vbox"

   if [ ${?} -gt 0 ]; then
      logE "Error registering VM"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   storage_name='SATA'
   ${VBOXMANAGE} storagectl ${vmname} \
                            --name "${storage_name}" \
                            --add sata \
                            --controller IntelAHCI

   if [ ${?} -gt 0 ]; then
      logE "Error creating ${storage_name} controller"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} storageattach ${vmname} \
                               --storagectl "${storage_name}" \
                               --port 0 \
                               --device 0 \
                               --type hdd \
                               --medium "${vmhome}/${vmname}.vdi"

   if [ ${?} -gt 0 ]; then
      logE "Error attaching ${storage_name} storage"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   dvd_name='IDE'
   ${VBOXMANAGE} storagectl ${vmname} \
                            --name "${dvd_name}" \
                            --add ide

   if [ ${?} -gt 0 ]; then
      logE "Error creating ${storage_name} controller"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} storageattach ${vmname} \
                               --storagectl "${dvd_name}" \
                               --port 0 \
                               --device 0 \
                               --type dvddrive \
                               --medium ${install_iso_path}

   if [ ${?} -gt 0 ]; then
      logE "Error attaching ${storage_name} storage"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} modifyvm ${vmname} --ioapic on

   if [ ${?} -gt 0 ]; then
      logE "Error modifying VM APIC"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} modifyvm ${vmname} --boot1 dvd \
                                    --boot2 disk \
                                    --boot3 none \
                                    --boot4 none

   if [ ${?} -gt 0 ]; then
      logE "Error modifying VM boot order"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} modifyvm ${vmname} --memory ${ram_mb} \
                                    --vram 128

   if [ ${?} -gt 0 ]; then
      logE "Error modifying VM RAM"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} modifyvm ${vmname} --nic1 bridged \
                                    --bridgeadapter1 wlan0

   if [ ${?} -gt 0 ]; then
      logE "Error modifying VM NIC 1"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} modifyvm ${vmname} --macaddress1 ${mac_addr}

   if [ ${?} -gt 0 ]; then
      logE "Error modifying VM NIC 1 MAC address"
      exit ${EXIT_ERROR_OCCURRED}
   fi

   ${VBOXMANAGE} modifyvm ${vmname} --clipboard bidirectional

   if [ ${?} -gt 0 ]; then
      logE "Error modifying VM clipboard"
      exit ${EXIT_ERROR_OCCURRED}
   fi

exit ${EXIT_SUCCESS}
