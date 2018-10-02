#!/bin/bash

set -e

pidfile="/tmp/service_discovery"

# lock it
exec 200>$pidfile
flock -n 200 || ( echo -e "Service discovery script is already running. Aborting . .  " && exit 1 )
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


SOLR_IP=$( aws ec2 describe-instances --filters "Name=tag:Name,Values=solr1__${ENV}"  'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text )
DATABASE_IP=$( aws ec2 describe-instances --filters "Name=tag:Name,Values=postgres1_${ENV}"  'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text )
REDIS_IP=$( aws ec2 describe-instances --filters "Name=tag:Name,Values=redis1_${ENV}"  'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text )

if [ "${DATABASE_IP}" != "" ] && [ "${DATABASE_HOST}" != "${DATABASE_IP}" ]
then
        echo "Found new RDS Endpoint: ${DATABASE_IP}"
        sudo sed -i "s%DATABASE_HOST=.*%DATABASE_HOST=${DATABASE_IP}%g" /etc/environment
        DATABASE_HOST="${SOLR_IP}"
fi

if [ "${REDIS_IP}" != "" ] && [ "${REDIS_HOST}" != "${REDIS_IP}" ]
then
        echo "Found new Redis IP: ${REDIS_IP}"
        sudo sed -i "s%REDIS_HOST=.*%REDIS_HOST=${REDIS_IP}%g" /etc/environment
        REDIS_HOST="${REDIS_IP}"
fi

if [ "${SOLR_IP}" != "" ] && [ "${SOLR_HOST}" != "${SOLR_IP}" ]
then
        echo "Found new Solr IP: ${SOLR_IP}"
        sudo sed -i "s%SOLR_HOST=.*%SOLR_HOST=${SOLR_IP}%g" /etc/environment
        SOLR_HOST="${SOLR_IP}"
fi

echo $DATABASE_HOST
echo $REDIS_HOST
echo $SOLR_HOST

#php /var/www/application/provision/tools/replace_env_vars.php



