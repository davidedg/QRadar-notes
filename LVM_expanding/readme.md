# LVM Expansion on QRadar 7.4+

These are my notes on QRadar VM LVM expansion
\
Apply EXTREME CAUTION if you want to follow along.
\
\
**!!! DISCLAIMER !!!**
--
This is **totally unsupported** by IBM - see
\
https://www.ibm.com/support/pages/does-qradar-support-lvm-file-system-storage-expansion
--
\
Plan
----------
0. Inspect Disk Layout
1. Ensure a full backup is available
2. Stop all services
3. Add LVM extents (Option A: extend over existing virtual disk; Option B: just add a separate virtual disk)
4. Extend LV
5. Grow XFS volume
6. Reboot

\
0 - Inspect Disk Layout
----------------------

General Disk Layout:

    [root@qradar ~]# lsblk -f -p
    NAME                                 FSTYPE      LABEL                           UUID                                   MOUNTPOINT
    /dev/sda
    ├─/dev/sda1
    ├─/dev/sda2                          xfs                                         d8fd5697-61a3-45a4-952f-5d8b4f27ba20   /boot
    ├─/dev/sda3                          xfs                                         378930d5-4dac-4a4a-87ab-16412678a0e3   /recovery
    ├─/dev/sda4                          LVM2_member                                 M9N7PH-3gD5-mXwO-GU1N-Do3x-kdQ1-pEXZs7
    │ ├─/dev/mapper/rootrhel-root        xfs                                         8f0d4a1d-f784-46d1-b18d-3b6311aff38b   /
    │ ├─/dev/mapper/rootrhel-storetmp    xfs                                         13186d4a-7092-4b7d-8faa-efc0671bb669   /storetmp
    │ ├─/dev/mapper/rootrhel-tmp         xfs                                         f4f7e73e-bc42-4735-bf47-2092f30e7660   /tmp
    │ ├─/dev/mapper/rootrhel-home        xfs                                         159c3a91-e4e6-45f3-884c-bcc5822fb22a   /home
    │ ├─/dev/mapper/rootrhel-opt         xfs                                         2022bd67-f07d-4708-8e8d-d178e1f5456e   /opt
    │ ├─/dev/mapper/rootrhel-varlogaudit xfs                                         fffceae4-7c14-4900-9def-d36a83c50c57   /var/log/audit
    │ ├─/dev/mapper/rootrhel-varlog      xfs                                         d254a82b-b806-4f00-944f-d719120e1581   /var/log
    │ └─/dev/mapper/rootrhel-var         xfs                                         a0d8a606-1b4c-4023-9876-2a43d5506d47   /var
    └─/dev/sda5                          swap                                        98ff1a98-fc33-4926-aa6e-4b8ac6ccbfad   [SWAP]

    [root@qradar ~]# blkid
    /dev/sda1: PARTUUID="2df16601-a25d-4461-a991-9fbfeba1b83c"
    /dev/sda2: UUID="d8fd5697-61a3-45a4-952f-5d8b4f27ba20" TYPE="xfs" PARTUUID="6157294e-fad4-42a5-849d-be5d447c3a9a"
    /dev/sda3: UUID="378930d5-4dac-4a4a-87ab-16412678a0e3" TYPE="xfs" PARTUUID="8b9f8646-91c0-4d91-870c-dcc223b836d0"
    /dev/sda4: UUID="M9N7PH-3gD5-mXwO-GU1N-Do3x-kdQ1-pEXZs7" TYPE="LVM2_member" PARTUUID="05977c2d-293d-4497-a984-0d5706f459ad"
    /dev/sda5: UUID="98ff1a98-fc33-4926-aa6e-4b8ac6ccbfad" TYPE="swap" PARTUUID="e6687dc7-4f16-4740-9e36-35d9618f2fe8"
    /dev/sr0: UUID="2021-05-17-15-52-56-00" LABEL="QRadar-2020_11_0_20210517144015" TYPE="iso9660" PTTYPE="dos"
    /dev/mapper/rootrhel-root: UUID="8f0d4a1d-f784-46d1-b18d-3b6311aff38b" TYPE="xfs"
    /dev/mapper/rootrhel-storetmp: UUID="13186d4a-7092-4b7d-8faa-efc0671bb669" TYPE="xfs"
    /dev/mapper/rootrhel-tmp: UUID="f4f7e73e-bc42-4735-bf47-2092f30e7660" TYPE="xfs"
    /dev/mapper/rootrhel-home: UUID="159c3a91-e4e6-45f3-884c-bcc5822fb22a" TYPE="xfs"
    /dev/mapper/rootrhel-opt: UUID="2022bd67-f07d-4708-8e8d-d178e1f5456e" TYPE="xfs"
    /dev/mapper/rootrhel-varlogaudit: UUID="fffceae4-7c14-4900-9def-d36a83c50c57" TYPE="xfs"
    /dev/mapper/rootrhel-varlog: UUID="d254a82b-b806-4f00-944f-d719120e1581" TYPE="xfs"
    /dev/mapper/rootrhel-var: UUID="a0d8a606-1b4c-4023-9876-2a43d5506d47" TYPE="xfs"

    [root@qradar ~]# cat /etc/fstab | grep  "mapper\|swap\|xfs"
    /dev/mapper/rootrhel-root /                    xfs        inode64,logbsize=256k,noatime,nobarrier 0 0
    UUID=d8fd5697-61a3-45a4-952f-5d8b4f27ba20 /boot                xfs        defaults             0 0
    /dev/mapper/rootrhel-home /home                xfs        inode64,logbsize=256k,noatime,nobarrier 0 0
    /dev/mapper/rootrhel-opt /opt                 xfs        inode64,logbsize=256k,noatime,nobarrier 0 0
    UUID=378930d5-4dac-4a4a-87ab-16412678a0e3 /recovery            xfs        defaults             0 0
    /dev/mapper/rootrhel-storetmp /storetmp            xfs        inode64,logbsize=256k,noatime,nobarrier 0 0
    /dev/mapper/rootrhel-tmp /tmp                 xfs        inode64,logbsize=256k,noatime,nobarrier 0 0
    /dev/mapper/rootrhel-var /var                 xfs        inode64,logbsize=256k,noatime,nobarrier 0 0
    /dev/mapper/rootrhel-varlog /var/log             xfs        inode64,logbsize=256k,noatime,nobarrier 0 0
    /dev/mapper/rootrhel-varlogaudit /var/log/audit       xfs        inode64,logbsize=256k,noatime,nobarrier 0 0
    UUID=98ff1a98-fc33-4926-aa6e-4b8ac6ccbfad swap                 swap       defaults             0 0

    [root@qradar ~]# df -l -T | grep -v tmpfs
    Filesystem                       Type     1K-blocks     Used Available Use% Mounted on
    /dev/mapper/rootrhel-root        xfs       50822916 23131248  27691668  46% /
    /dev/sda2                        xfs        1038336   293780    744556  29% /boot
    /dev/sda3                        xfs       33538048  9762504  23775544  30% /recovery
    /dev/mapper/rootrhel-home        xfs        1038336    33160   1005176   4% /home
    /dev/mapper/rootrhel-tmp         xfs        3135488    55224   3080264   2% /tmp
    /dev/mapper/rootrhel-opt         xfs       13096960  4920112   8176848  38% /opt
    /dev/mapper/rootrhel-var         xfs        5232640   286888   4945752   6% /var
    /dev/mapper/rootrhel-storetmp    xfs       15718400    66648  15651752   1% /storetmp
    /dev/mapper/rootrhel-varlog      xfs       15718400   450012  15268388   3% /var/log
    /dev/mapper/rootrhel-varlogaudit xfs        3135488    80052   3055436   3% /var/log/audit

    [root@qradar bin]# mount | sort | grep -v ca_jail | grep xfs
    /dev/mapper/rootrhel-home on /home type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
    /dev/mapper/rootrhel-opt on /opt type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
    /dev/mapper/rootrhel-root on / type xfs (rw,noatime,attr2,inode64,noquota)
    /dev/mapper/rootrhel-storetmp on /storetmp type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
    /dev/mapper/rootrhel-tmp on /tmp type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
    /dev/mapper/rootrhel-varlogaudit on /var/log/audit type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
    /dev/mapper/rootrhel-varlog on /var/log type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
    /dev/mapper/rootrhel-var on /var type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
    /dev/sda2 on /boot type xfs (rw,relatime,attr2,inode64,noquota)
    /dev/sda3 on /recovery type xfs (rw,relatime,attr2,inode64,noquota)

    [root@qradar ~]# swapon -s
    Filename                                Type            Size    Used    Priority
    /dev/sda5                               partition       4194300 264     -2

    
    
