#!/bin/bash

showHelp() {
# `cat << EOF` This means that cat should stop reading when EOF is detected
cat << EOF
Usage: ./wp-install [-hdi]
Easy installation of WordPress via the console directly on the server.

-h, -help, --help			Display help

-d, -del, --del				Deletes the WordPress installation (without any warning)

-i, -interactive, --interactive		Asks interactive your environment for the WordPress installation

EOF
# EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
}

###
### Check for wp cli
###
wp cli version 1>/dev/null
if [ $? -ne 0 ]; then
	echo "Unfortunately, the WP-CLI is not available, so I have to abort."
	exit 1
fi

###
### Check for package aaemnnosttv/wp-cli-dotenv-command
###
wp cli has-command "dotenv" 2>/dev/null
if [ $? -ne 0 ]; then
	wp package install aaemnnosttv/wp-cli-dotenv-command
	# plan b in case the memory runs out
	if [ $? -ne 0 ]; then
		php -d memory_limit=512M "$(which wp)" package install aaemnnosttv/wp-cli-dotenv-command
	fi
fi

###
### What work is waiting for me?
###
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "help,del,delete,interactive" -o "hdi" -a -- "$@")

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters 
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true
do
	case $1 in
		-h | --help) 
			showHelp
			exit 0;;
		-d | --d | -del | --del | -delete | --delete)
			if [ -f '../wp-cron.php' ]; then
				echo "The WordPress installation will be deleted..."
				wp db clean --yes
				rm -f -d -r ../wp-admin
				rm -f -d -r ../wp-content
				rm -f -d -r ../wp-includes
				rm ../*
				rm ../.htaccess
			else
				echo "There is nothing to delete!"
			fi
			exit;;
		-i | --i | -interactive | --interactive)
			wp dotenv init --template=.env.wordpress --interactive
			break;;
		--)
			shift
			break;;
	esac
	shift
done

if [ -f '../wp-cron.php' ]; then
	echo "WordPress files seem to already be present here, so I have to abort."
	exit 1
fi


if ! [ -f './.env' ]; then
	echo "The information for the WordPress installation is missing. Therefore the query starts now..."
	wp dotenv init --template=.env.wordpress --interactive
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

wp_memory_limit=$(wp dotenv get wp_memory_limit)
wp_environment=$(wp dotenv get wp_environment)

wp_blogdescription=$(wp dotenv get wp_blogdescription) 
wp_plugin_install=$(wp dotenv get wp_plugin_install) 
wp_theme_install=$(wp dotenv get wp_theme_install)
wp_theme_delete=$(wp dotenv get wp_theme_delete)


## change directory to the doc-root
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



## get new salts for your wp-config.php file
wp config shuffle-salts

## more ram
wp config set WP_MEMORY_LIMIT $wp_memory_limit
wp config set WP_MAX_MEMORY_LIMIT $wp_memory_limit

## set the environment type
wp config set WP_ENVIRONMENT_TYPE $wp_environment
wp config set WP_ENV $wp_environment

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

## install and activate theme
wp theme install $wp_theme_install
wp theme activate $wp_theme_install
wp theme delete $wp_theme_delete

## Removes all widgets from the sidebar and places them in Inactive Widgets.
wp widget reset --all



## htaccess
## https://gist.github.com/seoagentur-hamburg/c96bc796764baaa64d43b70731013f8a
## Andreas Hecht
git clone https://gist.github.com/c96bc796764baaa64d43b70731013f8a.git
mv ./c96bc796764baaa64d43b70731013f8a/.htaccess .htaccess
rm -f -d -r ./c96bc796764baaa64d43b70731013f8a/
