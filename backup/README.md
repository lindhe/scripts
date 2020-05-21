# Setup backup scripts

Begin by creating a new zfs volume for the backup on the server:
`sudo zfs create storage/backups/...`

```bash
sudo mkdir /etc/backup
# Populate /etc/backup/authorized_networks.txt with desired SSID
sudo cp exclude.txt /etc/backup/exclude.txt
# Create cronjob: @daily date '+%s' > /etc/backup/alive
# Edit backup.sh according to your needs
sudo cp backup.sh /etc/backup/backup.sh
# Configure /root/.ssh/config with host named backup
```

Remember to update the `~/.ssh/authorized_keys` with a new `command="..."` line
if using this guide:
https://www.guyrutenberg.com/2014/01/14/restricting-ssh-access-to-rsync/

