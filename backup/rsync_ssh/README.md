# Setup backup scripts

1. Begin by creating a new zfs volume for the backup on the server:

  ```shell
  sudo zfs create storage/backups/...
  ```

2. Install the script on the client computer:

  ```shell
  sudo make install
  ```

Remember to update the `~/.ssh/authorized_keys` with a new `command="..."` line
if using this guide:
https://www.guyrutenberg.com/2014/01/14/restricting-ssh-access-to-rsync/

