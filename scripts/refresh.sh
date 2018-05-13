#!/bin/sh

/usr/bin/ansible-playbook $(/bin/cat /etc/role).yml

exit ${?}
