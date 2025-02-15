#!/bin/bash

# Set snapshot names
time_stamp=$(date '+%Y-%m-%d_%H-%M-%S')

tyler_snap_name=tyler-${time_stamp}
meagan_snap_name=meagan-${time_stamp}
root_snap_name=root-${time_stamp}

plex_snap_name=plex-${time_stamp}
docker_snap_name=docker-${time_stamp}
vms_snap_name=virtual_machines_${time_stamp}


# relevant folders
snap_folder=/snapshots/
backup_folder=/mnt/tyler/fileserver/backups/

# XZ Multithread
export XZ_DEFAULTS="-T 3"

# Create snapshots
btrfs subvolume snapshot -r /home/tyler ${snap_folder}/${tyler_snap_name}
btrfs subvolume snapshot -r /home/meagan ${snap_folder}/${meagan_snap_name}
btrfs subvolume snapshot -r / ${snap_folder}/${root_snap_name}

btrfs subvolume snapshot -r /srv/docker/ ${snap_folder}/${docker_snap_name}
btrfs subvolume snapshot -r /srv/plex/ ${snap_folder}/${plex_snap_name}
btrfs subvolume snapshot -r /srv/virtual_machines/ ${snap_folder}/${vms_snap_name}


cd $snap_folder
echo "Creating Root Tarball..."
tar \
	--warning=no-file-ignored \
	-caPf ${snap_folder}/${root_snap_name}.tar.xz ${root_snap_name}

chown tyler ${snap_folder}/${root_snap_name}.tar.xz
chgrp tyler ${snap_folder}/${root_snap_name}.tar.xz
mv ${snap_folder}/${root_snap_name}.tar.xz ${backup_folder}/
echo "Finished!"

echo "Creating Docker Tarball..."
tar \
	--warning=no-file-ignored \
	-caPf ${snap_folder}/${docker_snap_name}.tar.xz ${docker_snap_name}

chown tyler ${snap_folder}/${docker_snap_name}.tar.xz
chgrp tyler ${snap_folder}/${docker_snap_name}.tar.xz
mv ${snap_folder}/${docker_snap_name}.tar.xz ${backup_folder}/
echo "Finished!"


echo "Creating PLEX Tarball..."
tar \
	--warning=no-file-ignored \
	-caPf ${snap_folder}/${plex_snap_name}.tar.xz ${plex_snap_name}

chown tyler ${snap_folder}/${plex_snap_name}.tar.xz
chgrp tyler ${snap_folder}/${plex_snap_name}.tar.xz
mv ${snap_folder}/${plex_snap_name}.tar.xz ${backup_folder}/
echo "Finished!"


echo "Creating tyler Tarball..."
tar \
	--exclude='tyler/.cache' \
	-caPf ${snap_folder}/${tyler_snap_name}.tar.xz $tyler_snap_name 

chown tyler ${snap_folder}/${tyler_snap_name}.tar.xz
chgrp tyler ${snap_folder}/${tyler_snap_name}.tar.xz
mv ${snap_folder}/${tyler_snap_name}.tar.xz ${backup_folder}/
echo "Finished!"


echo "Creating meagan Tarball..."
tar -caf ${snap_folder}/${meagan_snap_name}.tar.xz $meagan_snap_name

chown tyler ${snap_folder}/${meagan_snap_name}.tar.xz
chgrp tyler ${snap_folder}/${meagan_snap_name}.tar.xz
mv ${snap_folder}/${meagan_snap_name}.tar.xz ${backup_folder}/
echo "Finished!"


echo "Rsyncing VM images..."
rsync -avhAEXH  ${snap_folder}/${vms_snap_name}/ /mnt/virtual_machines/
echo "Finished!"

echo "Cleaning up..."
# Delete current backup
btrfs subvolume delete ${snap_folder}/${tyler_snap_name}
btrfs subvolume delete ${snap_folder}/${meagan_snap_name}
btrfs subvolume delete ${snap_folder}/${root_snap_name}
btrfs subvolume delete ${snap_folder}/${docker_snap_name}
btrfs subvolume delete ${snap_folder}/${plex_snap_name}
btrfs subvolume delete ${snap_folder}/${vms_snap_name}
echo "Finished!"
