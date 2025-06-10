#!/bin/bash

# Script to disable IPv6 on Ubuntu 24.10
# Run as root (sudo)

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use sudo."
   exit 1
fi

echo "Disabling IPv6 on Ubuntu 24.10..."

# Step 1: Modify GRUB to disable IPv6 at kernel level
GRUB_FILE="/etc/default/grub"
if grep -q "ipv6.disable=1" "$GRUB_FILE"; then
    echo "GRUB already configured to disable IPv6."
else
    sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/ s/"\(.*\)"/"\1 ipv6.disable=1"/' "$GRUB_FILE"
    if [[ $? -eq 0 ]]; then
        echo "Updated GRUB configuration to disable IPv6."
    else
        echo "Failed to update GRUB configuration. Check $GRUB_FILE manually."
        exit 1
    fi
fi

# Step 2: Update GRUB
echo "Updating GRUB..."
update-grub
if [[ $? -eq 0 ]]; then
    echo "GRUB updated successfully."
else
    echo "Failed to update GRUB. Please run 'sudo update-grub' manually."
    exit 1
fi

# Step 3: Disable IPv6 in sysctl
SYSCTL_FILE="/etc/sysctl.conf"
SYSCTL_LINES="
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
"

if grep -q "net.ipv6.conf.all.disable_ipv6" "$SYSCTL_FILE"; then
    echo "Sysctl already configured to disable IPv6."
else
    echo "$SYSCTL_LINES" >> "$SYSCTL_FILE"
    if [[ $? -eq 0 ]]; then
        echo "Added IPv6 disable settings to $SYSCTL_FILE."
    else
        echo "Failed to update $SYSCTL_FILE. Check permissions."
        exit 1
    fi
fi

# Step 4: Apply sysctl changes
echo "Applying sysctl changes..."
sysctl -p
if [[ $? -eq 0 ]]; then
    echo "Sysctl changes applied successfully."
else
    echo "Failed to apply sysctl changes. Run 'sudo sysctl -p' manually."
    exit 1
fi

# Step 5: Configure systemd-networkd to disable IPv6
NETWORK_DIR="/etc/systemd/network"
NETWORK_FILE="$NETWORK_DIR/20-wired.network"

# Create network directory if it doesn't exist
mkdir -p "$NETWORK_DIR"

if [[ -f "$NETWORK_FILE" ]] && grep -q "IPv6AcceptRA=no" "$NETWORK_FILE"; then
    echo "systemd-networkd already configured to disable IPv6."
else
    cat << EOF > "$NETWORK_FILE"
[Match]
Name=*

[Network]
IPv6AcceptRA=no
LinkLocalAddressing=no
EOF
    if [[ $? -eq 0 ]]; then
        echo "Configured systemd-networkd to disable IPv6."
    else
        echo "Failed to configure $NETWORK_FILE."
        exit 1
    fi
fi

# Step 6: Restart systemd-networkd
echo "Restarting systemd-networkd..."
systemctl restart systemd-networkd
if [[ $? -eq 0 ]]; then
    echo "systemd-networkd restarted successfully."
else
    echo "Failed to restart systemd-networkd. Run 'sudo systemctl restart systemd-networkd' manually."
    exit 1
fi

# Step 7: Clear ip6tables rules
echo "Clearing ip6tables rules..."
ip6tables -F
if [[ $? -eq 0 ]]; then
    echo "ip6tables rules cleared."
else
    echo "Warning: Failed to clear ip6tables rules."
fi

# Step 8: Verify IPv6 is disabled
echo "Verifying IPv6 status..."
if ip a | grep -q inet6; then
    echo "Warning: IPv6 addresses still detected. Check configuration."
else
    echo "No IPv6 addresses detected."
fi

if sysctl -a | grep -q "net.ipv6.conf.all.disable_ipv6 = 1"; then
    echo "Sysctl confirms IPv6 is disabled."
else
    echo "Warning: Sysctl settings not applied as expected."
fi

if ip -6 route 2>/dev/null | grep -q "unreachable"; then
    echo "No IPv6 routes detected."
else
    echo "Warning: IPv6 routes may still be active."
fi

# Step 9: Prompt for reboot
echo "IPv6 has been disabled. A reboot is required to apply all changes."
read -p "Would you like to reboot now? (y/N): " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    echo "Rebooting now..."
    reboot
else
    echo "Please reboot manually to apply changes (run 'sudo reboot')."
fi

exit 0