# [Bedrock](https://roots.io/bedrock/)
[![Build Status](https://travis-ci.org/roots/bedrock.svg)](https://travis-ci.org/roots/bedrock)

Bedrock is a modern WordPress stack that helps you get started with the best development tools and project structure.

Much of the philosophy behind Bedrock is inspired by the [Twelve-Factor App](http://12factor.net/) methodology including the [WordPress specific version](https://roots.io/twelve-factor-wordpress/).

## Features

* Better folder structure
* Dependency management with [Composer](http://getcomposer.org)
* Easy WordPress configuration with environment specific files
* Environment variables with [Dotenv](https://github.com/vlucas/phpdotenv)
* Autoloader for mu-plugins (use regular plugins as mu-plugins)
* Enhanced security (separated web root and secure passwords with [wp-password-bcrypt](https://github.com/roots/wp-password-bcrypt))

Use [Trellis](https://github.com/roots/trellis) for additional features:

* Easy development environments with [Vagrant](http://www.vagrantup.com/)
* Easy server provisioning with [Ansible](http://www.ansible.com/) (Ubuntu 14.04, PHP 5.6 or HHVM, MariaDB)
* One-command deploys

See a complete working example in the [roots-example-project.com repo](https://github.com/roots/roots-example-project.com).

## Requirements

* PHP >= 5.5
* Composer - [Install](https://getcomposer.org/doc/00-intro.md#installation-linux-unix-osx)

## Installation

1. Clone the git repo - `git clone git@31.192.224.208:wordpress/bedrock.git`
2. Run `composer install`
3. Copy `.env.example` to `.env` and update environment variables:
  * `DB_NAME` - Database name
  * `DB_USER` - Database user
  * `DB_PASSWORD` - Database password
  * `DB_HOST` - Database host
  * `WP_ENV` - Set to environment (`development`, `staging`, `production`)
  * `WP_HOME` - Full URL to WordPress home (http://example.com)
  * `WP_SITEURL` - Full URL to WordPress including subdirectory (http://example.com/wp)
  * `AUTH_KEY`, `SECURE_AUTH_KEY`, `LOGGED_IN_KEY`, `NONCE_KEY`, `AUTH_SALT`, `SECURE_AUTH_SALT`, `LOGGED_IN_SALT`, `NONCE_SALT` - Generate with [wp-cli-dotenv-command](https://github.com/aaemnnosttv/wp-cli-dotenv-command) or from the [WordPress Salt Generator](https://api.wordpress.org/secret-key/1.1/salt/)
4. Add theme(s) in `web/app/themes` as you would for a normal WordPress site.
5. Set your site vhost document root to `/path/to/site/web/` (`/path/to/site/current/web/` if using deploys)
6. Access WP admin at `http://example.com/wp/wp-admin`
7. Activate Timber plugin - `wp plugin activate timber`
8. Activate Lumberjack Starter theme - `wp theme activate lumberjack`
9. Activate ACF Plugins
```
wp plugin activate advanced-custom-fields acf-flexible-content acf-flexible-content acf-flexible-content
```

## Deploys

There are two methods to deploy Bedrock sites out of the box:

* [Trellis](https://github.com/roots/trellis)
* [bedrock-capistrano](https://github.com/roots/bedrock-capistrano)

Any other deployment method can be used as well with one requirement:

`composer install` must be run as part of the deploy process.

## Documentation

Bedrock documentation is available at [https://roots.io/bedrock/docs/](https://roots.io/bedrock/docs/).

## Contributing

Contributions are welcome from everyone. We have [contributing guidelines](CONTRIBUTING.md) to help you get started.

## Community

Keep track of development and community news.

* Participate on the [Roots Discourse](https://discourse.roots.io/)
* Follow [@rootswp on Twitter](https://twitter.com/rootswp)
* Read and subscribe to the [Roots Blog](https://roots.io/blog/)
* Subscribe to the [Roots Newsletter](https://roots.io/subscribe/)

## WP-CLI

wp plugin list - Get a list of plugins.

wp theme list - Get a list of themes.

wp rewrite flush - Flush rewrite rules.

wp db export - Exports the MySQL database to a file or to STDOUT.

`wp db export --add-drop-table`

## Bash: Download MySQL database & files to from live to development server

**Change parameters in script file at first**

Development Environment (local pc)
```
dev_db='dev_db_name'
dev_db_user='dev_db_username'
dev_db_pwd='dev_db_password'
dev_db_host='dev_db_host'
dev_files_path='/home/username/Workspace/project' # Absolute or relative to the current directory
dev_url='http://localhost/project'
```

Staging Environment (development server)
```
live_host='live_ssh_host' # Blank if local
live_user='live_ssh_username'    # Blank if local

live_db='live_db_host'
live_db_user='live_db_username'
live_db_pwd='live_db_password'
live_files_path='/var/www/path/to/project' # Absolute or relative to $HOME (if using SSH) or current directory (if local)
live_url='http://dev.domain.net/project'
```

Make script executable in terminal
`chmod +x download-live-site.sh`

Run script
`./download-live-site.sh`

