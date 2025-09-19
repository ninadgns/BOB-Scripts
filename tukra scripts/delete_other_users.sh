#!/bin/bash

# Get the current user
CURRENT_USER=$(whoami)

# Minimum UID for normal users (usually 1000 on Ubuntu)
MIN_UID=1000

echo "Current user: $CURRENT_USER"
echo "Deleting all users except: $CURRENT_USER"
echo "----------------------------"

# Loop through users in /etc/passwd
while IFS=: read -r username _ uid _ _ home shell; do
    # Skip system users and current user
    if [[ "$uid" -ge $MIN_UID && "$username" != "$CURRENT_USER" ]]; then
        echo "Deleting user: $username"

        # Delete user and their home directory
        sudo userdel -r "$username"

        if [[ $? -eq 0 ]]; then
            echo "✅ Successfully deleted $username"
        else
            echo "❌ Failed to delete $username"
        fi
    fi
done < /etc/passwd

