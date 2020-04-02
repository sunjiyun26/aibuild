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
  # 判断本机python是否满足需求
  if [ $U_V1 -eq $V1 -a  $U_V2 -eq $V2 ]; then
   echo "Your Python is OK!"
  else
   if [ -d "/usr/bin/python-original" ]; then
    mv /usr/bin/python-original /usr/bin/python
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
  tar zxf ./Python-2.7.6.tgz -C /usr/local/src/
  # 编译并安装
  cd /usr/local/src/Python-2.7.6/
  ./configure --prefix=/usr/local/python2.7
  make&&make install
  # 建立软链接
  mv /usr/bin/python /usr/bin/python-original
  ln -s /usr/local/python2.7/bin/python2.7 /usr/bin/python
  # 检查是否安装成功
  checkPython
  # 解决安装新版本python后无法使用yum的问题
  sed -i "s/python*/python-original/g" /usr/bin/yum
  echo "updating Python finished!"
}
checkPip(){
  # 推荐使用pip-20.0.2
  PV1=19
  PV2=2
  PV3=3
  echo   need Pip version is : $PV1.$PV2.$PV3
  # 获取本机pip版本号。
   PU_V1=$( pip --version 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}')
   PU_V2=$( pip --version 2>&1 | awk '{print $2}' | awk -F '.' '{print $2}')
   PU_V3=$( pip --version 2>&1 | awk '{print $2}' | awk -F '.' '{print $3}')
   echo  your pip version is $PU_V1.$PU_V2.$PU_V3
   # 如果不是19.2.3则需要重新安装pip
    if [ $PU_V1 -eq $PV1 -a  $PU_V2 -eq $PV2 ]; then
    echo "Your pip is OK!"
    else
      if [ -d "/usr/bin/pip-original" ]; then
        mv /usr/bin/pip-original /usr/bin/pip
      fi 
    echo "Your Pip is not OK,you need to update Pip!"
    updatePip
     fi
}
updatePip(){
  yum install -y wget
  yum install -y unzip
  # 下载并安装setuptools
  cd /home 
  wget  https://files.pythonhosted.org/packages/d3/3e/1d74cdcb393b68ab9ee18d78c11ae6df8447099f55fe86ee842f9c5b166c/setuptools-40.0.0.zip 
  if [[ -f "setuptools-40.0.0.zip" ]]; then
    unzip setuptools-40.0.0.zip
    cd /home/setuptools-40.0.0
    python ./setup.py build
    python ./setup.py install
    echo "setuptools installed successfully"
    # 下载并安装pip
     cd /home
     wget https://files.pythonhosted.org/packages/00/9e/4c83a0950d8bdec0b4ca72afd2f9cea92d08eb7c1a768363f2ea458d08b4/pip-19.2.3.tar.gz
     if [[ -f "pip-19.2.3.tar.gz" ]]; then 
       tar -zxvf pip-19.2.3.tar.gz
       cd  ./pip-19.2.3
       python setup.py install
       # 建立软连接
       ln -s /usr/local/python2.7/bin/pip2.7 /usr/bin/pip2.7
       mv /usr/bin/pip /usr/bin/pip-original
       ln -s /usr/bin/pip2.7 /usr/bin/pip
     fi
   fi
  
  
  # 检查安装是否成功
  checkPip
  echo "updating pip finished"
}
# 验证python 版本
checkPython
# 验证pip版本
checkPip
# 安装依赖包
    pip install jinja2 -i https://pypi.doubanio.com/simple/
    pip install configobj -i https://pypi.doubanio.com/simple/
    pip install oauthlib -i https://pypi.tuna.tsinghua.edu.cn/simple/
    pip install pyyaml -i https://pypi.doubanio.com/simple/
    pip install requests -i  https://pypi.tuna.tsinghua.edu.cn/simple/   
    pip install jsonpatch -i  https://pypi.tuna.tsinghua.edu.cn/simple/
    pip install jsonschema -i  https://pypi.tuna.tsinghua.edu.cn/simple/ 
    pip install urwid -i  https://pypi.tuna.tsinghua.edu.cn/simple/
    pip install six -i  https://pypi.tuna.tsinghua.edu.cn/simple/