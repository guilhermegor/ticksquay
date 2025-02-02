#!/bin/bash

set -e  # Exit on error

echo "Starting Python setup..."

# Ensure pip is installed and upgraded
echo "Ensuring pip is installed and upgraded..."
python -m ensurepip --upgrade

# Install Python dependencies from requirements.txt
echo "Installing Python dependencies from requirements.txt..."
python -m pip install --upgrade pip && \
    python -m pip install --no-cache-dir -r /opt/airflow/requirements.txt

echo "Python setup completed successfully."