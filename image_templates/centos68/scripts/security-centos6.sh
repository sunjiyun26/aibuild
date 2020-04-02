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

# 设置密码长度最小为8位，至少包含小写字母、大写字母、数字、特殊字符等4类字符
systemAuthConf=/etc/pam.d/system-auth
sed -i  "s/pam_cracklib.so.*/&  minlen=8 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1/g" $systemAuthConf

# 强制用户不使用最近5次的密码
sed -i  "s/^password.*sufficient.*pam_unix.so.*/&  remember=5/g" $systemAuthConf

# /etc/pam.d/password-auth
passwordConf=/etc/pam.d/password-auth
# 强制用户不使用最近5次的密码
sed -i  "s/^password.*sufficient.*pam_unix.so.*/&  remember=5/g" $passwordConf

# 设置密码到期前7天提醒修改密码
passwordConfLoginDef=/etc/login.defs
sed -i 's/PASS_WARN_AGE\s[1-9]\d*/PASS_WARN_AGE   7/g' $passwordConfLoginDef
sed -i 's/PASS_MAX_DAYS.*[1-9]\d*/PASS_MAX_DAYS   99999/g' $passwordConfLoginDef

# 系统中不应存在除root以外UID为0的用户
accounts=$(awk -F: '$3 == 0 { print $1 }' /etc/passwd | grep -v root)
if [ -n "$accounts" ]; then
  for account in $accounts; do
    sed -i "s/^$account:x:0:0*/^lin:x:1000:1000/g" /etc/passwd

  done
fi

# 禁止空密码账户存在
accountEmptys=$(awk -F: 'length($2)==0 {print $1}' /etc/shadow)
for accountEmpty in $accountEmptys; do
  passwd -l $accountEmpty

done

# 禁止空密码用户使用SSH登录
# 使用SSH登录时，最大密码尝试失败次数为5次。
sshdConfig=/etc/ssh/sshd_config
sed -i 's/.*PermitEmptyPasswords.*/PermitEmptyPasswords   no/g' $sshdConfig
tee -a $sshdConfig << EOF
MaxAuthTries 5
EOF

# -----密码相关结束-----------

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

tee -a $sshdConfig << EOF
LogLevel INFO
EOF

# ---------安全审计结束-----------

# 如无实际业务需要建议关闭 isdn、portmap、sendmail、netfs、ftp、telnet、rlogin等。

$(service isdn stop)
$(service portmap stop)
$(service sendmail stop)
$(service netfs stop)
$(service ftp stop)
$(service telnet stop)
$(service rlogin stop)

# 在iptables中关闭高危端口
$(iptables -A INPUT -p tcp –-dport     25 -j DROP)

# service iptable status

# 防火墙
serviceStatus2 iptable
statusFlag=$?
if [ $statusFlag -eq 1 ]; then
  echo 'service iptable has been installed and running'
else
  servcie iptables start
  chkconfig iptables on
  echo 'iptables status '$(serviceStatus2 iptable)
fi

$(service iptables save)
sleep 3
$(service iptables restart)

# $sshdConfig
Protocol 2
sed -i 's/#Protocol 2/Protocol 2/g' $sshdConfig

#----------- 防火墙结束------------

# 登录超时设置。
profileConfig=/etc/profile
tee -a $profileConfig << EOF
export TMOUT=600
EOF

# 访问控制
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
