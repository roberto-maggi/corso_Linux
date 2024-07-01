# backup_nginx.sh
#!/bin/bash
# /usr/bin/tar cvfj www_dir-$(date +'%d-%m-%Y'-%H.%M).tar.gz -C /var/www/ .  > /dev/null 2>&1 
# /usr/bin/tar cvfj www_dir-$(date +'%d-%m-%Y'-%H.%M).tar.gz -C /var/log/nginx .  > /dev/null 2>&1 