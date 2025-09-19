#!/bin/bash

# Script to set password for 'student' user to 'student'
# This bypasses Ubuntu's password complexity requirements

USERNAME="student"
PASSWORD="student"

echo "Setting password for user '$USERNAME'..."

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo "Error: User '$USERNAME' does not exist."
    echo "Create the user first with: sudo adduser $USERNAME"
    exit 1
fi

# Set the password using usermod with openssl encryption
# This bypasses all password quality checks
if sudo usermod --password $(openssl passwd -1 "$PASSWORD") "$USERNAME"; then
    echo "✓ Password successfully set for user '$USERNAME'"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
else
    echo "✗ Failed to set password for user '$USERNAME'"
    exit 1
fi

echo "Done!"
