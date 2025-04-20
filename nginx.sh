#!/usr/bin/env bash
################################### Start Safe Header ##########################
#Developed by Alex Umansky aka TheBlueDrara
#Porpuse a tool to install nginx and config it 
#Date 1.3.2025
#Version 0.0.1
set -o nounset
set -o errexit
set -o pipefail
################################## End Safe Header ############################
SITES_AVAILABLE=/etc/nginx/sites-available
SITES_ENABLED=/etc/nginx/sites-enabled/
LOGFILE=~/Desktop/script_logs.txt
NULL=/dev/null
TOOL_LIST=("nginx" "nginx-extras")
. /etc/os-release
. nginx.template

function main(){

    if [[ $ID_LIKE == "debian" ]]; then
	    echo "Running on Debian-family distro. Executing main code..."
    else
	    echo "This script is designed to run only on Debian-family distro only!"
	    exit 1
    fi

    if [[ ! -f nginx.template ]]; then
        echo "Missing nginx.template file"
        exit 1
    fi

    for tool in ${TOOL_LIST[@]}; do
        if ! dpkg -s $tool &>$NULL; then
            echo "Installing $tool..."
            if ! sudo apt-get install $tool -y >> $LOGFILE 2>&1; then
            log ERROR "[install_nginx] failed to install $tool"
            echo -e "Failed to install package named: $tool\
            \nExisting Script..."
            return 1
            fi
        else
            echo "$tool is already installed."
        fi
    done

    echo -e "======================================================\
    \n \
    \n Hello Dear User!\
    \n Please take in mind in the current version of the script, each option creates it own webserver + the different options!\
    \n If you want to choose another option, it will create a new webserver with a different local ip address.\
    \n \
    \n \
    \n Please chose your desired option\
    \n install nginx: '-i'\
    \n Configure new VH: -d '<IP address of the domain> <domain_name>'\
    \n Configure VH and Create a public html folder for current user: -u '<IP address of the domain> <domain_name>'\
    \n Create an authentication using htpasswd: -a '<IP address of the domain> <domain_name>'\
    \n Create an authentication using PAM: -p '<IP address of the domain> <domain_name>'\
    \n \
    \n======================================================"

    while getopts "id:u:a:p:" opt; do
        case $opt in
            d)
                ip=$(echo "$OPTARG" | awk '{print $1}')
                domain=$(echo "$OPTARG" | awk '{print $2}')
                if [[ -z "$domain" ]] || [[ -z "$ip" ]]; then
                    echo "Syntax error: Missing Argument -d '<IP_address> <domain>'"
                else
                    configure_vh "$ip" "$domain"
                fi
                ;;
            i)
                install_nginx
                ;;
            u)
                ip=$(echo "$OPTARG" | awk '{print $1}')
                domain=$(echo "$OPTARG" | awk '{print $2}')
                if [[ -z "$domain" ]] || [[ -z "$ip" ]]; then
                    echo "Syntax error: Missing Argument -d '<IP_address> <domain>'"
                else
                    enable_user_dir "$ip" "$domain"
                fi
                ;;
            a)
                ip=$(echo "$OPTARG" | awk '{print $1}')
                domain=$(echo "$OPTARG" | awk '{print $2}')
                if [[ -z "$domain" ]] || [[ -z "$ip" ]]; then
                    echo "Syntax error: Missing Argument -d '<IP_address> <domain>'"
                else
                    auth "$ip" "$domain"
                fi
                ;;
            p)
                ip=$(echo "$OPTARG" | awk '{print $1}')
                domain=$(echo "$OPTARG" | awk '{print $2}')
                if [[ -z "$domain" ]] || [[ -z "$ip" ]]; then
                    echo "Syntax error: Missing Argument -p '<IP_address>  <domain>'"
                else
                    create_pam "$ip" "$domain"
                fi
                ;;
        esac
    done
}


function config_file(){

# ADD a check that if the user inputs an ip or domain that already exit, out put the info to the user and try again
    sudo touch $SITES_AVAILABLE/$domain
    sudo mkdir /var/www/$domain
    echo "<h1>Hello from $domain!</h1>" | sudo tee /var/www/$domain/index.html > $NULL
    echo "$ip $domain" | sudo tee -a /etc/hosts > $NULL
    sudo ln -s $SITES_AVAILABLE/$domain $SITES_ENABLED
    sudo systemctl restart nginx

}


function configure_vh(){

    config_file "ip" "domain"
    eval "echo \"$domain_conf\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    if curl -I http://$domain; then
        return 0
    else
        echo "Something went wrong"
	return 1
    fi
}


function enable_user_dir(){
    sudo mkdir /home/$USER/public_html
    sudo chmod +x /home/$USER
    sudo chmod 755 /home/$USER/public_html
    config_file "ip" "domain"
    echo "<h1>Hello from $USER!</h1>" | sudo tee /home/$USER/public_html/index.html > $NULL
    eval "echo \"$user_dir_conf\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    sudo systemctl restart nginx
        if curl -I http://$domain/~$USER; then
            return 0
	    else
	        echo "Something Went Wrong"
	        return 1
        fi
}


function auth(){

    if ! sudo apt-get install apache2-utils -y >> $LOGFILE 2>&1; then
        log ERROR "[install_nginx] failed to install apache2-utils"
        echo -e "Failed to install package named: apache2-utils\
        \nExisting Script..."
        return 1
    fi
    config_file "ip" "domain"
    read -rp "Please enter a username: " username
    sudo htpasswd -c /etc/nginx/.htpasswd $username
    eval "echo \"$auth_conf\"" | sudo tee $SITES_AVAILABLE/$domain > $NULL
    sudo systemctl restart nginx
    curl -u $username:password -I http://$domain/secure
}


function create_pam(){

    if ! sudo apt-get install libpam0g-dev libpam-modules -y >> $LOGFILE 2>&1; then
        log ERROR "[install_nginx] failed to install PAM"
	    echo -e "Failed to install PAM\
	    \nExisting Script..."
	    return 1
    fi
    config_file "ip" "domain"
    eval "echo \"$pam_conf\"" | sudo tee $SITES_AVAILABLE/$domain > $NULL
    echo "auth required pam_unix.so account required pam_unix.so"| sudo tee -a /etc/pam.d/nginx
    sudo usermod -aG shadow www-data
    sudo mkdir /var/www/html/auth-pam
    echo "$html_template" | sudo tee -a /var/www/html/auth-pam/index.html > $NULL
    sudo systemctl restart nginx
}


function log(){
    touch $LOGFILE
    local level="$1"; shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] $message" >> $LOGFILE
}


main "$@"

















