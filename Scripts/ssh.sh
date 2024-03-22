apt update -y
apt install ssh -y
echo PermitRootLogin yes >> /etc/ssh/sshd_config
systemctl restart ssh