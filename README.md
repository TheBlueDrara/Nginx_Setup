# Butter my Nginx

## A script to deploy an nginx web server with ease

This script will make the set-up of an nginx web server easy 😎

### 📝Features

- Choose if the web server is HTTP or HTTPS based with SSL certificate creation.
- Create Public User directory
- Create Authentcation using htpasswd
- Do all the thing above all togther


### 🚀 Usage


```
sudo bash nginx.sh -d '<domain IP address> <domain name> -u <public_directory_name> -a -s
```

### 🛠️ Options:

| Flag | Description |
|------|-------------|
| `-d '<domain_IP__address> <domain_name>'` | Specifies the domain name and address (Required). |
| `-s` | Enables SSL and Creates Certification. |
| `-u <Public_Directory_name>` | Sets up user directory configuration. |
| `-a` | Enables basic authentication. |


## 🔧 Prerequisites
- Root or Sudo user
- Debian Family based distrobution
- Bash shell installed


### You can find the contributors here:

[Contributors](CONTRIBUTORS.md)


### You can see the task here:

[Task](TASK.md)



#### Daily WarHammer40K quote

```
To break faith with the Omnissiah is to embrace oblivion.
The soulless cog is cast aside; the rusted gear is melted down.
Praise the Machine God, or be discarded as scrap.
```
