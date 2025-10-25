sudo tee /etc/apt/sources.list >/dev/null <<'EOF'
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
EOF
sudo apt update


sudo apt install -y intel-media-va-driver vainfo intel-gpu-tools firmware-misc-nonfree

echo 'options i915 enable_guc=3' | sudo tee /etc/modprobe.d/i915.conf
sudo update-initramfs -u
sudo reboot


lspci -nn | grep -E "VGA|3D|Display"      # should show 8086:46a6
lsmod | grep i915                          # i915 should be loaded
ls /dev/dri                                # expect card0 and renderD128
vainfo                                      # should report "Driver version: Intel iHD"
