#!/bin/bash

# 上传到蒲公英

source ./get_project_info.sh

pgyerUKey="c9452a5a73cf3b222b82bf865d2a3655"  #蒲公英ukey
pgyerApiKey="59f5fd6034ecf1b3db7ea3999ef2fa31" #蒲公英apiKey

# 上传蒲公英，参数1：文件路径
# installType: 应用安装方式，值为(2,3，4)。2：密码安装，3：邀请安装，4：回答问题安装
function uploadPGY() {
  local result=$(curl -F "file=@$1" \
      -F "uKey=$pgyerUKey" \
      -F "_api_key=$pgyerApiKey" \
      -F "installType=2" \
      -F "password=666" \
      -F "updateDescription=测试更新说明" \
      -F "publishRange=1" \
      http://www.pgyer.com/apiv1/app/upload)
  # 判断上传结果
  if [[ $? != 0 || ! "${result}" =~ "http" ]]; then
      echo "上传蒲公英失败"
      return 1
  fi

  local appQRCodeURL=$(echo ${result#*http})
  appQRCodeURL=$(echo ${appQRCodeURL%\"*})
  appQRCodeURL=http${appQRCodeURL}
  echo "应用下载二维码URL：${appQRCodeURL}"

  if [[ -f ${QRCodeFile} ]]; then
    rm -f ${QRCodeFile}
  fi

  local qrFileContent="<a href=\"${appQRCodeURL}\">QRCode</a>"
  echo ${qrFileContent} > ${QRCodeFile}
}

# 找到上传文件的路径
targetFilePath=""
if [[ "$Platform" = "android" ]]; then
  apkPaths=$(find ${WorkspacePath}/build/app -name *.apk -maxdepth 1)
  if [[ -z $apkPaths ]]; then
    echo "apk文件在路径[${WorkspacePath}/build/app]下找不到"
    exit 1
  fi

  apkPathsCount=$(find ${WorkspacePath}/build/app -name *.apk -maxdepth 1 | wc -l)
  apkPathsCount=$(echo $apkPathsCount | sed 's/ //g')
  echo "apk path = $apkPaths, apkPathsCount = $apkPathsCount"

  # 如果有加固包，就选择加固包上传
  if [[ $apkPathsCount -gt 1 ]]; then
    for file in $apkPaths; do
      echo "file = $file"
      if [[ "$file" =~ "legu" ]]; then
        targetApkPath=$file
        break
      fi
    done
  else
    targetFilePath=$apkPaths
  fi
else
  targetFilePath=$(find ${ProjectPath}/build -name *.ipa -maxdepth 1)
  if [[ -z $targetFilePath ]]; then
    echo "查找IPA文件失败"
    exit 1
  fi
fi

echo "upload file path = $targetFilePath"
uploadPGY "$targetFilePath"
exit $?
