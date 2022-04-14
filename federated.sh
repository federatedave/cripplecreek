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

apt-get -y -qq install sudo ufw fail2ban htop curl

adduser --disabled-password --gecos "" $USERNAME
usermod -aG sudo $USERNAME

echo "$USERNAME:$password" | sudo chpasswd

  echo -e
  echo -e 'Adding SSH Keys'
  while true; do
    read < /dev/tty -rp 'Enter SSH Key [Paste in key, or enter to skip or finish adding keys]: ' sshKey
    if [[ -z "$sshKey" ]]; then
      break
    fi
    if [[ ! -d '/home/$USERNAME/.ssh' ]]; then
      mkdir -p /home/$USERNAME/.ssh
    fi
    touch /home/$USERNAME/.ssh/authorized_keys
    echo -e "$sshKey" >>/home/$USERNAME/.ssh/authorized_keys
    echo -e 'Saved SSH Key\n'
  done

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
echo -e 'Finished initial machine setup script.'
exit 0