# 🚀 Nginx Configuration Task

Create a shell script that sets up the following optional Nginx features:

- 🏠 **User Public Directory** (`user_dir`)
- 🔐 **Basic Authentication**
- 🧩 **PAM-based Authentication**
- ⚙️ **CGI Scripting Support**

---

### ✅ Objectives

- 📦 **Verify Nginx Installation**  
  Ensure Nginx is installed; if not, prompt or install it.

- 🌐 **Check Virtual Host Configuration**  
  Confirm that a virtual host is configured. If not, prompt for a domain name and configure it.

- 🔍 **Check & Install Dependencies**  
  Verify that required packages for `user_dir`, `auth`, and `CGI` are present. Install missing dependencies automatically.

- 🧰 **Support for Arguments & Flags**  
  Implement a flexible argument-based system to configure each feature individually or in combination via command-line flags.

---

This script should be modular, reusable, and user-friendly. Bonus points for adding colorful logging and help menus!

[Link](https://gitlab.com/vaiolabs-io/nginx-shallow-dive)

