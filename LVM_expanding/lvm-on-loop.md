# LVM Expansion over LOOP device on QRadar 7.4+

Emergency procedure to temporarily expand LVM volume with a LOOP device on another partition

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

This has only been tested in a LAB while preparing a "Plan B" for a DR where /opt was not properly sized and only had 2GB available on no further expansions could be possible.
In the end, this was not needed.
But the lab did complete a 7.4.3FP5 -> 7.5U7 upgrade while this hack was enabled ... :D


\
Plan
----------
1. Allocate space and setup loop device
2. Make sure loop device is activated at boot
3. Extend LVM over the new loop device and expand fs
4. (optional) Migrate to a new disk when available

\
1 - Allocate space and setup loop device
----------------------

Uee some free space on /recovery/

    lofile=/recovery/lvm-addon-1.looplvm
    fallocate -l 5G "$lofile"
    
    lomountpoint=$(findmnt -n -o TARGET --target $lofile)
    lomounttarget=$(echo "${lomountpoint}" | sed -e 's#^/##' -e 's#/#-#g')
    [[ "$lomounttarget" == "" ]] || lomounttarget="${lomounttarget}.mount"
        
    lodev=$(losetup -f)
    losetup --partscan $lodev "$lofile"
    wipefs --all $lodev

\
2 - Make sure loop device is activated at boot
----------------------

We create a systemd unit that sets up the loop device right after the volume holding the loop file has been mounted:

    lodevidx=$(echo "${lodev}" | sed -e 's#/dev/loop##')
    
    cat <<EOF | tee /etc/systemd/system/losetup-${lodevidx}.service
    [Unit]
    Description=Loop device ${lodevidx} configuration
    DefaultDependencies=no
    After=systemd-udevd.service local-fs-pre.target ${lomounttarget}
    
    [Service]
    Type=oneshot
    ExecStart=/sbin/losetup $lodev "$lofile"
    ExecStart=/sbin/partprobe $lodev
    RemainAfterExit=no
    
    [Install]
    WantedBy=local-fs.target
    EOF

        
    systemctl daemon-reload
    systemctl enable losetup-${lodevidx}.service


\
3 - Extend LVM over the new loop device and expand fs
----------------------

Let's use the new loop device to extend LVM for /opt
Change this to your needs but - beware - I only tested this specific configuration !!!

    pvcreate $lodev
    vgextend rootrhel $lodev
    lvextend /dev/rootrhel/opt -l +100%FREE $lodev
    xfs_growfs /dev/rootrhel/opt

\
4 - (optional) Migrate to a new disk when available
----------------------

Once a new real disk has been made available (e.g. sdb), we might want to migrate back from this -hack- solution:

Identify the loopdevice in use for LVM:

    loopdev=$(pvdisplay /dev/loop* 2>/dev/null | grep "PV Name" | awk '{print $3}')
    echo "${loopdev}"

Migrate LVM devices to the new disk (assuming already initialized and added to the vg):

    pvmove ${loopdev} /dev/sdb

Remove the loop device from the VG

    vgreduce rootrhel ${loopdev}

Remove the losetup systemd unit:

    systemctl disable losetup.service
    rm /etc/systemd/system/losetup.service
    systemctl daemon-reload

