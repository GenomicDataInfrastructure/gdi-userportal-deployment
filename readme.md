# ckan-gdi
Deployment notes for CKAN (based on https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/tree/user-portal-main) assuming RHEL-based Linux distribution.
The docker-compose file has been manually modified so that the deployment includes ckan.ini from this directory.

# Preparatory steps on the VM
```
# Install some tools
sudo dnf install git 

# Install, start and enable Docker
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

# You can also [create a user](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/4/html/system_administration_guide/s2-users-add)
# And [add her to a docker group](https://docs.docker.com/engine/install/linux-postinstall/) so that docker can be run without sudo.

# Configure firewall
firewall-cmd --permanent --zone=public --add-port=8443/tcp
# If you intend to run a reverse proxy on the machine as well, ensure 80/443 are open and nginx is configured to proxy connection to port 8443.
```

# Installation
```
# Prepare the project files
mkdir -p /srv
cd /srv
git clone https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker.git
cd gdi-userportal-ckan-docker/
git checkout user-portal-main
cp .env.example .env

# Replace docker-compose.yml with the file provided in this repository
# Place ckan.ini
```

# Configuration
Check ckan.ini file, fill .env values

# Running
```
sudo su
cd /srv/gdi-userportal-ckan-docker/
docker compose up -d
```