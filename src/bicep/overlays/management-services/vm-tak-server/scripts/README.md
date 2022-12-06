# TakImage
Scripts to configure a TAK Server on Linux image for use in Azure Deployments

- On a configured base Linux image, run the install script.
  - `. install.sh`
- This will create two cronjobs:
  - `# Run the init_server script at next reboot
  - `@reboot /bin/bash /root/init_server.sh`
  - `# Remove the default repos at reboot`
  - `@reboot /bin/rm -f /etc/yum.repos.d/CentOS*.repo`
- Additional commands and scripts should be added to init_server.sh
- Teardown of any additions to init_server.sh should be added to generalize.sh
