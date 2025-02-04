#!/bin/bash

# Apache configs
if [ "${ALM_ENABLE_SSL}" = "y" ]; then REPLACE_SSL="#SSL# *"; fi
if [ "${ALM_ENABLE_JENKINS}" = "y" -o "${JENKINS_INSTALLED}" = "y" ]; then
  REPLACE_JENKINS="#JENKINS# *"
fi
if [ "${ALM_SUBDIR}" = "" ]; then
  DOCMENT_ROOT="/opt/alminium/public"
else
  DOCMENT_ROOT="/var/www/html\nRailsBaseURI ${ALM_SUBDIR}"
fi
OS_TYPE=${OS}
if [ "`echo ${OS_TYPE} | grep ubuntu`" != "" ]; then OS_TYPE=debian
elif [ "`echo ${OS_TYPE} | grep rhel`" != "" ]; then OS_TYPE=rhel; fi

for FILE in $(ls etc/ | grep '.conf$')
do
  sed -e "s|#HOSTNAME#|${ALM_HOSTNAME}|" \
      -e "s|#${OS_TYPE}# *||" \
      -e "s|${REPLACE_SSL}||" \
      -e "s|${REPLACE_JENKINS}||" \
      -e "s|#SUBDIR#|${ALM_SUBDIR}|" \
      -e "s|#DOCUMENTROOT#|${DOCMENT_ROOT}|" \
      -e "s|#DB_HOST#|${ALM_DB_HOST}|" \
      "etc/${FILE}" > "${ALM_ETC_DIR}/${FILE}"
done

# log rotate
cp ${ALM_ETC_DIR}/alminium-logrotate /etc/logrotate.d/alminium

# apaches's conf
## passenger
if [ "${ALM_PASSSENGER_PACKAGE_AVAILABLE}" = "1" ]; then
  # installed from os's packaged. so configure with passenger-config
  passenger-config validate-install --auto --validate-apache2
else
  # installed from gem. so configure with bundle exec i
  # passenger-install-apache2-module
  pushd ${ALM_INSTALL_DIR}
  ${BUNDLER} exec passenger-install-apache2-module --snippet > ${ALM_ETC_DIR}/passenger.conf
  if [ "`echo ${OS} | grep rhel`" != "" ]; then
    ${BUNDLER} exec passenger-install-apache2-module --auto
  else
    ${BUNDLER} exec passenger-install-apache2-module --auto --apxs2-path='/usr/bin/apxs'
  fi
  popd
  ln -sf "${ALM_ETC_DIR}/passenger.conf" "${APACHE_CONF_DIR}/"
  rm "${APACHE_CONF_DIR}//passenger.load" 2>/dev/null
fi
## alminium
ln -sf "${ALM_ETC_DIR}/alminium.conf" "${APACHE_SITE_CONF_DIR}/" 

# OS depend installing
source inst-script/${OS}/post-install.sh

# restart service
source inst-script/service-restart.sh

# vim: set ts=2 sw=2 et:
