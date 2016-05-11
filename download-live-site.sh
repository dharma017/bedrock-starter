#!/bin/bash

#===============================================================================
# This is a template for a script I use on a lot of sites to copy the database
# (MySQL) and any uploaded files to the development site, and modify the
# database as required.
#
# The script should be on the development server. The live site can either be on
# the same server, or a remote server connected via SSH.
#
# Most of the editable settings are at the top, for easy setup, but it can be
# customised as much as necessary.
#===============================================================================

set -o nounset -o pipefail

# I typically keep this script in the root of the site
cd $(dirname $0)

#===============================================================================
# Settings
#===============================================================================

# Development Environment
dev_db='dev_db_name'
dev_db_user='dev_db_username'
dev_db_pwd='dev_db_password'
dev_db_host='dev_db_host'
dev_files_path='/home/username/Workspace/project' # Absolute or relative to the current directory
dev_url='http://localhost/project'

# Directory to backup the development database to
backups_dir='db-backups'

# Staging Environment
live_host='live_ssh_host' # Blank if local
live_user='live_ssh_username'    # Blank if local

live_db='live_db_host'
live_db_user='live_db_username'
live_db_pwd='live_db_password'
live_files_path='/var/www/path/to/project' # Absolute or relative to $HOME (if using SSH) or current directory (if local)
live_url='http://dev.domain.net/project'

# MySQL script to run after downloading the development database
read -r -d '' mysql_script <<'END_MYSQL_SCRIPT'
    # UPDATE wp_options
    # SET option_value = 'me@example.com'
    # WHERE option_name = 'admin_email';
    # UPDATE wp_posts
    # SET post_content = REPLACE(post_content, 'http://www.example.com', 'http://dev.example.com');
    # UPDATE wp_postmeta
    # SET meta_value = REPLACE(meta_value, 'http://www.example.com', 'http://dev.example.com')
    # WHERE LEFT(meta_value, 2) != 'a:';
    # UPDATE wp_users
    # SET user_email = CONCAT('me+user-', ID, '@example.com');
END_MYSQL_SCRIPT

# PHP script to run after downloading the development database
# (Useful for altering serialized data, which is tricky/impossible to do through SQL)
read -r -d '' php_script <<'END_PHP_SCRIPT'
    # // Load WordPress API
    # require_once 'www/wp-load.php';
    # // Deactivate plugins
    # require_once 'www/wp-admin/includes/plugin.php';
    # deactivate_plugins('google-analytics-for-wordpress/googleanalytics.php');
    # deactivate_plugins('w3-total-cache/w3-total-cache.php');
    # // Update serialized options
    # $options = get_option("si_contact_form");
    # if ($options) {
    #     $options['email_to'] = 'Administrator,me@example.com';
    #     update_option("si_contact_form$i", $options);
    # }
END_PHP_SCRIPT

#===============================================================================

ask() {
    # http://djm.me/ask
    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question - use /dev/tty in case stdin is redirected from somewhere else
        read -p "$1 [$prompt] " REPLY </dev/tty

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

# Make sure this isn't run accidentally
ask 'Are you sure you want to overwrite the development site?' || exit

# Check the settings have been filled in above
if [ -z "$live_db" ]; then
    echo "This script has not been configured correctly." >&2
    exit 1
fi

# Take ownership of files, to ensure they are overwritten properly later
if [ -n "$dev_files_path" ]; then
    echo "Taking ownership of files..."
    sudo chown -R "$USER" "$dev_files_path" || exit
fi

# Backup database
if [ -n "$backups_dir" ]; then
    echo "Backing up existing development database..."
    if [ ! -d "$backups_dir" ]; then
        mkdir $backups_dir || exit
    fi
    mysqldump --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s\nhost = %s" "$dev_db_user" "$dev_db_pwd" "$dev_db_host") --routines "$dev_db" | bzip2 -9 > "$backups_dir/$dev_db.`date +%Y-%m-%d-%H.%M.%S`.sql.bz2" || exit
    # exit 1
fi

# Empty database
echo "Clearing existing development database..."
tables=$(mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s\nhost = %s" "$dev_db_user" "$dev_db_pwd" "$dev_db_host") "$dev_db" -Ne "SHOW TABLES")

(
    echo "SET FOREIGN_KEY_CHECKS = 0;"
    while read -r table; do
        if [ -n "$table" ]; then
            echo "DROP TABLE \`$table\`;"
        fi
    done <<< "$tables"
    echo "SET FOREIGN_KEY_CHECKS = 1;"
    echo "ALTER DATABASE DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
) | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s\nhost = %s" "$dev_db_user" "$dev_db_pwd" "$dev_db_host") "$dev_db" || exit

# Copy database
echo "Copying database..."
if [ -n "$live_host" ]; then
    printf "[client]\nuser = %s\npassword = %s" "$live_db_user" "$live_db_pwd" | ssh "$live_user@$live_host" "set -o pipefail; mysqldump --defaults-extra-file=<(cat) --routines '$live_db' | bzip2 -9" | bunzip2 | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s\nhost = %s" "$dev_db_user" "$dev_db_pwd" "$dev_db_host") "$dev_db" || exit
else
    mysqldump --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$live_db_user" "$live_db_pwd") --routines "$live_db" | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s\nhost = %s" "$dev_db_user" "$dev_db_pwd" "$dev_db_host") "$dev_db" || exit
fi

# Update database
if [ -n "$mysql_script" -o -n "$php_script" ]; then
    echo "Updating database..."
fi

if [ -n "$mysql_script" ]; then
    echo "$mysql_script" | mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s\nhost = %s" "$dev_db_user" "$dev_db_pwd" "$dev_db_host") "$dev_db" || exit
fi

if [ -n "$php_script" ]; then
    echo "<?php $php_script" | php || exit
fi

# Copy files
if [ -n "$dev_files_path" -a -n "$live_files_path" ]; then
    echo "Running WP CLI Commands..."
    if [ -n "$live_host" ]; then
        wp search-replace "$live_url" "$dev_url"
        wp user list
        wp user update 1 --user_pass=admin
        wp rewrite flush
    fi

    echo "Syncing files..."
    if [ -n "$live_host" ]; then
        rsync -avuz --progress "$live_user@$live_host:$live_files_path/wp-content/uploads" "$dev_files_path/wp-content" || exit
    fi
    echo
    chmod ugo+rwX -R "$dev_files_path" || exit
fi

# Done
echo "Done."
