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
LOGFILE=~/Desktop/script_logs.txt
NULL=/dev/null
TOOL_LIST=("nginx" "nginx-extras")
ENABLE_SSL=1
PUBLIC_DIR="public_html"
domain="example.com"
ip=""
. /etc/os-release
. nginx.template


function main(){

    #Checks if script runs as sudo or root user
    if [[ $EUID -ne 0 ]]; then
        echo "Please run this script with sudo or as root user."
        exit 1
    fi

    #Check if runing debian distro
    if [[ $ID_LIKE == "debian" ]]; then
        echo "Running on Debian-family distro. Executing main code..."
    else
        echo "This script is designed to run only on Debian-family distro only!"
        exit 1
    fi

    #Check if template file present in the directory
    if [[ ! -f nginx.template ]]; then
        echo "Missing nginx.template file"
        exit 1
    fi

    #Install neccery tools
    for tool in ${TOOL_LIST[@]}; do
        install "$tool"
    done
    
    #Script menu
    echo -e "\
    \n======================================================\
    \n \
    \n🧠 SCRIPT USAGE HELP MENU\
    \n--------------------------\
    \n \
    \nThis script allows you to create a basic HTTP/HTTPS web server\
    \nwith optional features like authentication and user public directories.\
    \n\
    \n🔹 Required Flag:\
    \n    -d '<IP_address> <Domain_Name>'\
    \n       → Defines the IP and domain name for the virtual host.\
    \n       → This flag is mandatory for the script to proceed.\
    \n\
    \n🔹 Optional Flags:\
    \n    -u <public_directory_name>\
    \n        → Creates a public_html directory for the current user.\
    \n        → Useful for hosting personal web pages.\
    \n\
    \n    -a\
    \n        → Enables basic authentication using htpasswd.\
    \n        → Users will need a username and password to access the site.\
    \n\
    \n    -p\
    \n        → PAM authentication (Pluggable Authentication Modules).\
    \n        → ⚠️ Currently not supported in this version.\
    \n\
    \n    -s
    \n        → Enables HTTPS web server
    \n\
    \n📦 Example Usages:\
    \n    ./nginx.sh -d '127.0.0.10 mysite.local'\
    \n    ./nginx.sh -d '127.0.0.20 secure.site' -a\
    \n    ./nginx.sh -d '127.0.0.30 user.site' -u public_html\
    \n    ./nginx.sh -d '127.0.0.40 ninja.com' -s
    \n\
    \n======================================================\
    "


    while getopts "d:u:a:p:s" opt; do
        case $opt in
            d)
                ip=$(echo "$OPTARG" | awk '{print $1}')
                domain=$(echo "$OPTARG" | awk '{print $2}')
                ;;
            u)
                PUBLIC_DIR=$OPTARG
                enable_user_dir "$domain" "$PUBLIC_DIR"
                ;;
            a)
                auth "$domain"
                ;;
            p)
                #create_pam
                ;;
            s)
                ENABLE_SSL=0
        esac
    done

    if [[ -z "$domain" ]] || [[ -z "$ip" ]]; then
        echo "Syntax error: Missing required argument -d '<IP_address> <Domain_Name>'"
        return 1
    else
        configure_vh "$ip" "$domain" "$ENABLE_SSL"
    fi

    restart_nginx
}

#install nginx and neccery tools
function install(){

    package=$1
    if ! dpkg -s $package &>$NULL; then
        echo "Installing $package..."
        if ! sudo apt-get install $package -y >> $LOGFILE 2>&1; then
            log ERROR "[install_nginx] failed to install $package"
            echo -e "Failed to install package named: $package\
            \nExisting Script..."
            return 1
            fi
        else
            echo "$package is already installed."
    fi
}

#Creates a web server via HTTP or HTTPS depending on argument
function configure_vh(){

    local ip=$1
    local domain=$2
    local enable_ssl=$3
    config_file "$ip" "$domain"
    if [[ $enable_ssl -eq 1 ]]; then
        eval "echo \"$domain_conf_http\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    else
        create_ssl "$domain"
    fi

    if curl -I http://$domain; then
        return 0
    else
        echo "Something went wrong, please check the config files at /etc/nginx/sites-available/$domain"
        exit 1
    fi
}

#Creates  the config files
function config_file(){

    local ip=$1
    local domain=$2
    sudo touch $SITES_AVAILABLE/$domain
    sudo mkdir /var/www/$domain
    echo "<h1>Hello from $domain!</h1>" | sudo tee /var/www/$domain/index.html > $NULL
    echo "$ip $domain" | sudo tee -a /etc/hosts > $NULL
    sudo ln -s $SITES_AVAILABLE/$domain $SITES_ENABLED
}

#Adds users directories to the web server config
function enable_user_dir(){
    local domain=$1
    local public_dir=$2
    sudo mkdir /home/$USER/$public_dir
    sudo chmod +x /home/$USER
    sudo chmod 755 /home/$USER/$public_dir
    echo "<h1>Hello from $USER!</h1>" | sudo tee /home/$USER/$public_dir/index.html > $NULL
    eval "echo \"$user_dir_conf\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
        if curl -I http://$domain/~$USER; then
            return 0
	    else
	        echo "Something Went Wrong"
	        return 1
        fi
}

#Adds htpasswd authentication to the web server config
function auth(){

    local domain=$1
    if ! sudo apt-get install apache2-utils -y >> $LOGFILE 2>&1; then
        log ERROR "[install_nginx] failed to install apache2-utils"
        echo -e "Failed to install package named: apache2-utils\
        \nExisting Script..."
        return 1
    fi
    read -rp "Please enter a username for the authentication: " username
    sudo htpasswd -c /etc/nginx/.htpasswd $username
    eval "echo \"$auth_conf\"" | sudo tee $SITES_AVAILABLE/$domain > $NULL
    curl -u $username:password -I http://$domain/secure
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
    if sudo openssl req -x509 -newkey rsa:4096 -keyout "$key_file_path" -out "$cert_file_path" -days 365 -nodes; then
        echo "SSL key and cery were created at keyfile: "$key_file" certfile: "$cert_file""
    else
        echo "There was an error in creating the key and cert files"
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

echo } >> $SITES_AVAILABLE/$domain
if sudo nginx -t; then
    sudo systemctl restart nginx
else
    echo "NGINX configuration test failed. Aborting restart..."
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
    echo "[$timestamp] [$level] $message" >> $LOGFILE
}


main "$@"


