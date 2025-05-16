# HomeKit - Shader automation

Skeleton project from [metachris/typescript-boilerplate](https://github.com/metachris/typescript-boilerplate)

Start the device by running `yarn start`

# Raspberry Pi installation (Raspberry W Zero)

- Use preconfigured SD card from https://www.adafruit.com/product/4266
- Enable SSH, set up wifi credentials and update password: [tutorial](https://desertbot.io/blog/setup-pi-zero-w-headless-wifi)
- [Use SSH key instead of password to login](https://serverfault.com/a/2436).
- Git

```bash
sudo apt-get install -y git
git config --global user.email "sabranguillaume@gmail.com"
git config --global user.name "Guillaume Sabran"
```

- Git SSH keys: [add SSH key login](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).
- ZSH

```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "\nexec bash && source ~/.bashrc && exec zsh\n\n" >> ~/.zshrc
```

- Install node & co

```bash
NODE_VERSION=v14.10.0
wget "https://unofficial-builds.nodejs.org/download/release/$NODE_VERSION/node-$NODE_VERSION-linux-armv6l.tar.gz"
tar -xzf node-$NODE_VERSION-linux-armv6l.tar.gz
cd node-$NODE_VERSION-linux-armv6l/
sudo cp -R * /usr/local
cd ../
rm -r node-$NODE_VERSION-linux-armv6l
rm node-$NODE_VERSION-linux-armv6l.tar.gz

# change permissions/ownership to current user
sudo find /usr/local/lib/node_modules -type d -user root -exec sudo chown -R $USER: {} +

# Package manager
sudo npm install --global yarn
# Process manager
sudo npm install --global pm2
pm2 startup
sudo pm2 startup
```

- Python 3

```bash
# change alias to python 3
sudo rm /usr/bin/python
sudo ln -s /usr/bin/python3 /usr/bin/python
ls -l /usr/bin/python
sudo apt-get install python3-pip
```

- VEML 7700 (light sensor)

```bash
# Enable IC2 port
sudo raspi-config
# Manually select > Interface Options > I2C > Enable

# Python package
pip3 install adafruit-circuitpython-veml7700
```

- Servo

```bash
sudo apt-get install pigpio
```

- Repo setup

```bash
mkdir code && cd code && git clone git@github.com:gsabran/homekit-auto-skylight-shader.git
cd homekit-auto-skylight-shader
yarn install

# start
# pm2 is used with sudo as some components (GPIO pins) need sudo permissions to be accessed
yarn build && sudo pm2 start ./dist/tsc/main.js
pm2 start src/veml7700.py --name veml7700-light-measure --interpreter python3
# Log
sudo pm2 logs main
pm2 logs veml7700-light-measure
# stop
sudo pm2 stop all
pm2 stop all

# Update
sudo pm2 stop all && pm2 stop all && \
  cd /home/pi/code/homekit-auto-skylight-shader && \
  git fetch origin main && git add . && git reset origin/main --hard \
  yarn build && \
  sudo pm2 start ./dist/tsc/main.js && \
  pm2 start src/veml7700.py --name veml7700-light-measure --interpreter python3 && \
  sudo pm2 save && pm2 save
```

## Remove development

- Install [Sync-Rsync](https://marketplace.visualstudio.com/items?itemName=vscode-ext.sync-rsync)
