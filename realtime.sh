!/bin/bash

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#    Let's Federate This Machine      #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'

echo -e

date

export LC_ALL=C

cancel() {
  echo -e
  echo -e " Aborted..."
  exit
}

init() {
  # check release, need to add break if not ubuntu...
  if cat /etc/issue | grep -Eqi "ubuntu"; then
      RELEASE="ubuntu"
  elif cat /proc/version | grep -Eqi "ubuntu"; then
      RELEASE="ubuntu"
  fi
}

trap cancel SIGINT

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

init

echo -e 'Updating existing system...'

apt-get update -y -qq && apt-get upgrade -y -qq

echo -e
DISABLE_ROOT="Y"
DISABLE_PASSWORD_AUTH="Y"
INSTALL_BASIC_PACKAGES="Y"
TIMEZONE="America/Denver"
USERNAME="federated"
PASSWORD="federated"
ADD_NEW_USER="Y"
SSHKEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHnH7VtPVFxqreal5KQT3nQYWoC/kC0k0lTUHLOJBd+0NZO8q0b61eaQF+xxUAM6j0zlosmShk6JaBHeCtV6VMn0YIPKc53UehI/yEwALBx0XvCXWqsEY8jZnSAaXsHKBE+aP3/MiO0rT8w9UcqEfGj9XtU6vbrFRSGlCxK/sIyACLdgDZ2PAmbhTUJ3KUiSJlt9Zntuc36j2Jw3jBSQ/AldnuE36+jiWS32DnSv9S1kt4BeacZy+mqbJz+m4s9Emmakudwd3aBqfajENQrKJO4vJxHJBtQqW0HF7OlTq2n+3MmLNpZ3nMASecc56bbZj7Kw45OlrVSLkiuDWYaJ5+zPma1i/Z1NPN9qOlLYrgeRn4bUPZNhMn2KbF2AVMViVYC28OPUMKlBSA4dIeCT6cK6WLF0HT7VsrUuWeUSA31d/kyFpvlz60F2YuTUY5vqHY8+7gK/pxSKl3Zd6nXiOvsZ+SQcHZ0AZit5jRVfAFvWO7t7jLuddgDmPujyGGGmk= david@jupiter"

apt-get -y -qq install sudo ufw fail2ban htop curl

adduser --disabled-password --gecos "" $USERNAME
usermod -aG sudo $USERNAME

echo "$USERNAME:$PASSWORD" | sudo chpasswd

echo -e
echo -e 'Adding Federated Key'
mkdir -p /home/$USERNAME/.ssh
touch /home/$USERNAME/.ssh/authorized_keys
echo -e "$SSHKEY" >>/home/$USERNAME/.ssh/authorized_keys
echo -e 'Saved Federated Key\n'

echo -e
echo -e 'Disabling Root Login...'
sed -i '/PermitRootLogin yes/c\PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/#PermitRootLogin prohibit-password/c\PermitRootLogin no' /etc/ssh/sshd_config

echo -e
echo -e 'Disabling Password Authentication...'
sed -i '/PasswordAuthentication yes/c\PasswordAuthentication no' /etc/ssh/sshd_config

systemctl restart sshd

echo -e
echo -e 'Setting Timezone...'
timedatectl set-timezone $TIMEZONE

unset LC_ALL

echo -e
echo -e 'Finished realtime machine setup script. That was easy.'

echo -e
echo -e 'Setting up matrix and jitsi'

#curl -s https://mailinabox.email/setup.sh | sudo bash

echo -e
echo -e 'Done.'

exit 0