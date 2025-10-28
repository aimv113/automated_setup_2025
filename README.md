Install Ubuntu 24.04.3

sudo apt update

sudo apt install openssh-server ansible git -y

sudo systemctl start ssh

sudo systemctl enable ssh


hostname -I
ssh finn@ip address

git clone https://github.com/aimv113/automated_setup_2025.git

cd automated_setup_2025/

ansible-playbook ubuntu-setup.yml -K

ssh-copy-id -p 33412 finn@ip address



fix for VM's
# Replace the X11 config with a more restrictive one
sudo bash -c 'cat > /etc/X11/xorg.conf.d/10-qxl-display.conf << "EOF"
Section "ServerFlags"
    Option "AutoAddGPU" "false"
EndSection

Section "ServerLayout"
    Identifier "Layout0"
    Screen 0 "Screen0"
EndSection

Section "Device"
    Identifier "QXL"
    Driver "qxl"
    BusID "PCI:0:1:0"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "QXL"
EndSection
EOF'

# Also remove any other X11 configs that might interfere
sudo rm -f /etc/X11/xorg.conf.d/10-nvidia.conf 2>/dev/null

# Restart GDM
sudo systemctl restart gdm3


For TensorRT
apt show tensorrt
sudo apt-get install tensorrt


