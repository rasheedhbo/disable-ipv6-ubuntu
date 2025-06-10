# Disable IPv6 on Ubuntu 24.10

This repository contains a Bash script (`disable_ipv6.sh`) to completely disable IPv6 on an Ubuntu 24.10 VPS, such as those hosted on Cloud VPS. The script modifies GRUB, sysctl, and `systemd-networkd` configurations to disable IPv6 at the kernel and network levels, clears `ip6tables` rules, and verifies the changes.

## Features
- Disables IPv6 via kernel parameter (`ipv6.disable=1` in GRUB).
- Configures sysctl to disable IPv6 for all interfaces.
- Sets up `systemd-networkd` to prevent IPv6 address assignment.
- Clears IPv6 firewall rules (`ip6tables`).
- Includes verification steps to confirm IPv6 is disabled.
- Idempotent: safely skips already-applied configurations.
- Prompts for reboot to apply changes.

## Prerequisites
- Ubuntu 24.10 VPS.
- `sudo` privileges.
- `curl` or `wget` installed (for direct execution).
- `systemd-networkd` (default in Ubuntu 24.10 server). For Network Manager setups, manual configuration may be needed.

## Usage

### Option 1: Run Directly from GitHub
Fetch and execute the script in one command using `curl` or `wget`. **Warning**: Review the script first to ensure it’s trusted.

```bash
curl -s https://raw.githubusercontent.com/rasheedhbo/disable-ipv6-ubuntu/main/disable_ipv6.sh | sudo bash
```

Or with `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/rasheedhbo/disable-ipv6-ubuntu/main/disable_ipv6.sh | sudo bash
```

- Follow the script’s prompts (e.g., reboot confirmation).

### Option 2: Download and Run Locally
For better security, download and inspect the script before running:

1. Download the script:
   ```bash
   curl -s https://raw.githubusercontent.com/rasheedhbo/disable-ipv6-ubuntu/main/disable_ipv6.sh -o disable_ipv6.sh
   ```
   Or:
   ```bash
   wget https://raw.githubusercontent.com/rasheedhbo/disable-ipv6-ubuntu/main/disable_ipv6.sh -O disable_ipv6.sh
   ```

2. Review the script:
   ```bash
   nano disable_ipv6.sh
   ```

3. Make it executable:
   ```bash
   chmod +x disable_ipv6.sh
   ```

4. Run the script:
   ```bash
   sudo ./disable_ipv6.sh
   ```

5. Clean up:
   ```bash
   rm disable_ipv6.sh
   ```

### Post-Execution
- The script will prompt for a reboot. Run `sudo reboot` if you choose not to reboot immediately.
- Verify IPv6 is disabled after reboot (see [Verification](#verification)).

## Verification
After rebooting, confirm IPv6 is disabled:

1. Check for IPv6 addresses:
   ```bash
   ip a | grep inet6
   ```
   Should return no output.

2. Verify sysctl settings:
   ```bash
   sysctl -a | grep ipv6 | grep disable
   ```
   Should show `net.ipv6.conf.all.disable_ipv6 = 1`, etc.

3. Check IPv6 routes:
   ```bash
   ip -6 route
   ```
   Should show no routes or an error like `Address family not supported`.

4. Test IPv6 connectivity:
   ```bash
   ping6 -c 4 google.com
   ```
   Should fail with `Network is unreachable`.

5. Check for IPv6 sockets:
   ```bash
   ss -tuln | grep :::*
   ```
   Should return no output.

## Notes
- **Network Manager**: If your VPS uses Network Manager instead of `systemd-networkd`, manually disable IPv6:
  ```bash
  sudo nano /etc/NetworkManager/system-connections/<connection-name>.nmconnection
  ```
  Add:
  ```
  [ipv6]
  method=disabled
  ```
  Then:
  ```bash
  sudo systemctl restart NetworkManager
  ```

- **Reverting**: To re-enable IPv6:
  1. Remove `ipv6.disable=1` from `/etc/default/grub`.
  2. Delete `net.ipv6` lines from `/etc/sysctl.conf`.
  3. Remove or edit `/etc/systemd/network/20-wired.network`.
  4. Run:
     ```bash
     sudo update-grub
     sudo sysctl -p
     sudo reboot
     ```

## Troubleshooting
- If IPv6 persists, check for conflicting configurations in `/etc/network/interfaces` or other `systemd-networkd` files.
- Ensure no applications (e.g., Nginx, Apache) explicitly enable IPv6.
- For errors, review the script’s output or contact the repository maintainer.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for improvements or bug fixes.