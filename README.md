# dotfiles

My dotfiles and init scripts.

## vmware integration

[How to mount](https://docs.vmware.com/en/VMware-Workstation-Pro/15.0/com.vmware.ws.using.doc/GUID-AB5C80FE-9B8A-4899-8186-3DB8201B1758.html) shared folders into guest os:

```bash
sudo /usr/bin/vmhgfs-fuse .host:/ /home/denis/shares -o subtype=vmhgfs-fuse,allow_other
```
