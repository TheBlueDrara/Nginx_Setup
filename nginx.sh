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
SITES_AVAILABLE=/etc/nginx/sites-available/
SITES_ENABLED=/etc/nginx/sites-enabled/
LOGFILE=~/Desktop/script_logs.txt
NULL=/dev/null
. /etc/os-release
. nginx.template


if [[ $ID_LIKE == "debian" ]]; then
	echo "Running on Debian-family distro. Executing main code..."
else
	echo "This script is designed to run only on Debian-family distro only!"
	exit 1
fi


touch $LOGFILE #Creating a log file


#Writing a new Main function

function main(){

    while getopts "i d:u:" opt; do
        case $opt in
            d)
                domain="$OPTARG"
                if [[ -z "$domain" ]]; then
                    echo "Syntax error: Missing Argument -d <domain>"
                else
                    configure_vh "$domain"
                fi
                ;;
            i)
                install_nginx
                ;;
	    u)
		domain="$OPTARG"
		if [[ -z "$domain" ]]; then
		    echo "Syntax error: Missing Argument -u <domain>"
                else
                    enable_user_dir "$domain"
		fi
		;;
	    a)
                domain="$OPTARG"
                if [[ -z "$domain" ]]; then
                    echo "Syntax error: Missing Argument -a <domain>"
                else
                    auth "$domain"
                fi
                ;;
	    p)
		domain="$OPTARG"
                if [[ -z "$domain" ]]; then
                    echo "Syntax error: Missing Argument -p <domain>"
                else
                    create_pam "$domain"
                fi
                ;;


        esac
    done


function install_nginx(){
    
    tool_list=("nginx" "nginx-extras")
    for tool in ${tool_list[@]}; do
        if ! dpkg -s $tool &>$NULL; then
            echo "Installing $tool..."
            if ! sudo apt-get install $tool -y >> $LOGFILE 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to install $tool" >> "$LOGFILE"
            echo -e "Failed to install package named: $tool\
            \nExisting Script..."
            return 1
            fi

        else
            echo "$tool is already installed."
        fi
    done
    return 0
}


function configure_vh(){

    sudo touch $SITES_AVAILABLE/$domain
    eval "echo \"$domain_conf\"" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    sudo ln -s $SITES_AVAILABLE/$domain $SITES_ENABLED
    sudo mkdir /var/www/$domain
    echo "127.0.0.130 $domain" | sudo tee -a /etc/hosts > $NULL
    sudo systemctl restart nginx
    if curl -I http://$domain; then
        return 0
    else
        echo "Something went wrong"
	return 1
    fi
}


function enable_user_dir(){

    if sudo mkdir /home/$USER/public_html; then
        echo "Created a public_html dir!"
    else
        echo "Dir already exists"
    fi    
    echo "Hello from $USER!" | sudo tee /home/$USER/public_html/index.html
    eval "echo \"$user_dir_conf\"" | sudo tee -a $SITES_AVAILABLE/$SERVER_NAME > $NULL
    sudo systemctl restart nginx
    sudo chmod +x /home/$USER
    sudo chmod 755 /home/$USER/public_html
        if curl -I http://$domain/~$USER; then
            return 0
	else
	    echo "Something Went Wrong"
	    return 1
        fi
}


function auth(){
    
    if  sudo apt-get install apache2-utils -y; then
        read -rp "Please enter a username: " username
        sudo htpasswd -c /etc/nginx/.htpasswd $username

        eval "echo \"$auth_conf\"" | sudo tee $SITES_AVAILABLE/$domain > $NULL
        sudo systemctl restart nginx
        curl -u $username:password -I http://$domain/secure
        if [ $? -eq 0 ]; then
            echo "Username and Password created successfully!"
	    return 0
        else
            echo "Something Went Wrong..."
	    return 1
        fi
     fi

}


function create_pam(){

    if sudo apt-get install libpam0g-dev libpam-modules -y; then
        echo "Pam Installed correctly!"
	return 0
    else
        echo "Failed to install PAM"
        return 1
    fi
    eval "echo \"$pam_conf\"" | sudo tee $SITES_AVAILABLE/$domain > $NULL
    echo "auth required pam_unix.so account required pam_unix.so"| sudo tee -a /etc/pam.d/nginx
    sudo usermod -aG shadow www-data
    sudo mkdir /var/www/html/auth-pam
    echo "$html_template" | sudo tee /var/www/html/auth-pam/index.html > $NULL
    sudo systemctl restart nginx
}


    echo -e "======================================================\
    \nPlease chose your desired option\
    \n install nginx: '-i'\
    \n Configure new VH: '-d <domain_name>'\
    \n Create a public html folder: '-u <domain_name>\
    \n Create an authentication using htpasswd: '-a <domain_name>\
    \n Create an authentication using PAM: '-p <domain_name>\
    \n======================================================"

main $@

















