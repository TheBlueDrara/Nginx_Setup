# 🧈 Butter My Nginx — Easy, Automated Web Server Deployment

## A Bash script to deploy an Nginx web server effortlessly

This script helps you spin up a web server with just a single command. Whether you want a quick HTTP server or a secure HTTPS site with authentication and user directories — this tool does it all.

---

### 📝 Features

- Automatically installs and configures Nginx
- Choose between HTTP or HTTPS with automatic SSL certificate creation
- Create a public user directory for personalized content
- Enable basic authentication using `htpasswd`
- Or do all of the above at once – fully automated!
- Configures your web server using sourced configuration templates
- Saves logs in the users /Home directory
---

### 🚀 Usage

```bash
sudo bash nginx.sh [options]
```

You can run the script with no options to deploy a default HTTP server at `127.0.0.1` with the domain `Banana.com`.

---

### 🛠️ Options

| Flag | Long Option     | Description                                               |
|------|------------------|-----------------------------------------------------------|
| `-d` | `--domain`       | Set domain IP and name: `<IP_address> <domain_name>`     |
| `-s` | `--ssl`          | Enable HTTPS with auto-generated SSL certificate         |
| `-u` | `--user-dir`     | Create a public directory: `<directory_name>`            |
| `-a` | `--auth`         | Enable basic authentication using htpasswd               |
| `-p` | `--pam-auth`     | Enable PAM auth *(currently not supported)*              |
| `-c` | `--cgi`          | Enable CGI support *(currently not supported)*           |
| `-h` | `--help`         | Display script help information                          |

---

### 🔧 Prerequisites

- Root or `sudo` privileges  
- Debian-based Linux distribution  
- Bash shell installed  
- Template files stored in `./templates/*.tmpl`  

---

### 🧑‍💻 Contributors

See the full list of contributors in [here](CONTRIBUTORS.md)

---

### 📋 Task Tracking

Project tasks are documented in [here](TASK.md)

---

### ⚙️ Dev Notes

- The script uses modular Bash functions
- Color-coded logging that is saved in the users /Home directory in a file named "nginx_script_logs"
- You can extend it with your own `.tmpl` configuration blocks inside the `templates` directory.
- For the machine god!

---

### ⚔️ Daily Warhammer 40K Quote

```
To break faith with the Omnissiah is to embrace oblivion.
The soulless cog is cast aside; the rusted gear is melted down.
Praise the Machine God, or be discarded as scrap.
```


