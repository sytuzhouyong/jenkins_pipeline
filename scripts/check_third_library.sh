#!/bin/bash

# gsed --help > /dev/null
# if [[ $? != 0 ]]; then
# echo "没有安装 gnu-sed，开始安装..."
# brew install gnu-sed
# fi

# xcpretty --help > /dev/null
# if [[ $? != 0 ]]; then
# echo "没有安装 xcpretty，开始安装..."
# gem install xcpretty
# fi

SHARED_LIBRARY_PATH="${WORKSPACE}/../${JOB_NAME}@libs/pipeline-shared-library"
if [[ ! -d "${SHARED_LIBRARY_PATH}" ]]; then
  echo "${SHARED_LIBRARY_PATH}目录不存在"
  exit 1
fi

# 1. 拷贝脚本文件
# 文件不能放在子模块目录下，因为子模块会在更新代码阶段删除重新下载
function copyScriptFiles() {
  local sourceDir=${SHARED_LIBRARY_PATH}/scripts
  if [[ ! -d "$sourceDir" ]]; then
    echo "脚本目录文件不存在：${sourceDir}"
    exit 1
  fi

  targetDir=${WORKSPACE}/scripts
  test -d ${targetDir} && rm -rf ${targetDir}
  mkdir -p ${targetDir}

  echo "source dir = ${sourceDir}, target dir = ${targetDir}"
  cp -r ${sourceDir}/* ${targetDir}/
}

function copyPlistFiles() {
  # 2. 拷贝资源文件
  local sourceDir=${SHARED_LIBRARY_PATH}/resources/export_plist_files/${AppIdentifier}
  if [[ ! -d "$sourceDir" ]]; then
    echo "plist资源目录不存在：${sourceDir}"
    exit 1
  fi
  targetDir=${WORKSPACE}/export_plist_files
  test -d ${targetDir} && rm -rf ${targetDir}
  mkdir -p ${targetDir}
  cp -r ${sourceDir}/* ${targetDir}/
}


copyScriptFiles

if [[ "${Platform}" = "ios" ]]; then
  copyPlistFiles
fi
