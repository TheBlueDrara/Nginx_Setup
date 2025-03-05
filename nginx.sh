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
SITES_ENABLED="/etc/nginx/sites-enabled"

function main(){
    while true; do
    echo "======================================================"
    echo "Please chose your desired option"
    echo -e "a) install nginx"
    echo -e "b) Check if VH exist, if not, configure your own"
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

    if ! dpkg -l |grep -E '^\s*ii\s+nginx' > /dev/null; then
        MISSING_PACKAGES+="nginx "
    fi

    if ! dpkg -l |grep -E '^\s*ii\s+nginx-extras' > /dev/null; then
        MISSING_PACKAGES+="nginx-extras "
    fi

    if [ -n "$MISSING_PACKAGES" ]; then
        echo "nginx and enginx-extras are already installed..."
    elif
        echo "The following packages are missing: $MISSING_PACKAGES"
        echo "Would you like to install them (yes/no)?"
        read -r PAR1
        [ $PAR1 == "yes" ]; then
        sudo apt-get update && sudo apt-get install -y $MISSING_PACKAGES
        if [ $? -eq 0 ] && echo "Everything installed correctly!" || echo " Failed to install"
        fi
    else
        echo "Goodbye!"  
    fi
    main 
}

function configure_vh(){

    read -rp "Please enter your servers name: " FIND_SERVER
    VHOSTS=$(grep $FIND_SERVER $SITES_AVAILABLE 2>/dev/null)

    if [ -n $VHOSTS ]; then
        echo "Virtual host found:"
        echo $VHOSTS
    else 
        echo "No virtual host found"
    fi

    read -rp "Would you like to create a new VH? (yes/no)?" PAR2
    if [ $PAR2 == "yes" ]; then
    read -rp "Please enter new VH name: " SERVER_NAME
    touch $SITES_AVAIABLE/$SERVER_NAME
    echo "server {
    listen 80;
    server_name $SERVER_NAME;
    root /var/www/$SERVER_NAME;
    index index.html; }" >> $SITES_AVAIABLE/$SERVER_NAME
    ln -s $SITES_AVAILABLE/$SERVER_NAME $SITES_ENABLED
    read -rp "Please enter a header name for yourwebpage" HEADER_NAME
    echo "<h1>$HEADER_NAME</h1>" >> /var/www/$SERVER_NAME2/index.html
    sudo systemctl restart nginx
    curl -I http://$SERVER_NAME
    fi
    main
}

function enable_user_dir(){

    echo 'location ~ ^/~(.+?)(/.*)?$ {
    alias /home/$1/public_html$2; }' >> $SITES_AVAIABLE/default
    sudo systemctl restart nginx
    bash curl -I http://localhost/~$USER
    if [ $? -eq 0 ] && echo "Configured a personal webpage successfully" || echo "Failed"
    fi
    main
}

function auth(){
    
    sudo apt-get update && sudo apt-get install apache2-utils
    read -rp "Please enter a username" USERNAME
    sudo htpasswd -c /etc/nginx/.htpasswd $USERNAME
    echo "location /secure {
    auth_basic "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd; }" >> $SITES_AVAILABLE/$SERVER_NAME
    sudo systemctl restart nginx
    curl -u $USERNAME:password -I http://localhost/secure
    if [ $? -eq 0 ] && echo "Username and Password created successfully!" || echo "Error"
    fi
    main

}

function create_pam(){

    sudo apt-get update && sudo apt-get install libpam0g-dev libpam-modules
    echo "server {
        ...
        ...

       location /auth-pam {
           auth_pam "PAM Authentication";
           auth_pam_service_name "nginx";
       }
}
" >> $SITES_AVAILABLE/$SERVER_NAME
    echo "auth account include include common-auth common-account" >> /etc/pam.d/nginx
    usermod -aG shadow www-data
    systemctl restart nginx
    mkdir /var/www/html/auth-pam
    echo " <html>
    <body>
    <div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
    Test Page for PAM Auth
    </div>
    </body>
    </html>" >> /var/www/html/auth-pam/index.html 
    main

}



# CGI function
main $@


















