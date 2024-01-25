#!/usr/bin/env bash
set -e

source /usr/local/etc/library.sh

install_template apache2/ncp.conf.sh /etc/apache2/sites-available/ncp.conf --defaults
bash -c "sleep 2 && service apache2 reload" &>/dev/null &