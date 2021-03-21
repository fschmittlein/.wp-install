#!/bin/bash

wp cli version
if [ $? -ne 0 ]; then
	echo "Unfortunately, the WP-CLI is not available, so I have to abort."
	exit 1
fi

wp cli has-command "dotenv"
if [ $? -ne 0 ]; then
	wp package install aaemnnosttv/wp-cli-dotenv-command
	if [ $? -ne 0 ]; then
		php -d memory_limit=512M "$(which wp)" package install aaemnnosttv/wp-cli-dotenv-command
	fi
fi

while getopts "hdi" option; do
  case $option in
    h | -help)
	  echo "usage: $0 hoster [-d] [-i]"
	  exit
	  ;;
#    all-inkl | allinkl)
#	  echo "Hoster: all-inkl"
#      ;;
#	uberspace)
#	  echo "Hoster: uberspace"
#	  ;;
	d | -del | --del | -delete | --delete)
      echo "The WordPress installation will be deleted..."
	  wp db clean --yes
	  rm -f -d -r ../wp-admin
	  rm -f -d -r ../wp-content
	  rm -f -d -r ../wp-includes
	  rm ../*
	  rm ../.htaccess
	  exit
      ;;
	i | -interactive | --interactive)
      wp dotenv init --template=.env.example --interactive
	  ;;
    ?)
	  echo "error: option -$OPTARG is not implemented"
	  exit
	  ;;
  esac
done

if ! [ -f './.env' ]; then
	echo "The information for the WordPress installation is missing. Therefore the query starts now..."
	wp dotenv init --template=.env.example --interactive
fi


wp_locale=$(wp dotenv get wp_locale)
wp_version=$(wp dotenv get wp_version)

wp_dbname=$(wp dotenv get wp_dbname)
wp_dbuser=$(wp dotenv get wp_dbuser)
wp_dbpass=$(wp dotenv get wp_dbpass)
wp_dbhost=$(wp dotenv get wp_dbhost)
wp_dbprefix=$(wp dotenv get wp_dbprefix)

wp_url=$(wp dotenv get wp_url)
wp_title=$(wp dotenv get wp_title)
wp_admin_user=$(wp dotenv get wp_admin_user)
wp_admin_email=$(wp dotenv get wp_admin_email)

wp_blogdescription=$(wp dotenv get wp_blogdescription) 
wp_plugin_install=$(wp dotenv get wp_plugin_install) 
wp_theme_install=$(wp dotenv get wp_theme_install)
wp_theme_delete=$(wp dotenv get wp_theme_delete)


cd ..


## download and install wordpress
wp core download --locale=$wp_locale --version=$wp_version
wp config create --dbname=$wp_dbname --dbuser=$wp_dbuser --dbpass=$wp_dbpass --dbhost=$wp_dbhost --dbprefix=$wp_dbprefix
if [ $? -ne 0 ]; then
	echo "I guess there was a download error. That's why we're stopping here..."
	exit 1
fi
wp core install --url=$wp_url --title="$wp_title" --admin_user=$wp_admin_user --admin_email=$wp_admin_email


## empties a site of its content (posts, comments, terms, and meta)
wp site empty --uploads --yes

## delete all default plugins
wp plugin delete --all

## Removes all widgets from the sidebar and places them in Inactive Widgets.
wp widget reset --all



## get new salts for your wp-config.php file
wp config shuffle-salts

## more ram
wp config set WP_MEMORY_LIMIT 512M
wp config set WP_MAX_MEMORY_LIMIT 512M

## set the environment type
wp config set WP_ENVIRONMENT_TYPE production
wp config set WP_ENV production

## Automatic Database Optimizing
wp config set WP_ALLOW_REPAIR false --raw

## HTTPS for all
wp config set FORCE_SSL_LOGIN true --raw
wp config set FORCE_SSL_ADMIN true --raw

## Performance
wp config set WP_CACHE false --raw
wp config set COMPRESS_CSS false --raw
wp config set COMPRESS_SCRIPTS false --raw
wp config set CONCATENATE_SCRIPTS false --raw
wp config set ENFORCE_GZIP true --raw

## Content
wp config set AUTOSAVE_INTERVAL 30
wp config set WP_POST_REVISIONS 5
wp config set MEDIA_TRASH true --raw
wp config set EMPTY_TRASH_DAYS 7

## File edition
wp config set DISALLOW_FILE_MODS false --raw
wp config set DISALLOW_FILE_EDIT true --raw
wp config set IMAGE_EDIT_OVERWRITE true --raw

## Debug
wp config set WP_DEBUG false --raw
wp config set WP_DEBUG_DISPLAY true --raw
wp config set WP_DEBUG_LOG true --raw
wp config set SCRIPT_DEBUG false --raw
wp config set SAVEQUERIES false --raw



## change permalinks
wp rewrite structure '/%postname%/'

## delete the default blogdescription
wp option update blogdescription "$wp_blogdescription"

## hide for the search engines
wp option update blog_public 0

## disable the avatars
wp option update show_avatars 0

## install and activate plugins
wp plugin install $wp_plugin_install --activate

## after installing all plugins, update the language
wp language plugin install --all $wp_locale

##install and activate theme
wp theme install $wp_theme_install
wp theme activate $wp_theme_install
wp theme delete $wp_theme_delete



## htaccess
## https://gist.github.com/seoagentur-hamburg/c96bc796764baaa64d43b70731013f8a
## Andreas Hecht
git clone https://gist.github.com/c96bc796764baaa64d43b70731013f8a.git
mv ./c96bc796764baaa64d43b70731013f8a/.htaccess .htaccess
rm -f -d -r ./c96bc796764baaa64d43b70731013f8a/