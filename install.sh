!/bin/bash

# Machine Setup Script by Federated Computer, Inc.

echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'
echo -e '#    Let's Federate This Machine      #'
echo -e '# ## ## ## ## ## ## ## ## ## ## ## ## #'

echo -e
date

# override locale to eliminate parsing errors (i.e. using commas a delimiters rather than periods)
export LC_ALL=C

cancel() {
  echo -e
  echo -e " Aborted..."
  exit
}

init() {
  # check release
  if cat /etc/issue | grep -Eqi "debian"; then
      RELEASE="debian"
  elif cat /etc/issue | grep -Eqi "ubuntu"; then
      RELEASE="ubuntu"
  elif cat /proc/version | grep -Eqi "debian"; then
      RELEASE="debian"
  elif cat /proc/version | grep -Eqi "ubuntu"; then
      RELEASE="ubuntu"
  fi
}

trap cancel SIGINT

while getopts 'ah' flag; do
  case "${flag}" in
  a) AUTO="True" ;;
  h) HELP="True" ;;
  *) exit 1 ;;
  esac
done

if [[ -n $HELP ]]; then
  echo -e
  echo -e "Usage: ./setup.sh [-mh]"
  echo -e "       curl -sL github.com/federatedave/cripplecreek/setup.sh | sudo bash"
  echo -e "       curl -sL github.com/federatedave/cripplecreek/setup.sh | sudo bash -s --{ah}"
  echo -e
  echo -e "Flags:"
  echo -e "       -a : run setup script automatically"
  echo -e "       -h : prints this lovely message, then exits"
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

init

echo -e 'Updating system...'

apt-get update -y -qq && apt-get upgrade -y -qq


echo -e
DISABLE_ROOT="Y"
DISABLE_PASSWORD_AUTH="Y"
INSTALL_BASIC_PACKAGES="Y"
INSTALL_DOCKER="Y"
INSTALL_DOCKER_COMPOSE="Y"
TIMEZONE="America/Denver"
USERNAME="federated"
ADD_NEW_USER="Y"
INSTALL_ZSH="Y"
if [ -z "$AUTO" ]; then
    read < /dev/tty -p 'Install basic packages? [y/N]: ' INSTALL_BASIC_PACKAGES
    read < /dev/tty -p 'Add Sudo User? [y/N]: ' ADD_NEW_USER
    read < /dev/tty -p 'Disable Root Login? [y/N]: ' DISABLE_ROOT
    read < /dev/tty -p 'Disable Password Authentication? [y/N]: ' DISABLE_PASSWORD_AUTH
    read < /dev/tty -p 'Install zsh and oh-my-zsh? [y/N]: ' INSTALL_ZSH
    read < /dev/tty -p 'Install Docker? [y/N]: ' INSTALL_DOCKER
    read < /dev/tty -p 'Install Docker Compose? [y/N]: ' INSTALL_DOCKER_COMPOSE
    read < /dev/tty -p 'Enter your TIMEZONE [Empty to skip]: ' TIMEZONE
    read < /dev/tty -p 'Enter any other packages to be installed [Empty to skip]: ' packages
fi

if [[ "$INSTALL_BASIC_PACKAGES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  # Install basic packages
  echo -e
  echo -e 'Installing Basic Packages: sudo ufw fail2ban htop curl apache2 git certbot python3-certbot-dns-cloudflare autojump'

apt-get -y -qq install sudo ufw fail2ban htop curl apache2 tmux git certbot python3-certbot-dns-cloudflare autojump

fi

if [[ "$ADD_NEW_USER" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  echo -e 'Setting sudo user...'
  read < /dev/tty -rp 'Username: ' USERNAME
  echo -n 'Password: '
  read < /dev/tty -rs password
  if [[ "$RELEASE" == "centos" ]]; then
    adduser $USERNAME
    usermod -aG wheel $USERNAME
  else
    adduser --disabled-password --gecos "" $USERNAME
    usermod -aG sudo $USERNAME
  fi
  echo "$USERNAME:$password" | sudo chpasswd

  echo -e
  echo -e 'Adding SSH Keys'
  while true; do
    read < /dev/tty -rp 'Enter SSH Key [Empty to skip]: ' sshKey
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
fi

if [[ "$DISABLE_ROOT" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  echo -e 'Disabling Root Login...'
  sed -i '/PermitRootLogin yes/c\PermitRootLogin no' /etc/ssh/sshd_config
fi
if [[ "$DISABLE_PASSWORD_AUTH" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  echo -e 'Disabling Password Authentication...'
  sed -i '/PasswordAuthentication yes/c\PasswordAuthentication no' /etc/ssh/sshd_config
fi
systemctl restart sshd

if [[ -n $TIMEZONE ]]; then
  echo -e
  echo -e 'Setting Timezone...'
  timedatectl set-timezone $TIMEZONE
fi

if [[ "$INSTALL_ZSH" =~ ^([yY][eE][sS]|[yY])$  ]]; then
  echo -e
  if [[ -z "$(command -v zsh)" ]]; then
    echo -e 'Installing zsh and ohmyzsh...'
    if [[ "$RELEASE" == "centos" ]]; then
      yum -y -q install zsh git
    else
      apt-get -y -qq install zsh git
    fi
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
fi

# Install Docker
if [[ "$INSTALL_DOCKER" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  if [[ -z "$(command -v docker)" ]]; then
    curl -fsSL https://get.docker.com | bash
  fi
  usermod -aG docker $USERNAME
  echo -e "Docker Installed. Added $USERNAME to docker group"
fi
if [[ "$INSTALL_DOCKER_COMPOSE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e
  if [[ -z "$(command -v docker-compose)" ]]; then
    curl -L "https://github.com/docker/compose/releases/download/v2.3.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi
  echo -e "Docker Compose Installed."
fi

if [[ -n $packages ]]; then
  echo -e
  echo -e "Installing $packages ..."
  if [[ "$RELEASE" == "centos" ]]; then
    yum -y -q install $packages
  else
    apt-get -y -qq install $packages
  fi
fi

# reset locale settings
unset LC_ALL

echo -e
echo -e 'Finished setup script.'
exit 0