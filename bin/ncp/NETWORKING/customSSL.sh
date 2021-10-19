#!/bin/bash

# Custom SSL on NextCloudPi
#
# Copyleft 2021 by Fabian Chong <fabian _a_t_ zyrax _d_o_t_ net>
# GPL licensed (see end of file) * Use at your own risk!
#


ncdir=/var/www/nextcloud
nc_vhostcfg=/etc/apache2/sites-available/nextcloud.conf
vhostcfg2=/etc/apache2/sites-available/ncp.conf

is_active()
{
  [[ "${ACTIVE}" == "yes" ]]
}

tmpl_CUSTOMSSL_DOMAIN() {
  (
  . /usr/local/etc/library.sh
  if is_active_app customssl; then
    find_app_param customssl DOMAIN
  fi
  )
}

tmpl_CUSTOMSSL_SSLCertificateFile() {
  (
  . /usr/local/etc/library.sh
  if is_active_app customssl; then
    find_app_param customssl SSLCertificateFile
  fi
  )
}

tmpl_CUSTOMSSL_SSLCertificateKeyFile() {
  (
  . /usr/local/etc/library.sh
  if is_active_app customssl; then
    find_app_param customssl SSLCertificateKeyFile
  fi
  )
}

tmpl_CUSTOMSSL_SSLCertificateChainFile() {
  (
  . /usr/local/etc/library.sh
  if is_active_app customssl; then
    find_app_param customssl SSLCertificateChainFile
  fi
  )
}

tmpl_CUSTOMSSL_SSLCACertificateFile() {
  (
  . /usr/local/etc/library.sh
  if is_active_app customssl; then
    find_app_param customssl SSLCACertificateFile
  fi
  )
}

tmpl_CUSTOMSSL_SSLCACertificatePath() {
  (
  . /usr/local/etc/library.sh
  if is_active_app customssl; then
    find_app_param customssl SSLCACertificatePath
  fi
  )
}

tmpl_CUSTOMSSL_SSLCARevocationPath() {
  (
  . /usr/local/etc/library.sh
  if is_active_app customssl; then
    find_app_param customssl SSLCARevocationPath
  fi
  )
}

CUSTOMSSL_SSLCARevocationFile() {
  (
  . /usr/local/etc/library.sh
  if is_active_app customssl; then
    find_app_param customssl SSLCARevocationFile
  fi
  )
}

configure()
{
  [[ "${ACTIVE}" != "yes" ]] && {
    install_template customssl.conf.sh "${nc_vhostcfg}"
    echo "Custom SSL certificates disabled. Using self-signed certificates instead."
    exit 0
  }
  local DOMAIN_LOWERCASE="${DOMAIN,,}"

  [[ "$DOMAIN" == "" ]] && { echo "empty domain"; return 1; }

  local IFS_BK="$IFS"

  # Do it
  [[ "${DOMAIN}" != "" ]] && {
    # Configure Apache
    install_template customessl.conf.sh "${nc_vhostcfg}"
    sed -i "s|SSLCertificateFile.*|SSLCertificateFile $SSLCertificateFile|" $vhostcfg2
    sed -i "s|SSLCertificateKeyFile.*|SSLCertificateKeyFile $SSLCertificateKeyFile|" $vhostcfg2

    # Configure Nextcloud
    ncc config:system:set trusted_domains "0" --value="$DOMAIN"
    set-nc-domain "$DOMAIN"

    apachectl -k graceful
    rm -rf $ncdir/.well-known

    # Update configuration
    return 0
  }
  rm -rf $ncdir/.well-known
  return 1
}


# License
#
# This script is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this script; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA  02111-1307  USA

