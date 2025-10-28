Install Ubuntu 24.04.3

sudo apt update

sudo apt install openssh-server ansible git -y

sudo systemctl start ssh

sudo systemctl enable ssh


hostname -I
ssh finn@ip address

git clone https://github.com/aimv113/automated_setup_2025.git

cd automated_setup_2025/


ansible-playbook ubuntu-setup.yml