Inspect `/dev/sda`:

    [root@qradar ~]# parted /dev/sda u s print
    Model: VMware, VMware Virtual S (scsi)
    Disk /dev/sda: 293601280s
    Sector size (logical/physical): 512B/512B
    Partition Table: gpt
    Disk Flags: pmbr_boot

    Number  Start       End         Size        File system     Name  Flags
     1      2048s       4095s       2048s                             bios_grub
     2      4096s       2101247s    2097152s    xfs
     3      2101248s    69210111s   67108864s   xfs
     4      69210112s   285208575s  215998464s                        lvm
     5      285208576s  293597183s  8388608s    linux-swap(v1)


We will use `sgdisk` for some inspections.
\
First download it:

    cd
    wget http://mirror.centos.org/centos/7/os/x86_64/Packages/gdisk-0.8.10-3.el7.x86_64.rpm
    mkdir bin gdisk
    cd gdisk
    rpm2cpio ../gdisk-0.8.10-3.el7.x86_64.rpm | cpio -idmv
    cd ../bin
    ln -s ../gdisk/usr/sbin/sgdisk

    sgdisk

Then gather info:

    [root@qradar bin]# sgdisk -p /dev/sda
    Disk /dev/sda: 293601280 sectors, 140.0 GiB
    Logical sector size: 512 bytes
    Disk identifier (GUID): E7A603C6-870C-4605-A5AA-1E296702D362
    Partition table holds up to 128 entries
    First usable sector is 34, last usable sector is 293601246
    Partitions will be aligned on 2048-sector boundaries
    Total free space is 6077 sectors (3.0 MiB)

    Number  Start (sector)    End (sector)  Size       Code  Name
       1            2048            4095   1024.0 KiB  EF02
       2            4096         2101247   1024.0 MiB  0700
       3         2101248        69210111   32.0 GiB    0700
       4        69210112       285208575   103.0 GiB   8E00
       5       285208576       293597183   4.0 GiB     8200

    [root@qradar bin]# sgdisk -i 4 /dev/sda
    Partition GUID code: E6D6D379-F507-44C2-A23C-238F2A3DF928 (Linux LVM)
    Partition unique GUID: 05977C2D-293D-4497-A984-0D5706F459AD
    First sector: 69210112 (at 33.0 GiB)
    Last sector: 285208575 (at 136.0 GiB)
    Partition size: 215998464 sectors (103.0 GiB)
    Attribute flags: 0000000000000000
    Partition name: ''
    
    [root@qradar bin]# sgdisk -i 5 /dev/sda
    Partition GUID code: 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F (Linux swap)
    Partition unique GUID: E6687DC7-4F16-4740-9E36-35D9618F2FE8
    First sector: 285208576 (at 136.0 GiB)
    Last sector: 293597183 (at 140.0 GiB)
    Partition size: 8388608 sectors (4.0 GiB)
    Attribute flags: 0000000000000000
    Partition name: ''

    [root@qradar bin]# sgdisk --display-alignment  --first-in-largest --end-of-largest --first-aligned-in-largest /dev/sda
    2048
    293597184
    293601246
    293597184


