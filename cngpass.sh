#!/bin/bash

# Script to set password for current user to 'student'
# This bypasses Ubuntu's password complexity requirements

# Get the current logged-in user
USERNAME="student"
PASSWORD="student"

echo "Setting password for current user '$USERNAME'..."

# Check if user exists (should always be true for current user)
if ! id "$USERNAME" &>/dev/null; then
    echo "Error: Current user '$USERNAME' not found."
    exit 1
fi

# Set the password using usermod with openssl encryption
# This bypasses all password quality checks
if sudo usermod --password $(openssl passwd -1 "$PASSWORD") "$USERNAME"; then
    echo "✓ Password successfully set for user '$USERNAME'"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo ""
    echo "You can now log in with:"
    echo "  Username: $USERNAME"
    echo "  Password: $PASSWORD"
else
    echo "✗ Failed to set password for user '$USERNAME'"
    exit 1
fi

echo "Done!"
