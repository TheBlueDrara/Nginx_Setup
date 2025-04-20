#!/usr/bin/env bash
################################### Start Safe Header ##########################
#Developed by Alex Umansky aka TheBlueDrara
#Porpuse a tool to install nginx and config it 
#Date 1.3.2025
#Version 3.0.1
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
SSL_CRET=""
SSL_KEY=""

. /etc/os-release
. nginx.template


function main(){
    #check if runing debian distro
    if [[ $ID_LIKE == "debian" ]]; then
	    echo "Running on Debian-family distro. Executing main code..."
    else
	    echo "This script is designed to run only on Debian-family distro only!"
	    exit 1
    fi
    #check if template file present in the directory
    if [[ ! -f nginx.template ]]; then
        echo "Missing nginx.template file"
        exit 1
    fi
    #install neccery tools
    for tool in ${TOOL_LIST[@]}; do
        install "$tool"
    done
    
    #script menu
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
    \n    -s '<Path_to_ssl_cret> <Path_to_ssl_key>'
    \n        → Enables HTTPS web server
    \n\
    \n📦 Example Usages:\
    \n    ./nginx.sh -d '127.0.0.10 mysite.local'\
    \n    ./nginx.sh -d '127.0.0.20 secure.site' -a\
    \n    ./nginx.sh -d '127.0.0.30 user.site' -u public_html\
    \n    ./nginx.sh -d '127.0.0.40 ninja.com' -s '.ssl_cret.pem .ssl_key.pem'
    \n\
    \n======================================================\
    "


    while getopts "d:u:a:p:s:" opt; do
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

                $SSL_CRET=$(echo "$OPTARG" | awk '{print $1}')
                $SSL_KEY=$(echo "$OPTRAG" | awk '{print $2}')
                ENABLE_SSL=0
        esac
    done

    if [[ -z "$domain" ]] || [[ -z "$ip" ]]; then
        echo "Syntax error: Missing required argument -d '<IP_address> <Domain_Name>'"
    else
        configure_vh "$ip" "$domain" "$ENABLE_SSL" "$SSL_CRET" "$SSL_KEY"
    fi

    echo } >> $SITES_AVAILABLE/$domain
    sudo systemctl restart nginx
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

#creates just a simple http web server
function configure_vh(){
    local ip=$1
    local domain=$2
    local enable_ssl=$3
    local ssl_cret=$4
    local ssl_key=$5
    config_file "$ip" "$domain"
    if [[ $enable_ssl -eq 1 ]]; then
        eval "echo \"$domain_conf_http\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    else
        check_ssl "$ssl_cret" "$ssl_key"
        eval "echo \"$domain_conf_https\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    fi

    if curl -I http://$domain; then
        return 0
    else
        echo "Something went wrong, please check the config files at /etc/nginx/sites-available/$domain"
        exit 1
    fi
}

#create  the config files
function config_file(){
    local ip=$1
    local domain=$2
    sudo touch $SITES_AVAILABLE/$domain
    sudo mkdir /var/www/$domain
    echo "<h1>Hello from $domain!</h1>" | sudo tee /var/www/$domain/index.html > $NULL
    echo "$ip $domain" | sudo tee -a /etc/hosts > $NULL
    sudo ln -s $SITES_AVAILABLE/$domain $SITES_ENABLED
}

#creates an http web server with users directories
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

#creates an http web server with htpasswd authentication
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


function check_ssl(){
local cert_file=$1
local key_file=$2
local ssl_dir=$(dirname "$key_file")

if [[ ! -e $cert_file || ! -e $key_file ]]; then
    read -p "Looks like the cert and key file don't exist, would you like to to create them? [y/n] " user_input
    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        mkdir -p "$ssl_dir"
        if  openssl req -x509 -newkey rsa:4096 -keyout "$key_file" -out "$cert_file" -days 365 -nodes; then
            echo "SSL key and cery were created at keyfile: "$key_file" certfile: "$cert_file""
            return 0
        else
            echo "There was an error in crearing the key and cert files"
            return 1
        fi
    elif [[ "$user_input" == "n" || "$user_input" == "N" ]]; then
        return 1
    else
        echo "Invalid input [y/n]"
        return 1
    fi

       echo "The cert and key file already exist"
    fi
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

