\
1 - Ensure a full backup
------------------------

VM backup or cold-snapshot must be readily available in case of disaster.
\
You may also want a quick GPT partition backup (especially for Option A):

    sgdisk --backup=/root/sda_backup /dev/sda

\
2 - Stop all services
---------------------

I tried with everything still running, this is just to be on a safer side...
\
Stop QRadar services:

    systemctl stop ecs-ec-ingress
    systemctl stop ecs-ep
    service tomcat stop
    service hostcontext stop
    service hostservices stop 
    systemctl stop systemStabMon
    systemctl stop crond

\
3 - Option-A - Add LVM space by extending existing virtual disk
---------------------------------------------------------------

Extend virtual disk:
\
On ESXi, this should be doable online - https://kb.vmware.com/s/article/1004047
\
If you can plan for greater downtime, just do it offline...
\
Say we extend +12 GB
\
We need to remove swap on /dev/sda5, to allow for /dev/sda4 expansion.
\
Remove Swap:

    swapoff -a
    #dd if=/dev/zero of=/dev/sda5 bs=1MB
    #parted /dev/sda rm 5
    partprobe /dev/sda

Calculate new sda4 partition boundary (added 12GB):

    [root@qradar bin]# LASTSECTOR=$(parted /dev/sda u s print | grep "^ 4" | awk '{print $3}' | sed -e 's/s//')
    [root@qradar bin]# echo $LASTSECTOR
    285208575

    [root@qradar bin]# INCREASESIZE=$((12 * 1024*1024*1024 / 512 ))
    [root@qradar bin]# echo $INCREASESIZE
    25165824

    [root@qradar bin]# NEWLASTSECTOR=$((LASTSECTOR + INCREASESIZE))
    [root@qradar bin]# echo $NEWLASTSECTOR
    310374399

