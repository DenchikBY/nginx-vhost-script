#!/bin/bash

if [ "$(whoami)" != 'root' ]; then
	echo "You have no permission to run $0 as non-root user. Use sudo"
	exit 1;
fi

domain=$1
rootPath=$2
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
serverRoot='/srv/'
domainRegex="^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"

while [ "$domain" = "" ]
do
	echo "Please provide domain:"
	read domain
done

until [[ $domain =~ $domainRegex ]]
do
	echo "Enter valid domain:"
	read domain
done

if [ -e $sitesAvailable$domain ]; then
	echo "This domain already exists.\nPlease Try Another one"
	exit;
fi


if [ "$rootPath" = "" ]; then
	rootPath=$serverRoot$domain
fi

if ! [ -d $rootPath ]; then
	mkdir $rootPath
	chmod 777 $rootPath
	if ! echo "Hello, world!" > $rootPath/index.php
	then
		echo "ERROR: Not able to write in file $rootPath/index.php. Please check permissions."
		exit;
	else
		echo "Added content to $rootPath/index.php"
	fi
fi

if ! [ -d $sitesEnable ]; then
	mkdir $sitesEnable
	chmod 777 $sitesEnable
fi

if ! [ -d $sitesAvailable ]; then
	mkdir $sitesAvailable
	chmod 777 $sitesAvailable
fi

configName=$domain

if ! echo "server {
	listen 80;
	root $rootPath;
	index index.php index.hh index.html index.htm;
	server_name $domain;
	location = /favicon.ico { log_not_found off; access_log off; }
	location = /robots.txt { log_not_found off; access_log off; }
	location ~* \.(jpg|jpeg|gif|css|png|js|ico|xml)$ {
		access_log off;
		log_not_found off;
	}
	location ~ \.(php|hh)$ {
		fastcgi_pass 127.0.0.1:9000;
		fastcgi_index index.php;
		include fastcgi_params;
		fastcgi_param HTTPS off;
	}
	location ~ /\.ht {
		deny all;
	}
	client_max_body_size 0;
}" > $sitesAvailable$configName
then
	echo "There is an ERROR create $configName file"
	exit;
else
	echo "New Virtual Host Created"
fi

if ! echo "127.0.0.1	$domain" >> /etc/hosts
then
	echo "ERROR: Not able write in /etc/hosts"
	exit;
else
	echo "Host added to /etc/hosts file"
fi

ln -s $sitesAvailable$configName $sitesEnable$configName

service nginx restart

echo "Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootPath"
exit;
