#!/bin/bash

set -e

TEXTSTART="\n\e[0;33m####"
TEXTEND="\e[0m"

pidfile="/tmp/deploy"

# lock it
exec 200>$pidfile
flock -n 200 || ( echo -e "\e[0;31mDeploy script is already running. Aborting . .  ${TEXTEND}" && exit 1 )
pid=$$
echo $pid 1>&200


populate_env_vars()
{
    #Populate /etc/environment if it was modified
    for line in $( cat /etc/environment ) ; do
        if [ "$line" != "" ]; then
            export $line || true
        fi
    done
}

populate_env_vars

#ENV=prod

if [ -z "${APP_ENV}" ]
then
        echo -e "\e[0;31mAPP_ENV is not set. Aborting . .  ${TEXTEND}"
        exit 1
fi

if [ ${APP_ENV} = "dev" ]
then
        echo -e "\e[0;31mScript should not run from dev. Aborting . .  ${TEXTEND}"
        exit 1
fi


BUILD=""
if [ "$1" != "" ]; then
    BUILD="$1"
fi

WWW_DIR_NAME=/var/www
APPLICATION_DIR_NAME=application
TIMESTAMP=$(date '+%Y_%m_%d__%H_%M_%S')
APPLICATION_NEW_DIR_NAME="${APPLICATION_DIR_NAME}_${TIMESTAMP}"
WEBSERVER_CONFIG_PATH="${WWW_DIR_NAME}/${APPLICATION_NEW_DIR_NAME}/provision/ansible/roles/webserver/files/${APP_ENV}"
SITE_DIR="${WWW_DIR_NAME}/${APPLICATION_NEW_DIR_NAME}/sites/example.com"

HTTPDUSER=`ps aux | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1`
CURRENTUSER=`logname`
LATEST_BUILD_VAR_FILE="/tmp/lastest_myproject_${APP_ENV}_build"
LATEST_BUILD_FILE=/tmp/myproject.tar.bz2



if [ -z "$BUILD" ]
then
        aws s3 cp s3://myproject.artifacts/builds/"${APP_ENV}"/lastest_myproject_build $LATEST_BUILD_VAR_FILE
else
        echo "myproject.$BUILD.tar.bz2" > $LATEST_BUILD_VAR_FILE
fi

BUILD=`cat $LATEST_BUILD_VAR_FILE`

echo -e "${TEXTSTART} Starting Deploy for build $BUILD on ${APP_ENV} .. ${TEXTEND}"

aws s3 cp s3://myproject.artifacts/builds/"${APP_ENV}"/"$BUILD" "${LATEST_BUILD_FILE}"

echo -e "${TEXTSTART} Extracting deploy package ${TEXTEND}"

mkdir -p "${WWW_DIR_NAME}/${APPLICATION_NEW_DIR_NAME}/"
cd "${WWW_DIR_NAME}"
tar jxf $LATEST_BUILD_FILE --directory $APPLICATION_NEW_DIR_NAME

echo -e "${TEXTSTART} Running service discovery ${TEXTEND}"
"${WWW_DIR_NAME}/${APPLICATION_NEW_DIR_NAME}/provision/tools/service_discovery.sh"
populate_env_vars

echo -e "${TEXTSTART} Rebuilding cache ${TEXTEND}"
php "${SITE_DIR}"/bin/console cache:clear --env="${APP_ENV}" --no-debug

echo -e "${TEXTSTART} Configuring Permissions ${TEXTEND}"
chown -R "$CURRENTUSER":"$HTTPDUSER" "${WWW_DIR_NAME}/${APPLICATION_NEW_DIR_NAME}"
chmod -R 0755 "${WWW_DIR_NAME}/${APPLICATION_NEW_DIR_NAME}"
setfacl -dR -m u:"$HTTPDUSER":rwX -m u:"$CURRENTUSER":rwX "${SITE_DIR}/var"


rm -rf $APPLICATION_DIR_NAME
ln -s "${WWW_DIR_NAME}/${APPLICATION_NEW_DIR_NAME}"  "${WWW_DIR_NAME}/${APPLICATION_DIR_NAME}"


echo -e "${TEXTSTART} Coping config files ${TEXTEND}"

/bin/cp "${WEBSERVER_CONFIG_PATH}"/config/myproject/nginx/nginx.conf /etc/nginx/nginx.conf
/bin/cp "${WEBSERVER_CONFIG_PATH}"/config/myproject/nginx/fastcgi_params /etc/nginx/fastcgi_params
if [ ! -f /etc/nginx/whitelist_ips ]; then
    echo "" > /etc/nginx/whitelist_ips
fi

/bin/cp "${WEBSERVER_CONFIG_PATH}"/config/php/cli/php.ini /etc/php/7.2/cli/php.ini
/bin/cp "${WEBSERVER_CONFIG_PATH}"/config/php/fpm/php.ini /etc/php/7.2/fpm/php.ini
/bin/cp "${WEBSERVER_CONFIG_PATH}"/config/php/fpm/php-fpm.conf /etc/php/7.2/fpm/php-fpm.conf
/bin/cp "${WEBSERVER_CONFIG_PATH}"/config/php/opcache.ini /etc/php/7.2/mods-available/opcache.ini




php "${WWW_DIR_NAME}/application/provision/tools/replace_env_vars.php"



echo -e "${TEXTSTART} Restarting web services ${TEXTEND}"

sudo /etc/init.d/nginx reload
sudo /etc/init.d/php7.2-fpm reload

echo -e "${TEXTSTART} Cleaning up ${TEXTEND}"
find . -maxdepth 1 ! -name $APPLICATION_DIR_NAME ! -name . ! -name $APPLICATION_NEW_DIR_NAME -type d  -print0 | xargs -0 rm -rf

php "${SITE_DIR}"/bin/console myproject:sitemap:create
chown -R "$CURRENTUSER":"$HTTPDUSER" "${SITE_DIR}/web"

echo -e "\n\n\n\n\e[0;32m#######################\n#### Deploy Is Successful\n####################### ${TEXTEND}"