Resize /dev/sda4, adding +12GB:

    parted /dev/sda u s resizepart 4 $NEWLASTSECTOR
    partprobe /dev/sda

Re-create swap: // TODO: this can done with parted + check again partition type 0x8200 ?

    sgdisk --disk-guid=98ff1a98-fc33-4926-aa6e-4b8ac6ccbfad -N 5 /dev/sda
    partprobe  /dev/sda
    mkswap -U 98ff1a98-fc33-4926-aa6e-4b8ac6ccbfad /dev/sda5
  	swapon -a

Resize PV to use new space:

    pvresize /dev/sda4

    [root@qradar ~]# pvdisplay
    File descriptor 63 (pipe:[3417390]) leaked on pvdisplay invocation. Parent PID 12896: -bash
      --- Physical volume ---
      PV Name               /dev/sda4
      VG Name               rootrhel
      PV Size               <115.00 GiB / not usable 3.00 MiB
      Allocatable           yes
      PE Size               4.00 MiB
      Total PE              29438
  	  Free PE               3072
      Allocated PE          26366
      PV UUID               M9N7PH-3gD5-mXwO-GU1N-Do3x-kdQ1-pEXZs7

    [root@qradar ~]# vgdisplay
    File descriptor 63 (pipe:[3630354]) leaked on vgdisplay invocation. Parent PID 12896: -bash
      --- Volume group ---
      VG Name               rootrhel
      System ID
      Format                lvm2
      Metadata Areas        1
      Metadata Sequence No  12
      VG Access             read/write
      VG Status             resizable
      MAX LV                0
      Cur LV                8
      Open LV               8
      Max PV                0
      Cur PV                1
      Act PV                1
      VG Size               114.99 GiB
      PE Size               4.00 MiB
      Total PE              29438
      Alloc PE / Size       26366 / 102.99 GiB
  	  Free  PE / Size       3072 / 12.00 GiB
      VG UUID               M4PqAA-uqNe-e3bm-0nw6-QclB-jxWp-Szde0x


\
3 - Option-B - Add LVM space by using a new virtual disk
--------------------------------------------------------

This is a safer option: just add a new virtual disk to the VM.
It can generally be done online. If disk does not show up, either reboot or:

    ls /sys/class/scsi_host/
    echo "- - -" > /sys/class/scsi_host/host0/scan
    echo "- - -" > /sys/class/scsi_host/host1/scan
    echo "- - -" > /sys/class/scsi_host/host2/scan
    udevadm trigger --verbose --subsystem-match=block; udevadm settle
    udevadm trigger --verbose --type=devices --subsystem-match=scsi_disk ; udevadm settle
    blockdev --rereadpt /dev/sdb
    partprobe /dev/sdb

Create LVM PV on whole disk
	
	  pvcreate /dev/sdb

Add new PV to VG

  	vgextend rootrhel /dev/sdb


\
4 - Extend LV
-------------

    lvresize -L +4G /dev/rootrhel/root
    lvresize -L +1G /dev/rootrhel/storetmp
    lvresize -L +1G /dev/rootrhel/tmp
    lvresize -L +1G /dev/rootrhel/home
    lvresize -L +1G /dev/rootrhel/opt
    lvresize -L +1G /dev/rootrhel/varlogaudit
    lvresize -L +1G /dev/rootrhel/varlog
    lvresize -L +1G /dev/rootrhel/var


\
5 - Grow XFS Volume
-------------------

    xfs_growfs /dev/rootrhel/root
    xfs_growfs /dev/rootrhel/storetmp
    xfs_growfs /dev/rootrhel/tmp
    xfs_growfs /dev/rootrhel/home
    xfs_growfs /dev/rootrhel/opt
    xfs_growfs /dev/rootrhel/varlogaudit
    xfs_growfs /dev/rootrhel/varlog
    xfs_growfs /dev/rootrhel/var

\
6 - Reboot
----------

Reboot system and check everything is fine
