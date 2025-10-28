Install Ubuntu 24.04.3

sudo apt update

sudo apt install openssh-server ansible git -y

sudo systemctl start ssh

sudo systemctl enable ssh


hostname -I
ssh finn@<<ip address>

