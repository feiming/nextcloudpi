#! /bin/bash

set -e
source /usr/local/etc/library.sh

[[ "$1" != "--defaults" ]] || echo "INFO: Restoring template to default settings" >&2
[[ ! -f /.docker-image ]]  || echo "INFO: Docker installation detected" >&2

if [[ "$1" != "--defaults" ]]; then
  CUSTOMSSL_DOMAIN="$(
    # force defaults during initial build
    if ! [[ -f /.ncp-image ]]; then
      source "${BINDIR}/NETWORKING/customssl.sh"
      tmpl_CUSTOMSSL_DOMAIN
    fi
  )"
  CUSTOMSSL_SSLCertificateFile="$(
    # force defaults during initial build
    if ! [[ -f /.ncp-image ]]; then
      source "${BINDIR}/NETWORKING/customssl.sh"
      tmpl_CUSTOMSSL_SSLCertificateFile
    fi
  )"
  CUSTOMSSL_SSLCertificateKeyFile="$(
    # force defaults during initial build
    if ! [[ -f /.ncp-image ]]; then
      source "${BINDIR}/NETWORKING/customssl.sh"
      tmpl_CUSTOMSSL_SSLCertificateKeyFile
    fi
  )"
  CUSTOMSSL_SSLCertificateChainFile="$(
    # force defaults during initial build
    if ! [[ -f /.ncp-image ]]; then
      source "${BINDIR}/NETWORKING/customssl.sh"
      tmpl_CUSTOMSSL_SSLCertificateChainFile
    fi
  )"
  CUSTOMSSL_SSLCACertificatePath="$(
    # force defaults during initial build
    if ! [[ -f /.ncp-image ]]; then
      source "${BINDIR}/NETWORKING/customssl.sh"
      tmpl_CUSTOMSSL_SSLCACertificatePath
    fi
  )"
  CUSTOMSSL_SSLCACertificateFile="$(
    # force defaults during initial build
    if ! [[ -f /.ncp-image ]]; then
      source "${BINDIR}/NETWORKING/customssl.sh"
      tmpl_CUSTOMSSL_SSLCACertificateFile
    fi
  )"
  CUSTOMSSL_SSLCARevocationPath="$(
    # force defaults during initial build
    if ! [[ -f /.ncp-image ]]; then
      source "${BINDIR}/NETWORKING/customssl.sh"
      tmpl_CUSTOMSSL_SSLCARevocationPath
    fi
  )"
  CUSTOMSSL_SSLCARevocationFile="$(
    # force defaults during initial build
    if ! [[ -f /.ncp-image ]]; then
      source "${BINDIR}/NETWORKING/customssl.sh"
      tmpl_CUSTOMSSL_SSLCARevocationFile
    fi
  )"
fi

[[ -z "$CUSTOMSSL_DOMAIN" ]] || echo "INFO: Custom SSL domain is ${CUSTOMSSL_DOMAIN}" >&2

# skip during build
if ! [[ -f /.ncp-image ]] && [[ "$1" != "--defaults" ]] && [[ -f "${BINDIR}/SYSTEM/metrics.sh" ]]; then
  METRICS_IS_ENABLED="$(
  source "${BINDIR}/SYSTEM/metrics.sh"
  tmpl_metrics_enabled && echo yes || echo no
  )"
else
  METRICS_IS_ENABLED=no
fi

echo "INFO: Metrics enabled: ${METRICS_IS_ENABLED}" >&2

echo "### DO NOT EDIT! THIS FILE HAS BEEN AUTOMATICALLY GENERATED. CHANGES WILL BE OVERWRITTEN ###"
echo ""

cat <<EOF
<IfModule mod_ssl.c>
  <VirtualHost _default_:443>
    DocumentRoot /var/www/nextcloud
EOF

if [[ "$1" != "--defaults" ]] && [[ -n "$CUSTOMSSL_DOMAIN" ]]; then
  echo "    ServerName ${CUSTOMSSL_DOMAIN}"
else
  # Make sure the default snakeoil cert exists
  [ -f /etc/ssl/certs/ssl-cert-snakeoil.pem ] || make-ssl-cert generate-default-snakeoil --force-overwrite
  unset CUSTOMSSL_DOMAIN
fi

# NOTE: we fall back to self-signed snakeoil certs if we couldn't get a LE one
if [[ -d "${CUSTOMSSL_SSLCertificateFile}" ]] && [[ -d "${CUSTOMSSL_SSLCertificateKeyFile}" ]]
then
  cat <<EOF
    CustomLog /var/log/apache2/nc-access.log combined
    ErrorLog  /var/log/apache2/nc-error.log
    SSLEngine on
    SSLProxyEngine on
    SSLCertificateFile      ${CUSTOMSSL_SSLCertificateFile:-/etc/ssl/certs/ssl-cert-snakeoil.pem}
    SSLCertificateKeyFile ${CUSTOMSSL_SSLCertificateKeyFile:-/etc/ssl/private/ssl-cert-snakeoil.key}

    # For notify_push app in NC21
    ProxyPass /push/ws ws://127.0.0.1:7867/ws
    ProxyPass /push/ http://127.0.0.1:7867/
    ProxyPassReverse /push/ http://127.0.0.1:7867/
EOF
fi

[[ -d "${CUSTOMSSL_SSLCertificateChainFile}" ]] && echo "    SSLCertificateChainFile      ${CUSTOMSSL_SSLCertificateChainFile}"
[[ -d "${CUSTOMSSL_SSLCACertificatePath}" ]] && echo "    SSLCACertificatePath      ${CUSTOMSSL_SSLCACertificatePath}"
[[ -d "${CUSTOMSSL_SSLCACertificateFile}" ]] && echo "    SSLCACertificateFile      ${CUSTOMSSL_SSLCACertificateFile}"
[[ -d "${CUSTOMSSL_SSLCARevocationPath}" ]] && echo "    SSLCARevocationPath      ${CUSTOMSSL_SSLCARevocationPath}"
[[ -d "${CUSTOMSSL_SSLCARevocationFile}" ]] && echo "    SSLCARevocationFile      ${CUSTOMSSL_SSLCARevocationFile}"

[[ "$1" != "--defaults" ]] && [[ "$METRICS_IS_ENABLED" == yes ]]
then
  cat <<EOF

    <Location /metrics/system>
      ProxyPass http://localhost:9100/metrics

      Order deny,allow
      Allow from all
      AuthType Basic
      AuthName "Metrics"
      AuthUserFile /usr/local/etc/metrics.htpasswd
      <RequireAll>
        <RequireAny>
          Require host localhost
          Require valid-user
        </RequireAny>
      </RequireAll>

    </Location>
EOF
fi

cat <<EOF
  </VirtualHost>

  <Directory /var/www/nextcloud/>
    Options +FollowSymlinks
    AllowOverride All
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
    LimitRequestBody 0
    SSLRenegBufferSize 10486000
  </Directory>
  <IfModule mod_headers.c>
    Header always set Strict-Transport-Security "max-age=15768000; includeSubDomains"
  </IfModule>
</IfModule>
EOF

if ! [[ -f /.ncp-image ]]; then
  echo "Apache self check:" >> /var/log/ncp.log
  apache2ctl -t >> /var/log/ncp.log 2>&1
fi
