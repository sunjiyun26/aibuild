#!/bin/sh



checkPython() {
  #推荐版本V2.7
  V1=2
  V2=7
  V3=5

  echo   need python version is : $V1.$V2.$V3

  

  #获取本机python版本号。这里2>&1是必须的，python -V这个是标准错误输出的，需要转换
  U_V1=$( python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}')
  U_V2=$( python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $2}')
  U_V3=$( python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $3}')

  echo   your python version is : $U_V1.$U_V2.$U_V3

  #   if   [ "$U_V1" -lt $V1 ]]; then
  if   [[ $U_V1 -eq $V1 ]]; then
    echo     'Your python version is not OK!(1)'
  elif   [[ "$U_V1" -eq $V1 ]]; then
    if     [[ $U_V2 -lt $V2 ]]; then
      echo       'Your python version is not OK!(2)'
    elif     [[ $U_V2 -eq $V2 ]]; then
      if       [[ $U_V3 -lt $V3 ]]; then
        echo         'Your python version is not OK!(3)'
      fi
    fi
  fi

  echo   Your python version is OK!
}
# --验证python 版本
checkPython



yum -y install epel-release
yum -y install python-pip

# wget https://bootstrap.pypa.io/get-pip.py
# python get-pip.py    # 运行安装脚本

pip install --upgrade pip


# pip install selectivesearch -i http://pypi.douban.com/simple --trusted-host pypi.douban.com

pip install Jinja2 -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  --upgrade
pip install oauthlib -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  --upgrade

pip install configobj>=5.0.2 -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  --upgrade

pip install pyyaml -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  --upgrade

pip install requests -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  --upgrade

pip install jsonpatch -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  --upgrade

pip install jsonschema -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  --upgrade

pip install six -i http://pypi.douban.com/simple --trusted-host pypi.douban.com  --upgrade
