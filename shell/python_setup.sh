#!/bin/bash

set -e  # Exit on error

echo "Starting Python setup..."

# Download, build, and install Python 3.9
echo "Downloading and installing Python 3.9..."
wget https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz && \
    tar xzf Python-3.9.18.tgz && \
    cd Python-3.9.18 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    cd .. && \
    rm -rf Python-3.9.18 Python-3.9.18.tgz

# Ensure pip is installed and upgraded
echo "Ensuring pip is installed and upgraded..."
python3.9 -m ensurepip --upgrade

# Configure sudo to allow the user to run update-alternatives without a password
echo "Configuring sudo for update-alternatives..."
echo "${USER} ALL=(ALL) NOPASSWD: /usr/bin/update-alternatives" > /etc/sudoers.d/${USER}-update-alternatives
chmod 440 /etc/sudoers.d/${USER}-update-alternatives

# Install Python dependencies from requirements.txt
echo "Installing Python dependencies from requirements.txt..."
python3.9 -m pip install --upgrade pip && \
    python3.9 -m pip install --no-cache-dir -r /opt/airflow/requirements.txt

# Set Python 3.9 as the default Python version (run as root)
echo "Setting Python 3.9 as the default Python version..."
update-alternatives --install /usr/bin/python python /usr/local/bin/python3.9 1
update-alternatives --set python /usr/local/bin/python3.9

echo "Python setup completed successfully."