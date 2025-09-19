#!/bin/bash

# User Management Script (Standalone)
# This script performs user management tasks in sequence

echo "Starting user management operations..."

# Step 1: Delete all users except the current user
echo "Step 1: Deleting other users..."

CURRENT_USER=$(whoami)
MIN_UID=1000

echo "Current user: $CURRENT_USER"
echo "Deleting all users except: $CURRENT_USER"
echo "----------------------------"

while IFS=: read -r username _ uid _ _ home shell; do
    # Skip system users and current user
    if [[ "$uid" -ge $MIN_UID && "$username" != "$CURRENT_USER" ]]; then
        echo "Deleting user: $username"
        sudo userdel -r "$username"
        if [[ $? -eq 0 ]]; then
            echo "✅ Successfully deleted $username"
        else
            echo "❌ Failed to delete $username"
            # exit 1
        fi
    fi
done < /etc/passwd

echo "✅ User deletion step completed successfully"

# Step 2: Create new user BOB25 with password 'allbatchtour'
echo "Step 2: Creating user BOB25..."
sudo useradd -m -s /bin/bash BOB25
if [ $? -eq 0 ]; then
    echo "✅ User BOB25 created successfully"
    echo "BOB25:allbatchtour" | sudo chpasswd
    if [ $? -eq 0 ]; then
        echo "✅ Password set for BOB25"
    else
        echo "✅ Failed to set password for BOB25"
        exit 1
    fi
else
    echo "✅ Failed to create user BOB25"
    exit 1
fi

# Step 3: Restrict BOB25 wifi access (integrated from wifi.sh)
echo "Step 3: Restricting BOB25 wifi access..."

POLICY_DIR="/etc/polkit-1/localauthority/50-local.d"
POLICY_FILE="$POLICY_DIR/restrict-wifi.pkla"

# Function to restrict wifi for a user
restrict_wifi_for_user() {
    local username="$1"
    if ! id "$username" &>/dev/null; then
        echo "User '$username' does not exist, skipping WiFi restriction."
        return 1
    fi
    sudo mkdir -p "$POLICY_DIR"
    if [[ -f "$POLICY_FILE" ]] && grep -q "unix-user:$username" "$POLICY_FILE"; then
        echo "User '$username' is already restricted from WiFi access."
        return 0
    fi
    sudo tee -a "$POLICY_FILE" > /dev/null << EOF

[Deny WiFi for user $username]
Identity=unix-user:$username
Action=org.freedesktop.NetworkManager.wifi.*
ResultAny=no
ResultInactive=no
ResultActive=no
EOF
    sudo chmod 644 "$POLICY_FILE"
    echo "✅ WiFi restriction added for user '$username'"
    echo "User '$username' can still use wired connections."
    echo "Changes will take effect after the user logs out and back in."
}

restrict_wifi_for_user "BOB25"

echo "✅ BOB25 wifi restrictions applied successfully"

# Step 4: Change password for 'student' user to 'student'
echo "Step 4: Changing password for user 'student'..."

USERNAME="student"
PASSWORD="abirvy"

if ! id "$USERNAME" &>/dev/null; then
    echo "Error: User '$USERNAME' does not exist."
    echo "Create the user first with: sudo adduser $USERNAME"
    exit 1
fi

if sudo usermod --password $(openssl passwd -1 "$PASSWORD") "$USERNAME"; then
    echo "✅ Password successfully set for user '$USERNAME'"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
else
    echo "✅ Failed to set password for user '$USERNAME'"
    exit 1
fi

echo "All user management operations completed successfully!"
