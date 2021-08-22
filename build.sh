#!/usr/bin/env bash
#vv.lisyak@gmail.com

if [ -f ver ]
then
  export $(cat ver | sed 's/#.*//g' | xargs)
else 
  echo "ver Environment fine not exist"
  exit 0
fi
apt update
apt install -y rsync cloud-image-utils isolinux xorriso mc netcat git

cd /tmp && rm -rf ./iso*
mkdir ./iso && chmod 777 ./iso

#mount if iso exist and download & mount iso if not exist   
if [ -f $(basename -- $UBUNTU_ISO) ]
then
  mount ./$(basename -- $UBUNTU_ISO) /mnt
else
  wget $UBUNTU_ISO
  mount ./$(basename -- $UBUNTU_ISO) /mnt
fi

rsync -av --progress /mnt/ ./iso/

#clone repo with configs and sync with iso
git clone -b '$MAJOR_VERSION.$MINOR_VERSION.$PATH_VERSION' git@github.com:Netping/DKSF_90.git ./isogit

rsync -vr ./isogit/iso/ ./iso/
rm -rf ./isogit 

#Borg
bash /tmp/iso/netping/backup/borg.sh

#clone repo with NpServerSettings
git clone -b '$MAJOR_VERSION.$MINOR_VERSION.$PATH_VERSION' git@github.com:Netping/DKST90_NpServerSettings.git /tmp/
bash /tmp/DKST90_NpServerSettings/config.sh

VERSION=$MAJOR_VERSION.$MINOR_VERSION.$PATH_VERSION.$BUILD_VERSION$(date '+%Y-%m-%dT%H:%M:%S')
echo $VERSION > ./iso/netping/np_version

mv ./iso/ubuntu ./
cd ./iso/; find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec "$(which md5sum)" {} ; > ../md5sum.txt
cd .. ; mv ./md5sum.txt ./iso/ ; mv ./ubuntu ./iso/

#combine to bootable iso 
xorriso -as mkisofs -r   -V Ubuntu\ NetpingZabbix   -o DKSL90.$VERSION.iso   -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot   -boot-load-size 4 -boot-info-table   -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot   -isohybrid-gpt-basdat -isohybrid-apm-hfsplus   -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin    iso/boot iso
