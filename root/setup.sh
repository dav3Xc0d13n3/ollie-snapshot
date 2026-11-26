#!/bin/bash
echo "Installing persistent tools..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq neofetch htop vim nmap curl git
echo "Tools installed."
