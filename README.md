
************
Installation
************

Login into Raspberry PI, piCorePlayer
ssh tc@picoreplayer
password(standard): nosoup4u

get all files into following directory:
/mnt/mmcblk0p2/tce/amp_power/


a) Install wiringPi 
tce-load -wi wiringpi.tcz

b) Patch bootlocal.sh & run Backup
cd /opt && patch < /mnt/mmcblk0p2/tce/amp_power/bootlocal.sh.patch && sudo filetool.sh -b

c) Change file permissions 
chmod 775 /mnt/mmcblk0p2/tce/amp_power/amp_power
chmod 775 /mnt/mmcblk0p2/tce/amp_power/amp_power_initd

d) Reboot
sudo reboot
