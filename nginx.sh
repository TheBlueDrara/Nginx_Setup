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
    main
}


function configure_vh(){

    read -rp "Please enter new VH name: " SERVER_NAME
    sudo touch $SITES_AVAILABLE/$SERVER_NAME
    sudo tee $SITES_AVAILABLE/$SERVER_NAME >/dev/null << EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    root /var/www/$SERVER_NAME;

    index index.html;
    }
EOF

    sudo ln -s $SITES_AVAILABLE/$SERVER_NAME $SITES_ENABLED
    sudo mkdir /var/www/$SERVER_NAME
    read -rp "Please enter a header name for your webpage: " HEADER_NAME
    echo "<h1>$HEADER_NAME</h1>" | sudo tee /var/www/$SERVER_NAME/index.html > /dev/null
    echo "127.0.0.80 $SERVER_NAME" | sudo tee -a /etc/hosts
    sudo systemctl restart nginx
    if curl -I http://$SERVER_NAME; then
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

    index index.html

    location /auth-pam {
        auth_pam "PAM Authentication";
        auth_pam_service_name "nginx";
    }
}
EOF
    sudo echo "auth account include include common-auth common-account" >> /etc/pam.d/nginx
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



# CGI function
main $@


















