
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

## Open up and log into vnc server

## Open up VSC and log into git online

## download VSC extensions

## clone git repo

## setup .venv python 3.12
python -m pip install --upgrade pip setuptools wheel

pip install ultralytics tensorrt==10.13.3.9 onnxruntime-gpu==1.23.2 cvzone onvif_zeep


in rev4.3 in:
- tests/tensorRT/tensor-check.py
