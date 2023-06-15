#!/bin/bash 
set -xe
#if [[ $EUID -ne 0 ]]; then
#    echo "This script must be run as root"
#    exit 1
#fi
cat /etc/redhat-release 
# Red Hat Enterprise Linux release 8.7 (Ootpa)
sudo yum -y install bzip2-devel libffi-devel openssl-devel make zlib-devel perl ncurses-devel sqlite sqlite-devel python3 python3-devel
sudo yum groupinstall "Development Tools" -y
openssl version
function configure_python() {
    echo "Configuring Python"
    echo "******************"
    if which python3.11  >/dev/null; then
        echo "Python is installed"
        exit 0 
    else
        PYDIR=$HOME/opt/
        export PATH=$PYDIR/bin:$PATH
        export CPPFLAGS="-I$PYDIR/include $CPPFLAGS"

        mkdir -p $PYDIR/src
        cd $PYDIR/src

        # openssl
        if [ ! -f $PYDIR/src/openssl-1.1.1t.tar.gz ]; then
            wget https://www.openssl.org/source/openssl-1.1.1t.tar.gz
            tar xvf openssl-1.1.1t.tar.gz
        fi

        cd openssl-1.1*/
        ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
        sudo make
        sudo make install
#        sudo ldconfig
#        sudo tee /etc/profile.d/openssl.sh<<EOF
#export PATH=/usr/local/openssl/bin:\$PATH
#export LD_LIBRARY_PATH=/usr/local/openssl/lib:\$LD_LIBRARY_PATH
#EOF
#        source /etc/profile.d/openssl.sh
#        which openssl
        openssl version
        cd ..
        # python
        if [ ! -f $PYDIR/src/Python-3.11.2.tar.xz ]; then
            wget https://www.python.org/ftp/python/3.11.2/Python-3.11.2.tar.xz
            tar xf Python-3.11.2.tar.xz
        fi

        cd Python-3.11.2
        sudo mkdir -p  /usr/lib64/Python-3.11.2
        ./configure  --prefix=/usr/lib64/Python-3.11.2 --enable-loadable-sqlite-extensions --enable-optimizations
        sudo make
        sudo make altinstall
        ls -lath /usr/lib64/Python-3.11.2
        whereis python3

        sudo rm -rf /usr/bin/python3
        sudo cp /usr/lib64/Python-3.11.2/bin/python3.11 /usr/local/bin/python3.11
        sudo cp /usr/lib64/Python-3.11.2/bin/python3.11 /usr/bin/python3.11
        sudo ln /usr/local/bin/python3.11 /usr/local/bin/python3
        sudo ln /usr/local/bin/python3.11 /usr/bin/python3
        sudo cp /usr/lib64/Python-3.11.2/bin/pip3.11 /usr/local/bin/pip3.11
        sudo rm -rf /usr/bin/pip3
        sudo ln /usr/lib64/Python-3.11.2/bin/pip3.11 /usr/bin/pip3
        
        sudo pip3 install setuptools-rust
        sudo pip3 install --user ansible-core
        sudo pip3 install --upgrade --user ansible
        sudo pip3 install ansible-navigator
        sudo pip3 install firewall
        sudo pip3 install pyyaml
        pip3 install ansible-vault

        /usr/lib64/Python-3.11.2/bin/ansible-navigator --version
        sudo cp /usr/lib64/Python-3.11.2/bin/ansible-navigator /usr/local/bin/ansible-navigator
        sudo cp /usr/lib64/Python-3.11.2/bin/ansible-vault /usr/bin/ansible-vault
        echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.profile
        source ~/.profile
    fi
    
}

configure_python