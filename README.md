# What this repository does?
This repository will help you to get a fresh WordPress installation using SSH.

## What this repository need?
1. Hosting with a SSH connection
2. git and wp cli on the server

## Installation and usage
1. Connect to your server using SSH
2. Go to the Document-Root of the domain (e.g. `cd html/htdocs`)
3. Clone the repository `git clone https://github.com/fschmittlein/.wp-install.git`
4. Change the directory `cd .wp-install`
5. Run `chmod +x wp-install.sh`
6. Run `./wp-install.sh` and wait or try `./wp-install.sh --help` for usage

## Customisations (.env or interactive)
All adjustments must be made in the `.env` file
