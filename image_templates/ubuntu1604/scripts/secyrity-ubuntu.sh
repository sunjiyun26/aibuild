#!/bin/bash

echo 'inspur security check begin'
echo 'inspur security check begin'
echo 'inspur security check begin'

# set -e
set -x

serviceStatus2() {
  status=$(systemctl status $1 | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
  if [ "$status" == "running" ]; then
    echo         "$1 service is running！"
    return 1
  else
    echo         "$1 not start"
    return 0
  fi
}

serviceInstalled() {
  command=$(ldd /usr/bin/passwd | grep libpam)
  if  [  "$command" == "" ]; then
    echo -e "service $1 is not installed"
    return 0
  else
    echo     "service $1  has been  installed"
    return 1
  fi

}

serviceInstalled libpam-cracklib
existFlag=$?
echo $existFlag
echo '----------serviceInstalled check end---------------'

updatecommand=$(apt-get update && apt-get install libpam-cracklib)
echo $updatecommand

commonpasswordCONF=/etc/pam.d/common-password

sed -i 's/difok=3/difok=3 minclass=3/g' $commonpasswordCONF
sed -i 's/try_first_pass sha512/try_first_pass sha512 minlen=8 remember=5/g' $commonpasswordCONF

sshdConfig=/etc/ssh/sshd_config
sed -i 's/.*PermitEmptyPasswords.*/PermitEmptyPasswords   no/g' $sshdConfig
sudo tee -a $sshdConfig << EOF
MaxAuthTries 5
EOF

# 设置密码到期前7天提醒修改密码
passwordConfLoginDef=/etc/login.defs
sed -i 's/PASS_WARN_AGE\s[1-9]\d*/PASS_WARN_AGE   7/g' $passwordConfLoginDef
sed -i 's/PASS_MAX_DAYS.*[1-9]\d*/PASS_MAX_DAYS   99999/g' $passwordConfLoginDef

# 系统中不应存在除root以外UID为0的用户
accounts=$(awk -F: '$3 == 0 { print $1 }' /etc/passwd | grep -v root)
for account in $accounts; do
  sudo sed -i "s/^$account:x:0:0*/^lin:x:1000:1000/g" /etc/passwd

done

# 禁止空密码账户存在
# 禁止空密码账户存在
accountEmptys=$(awk -F: 'length($2)==0 {print $1}' /etc/shadow)
for accountEmpty in $accountEmptys; do
  passwd -l $accountEmpty

done

# 确保rsyslog服务已启用，记录日志用于审计
# serviceListening rsyslog
serviceStatus2 rsyslog
statusFlag=$?
if [ $statusFlag -eq 1 ]; then
  echo 'service has been installed and running'
else
  service rsyslog start
  echo $(serviceStatus2 rsyslog)
fi

# 如无实际业务需要建议关闭 isdn、portmap、sendmail、netfs、ftp、telnet、rlogin等。

$(service isdn stop)
$(service portmap stop)
$(service sendmail stop)
$(service netfs stop)
$(service ftp stop)
$(service telnet stop)
$(service rlogin stop)

# 在iptables中关闭高危端口
$(iptables -A INPUT -p tcp -–dport   25 -j DROP)

# 确保ufw服务已启用，记录日志用于审计
# serviceListening rsyslog
serviceStatus2 ufw
statusFlag=$?
if [ $statusFlag -eq 1 ]; then
  echo 'service ufw has been installed and running'
else
  sudo ufw enable 
  sudo ufw default deny
  echo $(serviceStatus2 ufw)
fi

# 登录超时设置。
profileConfig=/etc/profile
sudo tee -a $profileConfig << EOF
export TMOUT=600
EOF

# 访问控制
# chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
# chmod 0644 /etc/group
# chmod 0644 /etc/passwd
# chmod 0400 /etc/shadow
# chmod 0400 /etc/gshadow
$(chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow)
$(chmod 0644 /etc/group)
$(chmod 0644 /etc/passwd)
$(chmod 0400 /etc/shadow)
$(chmod 0400 /etc/gshadow)

# chown root:root /etc/hosts.allow
# chown root:root /etc/hosts.deny
# chmod 644 /etc/hosts.deny
# chmod 644 /etc/hosts.allow

$(chown root:root /etc/hosts.allow)
$(chown root:root /etc/hosts.deny)
$(chmod 644 /etc/hosts.deny)
$(chmod 644 /etc/hosts.allow)

echo 'inspur security check end'
echo 'inspur security check end'
echo 'inspur security check end'