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
3. Add LVM extents: 
   - Option A (safest): just add a separate virtual disk
   - Option B: extend over existing virtual disk and add a new partition
   - ~~Option C (complicated): extend over existing virtual disk, preserving existing layout~~
4. Extend LV
5. Grow XFS volume
6. Reboot

\
0 - Inspect Disk Layout
----------------------

Get Disk/Partitions Layout:

	lsblk -f -p
<!-- -->
	NAME                                 FSTYPE      LABEL UUID                                   MOUNTPOINT
	/dev/sda
	├─/dev/sda1
	├─/dev/sda2                          xfs               938ef8ed-39b8-4638-b200-fc7402595258   /boot
	├─/dev/sda3                          xfs               55c2aed0-a933-4775-bd24-f43a533a86ab   /recovery
	├─/dev/sda4                          LVM2_member       nQhv0f-bikx-kVba-uVtM-jfGV-a2ci-Nwj1rL
	│ ├─/dev/mapper/storerhel-transient  xfs               cceae07f-44d3-4011-965f-7206bf32efab   /transient
	│ └─/dev/mapper/storerhel-store      xfs               f72d1975-c8d4-4359-bd76-d976388b2481   /store
	├─/dev/sda5                          LVM2_member       E9f26P-yde5-uStL-XYlk-JuEF-ooWx-P3ZQR3
	│ ├─/dev/mapper/rootrhel-root        xfs               6318ec5f-f504-467e-977f-879e1190274b   /
	│ ├─/dev/mapper/rootrhel-storetmp    xfs               be7a1ed4-9e73-40e9-aaa5-46d8c5e40794   /storetmp
	│ ├─/dev/mapper/rootrhel-tmp         xfs               c53ae190-4071-45d6-8a48-f5e78083d1eb   /tmp
	│ ├─/dev/mapper/rootrhel-home        xfs               92e975dc-95a0-4b1a-88af-a197c97e5da6   /home
	│ ├─/dev/mapper/rootrhel-opt         xfs               54f17a1c-1ac6-4b9e-b79d-7fce890ef336   /opt
	│ ├─/dev/mapper/rootrhel-varlogaudit xfs               87521bfb-28e1-4b9f-9458-c860f0e554ea   /var/log/audit
	│ ├─/dev/mapper/rootrhel-varlog      xfs               fbec1486-b47f-4aa3-aabb-eea1e3ebbde8   /var/log
	│ └─/dev/mapper/rootrhel-var         xfs               a4453252-4459-4a68-8f5d-52222ee88709   /var
	└─/dev/sda6                          swap              887b0b32-32fb-4632-b6f7-ef5bc1a27b97   [SWAP]
<!-- -->
	blkid
<!-- -->
	/dev/sda1: PARTUUID="5e1cc006-791e-4ca8-b12d-5f1f3f22a804"
	/dev/sda2: UUID="938ef8ed-39b8-4638-b200-fc7402595258" TYPE="xfs" PARTUUID="644bbb4f-e404-4e43-ac6e-866903044900"
	/dev/sda3: UUID="55c2aed0-a933-4775-bd24-f43a533a86ab" TYPE="xfs" PARTUUID="ff9eea7b-1db2-43a9-9807-28971edbc30b"
	/dev/sda4: UUID="nQhv0f-bikx-kVba-uVtM-jfGV-a2ci-Nwj1rL" TYPE="LVM2_member" PARTUUID="30064e1a-301c-43a6-bcaf-b0da9f8bbfc5"
	/dev/sda5: UUID="E9f26P-yde5-uStL-XYlk-JuEF-ooWx-P3ZQR3" TYPE="LVM2_member" PARTUUID="9f4d475b-ef15-4c2f-a705-8693cdf7a5c1"
	/dev/sda6: UUID="887b0b32-32fb-4632-b6f7-ef5bc1a27b97" TYPE="swap" PARTUUID="b1a43033-1a9c-497b-adf6-0030e35c6117"
	/dev/mapper/rootrhel-root: UUID="6318ec5f-f504-467e-977f-879e1190274b" TYPE="xfs"
	/dev/mapper/rootrhel-storetmp: UUID="be7a1ed4-9e73-40e9-aaa5-46d8c5e40794" TYPE="xfs"
	/dev/mapper/rootrhel-tmp: UUID="c53ae190-4071-45d6-8a48-f5e78083d1eb" TYPE="xfs"
	/dev/mapper/rootrhel-home: UUID="92e975dc-95a0-4b1a-88af-a197c97e5da6" TYPE="xfs"
	/dev/mapper/rootrhel-opt: UUID="54f17a1c-1ac6-4b9e-b79d-7fce890ef336" TYPE="xfs"
	/dev/mapper/rootrhel-varlogaudit: UUID="87521bfb-28e1-4b9f-9458-c860f0e554ea" TYPE="xfs"
	/dev/mapper/rootrhel-varlog: UUID="fbec1486-b47f-4aa3-aabb-eea1e3ebbde8" TYPE="xfs"
	/dev/mapper/rootrhel-var: UUID="a4453252-4459-4a68-8f5d-52222ee88709" TYPE="xfs"
	/dev/mapper/storerhel-transient: UUID="cceae07f-44d3-4011-965f-7206bf32efab" TYPE="xfs"
	/dev/mapper/storerhel-store: UUID="f72d1975-c8d4-4359-bd76-d976388b2481" TYPE="xfs"
