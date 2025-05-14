qemu-system-x86_64 \
	-cpu qemu64 \
	-nographic \
	-drive if=pflash,format=raw,unit=0,file=/usr/share/ovmf/x64/OVMF_CODE.4m.fd,readonly=on \
	-drive if=pflash,format=raw,unit=1,file=OVMF_VARS.4m.fd \
	-net none
