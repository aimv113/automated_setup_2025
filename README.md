# Automated Setup 2025

## Initial Ubuntu 24.04.3 Setup

### 1. Update System and Install Required Packages

```bash
sudo apt update
sudo apt install openssh-server ansible git -y
```

### 2. Configure SSH Service

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

### 3. Clone Repository and Run Setup

Get your IP address:
```bash
hostname -I
```

SSH into the machine:
```bash
ssh finn@<ip-address>
```

Clone the repository:
```bash
git clone https://github.com/aimv113/automated_setup_2025.git
cd automated_setup_2025/
```

Run the Ansible playbook:
```bash
ansible-playbook ubuntu-setup.yml -K -vv
```

### 4. Copy SSH Keys

```bash
ssh-copy-id -p 33412 finn@<ip-address>
```

---

## VM-Specific Configuration

### Fix for Virtual Machines (Display Issues)

Replace the X11 config with a more restrictive one:

```bash
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
```

Remove any other X11 configs that might interfere:
```bash
sudo rm -f /etc/X11/xorg.conf.d/10-nvidia.conf 2>/dev/null
```

Restart GDM:
```bash
sudo systemctl restart gdm3
```

---

## TensorRT Setup

### Install TensorRT

Check if TensorRT is available:
```bash
apt show tensorrt
```

Install TensorRT:
```bash
sudo apt-get install tensorrt
```

### Install Python Packages (in virtual environment)

```bash
pip install ultralytics nvidia-tensorrt onnxruntime-gpu
```


