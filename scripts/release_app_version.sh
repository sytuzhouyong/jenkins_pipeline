#!/bin/bash

set -e
# set -x
set -o pipefail

source ./utils_aliyun.sh
source ./utils_version_update.sh

function uploadFileName() {
  local timestamp=$(echo "$BuildString" | sed "s/-//g" | sed "s/ //g" | sed "s/://g")
  local ext="apk"
  if [[ "$Platform" = "ios" ]]; then
    ext="ipa"
  fi
  local fileName=${AppIdentifier}_${AppPackageType}_${BuildVersion}_${timestamp}.${ext}
  echo ${fileName}
}

function releaseAppVersion() {
  local appFilePath=""
  local uploadFileUrl=$(uploadFileName)

  if [[ "$Platform" = "ios" ]]; then
    appFilePath=$(find $BuildPath -d 1 -name "*.ipa") # path/to/Runner.ipa
  else
    # 这里后面要兼顾有多个渠道包的情况，因为铁军没有，所以这里先不考虑，后面再补上
    local apkFileDir=$WorkspacePath/build/app/outputs/apk
    appFilePath=`find $apkFileDir -name "*.apk" | tail -n 1`
  fi

  if [[ -z "$appFilePath" ]]; then
    echo "没有找到要上传的包文件"
    return 1
  fi
  echo "appFilePath = $appFilePath"

  # 1. 上传版本到阿里云
  uploadFileToAliyun "$appFilePath" "$uploadFileUrl"
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  # 2. 将版本信息调用接口存到数据库
  addAppVersion $AliyunUploadFileUrl
  if [[ $? -ne 0 ]]; then
    return 1
  fi
}

# 上传.dart.out文件压缩包
function releaseResourceVersion() {
  local fileList=$(ls ${WorkspacePath}/dart_vm)
  if [[ -z "${fileList}" ]] ; then
    echo "dart_vm目录为空"
    return 1
  fi

  if [[ -z "${PatchVersion}" ]]; then
    PatchVersion="1.0.0"
  fi
  timestamp=$(echo "$BuildString" | sed "s/-//g" | sed "s/ //g" | sed "s/://g")
  zipFileName=${AppIdentifier}_${AppPackageType}_${BuildVersion}_patch_${PatchVersion}_${timestamp}.zip
  zipFilePath=${WorkspacePath}/dart_vm/${zipFileName}

  # 压缩文件
  cd ${WorkspacePath}/dart_vm
  rm -f *.zip > /dev/null
  zip -r ${zipFileName} .
  if [[ $? -ne 0 || ! -f ${zipFileName} ]]; then
    echo "压缩文件 ${zipFileName}.zip 失败"
    return 1
  fi

  uploadFileToAliyun $zipFilePath $zipFileName
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  addResourceVersion $AliyunUploadFileUrl
  if [[ $? -ne 0 ]]; then
    return 1
  fi
}

if [[ "${isPublishApp}" = "true" ]]; then
  releaseAppVersion
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
fi

releaseResourceVersion
if [[ $? -ne 0 ]]; then
  exit 1
fi
