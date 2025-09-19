#!/bin/bash
# BOB Configuration File
# Centralized configuration for all BOB scripts

# Server Configuration
SERVER_IP="10.33.23.159"
SERVER_PORT="8000"
SERVER_URL="http://${SERVER_IP}:${SERVER_PORT}"

# Export variables for use in other scripts
export SERVER_IP
export SERVER_PORT  
export SERVER_URL

# Function to get server URL
get_server_url() {
    echo "$SERVER_URL"
}

# Function to get server IP
get_server_ip() {
    echo "$SERVER_IP"
}

# Function to get server port
get_server_port() {
    echo "$SERVER_PORT"
}
