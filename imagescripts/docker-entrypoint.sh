#!/bin/bash

set -o errexit

certbot_binary="/usr/bin/certbot"

if [ "$EUID" -ne 0 ]; then
  mkdir -p /home/jobber/.config/letsencrypt/
  # config-dir remains /etc/letsencrypt
  echo "work-dir=/home/jobber/.letsencrypt" > /home/jobber/.config/letsencrypt/cli.ini
  echo "logs-dir=/home/jobber/log" >> /home/jobber/.config/letsencrypt/cli.ini
fi

letsencrypt_testcert=""

if [ "${LETSENCRYPT_TESTCERT}" = "true" ]; then
  letsencrypt_testcert="--test-cert"
fi

letsencrypt_email=""

if [ -n "${LETSENCRYPT_EMAIL}" ]; then
  letsencrypt_email=${LETSENCRYPT_EMAIL}
fi

letsencrypt_domains=""

for (( i = 1; ; i++ ))
do
  VAR_LETSENCRYPT_DOMAIN="LETSENCRYPT_DOMAIN$i"

  if [ ! -n "${!VAR_LETSENCRYPT_DOMAIN}" ]; then
    break
  fi

  letsencrypt_domains=$letsencrypt_domains" -d "${!VAR_LETSENCRYPT_DOMAIN}
done

letsencrypt_challenge_mode="--standalone"

if  [ "${LETSENCRYPT_WEBROOT_MODE}" = "true" ]; then
  letsencrypt_challenge_mode="--webroot --webroot-path=/var/www/letsencrypt"
fi

letsencrypt_account_id=""

if [ -n "${LETSENCRYPT_ACCOUNT_ID}" ]; then
  letsencrypt_account_id="--account "${LETSENCRYPT_ACCOUNT_ID}
fi

letsencrypt_debug=""

if  [ "${LETSENCRYPT_DEBUG}" = "true" ]; then
  letsencrypt_debug="--debug"
fi

if [ -n "${LETSENCRYPT_CERTIFICATES_UID}" ] && [ -n "${LETSENCRYPT_CERTIFICATES_GID}" ]; then
	cat > /etc/letsencrypt/renewal-hooks/deploy/change_permissions.sh <<_EOF_
#!/bin/sh
set -e
chown -R ${LETSENCRYPT_CERTIFICATES_UID}.${LETSENCRYPT_CERTIFICATES_GID} /etc/letsencrypt
chmod 400 /etc/letsencrypt/archive/*/privkey*.pem
_EOF_
	chmod a+x /etc/letsencrypt/renewal-hooks/deploy/change_permissions.sh
else
	if [ -f /etc/letsencrypt/renewal-hooks/deploy/change_permissions.sh ]; then
		rm -f /etc/letsencrypt/renewal-hooks/deploy/change_permissions.sh
	fi
fi

if [ "$1" = 'jobberd' ]; then
  export JOB_NAME1="letsencryt_renewal"

  export JOB_COMMAND1="bash -c \"${certbot_binary} --text --non-interactive --no-bootstrap --no-self-upgrade certonly ${letsencrypt_challenge_mode} ${letsencrypt_testcert} ${letsencrypt_debug} --renew-by-default ${letsencrypt_account_id} ${letsencrypt_domains} ${@:2}\""

  if [ -n "${LETSENCRYPT_JOB_TIME}" ]; then
    export JOB_TIME1=${LETSENCRYPT_JOB_TIME}
  else
    export JOB_TIME1="0 0 1 15 * *"
  fi

  if [ -n "${LETSENCRYPT_JOB_ON_ERROR}" ]; then
    export JOB_ON_ERROR1=${LETSENCRYPT_JOB_ON_ERROR}
  else
    export JOB_ON_ERROR1="Continue"
  fi

  # export JOB_NOTIFY_ERR1="false"
  # export JOB_NOTIFY_FAIL1="false"

  /opt/jobber/docker-entrypoint.sh "$@"
fi

case "$1" in

  install)
    bash -c "${certbot_binary} --text --non-interactive --no-bootstrap --no-self-upgrade certonly ${letsencrypt_challenge_mode} ${letsencrypt_testcert} ${letsencrypt_debug} --email ${letsencrypt_email} --agree-tos ${letsencrypt_domains} ${@:2}"
    ;;

  newcert)
    bash -c "${certbot_binary} --text --non-interactive --no-bootstrap --no-self-upgrade certonly ${letsencrypt_challenge_mode} ${letsencrypt_testcert} ${letsencrypt_debug} ${letsencrypt_account_id} ${letsencrypt_domains} ${@:2}"
    ;;

  renewal)
    bash -c "${certbot_binary} --text --non-interactive --no-bootstrap --no-self-upgrade certonly ${letsencrypt_challenge_mode} ${letsencrypt_testcert} ${letsencrypt_debug} --renew-by-default ${letsencrypt_account_id} ${letsencrypt_domains} ${@:2}"
    ;;

  *)
    exec "$@"

esac
