#!/usr/bin/env bash
################################### Start Safe Header ##########################
#Developed by Alex Umansky aka TheBlueDrara
#Porpuse a tool to install nginx and config it 
#Date 1.3.2025
#Version 3.0.2
set -o nounset
set -o errexit
set -o pipefail
################################## End Safe Header ############################
SITES_AVAILABLE=/etc/nginx/sites-available
SITES_ENABLED=/etc/nginx/sites-enabled/
LOGFILE=$HOME/nginx_script_logs
NULL=/dev/null
TOOL_LIST=("nginx" "nginx-extras")
ENABLE_SSL=1
ENABLE_USER_DIR=1
ENABLE_AUTH="1"
PUBLIC_DIR="public_html"
DOMAIN="Banana.com"
IP_ADDR="127.0.0.1"
HELP_MENU=$(echo -e "
\e[36m
===========================================================
🧠 NGINX SETUP SCRIPT - HELP MENU
-----------------------------------------------------------
\e[0m

\e[1mDescription:\e[0m
  This script installs and configures an Nginx web server with 
  optional features like SSL, user public directories, and 
  basic authentication. It also works out of the box with 
  default settings.

\e[1mUsage:\e[0m
  sudo bash nginx.sh [options]

\e[1mNote:\e[0m
  If no options are passed, the script will create a default 
  HTTP server at \e[32m127.0.0.1\e[0m with domain \e[32mBanana.com\e[0m.

\e[1mAvailable Options:\e[0m

  \e[38;5;81m-d\e[0m | \e[38;5;81m--domain <IP_address> <domain_name>\e[0m  
      → Set the IP and domain name  
      → Overrides the default values  

  \e[38;5;83m-u\e[0m | \e[38;5;83m--user-dir <public_directory_name>\e[0m  
      → Create a user public directory (e.g., public_html)  

  \e[38;5;214m-a\e[0m | \e[38;5;214m--auth\e[0m  
      → Enable basic authentication using htpasswd  

  \e[38;5;203m-p\e[0m | \e[38;5;203m--pam-auth\e[0m  
      → PAM authentication (currently not supported)  

  \e[38;5;171m-c\e[0m | \e[38;5;171m--cgi\e[0m  
      → Enable CGI scripting support (feature placeholder)  

  \e[38;5;117m-s\e[0m | \e[38;5;117m--ssl\e[0m  
      → Enable HTTPS and auto-generate SSL certificate  

  \e[38;5;245m-h\e[0m | \e[38;5;245m--help\e[0m  
      → Show this help menu and exit  

\e[36m===========================================================\e[0m"
)
. /etc/os-release
#Loops all templates files to source them
for f in ./templates/*.tmpl; do source "$f"; done 



function main(){

    log MISC "==== Starting nginx setup script ===="
    sleep 1

    log INFO "Dear user if you need help you can add the -h | --help flag for more info!"
    sleep 1

    #Checks if script runs as sudo or root user
    if [[ $EUID -ne 0 ]]; then
        log WARNING "Please run this script with sudo or as root user."
        exit 1
    fi

    #Check if runing debian distro
    if [[ $ID_LIKE == "debian" ]]; then
        log INFO "Running on Debian-family distro. Executing main code..."
        sleep 1
    else
        log WARNING "This script is designed to run only on Debian-family distro only!"
        exit 1
    fi

    #Check if template directory present
    if [[ ! -d templates ]]; then
        log WARNING "Missing template files - </templates/*.tmpl>"
        exit 1
    fi

    while [[ $# != 0 ]] ; do
        case $1 in
            -d|--domain)
                IP_ADDR=$2
                DOMAIN=$3
                shift 3
                ;;
            -u|--user-dir)
                PUBLIC_DIR=$2
                ENABLE_USER_DIR=0
                shift 2
                ;;
            -a|--auth)
                ENABLE_AUTH=0
                shift
                ;;
            -p|--pam-auth)
                #create_pam
                shift
                ;;
            -c|--cgi)
                #create_cgi
                shift
                ;;
            -s|--ssl)
                ENABLE_SSL=0
                shift
                ;;
            -h|--help)
                echo "$HELP_MENU"
                exit 1
                shift 
                ;;
        esac
    done

    #Install neccery tools
    for tool in ${TOOL_LIST[@]}; do
        install "$tool"
    done

    if [[ "$DOMAIN" == "example.com" ]] || [[ "$IP_ADDR" == "127.0.0.1" ]]; then
        log WARNING "Using default values: domain= <$DOMAIN> ip= <$IP_ADDR>"
        sleep 1
    fi
    
    configure_vh "$IP_ADDR" "$DOMAIN" "$ENABLE_SSL"

    if [[ $ENABLE_USER_DIR -eq 0 ]]; then
        enable_user_dir "$DOMAIN" "$PUBLIC_DIR"
    fi

    if [[ $ENABLE_AUTH -eq 0 ]]; then
        auth "$DOMAIN"
    fi

    restart_nginx

    log INFO "==== Script completed successfully ===="
}

#install nginx and neccery tools
function install(){

    package=$1
    if ! dpkg -s $package &>$NULL; then
        echo "Installing $package..."
        sleep 1
        if ! apt-get install $package -y >> $LOGFILE 2>&1; then
            log ERROR "[install_nginx] failed to install $package"
            echo -e "Failed to install package named: $package\
            \nExisting Script..."
            return 1
            fi
        else
            log INFO "$package is already installed."
            sleep 1
    fi
}

#Creates a web server via HTTP or HTTPS depending on argument
function configure_vh(){

    local ip=$1
    local domain=$2
    local enable_ssl=$3
    config_file "$ip" "$domain"
    if [[ $enable_ssl -eq 0 ]]; then
        log INFO "SSL is enabled. Setting up certificates..."
        sleep 1
        create_ssl "$domain"
    else
        eval "echo \"$domain_conf_http\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    fi

    if curl -I http://$domain; then
    echo -e "\n"
        return 0
    else
        log WARNING "Something went wrong, please check the config files at /etc/nginx/sites-available/$domain"
        exit 1
    fi
}

#Creates  the config files
function config_file(){

    local ip=$1
    local domain=$2
    
    if [[ ! -f "$SITES_AVAILABLE/$domain" ]];then
        touch "$SITES_AVAILABLE/$domain"
    else
        log WARNING "This domain name already exists, please try with a diffrent name!"
        return 1
    fi

    if [[ ! -d /var/www/$domain ]];then
        mkdir -p /var/www/$domain
    else
        log WARNING "This root directory already exists, please try with a different domain name!"
        return 1
    fi

    echo "<h1>Hello from $domain!</h1>" | tee /var/www/$domain/index.html > $NULL
    echo "$ip $domain" | sudo tee -a /etc/hosts > $NULL

    if [[ ! -L $SITES_ENABLED/$domain ]];then
        ln -s $SITES_AVAILABLE/$domain $SITES_ENABLED/$domain
    else
        log WARNING "Cant soft link the "$SITES_AVAILABLE/$domain" to "$SITES_ENABLED" soft link already exists!" 
        return 1
    fi
}

#Adds users directories to the web server config
function enable_user_dir(){
    local domain=$1
    local public_dir=$2
    local user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    local username="$SUDO_USER"
    mkdir $user_home/$public_dir
    chmod +x $user_home ; chmod 755 $user_home/$public_dir
    echo "<h1>Hello from $username!</h1>" | tee $user_home/$public_dir/index.html > $NULL
    eval "echo \"$user_dir_conf\"" | tee -a $SITES_AVAILABLE/$domain > $NULL
        if curl -I http://$domain/~$user_home; then
            echo -e "\n"
            return 0
	    else
	        log WARNING "Something Went Wrong, user directory failed please check config files"
	        return 1
        fi
}

#Adds htpasswd authentication to the web server config
function auth(){

    local domain=$1
    if ! apt-get install apache2-utils -y >> $LOGFILE 2>&1; then
        log ERROR "[install_apache2-utils] failed to install apache2-utils"
        log WARNING "Failed to install package named: apache2-utils\
        \nExisting Script..."
        return 1
    fi
    read -rp "[INPUT] Please enter a username for the authentication: " username
    htpasswd -c /etc/nginx/.htpasswd $username
    echo -e "\n"
    eval "echo \"$auth_conf\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    curl -u $username:password -I http://$domain/secure
    echo -e "\n"
}

#Creates SSL certificate and adds HTTPS config to the web server
function create_ssl(){

    local domain=$1
    local cert_file="$domain.crt"
    local key_file="$domain.key"
    local cert_file_path="/etc/ssl/certs/$cert_file"
    local key_file_path="/etc/ssl/private/$key_file"
    local ssl_dir=$(dirname $key_file)
    mkdir -p "$ssl_dir"
    if  openssl req -x509 -newkey rsa:4096 -keyout "$key_file_path" -out "$cert_file_path" -days 365 -nodes; then
        echo -e "\n"
        log WARNING "SSL key and Certificate were created at keyfile: "$key_file" certfile: "$cert_file"\
        \n "
    else
        log WARNING "There was an error in creating the key and cert files"
        return 1
    fi
    eval "echo \"$domain_conf_https\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
}

#creates a http web server with autentication using PAM
#function create_pam(){
#
#    if ! sudo apt-get install libpam0g-dev libpam-modules -y >> $LOGFILE 2>&1; then
#        log ERROR "[install_nginx] failed to install PAM"
#	    echo -e "Failed to install PAM\
#	    \nExisting Script..."
#	    return 1
#    fi
#    config_file "ip" "domain"
#    eval "echo \"$pam_conf\"" | sudo tee $SITES_AVAILABLE/$domain > $NULL
#    echo "auth required pam_unix.so account required pam_unix.so"| sudo tee -a /etc/pam.d/nginx
#    sudo usermod -aG shadow www-data
#    sudo mkdir /var/www/html/auth-pam
#    echo "$html_template" | sudo tee -a /var/www/html/auth-pam/index.html > $NULL
#    sudo systemctl restart nginx
#}

#Checks if the nginx syntax is correct before a restart
function restart_nginx(){

    echo } >> $SITES_AVAILABLE/$DOMAIN
    if nginx -t; then
        echo -e "\n"
        systemctl restart nginx
    else
        echo -e "\n"
        log WARNING "NGINX configuration test failed. Aborting restart..."
        exit 1
    fi
}

#Log template 
function log(){

    touch $LOGFILE
    local level="$1"; shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    case "$level" in
        INFO) echo -e "\e[32m[$timestamp] [$level]\e[0m $message" ;;
        WARNING) echo -e "\e[33m[$timestamp] [$level]\e[0m $message" ;;
        ERROR) echo -e "\e[31m[$timestamp] [$level]\e[0m $message" ;;
        MISC) echo -e "\e[34m[$timestamp] [$level]\e[0m $message" ;;
    esac

    echo "[$timestamp] [$level] $message" >> $LOGFILE
}


main "$@"


