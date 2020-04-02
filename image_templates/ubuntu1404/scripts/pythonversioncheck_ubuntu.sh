#!/bin/sh

serviceInstalled() {
  command=$(dpkg -s $1)
  if  [  "$command" == "" ]; then
    echo -e "service $1 is not installed"
    return 0
  else
    echo     "service $1  has been  installed"
    return 1
  fi

}
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
  version=1
  # 判断本机python是否满足需求
  if [ $U_V1 -eq $V1 -a  $U_V2 -eq $V2 ]; then
   echo "Your Python is OK!"
  else
   if [ -d "/usr/bin/python.bak" ]; then
    mv /usr/bin/python.bak /usr/bin/python
   fi 
    echo "Your Python is not OK,you need to update Python!"
    updatePython
  fi
}
updatePython(){
  echo "begin updating Python!"
  # 安装wget以下载python安装包
  yum -y install wget
  # 安装依赖包  
  yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make
  # 下载安装包   
  cd /home
  wget http://mirrors.sohu.com/python/2.7.6/Python-2.7.6.tgz
  # 解压
  tar zxf Python-2.7.6.tgz -C /usr/local/src/
  # 编译并安装
  cd /usr/local/src/Python-2.7.6/
  ./configure --prefix=/usr/local/python2.7
  make&&make install
  # 建立软链接
  mv /usr/bin/python /usr/bin/python.bak
  ln -s /usr/local/python2.7/bin/python2.7 /usr/bin/python
  # 检查是否安装成功
  checkPython
  echo "updating Python finished!"
}
# 验证python 版本
checkPython
## 安装pip需要用到国内下载源，目前未找到



wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py    # 运行安装脚本

sudo pip install --upgrade pip


sudo pip install Jinja2
sudo pip install oauthlib

sudo pip install configobj>=5.0.2

sudopip install pyyaml

sudo pip install requests

sudo pip install jsonpatch

sudo pip install jsonschema

sudo pip install six
