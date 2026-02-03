
```bash
cd ~/automated_setup_2025
ansible-playbook post-reboot-verify.yml -K
```

**Verification includes:**
- ✅ NVIDIA driver loaded (`nvidia-smi`)
- ✅ CUDA toolkit available (`nvcc --version`)
- ✅ Docker NVIDIA runtime working
- ✅ PyTorch CUDA 13.0 support enabled
- ✅ TensorRT packages installed and held

---

Fix firefox as default browser
```bash
xdg-settings set default-web-browser firefox_firefox.desktop
xdg-mime default firefox_firefox.desktop x-scheme-handler/http
xdg-mime default firefox_firefox.desktop x-scheme-handler/https
```

## crontab

sudo crontab -e
```bash
0 6,18 * * * /sbin/reboot
0 6,18 * * * echo "Cron executed at $(date)" >> /var/log/cron_test.log
```

## Open up and log into vnc server

## Open up VSC and log into git online

## download VSC extensions
- Python
- Data preview
- indent rainbow
- rainbow csv

## clone git repo

## setup .venv python 3.12
python -m pip install --upgrade pip setuptools wheel

pip install ultralytics tensorrt==10.13.3.9 onnxruntime-gpu==1.23.2 cvzone onvif_zeep


## in rev4.3 in:
- tests/tensorRT/tensor-check.py


## in terminal
```bash
sudo systemctl disable --now fwupd-refresh.service fwupd-refresh.timer
```
to disable known issue: popup appears because Ubuntu’s Apport crash reporter found a .crash file in /var/crash from a previous boot or crash.

## for tocuh screen setup
```bash
sudo apt update
sudo apt install xserver-xorg-input-libinput xserver-xorg-input-evdev xserver-xorg-input-multitouch xinput-calibrator -y
```
```bash
sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
```
```bash
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null <<'EOF'
Section "InputClass"
    Identifier "Touchscreen"
    MatchProduct "eGalax Inc. USB TouchController"
    MatchDevicePath "/dev/input/event*"
    Driver "evdev"
    Option "Calibration" "0 4095 0 4095"
    Option "InvertX" "0"
    Option "InvertY" "0"
EndSection
EOF
```
```bash
sudo systemctl restart gdm
```
```bash
xinput list-props "$(xinput list | grep -i 'egalax' | grep -o 'id=[0-9]*' | cut -d= -f2)" | grep -E "Evdev Axis Calibration|Driver"
```





