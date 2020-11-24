
************
Installation
************

*****
wget -O - http://diskstation/amp_power/amp_power_install.sh | sh -s --
*****
Add to piCorePlayer in UserCommands 1
wget -O - http://diskstation/amp_power/amp_power_install.sh | sh -s --
*****



Login into Raspberry PI, piCorePlayer
ssh tc@picoreplayer
password(standard): nosoup4u

get all files into following directory:

mkdir /mnt/mmcblk0p2/tce/amp_power/
cd /mnt/mmcblk0p2/tce/amp_power/

wget http://diskstation/amp_power/amp_power
wget http://diskstation/amp_power/amp_power_initd
wget http://diskstation/amp_power/amp_power.version
wget http://diskstation/amp_power/bootlocal.sh.patch


a) Install wiringPi
tce-load -wi wiringpi.tcz

b) Patch bootlocal.sh & run Backup
cd /opt && patch < /mnt/mmcblk0p2/tce/amp_power/bootlocal.sh.patch && sudo filetool.sh -b
filetool.sh -b

c) Change file permissions
chmod 775 /mnt/mmcblk0p2/tce/amp_power/amp_power
chmod 775 /mnt/mmcblk0p2/tce/amp_power/amp_power_initd

d) Reboot
sudo reboot

************
Remark
************
Wiring according
https://coderwall.com/p/jsd5mw/raspberry-pi-garage-door-opener-with-garagepi
