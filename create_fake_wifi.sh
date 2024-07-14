#!/bin/bash

# Define variables
INTERFACE="wlan0"
SSID="FakeNetwork"
CHANNEL="6"
IP_RANGE_START="192.168.1.2"
IP_RANGE_END="192.168.1.30"
ROUTER_IP="192.168.1.1"
DNS_SERVER="8.8.8.8"

# Function to start monitor mode
start_monitor_mode() {
  echo "Starting monitor mode on $INTERFACE..."
  sudo airmon-ng start $INTERFACE
}

# Function to create hostapd config
create_hostapd_conf() {
  echo "Creating hostapd configuration file..."
  cat <<EOT > hostapd.conf
interface=$INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CHANNEL
EOT
}

# Function to create dnsmasq config
create_dnsmasq_conf() {
  echo "Creating dnsmasq configuration file..."
  cat <<EOT > dnsmasq.conf
interface=$INTERFACE
dhcp-range=$IP_RANGE_START,$IP_RANGE_END,12h
dhcp-option=3,$ROUTER_IP
dhcp-option=6,$ROUTER_IP
server=$DNS_SERVER
log-queries
log-dhcp
EOT
}

# Function to enable IP forwarding
enable_ip_forwarding() {
  echo "Enabling IP forwarding..."
  sudo sysctl -w net.ipv4.ip_forward=1
}

# Function to set up iptables
setup_iptables() {
  echo "Setting up iptables..."
  sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  sudo iptables -A FORWARD -i eth0 -o $INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
  sudo iptables -A FORWARD -i $INTERFACE -o eth0 -j ACCEPT
}

# Function to start hostapd
start_hostapd() {
  echo "Starting hostapd..."
  sudo hostapd hostapd.conf
}

# Function to start dnsmasq
start_dnsmasq() {
  echo "Starting dnsmasq..."
  sudo dnsmasq -C dnsmasq.conf
}

# Main script execution
start_monitor_mode
create_hostapd_conf
create_dnsmasq_conf
enable_ip_forwarding
setup_iptables
start_hostapd &
start_dnsmasq
