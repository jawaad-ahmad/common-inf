#!/bin/sh

AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
BC=/usr/bin/bc
DD=/bin/dd
DF=/bin/df
EXPR=/usr/bin/expr
GREP=/bin/grep
RM=/bin/rm
SLEEP=/bin/sleep
SYNC=/bin/sync

PROG="$(${BASENAME} ${0})"

PIN="13579"

# This script fills up this much of each filesystem; for a template, we can up
# this to 100%.
#THRESHOLD_PERCENT=98
THRESHOLD_PERCENT=100


#---
usage() {
#---

   cat << END_OF_FILE
NAME

   ${PROG} - Zeroes the free space on all ext partitions

SYNOPISYS

   ${PROG} [ options ] ${PIN}

DESCRIPTION

   Zeroes the given space on all ext partitions found in /etc/mtab. Only runs
   if "${PIN}" is provided on the command line exactly.

   -n Dry run

END_OF_FILE

}


#---
# Main
#---

   dryRun=0

   if [ "${1}" = "-n" ]; then
      dryRun=1
      echo "Recognized dry run option"
      shift
   fi

   # Prevent this script from accidentally running if not run intentionally
   if [ "${1}" = "${PIN}" ]; then
      echo "PIN received. Continuing to process (dryRun=${dryRun})"

#   # Zero out all free space - zero out every single filesystem plus the extra unused VG space, so you can better compress the image. We have a script that goes into every filesystem, dd's a bunch of zeroes until it fills up, then removes the file. Same for a VG with empty space, create an LV that fills 100%FREE, zero it out and remove it.
#   # Note this effectively un-thins the disks, so make sure enough free space is available before running.

# TODO update recommendations:
#    o  there are a few basic errors in the disk zeroing script.
#       o  you want $4 (Available) not $3 (Used) for determining how much to zero.
#          o  Negative on the $4 versus $3 — the way the df output happens the column says “Used” but it’s the available blocks as a number.
#       o  PREFIX is not set.
#          o  I did correct the PREFIX problem, my cut & paste omitted the block that figured out which RHEL version we’re running on and adapted.
#       o  the case where there is no free space in LVM just generates an error.
#    o  change to use mktemp instead of always using the file "zf"; just to
#       make sure you don't overwrite any files that might ahve been created
#       called zf
#       o  Interestingly enough it used to use mktemp but with a static file name it was easier to have our monitoring system detect the file and not alarm on the transient disk full condition, until that file was more than 30 minutes since last access. A better way might be to write the name of the file to a temp file it tests for, but it was easy enough to do it this other way.
#    o  you shouldn't need to call sync or sleep before removing the LV (although it doesn’t hurt). This is because sync flushes the file system buffers, but because you’re writing directly to a block device and not the file system, it doesn’t do anything. But you probably should add a sync after you do the DD to the file system, as it’s possible (although unlikely with a sufficiently large file) that the output to the ‘zf’ file won’t be make it to the block device! Alternatively, you can use the dd “conf=fdatasync” argument to imply this.
#    o  set the DD block size explicitly – the default is 512 bytes – and this may take a long time to write if you have a large block device or file system.

## Determine the version of RHEL
#cond=$(${GREP} -i Taroon /etc/redhat-release)
#if [ "$cond" = "" ]; then
#   export PREFIX="/usr/sbin"
#else
#   export PREFIX="/sbin"
#fi

      fs=`${GREP} 'ext[234]' /etc/mtab | ${AWK} -F" " '{ print $2 }'`

      for i in $fs; do
         number=$(${DF} -B 512 $i | \
                     ${AWK} -F" " '{ print $3 }' | \
                     ${GREP} -v Used)
         count=$(echo "scale=0; ${number} * ${THRESHOLD_PERCENT} / 100" | ${BC})

         echo "Processing filesystem ${i} (${number} used, ${count} count)"

         outfileBase="${i}/zf"
         count=0

         while [ 1 ]; do
            outFile="${outfileBase}${count}"
            echo "Determining file name for writing. Checking ${outFile}..."

            if [ \! -e "${outFile}" ]; then
               echo "Found no file ${outFile}"
               break
            fi

            count=$(${EXPR} ${count} + 1)
         done

         if [ ${dryRun} -eq 0 ]; then
            echo "Writing ${count} blocks to ${outFile}"
#            ${DD} count=${count} if=/dev/zero of=${outFile}
#            ${SYNC}
         else
            echo "Would write ${count} blocks to ${outFile}"
         fi

#         ${SLEEP} 15

         if [ ${dryRun} -eq 0 ]; then
            echo "Removing ${outFile}"
#            ${RM} -f ${outFile}
         else
            echo "Would remove ${outFile}"
         fi
      done

#      vg=$($PREFIX/vgdisplay | ${GREP} Name | ${AWK} -F" " '{ print $3 }')
#
#      for i in $vg; do
#         echo Processing filesystem ${i}
#
#         $PREFIX/lvcreate -l `$PREFIX/vgdisplay ${i} | ${GREP} Free | ${AWK} -F" " '{ print $5 }'` -n zero ${i}
#         if [ -a /dev/${i}/zero ]; then
#            cat /dev/zero > /dev/${i}/zero
#            ${SYNC}
#            ${SLEEP} 15
#            $PREFIX/lvremove -f /dev/${i}/zero
#         fi
#      done

   else

       echo "${PROG}: Insufficient arguments" 1>&2
       usage

   fi
exit 0