<!-- -->
	df -l -T -x tmpfs -x devtmpfs -x overlay
<!-- -->
	Filesystem                       Type 1K-blocks     Used Available Use% Mounted on
	/dev/mapper/rootrhel-root        xfs   13096960  3992124   9104836  31% /
	/dev/sda2                        xfs    1038336   316644    721692  31% /boot
	/dev/sda3                        xfs   33538048  5498856  28039192  17% /recovery
	/dev/mapper/rootrhel-home        xfs    1038336    34188   1004148   4% /home
	/dev/mapper/storerhel-transient  xfs   29615996    33144  29582852   1% /transient
	/dev/mapper/rootrhel-var         xfs    5232640   215428   5017212   5% /var
	/dev/mapper/storerhel-store      xfs  118468080 23794792  94673288  21% /store
	/dev/mapper/rootrhel-storetmp    xfs   15718400    43372  15675028   1% /storetmp
	/dev/mapper/rootrhel-opt         xfs   13096960  4727380   8369580  37% /opt
	/dev/mapper/rootrhel-tmp         xfs    3135488    38376   3097112   2% /tmp
	/dev/mapper/rootrhel-varlog      xfs   15718400   304136  15414264   2% /var/log
	/dev/mapper/rootrhel-varlogaudit xfs    3135488    96644   3038844   4% /var/log/audit
<!-- -->
	mount | sort | grep -v ca_jail | grep xfs
