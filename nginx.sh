#!/usr/bin/env bash
################################### Start Safe Header ##########################
#Developed by Alex Umansky aka TheBlueDrara
#Porpuse 
#Date 1.3.2025
set -o nounset
set -o errexit
set -o pipefail
################################## End Safe Header ############################
SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled/"

function main(){

    while true; do
    echo "======================================================"
    echo "Please chose your desired option"
    echo -e "a) install nginx"
    echo -e "b) Configure new VH"
    echo -e "c) Create a public html folder"
    echo -e "d) Create an authentication using htpasswd"
    echo -e "e) Create an authentication using PAM"
    echo -e "*) Exit"
    echo "======================================================"
    
    read -p "Enter your choice: " OPT
        case $OPT in
            a) install_nginx ;;
            b) configure_vh ;;
            c) enable_user_dir ;;
            d) auth ;;
            e) create_pam ;;
            *) echo "Existing"; exit 0 ;;
        esac
    done
}


function install_nginx(){
    
    MISSING_PACKAGES=()
    if ! dpkg -l |grep -E '^\s*ii\s+nginx' > /dev/null; then
        MISSING_PACKAGES+=("nginx")
    fi

    if ! dpkg -l |grep -E '^\s*ii\s+nginx-extras' > /dev/null; then
        MISSING_PACKAGES+=("nginx-extras")
    fi

    if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
        echo "nginx and enginx-extras are already installed..."

    elif [ ${#MISSING_PACKAGES[@]} -gt 0 ] ; then
        echo "The following packages are missing: $MISSING_PACKAGES"
        read -rp "Would you like to install (yes/no) " PAR1
            if [ $PAR1 == "yes" ]; then
                if sudo apt-get update && sudo apt-get install -y $MISSING_PACKAGES; then
                    echo "installed successfully"
                else
                   echo "Failed"
                fi
            fi

    else
        echo "Good bye"
    fi 
}


function configure_vh(){

    read -rp "Please enter new VH name: " SERVER_NAME
    sudo touch $SITES_AVAILABLE/$SERVER_NAME
VH_CONFIG="
server {
    listen 80;
    server_name $SERVER_NAME;
    root /var/www/$SERVER_NAME;

    index index.html; 
}
"
    echo $VH_CONFIG >> $SITES_AVAILABLE/$SERVER_NAME
    ln -s $SITES_AVAILABLE/$SERVER_NAME $SITES_ENABLED
    read -rp "Please enter a header name for yourwebpage" HEADER_NAME
    echo "<h1>$HEADER_NAME</h1>" >> /var/www/$SERVER_NAME2/index.html
    sudo systemctl restart nginx
    if curl -I http://$SERVER_NAME; then
        echo "Congrtz!"
    else
        echo "Fail"
    fi

    main
}


function enable_user_dir(){

USER_DIR_CONFIG="
location ~ ^/~(.+?)(/.*)?$ {
    alias /home/$1/public_html$2;
}
"
    echo $USER_DIR_CONFIG >> $SITES_AVAILABLE/default
    sudo systemctl restart nginx
        if bash curl -I http://localhost/~$USER; then
            echo "Congrtz!"
        fi
    main
}


function auth(){
    
    if sudo apt-get update && sudo apt-get install apache2-utils; then
        read -rp "Please enter a username" USERNAME
        sudo htpasswd -c /etc/nginx/.htpasswd $USERNAME

AUTH_CONFIG="
location /secure {
    auth_basic "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd; 
}
" 
        echo $AUTH_CONFIG >> $SITES_AVAILABLE/$SERVER_NAME
            sudo systemctl restart nginx
            curl -u $USERNAME:password -I http://localhost/secure
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

PAM_CONFIG="
server {
    ...
    ...

    location /auth-pam {
        auth_pam "PAM Authentication";
        auth_pam_service_name "nginx";
    }
}
"
    echo $PAM_CONFIG >> $SITES_AVAILABLE/$SERVER_NAME
    echo "auth account include include common-auth common-account" >> /etc/pam.d/nginx
    usermod -aG shadow www-data
    systemctl restart nginx
    mkdir /var/www/html/auth-pam

PAM_HTML="
<html>
    <body>
        <div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
            Test Page for PAM Auth
        </div>
    </body>
</html>
"
    echo $PAM_HTML >> /var/www/html/auth-pam/index.html 
    main
}



# CGI function
main $@


















