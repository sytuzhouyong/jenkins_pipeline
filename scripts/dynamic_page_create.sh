#!/bin/bash
# set -eux
# set -o pipefail

# 首次制作动态包，步骤包括如下：
# 1. 生成missile工具
# 2. 生成scan工具
# 3. 通过missile工具将给定目录下的dart文件转成json文件
# 4. 通过scan工具扫描dart库以及三方代码和yaml文件，生成mars_proxy工程
source ./get_project_info.sh
source ./flutter_version_active.sh
source ./utils_aliyun.sh

cd ${WorkspacePath}/vendor/zn_dart_vm/missile_vm
flutter pub get
if [[ $? -ne 0 ]]; then
    echo "flutter pub get in zn_dart_vm/missile_vm failed"
    exit 1
fi

cd ${WorkspacePath}/vendor/zn_dart_vm
bash ./missile_vm_start.sh "${WorkspacePath}"
if [[ $? -ne 0 ]]; then
    echo "missile_vm_start.sh execute failed"
    exit 1
fi
if [[ ! -d ${WorkspacePath}/dart_vm ]]; then
    echo "dart_vm目录没有生成"
    exit 1
fi
