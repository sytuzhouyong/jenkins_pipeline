#!/bin/bash
set -e
# set +x
set -o pipefail

source ./get_project_info.sh

##开发者账号
userName='devgroup@znlhzl.com'
##开发者账号密码，暂且不用，使用APP专用密码
##password=Work123456?
##APP专用密码(使用APP专用密码上传ipa才会成功)
password='dmyq-bvus-htxx-oznl'
##密钥ID
api_key='GW6K9Z54L2'
##发行人ID
api_issuer='1c5fb637-7191-4bcc-b173-b334ff742ffa'

cd $BuildPath
filePath=$(find . -d 1 -name "*.ipa")
echo "文件路径：$filePath"

echo "㊗️㊗️㊗️ 整个过程耗时较长，需耐心等待"
echo "=============== 正在验证ipa包... ==============="
xcrun altool --validate-app -f ${filePath} -t ios -u ${userName} -p ${password} --apiKey ${api_key} --apiIssuer ${api_issuer} --output-format xml
if [ $? -ne 0 ]; then
  echo "=============== 验证ipa包失败 ==============="
  exit 1
fi
echo "=============== 验证ipa包成功 ==============="

echo "=============== ipa包正在上传中... ==============="
xcrun altool --upload-app -f ${filePath} -t ios --apiKey ${api_key} --apiIssuer ${api_issuer} --verbose
if [ $? -ne 0 ]; then
  echo "=============== 上传ipa包失败 ==============="
  exit 1
fi
echo "=============== 上传ipa包成功 ==============="
