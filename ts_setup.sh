#!/bin/bash

cd ~/
mkdir teamsnap
ROOT_DIR=~/teamsnap

if [[ -z $GITHUB_OAUTH_TOKEN ]]; then
  open https://github.com/teamsnap/apiv3#github-personal-access-token-for-bundle
  read -p "Enter your github oauth token: " GITHUB_TOKEN
  echo "export GITHUB_OAUTH_TOKEN=${GITHUB_TOKEN}" >> ~/.bash_profile
fi

if type xcode-select> /dev/null 2>&1; then
  echo "xcode already installed. Skipping."
else
  exit 1
fi

xcode-select --install

if type docker > /dev/null 2>&1; then
  echo "Docker already installed. Skipping."
else
  open https://store.docker.com/editions/community/docker-ce-desktop-mac
  exit 1
fi

docker logout

if type brew >/dev/null 2>&1; then
  echo "Brew already installed. Skipping."
else
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update
brew upgrade
brew install gnupg gnupg2 imagemagick libxml2 libxslt wget npm node

brew install mysql
brew link mysql --force

echo "Installing Java"
brew cask install java

# Switch to using brew-installed bash as default shell
brew install bash
brew install bash-completion2
if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
  chsh -s /usr/local/bin/bash;
fi

# Add `~/bin` to the `$PATH`
echo 'export PATH="$PATH:/usr/local/bin:/usr/local/sbin:/bin:/sbin:$HOME/bin";' >> ~/.bash_profile
echo 'export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/' >> ~/.bash_profile

if type rbenv >/dev/null 2>&1; then
  echo "Rbenv already installed. Skipping."
else
  brew install rbenv ruby-build
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  source ~/.bash_profile
  rbenv init
  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
fi

brew cleanup
source ~/.bash_profile

# All core apps are now running on docker and do not need local rubies
# Classic depends on ruby 2.1.2
# rbenv install 2.1.2 
# rbenv install 2.3.1
# jext-jenn-web depends on ruby 2.3.3
# rbenv install 2.3.3
# rbenv install 2.3.8

source ~/.bash_profile
cd $ROOT_DIR

git clone git@github.com:teamsnap/docker-core-services.git
git clone git@github.com:teamsnap/ecco.git
git clone git@github.com:teamsnap/apiv3.git
git clone git@github.com:teamsnap/classic.git
git clone git@github.com:teamsnap/cogsworth.git
git clone git@github.com:teamsnap/nextjenn-web.git
git clone git@github.com:teamsnap/mcfeely.git
git clone git@github.com:teamsnap/dozer.git

echo "Setting up TS CLI...."
git clone git@github.com:teamsnap/ts_cli.git
cd ts_cli
./bin/ts_setup.sh
source ~/.bash_profile

which ts
read -p "Confirm which ts returned /YOUR/TEAMSNAP/PATH/ts_cli/bin/ts (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then

  echo 'export DOCKER_ENABLED=true' >> ~/.bash_profile
  echo "Setting up Core Services...."
  cd docker-core-services
  ts setup
  docker network create dockercoreservices_default
  ts start

  echo "Setting up ApiV3..."
  cd ../apiv3
  ts setup

  echo "Setting up Classic..."
  cd ../classic
  ts setup

  echo "Setting up DB..."
  cd ../ecco
  ts setup

  echo "Setting up Cogsworth..."
  cd ../cogsworth
  ts setup

  echo "Setting up NJW"
  cd ../nextjenn-web
  ts setup

  echo "Installing mcfeely...."
  cd ../mcfeely
  ts setup
 
  echo "Installing dozer...."
  cd ../dozer
  ts setup
 
 cd $ROOT_DIR

  echo "Done. Navigate to each project and run ts start for dockerized applications"
fi

echo "Follow the instructions at https://github.com/teamsnap/ts_cli to fix ts_cli before proceeding"
