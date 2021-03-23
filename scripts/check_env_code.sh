#!/bin/bash

# 检查代码环境相关配置

echo "current path = $PWD, file name = $0"
source ./get_project_info.sh
source ./flutter_version_active.sh

# 获取传递给脚本的参数
params=("$@")
for ((i=0; i<$#; i++ )); do
  item=${params[$i]}
  echo "参数 = $item"
done

# 设置 Flutter 环境
cd ${WorkspacePath}
test -f .packages && rm -f .packages
test -f pubspec.lock && rm -f pubspec.lock
test -f ios/Podfile.lock && rm -f ios/Podfile.lock

echo "🌹🌹🌹执行flutter pub get"
flutter pub get
if [[ $? -ne 0 ]]; then
  echo "❌❌❌ flutter pub get 执行失败"
  exit 1
fi

BuildVersion=$(echo ${BuildVersion} | sed 's/ //g') # 去空格
echo "BuildVersion = $BuildVersion, BuildNumber = $BuildNumber"

###### 1. 修改版本号
if [[ -n "$BuildVersion" ]]; then
  echo "1️⃣ 处理版本信息 ⏩"
  updateVersionInfo
  if [[ $? -ne 0 ]]; then
    echo "1️⃣ 处理版本信息 ❌"
    exit 1
  fi
  echo "1️⃣ 处理版本信息 ⏪"
fi

###### 2. 修改工程配置文件
echo "2️⃣ 处理工程配置文件 ⏩"
updateProjectConfigFile
if [[ $? -ne 0 ]]; then
  echo "2️⃣ 处理工程配置文件 ❌"
  exit 1
fi
echo "2️⃣ 处理工程配置文件 ⏪"

###### 3. 修改Flutter Mode配置
echo "3️⃣ 修改Flutter Mode配置 ⏩"
updateFlutterMode
if [[ $? -ne 0 ]]; then
  echo "3️⃣ 修改Flutter Mode配置 ❌"
  exit 1
fi
echo "3️⃣ 修改Flutter Mode配置 ⏪"

###### 10. 修改环境配置，如host url，各种第三方key，小程序分享类型等
echo "🔟 执行App相关脚本 ${WorkspacePath}/scripts/check_env_code_$AppIdentifier.sh ⏩"
cd ${WorkspacePath}/scripts
if [[ ! -f check_env_code_$AppIdentifier.sh ]]; then
  echo "⁉️⁉️⁉️ $check_env_code_$AppIdentifier.sh 文件不存在，跳过该处理"
else
  # 这里用source是为了脚本中可能会export一些变量给外部使用
  source ./check_env_code_$AppIdentifier.sh
  if [[ $? -ne 0 ]]; then
    echo "🔟 执行App相关脚本 ❌"
    exit 1
  fi
  echo "🔟 执行App相关脚本 ⏪"
fi

