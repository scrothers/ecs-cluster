#!/bin/bash

echo "[+] Run a system update first."
/usr/bin/yum -y update

echo "[+] Stopping unneeded services on the host."
SERVICES_STOP=(auditd netconsole sendmail)
for SERVICE in "$${SERVICES_STOP[@]}"; do
   /sbin/service $SERVICE stop
   /sbin/chkconfig $SERVICE off
done

echo "[+] Install additional required packages."
/usr/bin/yum -y erase ntp*
/usr/bin/yum -y install nfs-utils chrony awslogs amazon-ssm-agent

echo "[+] Configuring IAM lockdown for containers on the host."
/sbin/sysctl -w net.ipv4.conf.all.route_localnet=1
/sbin/iptables --insert FORWARD 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP
/sbin/iptables -t nat -A PREROUTING -p tcp -d 169.254.170.2 --dport 80 -j DNAT --to-destination 127.0.0.1:51679
/sbin/iptables -t nat -A OUTPUT -d 169.254.170.2 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679
/sbin/service iptables save

echo "[+] Setting up EFS on the host."
/bin/mkdir /efs
echo "" >> /etc/fstab
echo "${EFS_HOST}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2" >> /etc/fstab
/bin/mount /efs

echo "[+] Set up the chrony ntp service for AWS."
/sbin/service chronyd start

echo "[+] Start the Amazon SSM agent."
/sbin/start amazon-ssm-agent

echo "[+] Configuring ECS agent on the host."
cat <<EOF > /etc/ecs/ecs.config
ECS_CLUSTER=${ECS_CLUSTER}
ECS_RESERVED_PORTS = [22, 2375, 2376, 51678, 62689]
ECS_RESERVED_PORTS_UDP = []
ECS_UPDATES_ENABLED = true
ECS_RESERVED_MEMORY = 128
ECS_DISABLE_PRIVILEGED = true
ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION = 4h
ECS_ENABLE_TASK_IAM_ROLE = true
ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST = true
ECS_IMAGE_CLEANUP_INTERVAL = 10m
ECS_IMAGE_MINIMUM_CLEANUP_AGE = 30m
ECS_NUM_IMAGES_DELETE_PER_CYCLE = 10
ECS_ENABLE_CONTAINER_METADATA = true
EOF

echo "[+] Configuring awslogsd agent on the host."
cat <<EOF > /etc/awslogs/awslogs.conf
[plugins]
cwlogs = cwlogs

[default]
region = ${REGION}
EOF
cat <<EOF > /etc/awslogs/awslogs.conf
[general]
state_file = /var/lib/awslogs/agent-state

[dmesg]
datetime_format = %b %d %H:%M:%S
file = /var/log/dmesg
buffer_duration = 5000
initial_position = start_of_file
log_group_name = /var/log/dmesg
log_stream_name = {instance_id}

[docker]
datetime_format = %b %d %H:%M:%S
file = /var/log/docker
buffer_duration = 5000
initial_position = start_of_file
log_group_name = /var/log/docker
log_stream_name = {instance_id}

[ssm-agent]
datetime_format = %b %d %H:%M:%S
file = /var/log/amazon/ssm/amazon-ssm-agent.log
buffer_duration = 5000
initial_position = start_of_file
log_group_name = /var/log/amazon/ssm/amazon-ssm-agent.log
log_stream_name = {instance_id}

[ecs-agent]
datetime_format = %b %d %H:%M:%S
file = /var/log/ecs/ecs-agent.log.*
buffer_duration = 5000
initial_position = start_of_file
log_group_name = /var/log/ecs/ecs-agent.log
log_stream_name = {instance_id}
EOF

echo "[+] Start the awslogsd agent."
/sbin/service awslogs start

echo "[+] Configure the ssh daemon to run non-standard."
cat <<EOF > /etc/ssh/sshd_config
Port 62689
AddressFamily inet
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Logging
#SyslogFacility AUTH
SyslogFacility AUTHPRIV
#LogLevel INFO

# Authentication:
PermitRootLogin forced-commands-only
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no

# Configuration settings
UsePAM yes
X11Forwarding no
PrintLastLog yes
TCPKeepAlive yes
UsePrivilegeSeparation sandbox
ShowPatchLevel no
UseDNS no
PermitTunnel no

# Accept locale-related environment variables
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS
EOF

echo "[+] Restart the ssh daemon."
/sbin/service sshd restart

echo "[+] Install the AWS CloudWatch monitor."
cat <<EOF > /usr/local/sbin/aws-mon.sh
${AWS-MON-SCRIPT}
EOF
/bin/chmod +x /usr/local/sbin/aws-mon.sh
cat <<EOF > /etc/cron.d/awslogs
MAILTO=""

* * * * * root /usr/local/sbin/aws-mon.sh --from-cron --cpu-sy --cpu-id --cpu-wa --cpu-us --cpu-st --load-ave1 --load-ave5 --load-ave15 --mem-util --context-switch > /dev/null 2>&1
EOF
