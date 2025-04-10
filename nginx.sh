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



#Writing a new Main function using OPTARG

function main(){

    while getopts "i:d:" opt; do
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
        esac
    done





function install_nginx(){
    
    tool_list=("nginx" "nginx-extras")
    for tool in ${tool_list[@]}; do
        if ! dpkg -s $tool &>$NULL; then
            echo "Installing $tool..."
            touch $LOGFILE
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
    echo "$domain_conf" | sudo tee -a $SITES_AVAILABLE/$domain > $NULL
    sudo ln -s $SITES_AVAILABLE/$domain $SITES_ENABLED
    sudo mkdir /var/www/$domain
    echo "127.0.0.130 $domain" | sudo tee -a /etc/hosts
    sudo systemctl restart nginx
    if curl -I http://$domain; then
        echo "Congrtz!"
    else
        echo "Fail"
    fi
    main
}


function enable_user_dir(){

    if sudo mkdir /home/$USER/public_html; then
        echo "Created a public_html dir!"
    else
        echo "Dir already exists"
    fi    
    echo "Hello from $USER!" | sudo tee /home/$USER/public_html/index.html
    sudo tee $SITES_AVAILABLE/$SERVER_NAME >/dev/null << EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    root /var/www/$SERVER_NAME;

    index index.html;

    location ~ ^/~(.+?)(/.*)?$ {
        alias /home/\$1/public_html\$2;
        index index.html;
    }
}
EOF
    sudo systemctl restart nginx
    sudo chmod +x /home/$USER
    sudo chmod 755 /home/$USER/public_html
        if curl -I http://$SERVER_NAME/~$USER; then
            echo "Congrtz!"
        fi
    main
}


function auth(){
    
    if sudo apt-get update && sudo apt-get install apache2-utils -y; then
        read -rp "Please enter a username: " USERNAME
        sudo htpasswd -c /etc/nginx/.htpasswd $USERNAME

        sudo tee $SITES_AVAILABLE/$SERVER_NAME >/dev/null << EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    root /var/www/$SERVER_NAME;

    index index.html;

location /secure {
    auth_basic "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd; 
    }
}
EOF
        sudo systemctl restart nginx
        curl -u $USERNAME:password -I http://$SERVER_NAME/secure
        if [ $? -eq 0 ]; then
            echo "Username and Password created successfully!"
        else
            echo "Failed"       
        fi
     fi
    main

}


function create_pam(){

    if sudo apt-get update && sudo apt-get install libpam0g-dev libpam-modules; then
        echo "Pam Installed correctly!"
    else
        echo "Failed"
        return 1
    fi

    sudo tee $SITES_AVAILABLE/$SERVER_NAME >/dev/null <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    root /var/www/$SERVER_NAME;

    index index.html;

    location /auth-pam {
        auth_pam "PAM Authentication";
        auth_pam_service_name "nginx";
    }
}
EOF
    echo "auth required pam_unix.so account required pam_unix.so"| sudo tee -a /etc/pam.d/nginx
    sudo usermod -aG shadow www-data
    sudo mkdir /var/www/html/auth-pam
    sudo tee /var/www/html/auth-pam/index.html >/dev/null << EOF
<html>
    <body>
        <div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
            Test Page for PAM Auth
        </div>
    </body>
</html>
EOF
    sudo systemctl restart nginx
    main
}





    echo -e "======================================================\
    \nPlease chose your desired option\
    \na) install nginx\
    \nb) Configure new VH\
    \nc) Create a public html folder\
    \nd) Create an authentication using htpasswd\
    \ne) Create an authentication using PAM\
    \n*) Exit\
    \n======================================================"

main $@

















