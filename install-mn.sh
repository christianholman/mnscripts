#!/bin/sh
#Version 0.1.0
#Chaincoin Version 0.9.3 or above
#TODO: make script less "ubuntu" or add other linux flavors
#TODO: remove dependency on sudo user account to run script (i.e. run as root and specifiy chaincoin user so chaincoin user does not require sudo privileges)
#TODO: add proper install path rather than defaulting
#TODO: add specific dependencies depending on build option (i.e. gui requires QT4)

noflags() {
	echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
    echo "Usage: install-mn [options]"
    echo "Valid options are:"
    echo "-gui" #can prolly change this for something more interesting i.e. desktop, master node, etc.
    echo "-nogui" #this too
    echo "Do not provide more than one option."
    echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
    exit 1
}

message() {
	echo "╒════════════════════════════════════════════════════════════════════════════════>>"
	echo "| $1"
	echo "╘════════════════════════════════════════════<<<"
}

error() {
	message "An error occured, you must fix it to continue!"
	exit 1
}

success() {
	message "SUCCESS! You can now edit your ~/.chaincoin/chaincion.conf file with the correct values and then run chaincoind"
	exit 0
}

prepdependencies() { #TODO: add error detection
	message "Installing dependencies..."
	sudo apt-get update
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
	sudo apt-get install automake libdb++-dev build-essential libtool autotools-dev autoconf pkg-config libssl-dev libboost-all-dev libminiupnpc-dev git software-properties-common python-software-properties g++ bsdmainutils libevent-dev -y
	sudo add-apt-repository ppa:bitcoin/bitcoin -y
	sudo apt-get update
	sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
}

createswap() { #TODO: add error detection
	message "Creating 2GB temporary swap file...this may take a few minutes..."
	sudo dd if=/dev/zero of=/swapfile bs=1M count=2000
	sudo mkswap /swapfile
	sudo chown root:root /swapfile
	sudo chmod 0600 /swapfile
	sudo swapon /swapfile
}

clonerepo() { #TODO: add error detection
	message "Cloning from github repository..."
  	cd ~/
	git clone https://github.com/chaincoin/chaincoin.git
}

compile() {
	cd chaincoin #TODO: squash relative path
	message "Preparing to build..."
	./autogen.sh
	if [ $? -ne 0 ]; then error; fi
	message "Configuring build options..."
	./configure $1 --disable-tests
	if [ $? -ne 0 ]; then error; fi
	message "Building ChainCoin...this may take a few minutes..."
	make
	if [ $? -ne 0 ]; then error; fi
	message "Installing ChainCoin..."
	sudo make install
	if [ $? -ne 0 ]; then error; fi
}

createconf() {
	#TODO: Can check for flag and skip this
	#TODO: Random generate the user and password

	message "Creating chaincoin.conf..."

	CONFDIR=~/.chaincoin
	if [ ! -d "$CONFDIR" ]; then mkdir $CONFDIR; fi
	if [ $? -ne 0 ]; then error; fi

	printf "%s\n" "rpcuser=xxx" "rpcpassword=zzz" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" "maxconnectons=256" "rpcport=11995" "externalip=$mnip" "bind=$mnip" "masternode=1" "masternodeprivkey=REPLACE_WITH_MASTERNODE_PRIVKEY" "masternodeaddr=REPLACE_WITH_MASTERNODE_IP:11994" > $CONFDIR/chaincoin.conf

}

install() {
	createconf
	prepdependencies
	createswap
	clonerepo
	compile $1
	success
}

#main
#default to --without-gui
if [ $1 = "-gui" ]
then
	install
else
	install --without-gui
fi
