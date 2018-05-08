#!/bin/sh
#
# This script prepares a template for deployment
#
# TODO Mention that this script is used to wipe a VM before it is managed by Ansible, so it needs to be available as a single file with no dependencies for ease of use by downloading via a single wget command.

DIRNAME="/usr/bin/dirname"

PROGPATH="$(${DIRNAME} ${0})"

ZERO_FREE_SPACE="${PROGPATH}/zero-free-space.sh"

# TODO Mention references:
# References:
#    https://lonesysadmin.net/2013/03/26/preparing-linux-template-vms/
#    https://bashinglinux.wordpress.com/2013/03/23/creating-a-puppet-ready-image-centosfedora/
#    http://serverfault.com/questions/633683/prepping-a-virtual-appliance

#---
# Main
#---

##TODO...
#   # The ever-versatile libvirt tools include virt-sysprep, designed for performing these sorts of tasks. Even if you don’t use it, the list of things it does might be a useful reference: http://libguestfs.org/virt-sysprep.1.html

   #---
   # Step 0
   #---

   echo "Stopping the writing of new data"
   # otherwise, deployed VMs will have a log of the VM being shut down."

   /usr/sbin/service rsyslog stop
   # TODO (not available in Debian?) /usr/sbin/service auditd stop


   #---
   # Step 1
   #---

   echo "Removing old kernels"

   echo "(This section is currently unimplemented.)"
#   #/bin/package-cleanup --oldkernels --count=1
#
#    echo "Getting all packages up-to-date"
#    # (skip - already being done by Ansible)
#
#   #yum -y update


   #---
   # Step 2
   #---

   echo "Cleaning out the package manager cache"
   # Yum keeps a cache in /var/cache/yum that can grow quite large. Wipe this
   # to keep the template as small as possible.

   echo "(This section is currently unimplemented.)"
   #/usr/bin/yum clean all
   apt-get clean


   #---
   # Step 3
   #---

   echo "Forcing logs to rotate and remove old unneeded logs."

   /usr/sbin/logrotate --force /etc/logrotate.conf
   /bin/rm -f /var/log/*-???????? /var/log/*.gz
   /bin/rm -f /var/log/dmesg.old
   #/bin/rm -f /var/log/anaconda


   #---
   # Step 4
   #---

   echo "Truncating the audit logs and other logs"

   #/bin/cat /dev/null > /var/log/audit/audit.log
   /bin/cat /dev/null > /var/log/wtmp
   /bin/cat /dev/null > /var/log/lastlog
   #/bin/cat /dev/null > /var/log/grubby

#   # Clean up the VMware provisioning log if it exists (/var/log/vmware-imc/*)
#
#   # Get rid of the use of UUID in fstab and any NIC configuration so the new
#   # VM can find them when the UUIDs are regenerated
#
#   #sed -i -e 's/UUID=[0-9a-f-]*\s/\/dev\/sda1\t/' /etc/fstab ;
#   #sed -i -e '/^UUID=[0-9a-f-]*.*/d' /etc/sysconfig/network-scripts/ifcfg-eno* ;
#   #sed -i -e '/^UUID=[0-9A-F-]*.*/d' /etc/sysconfig/network-scripts/ifcfg-eno* ;


   #---
   # Step 6
   #---

   echo "Removing the traces of the template MAC address and UUIDs"

   echo "(This section is currently unimplemented.)"
   #/bin/sed -i ‘/^(HWADDR|UUID)=/d’ /etc/sysconfig/network-scripts/ifcfg-eth0


   #---
   # Step 5
   #---

   echo "Removing the udev persistent device rules"

   echo "(This section is currently unimplemented.)"
   #/bin/rm -f /etc/udev/rules.d/70*
   #find /etc/udev/rules.d/ -iname '70*net*' |xargs unlink ;

   echo "Letting the NTP daemon know to expect a big jump in time"

   echo "(This section is currently unimplemented.)"
   #[[ -a /etc/ntp.conf ]] && \
   #   [[ "$(head -1 /etc/ntp.conf)" == "tinker panic 0" ]] || \
   #   sed -i -e '1itinker panic 0\n' /etc/ntp.conf ;

   echo "Cleaning up /etc/hosts, /etc/resolv.conf, /etc/sysconfig/network of any customized values"

   echo "(This section is currently unimplemented.)"

   echo "Removing unneeded passwords in the /etc/shadow file"

   echo "(This section is currently unimplemented.)"

   echo "In addition to removing the ifcfg files, removing any route files (/etc/sysconfig/network-scripts/route-eno*)"

   echo "(This section is currently unimplemented.)"


   #---
   # Step 7
   #---

   echo "Cleaning out /tmp"

   # This can be bad if symlinks are maliciously placed in /tmp; since this is
   # a fresh install, not worried about it.

   /bin/rm -Rf /tmp/*
   /bin/rm -Rf /var/tmp/*


   #---
   # Step 11
   #---

   ${ZERO_FREE_SPACE}

#   # After finishing these last steps, use a trick depending on the kind of image being created:
#   #    For VMware, use vMotion to re-thin the VM; or clone the image into a new VM, with the destination set as thin provisioning.. When doing this, all the contiguous zeros will be converted into nothing.
#   #    For openstack/kvm images, you might want to convert them using qemu-img to qcow2 (if your provider supports it), and enable the compress flag: qemu-img convert -f raw -O qcow2 -c source.raw destination.qcow2
#
#   # Instruct the OS to redo the initial setup and put back that new machine
#   # smell
#
#   #yum history new
#   #yum reinstall basesystem -y
#   #sys-unconfig


   #---
   # Step 8
   #---

   echo "Removing SSH host keys"

   /bin/rm -f /etc/ssh/ssh_host_*key*


   #---
   # Step 9
   #---

   echo "Removing the root and other users' shell history"

   # This applies only if .bash_history is not a symlink.

   for d in /root /home/*; do
      [ \! -L ${d}/.bash_history ] && /bin/rm -f ${d}/.bash_history
   done
   unset HISTFILE


   #---
   # Step 10
   #---

   echo "Removing the root user's SSH history and other cruft"

#   /bin/rm -Rf ~root/.ssh/
#   #/bin/rm -f ~root/anaconda-ks.cfg
#
#   TODO might consider not doing this and just removing ~root/.ssh/known_hosts
#   if we have SSH keys we want to keep around.
#
#   TODO same for vagrant/ansible user???
#
#   # TODO if root password is set, then consider setting its age to 0 - this
#   # forces the owner to change the default password after deployment
#   chage -d 0 root
#
#   # TODO any files to remove from under /root?
#
#   # TODO set machine hostname to localhost in case customization is not done later
#   #hostname localhost
#   #sed -i -e "s/^HOSTNAME=.*/HOSTNAME=localhost" /etc/sysconfig/network
#
#   # TODO add your key to authorized_keys?
#   #mkdir -p /root/.ssh; echo "YOUR_SSH_PUBLIC_KEY" &gt; /root/.ssh/authorized_keys

# TODO???
#################################
##
## Get rid of the signs I was 
## tinkering with this
##
#################################
#[[ -a /etc/issue-original,v ]] && unlink /etc/issue-original,v ;
#[[ -a /etc/issue,v ]] && unlink /etc/issue,v ;
#ci -u /etc/issue ;


exit 0