<!-- -->
	/dev/mapper/rootrhel-home on /home type xfs (rw,nosuid,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/mapper/rootrhel-opt on /opt type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/mapper/rootrhel-root on / type xfs (rw,noatime,attr2,inode64,noquota)
	/dev/mapper/rootrhel-storetmp on /storetmp type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/mapper/rootrhel-tmp on /tmp type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/mapper/rootrhel-varlogaudit on /var/log/audit type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/mapper/rootrhel-varlog on /var/log type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/mapper/rootrhel-var on /var type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/mapper/storerhel-store on /store type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/mapper/storerhel-transient on /transient type xfs (rw,noatime,attr2,nobarrier,inode64,logbsize=256k,noquota)
	/dev/sda2 on /boot type xfs (rw,relatime,attr2,inode64,noquota)
	/dev/sda3 on /recovery type xfs (rw,relatime,attr2,inode64,noquota)
<!-- -->
	swapon -s
<!-- -->
	Filename                                Type            Size    Used    Priority
	/dev/sda6                               partition       15405052        62720   -2
<!-- -->
	parted -s /dev/sda unit s print
<!-- -->
	Model: VMware, VMware Virtual S (scsi)
	Disk /dev/sda: 536870912s
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags: pmbr_boot
	
	Number  Start       End         Size        File system     Name  Flags
	 1      2048s       4095s       2048s                             bios_grub
	 2      4096s       2101247s    2097152s    xfs
	 3      2101248s    69210111s   67108864s   xfs
	 4      69210112s   365539327s  296329216s                        lvm
	 5      365539328s  506056703s  140517376s                        lvm
	 6      506056704s  536866815s  30810112s   linux-swap(v1)

\
1 - Ensure a full backup
------------------------

**DO NOT SKIP THIS STEP**
\
VM backup or cold-snapshot must be readily available in case of disaster/errors.


\
2 - Stop all services
---------------------

I tried with everything still running, this is just to be on a safer side...
\
Stop QRadar services (last line is optional, should be safe enough as long as the db is shut down):

	systemctl stop ecs-ec-ingress
	systemctl stop ecs-ep
	service hostcontext stop
	service tomcat stop
	service hostservices stop 
	systemctl stop systemStabMon crond chronyd postfix snmpd containerd rhnsd rhsmcertd syslog

You may also want to disable automatic startup of the services BEFORE shutting down the VM (or disable network connectivity).

\
3 - Option A - Add LVM space by using a new virtual disk (assuming /dev/sdb)
----------------------------------------------------------------------------

This is a safer option: just add a new virtual disk to the VM.
\
It can generally be done online - if disk does not show up, either reboot or:

	/usr/bin/rescan-scsi-bus.sh

or these alternative low-level commands:
	
	ls /sys/class/scsi_host/
	echo "- - -" > /sys/class/scsi_host/host0/scan
	echo "- - -" > /sys/class/scsi_host/host1/scan
	echo "- - -" > /sys/class/scsi_host/host2/scan
	udevadm trigger --verbose --subsystem-match=block; udevadm settle
	udevadm trigger --verbose --type=devices --subsystem-match=scsi_disk ; udevadm settle

Re-read partition table

	partprobe /dev/sdb

Create LVM PV on the whole disk
	
	pvcreate /dev/sdb

Add the new PV to VG `storerhel` or `rootrhel` - e.g.:

  	vgextend storerhel /dev/sdb

\
3 - Option B - Add LVM space by extending an existing virtual disk and creating a new partition
-----------------------------------------------------------------------------------------------

Extend the virtual disk (e.g., adding +512GB):
\
On ESXi, this can be done online - https://kb.vmware.com/s/article/1004047
\
If you can plan for a longer downtime, just do it offline...
\
To re-read the new disk size:

	/usr/bin/rescan-scsi-bus.sh

or this alternative low-level command:

	echo 1 > /sys/class/block/sda/device/rescan

Re-read partition table

	partprobe /dev/sda

\
Verify the new size has been detected

	parted -s /dev/sda unit s print | grep "Disk /dev/sda"
<!-- -->
	Disk /dev/sda: 1073741824s
\
From the parted output in step 0, we take the last partition ending sector (536866815s) and add 1 to it (536866816s): this will be the starting sector for the next partition that we're creating:

	parted  /dev/sda

The `parted` commands will be:

	unit s
	mkpart
	(just hit Enter at the partition naming question)
	(just hit Enter at the filesystem question)
	536866816s
	100%
	set 7 lvm on
	quit

Output example:

	GNU Parted 3.1
	Using /dev/sda
	Welcome to GNU Parted! Type 'help' to view a list of commands.
	(parted) unit s
	(parted) mkpart
	Warning: Not all of the space available to /dev/sda appears to be used, you can fix the GPT to use all of the space (an extra ... blocks) or continue with the current setting?
	Fix/Ignore? Fix
	Partition name?  []?
	File system type?  [ext2]?
	Start? 536866816s
	End? 100%
	(parted) set 7 lvm on
	(parted) quit
	Information: You may need to update /etc/fstab.

Notice: some times there might be an extra warning re mismatched available space. You can answer "Fix".
\
Check outcome:

	parted -s /dev/sda unit s print
<!-- -->
	Model: VMware, VMware Virtual S (scsi)
	Disk /dev/sda: 1073741824s
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags: pmbr_boot
	
	Number  Start       End          Size        File system     Name  Flags
	 1      2048s       4095s        2048s                             bios_grub
	 2      4096s       2101247s     2097152s    xfs
	 3      2101248s    69210111s    67108864s   xfs
	 4      69210112s   365539327s   296329216s                        lvm
	 5      365539328s  506056703s   140517376s                        lvm
	 6      506056704s  536866815s   30810112s   linux-swap(v1)
	 7      536866816s  1073739775s  536872960s                        lvm


Create LVM PV on the new partition
	
	pvcreate /dev/sda7

Add the new PV to VG `storerhel` or `rootrhel` - e.g.:

  	vgextend storerhel /dev/sda7

\
3 - ~~Option C - Add LVM space by extending an existing virtual disk and maintaining original layout~~
--------------------------------------------------------------------------------------------------

We need to remove the swap partition from  on /dev/sda6, to allow for /dev/sda5 expansion, then we re-create swap.
\
This was just an "experiment" - really not required...
\
\
This option has been REMOVED, it was unstable and complicated. If you're curious, just inspect repo history - DO NOT TRUST THIS SECTION !!!

\
4 - Extend LV
-------------

Extend the required logical volumes, e.g.:

- `storerhel`

		lvextend -l +90%FREE  /dev/storerhel/store
		lvextend -l +100%FREE /dev/storerhel/transient
- `rootrhel`

		lvextend -L +5G   /dev/rootrhel/root
		lvextend -L +5G   /dev/rootrhel/storetmp
		lvextend -L +5G   /dev/rootrhel/tmp
		lvextend -L +5G   /dev/rootrhel/home
		lvextend -L +5G   /dev/rootrhel/opt
		lvextend -L +1G   /dev/rootrhel/var
		lvextend -L +5G   /dev/rootrhel/varlogaudit
		lvextend -L +100% /dev/rootrhel/varlog

\
5 - Grow XFS Volumes
--------------------

    xfs_growfs /dev/rootrhel/root
    xfs_growfs /dev/rootrhel/storetmp
    xfs_growfs /dev/rootrhel/tmp
    xfs_growfs /dev/rootrhel/home
    xfs_growfs /dev/rootrhel/opt
    xfs_growfs /dev/rootrhel/varlogaudit
    xfs_growfs /dev/rootrhel/varlog
    xfs_growfs /dev/rootrhel/var
    xfs_growfs /dev/storerhel/store
    xfs_growfs /dev/storerhel/transient

\
6 - Reboot
----------

Reboot system and check everything is fine
\
Commit VM snapshot.
