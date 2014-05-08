#!/bin/sh -e

[ -z "$1" ] && { echo "Usage: $0 [path of RAR downloads]"; exit 1; }
TMP_DIR="$1"
[ -d "$TMP_DIR" ] || { echo $TMP_DIR missing ; exit 1; }

# Extract VMDK from archive
unrar-nonfree p -inul $TMP_DIR/*part1* | tar -xvC $TMP_DIR
VMDK="$(echo $TMP_DIR/*.vmdk)"

# Hack into a VMDK2 image (from https://github.com/erik-smit/one-liners/blob/master/qemu-img.vmdk3.hack.sh)
FULLSIZE=$(stat -c%s "$VMDK")
VMDKFOOTER=$(($FULLSIZE - 0x400))
VMDKFOOTERVER=$(($VMDKFOOTER  + 4))

case "`xxd -ps -s $VMDKFOOTERVER -l 1 \"$VMDK\"`" in
  03)
    echo "$VMDK is VMDK3, patching to VMDK2."
    /bin/echo -en '\x02' | dd conv=notrunc status=noxfer oflag=seek_bytes seek="$VMDKFOOTERVER"  of="$VMDK"
    ;;
  02)
    echo "Already a VMDK2 file"
    ;;
  default)
    echo "$VMDK is neither version 2 or 3"
    exit 1
  ;;
esac

# Convert into QCOW2
qemu-img convert -f vmdk -O qcow2 "$VMDK" "$(basename $TMP_DIR/*.ovf .ovf).qcow2"

echo Finished! Delete $TMP_DIR to tidy up
