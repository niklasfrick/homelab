#!/usr/bin/env bash

<<COMMENT

COMMENT

# set -o nounset
# set -o errexit
# set -o xtrace
# set -o pipefail
# set -o verbose
# set -o noexec

# shopt -s extglob

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

PLEX_LATEST=$(curl -i --silent 'https://plex.tv/downloads/latest/5?channel=16&build=linux-x86_64&distro=redhat' | grep 'Location:' | sed 's/Location://g' | sed 's/\r//g')
PLEX_LATEST_FILE=$(basename ${PLEX_LATEST})
PLEX_INSTALLED_VERSION=$(rpm -qa | grep plexmediaserver)
PLEX_FILE_LOCATION='/tmp/latest_plex.rpm'


if [ ${PLEX_INSTALLED_VERSION}.rpm != ${PLEX_LATEST_FILE} ]; then
  echo 'Older version detected, upgrading now.'
  echo ''
  PLEX_FILE=$(wget --output-document=${PLEX_FILE_LOCATION} ${PLEX_LATEST}) && dnf install --assumeyes ${PLEX_FILE_LOCATION}
  systemctl restart plexmediaserver
else
  echo 'Latest version already installed!'
  echo ''
  exit 0
fi

exit 0
