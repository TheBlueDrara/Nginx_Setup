# Butter my Nginx


## A script to deploy an nginx web server with ease

This script will make the set-up of an nginx web server easy 😎

### 📝Features

- Choose between HTTP or HTTPS with SSL certificate creation

- Create a public user directory

- Enable basic authentication using htpasswd

- Or do all of the above at once – fully automated!

### 🚀 Usage

```
sudo bash nginx.sh -d '<domain_IP> <domain_name>' -u <public_directory_name> -a -s
```

### 🛠️ Options:

| Flag | Description |
|------|-------------|
| `-d '<domain_IP> <domain_name>'` | Specifies the domain IP and domain name (Required)|
| `-s` | Enables SSL and creates a certificate |
| `-u <Public_Directory_name>` | Sets up the user’s public directory |
| `-a` | Enables basic authentication with htpasswd |


## 🔧 Prerequisites
- Root or sudo privileges
- A Debian-based Linux distribution
- Bash shell installed

### 📋Task
You can find the Contributors [here](CONTRIBUTORS.md)

### 🧑‍💻Contributors 
You can see the Task [here](TASK.md)


#### Daily WarHammer40K quote

```
To break faith with the Omnissiah is to embrace oblivion.
The soulless cog is cast aside; the rusted gear is melted down.
Praise the Machine God, or be discarded as scrap.
```
