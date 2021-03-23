#!/bin/bash
# set -eux
# set -o pipefail

# 制作动态更新包，步骤包括如下：
# 1. 生成missile工具
# 2. 通过missile工具将给定的dart文件列表转成json文件

source ./utils_dynamic_page.sh
source ./utils_aliyun.sh

# 1. 创建missile工具
echo "🔥 创建missile_tool工具开始..."
generateMissileTool
if [[ $? -ne 0 ]]; then
    echo "❌ 创建missile_tool工具失败"
    exit 1
fi
echo "✅ 创建missile_tool工具成功"

# 2. dart文件转成json zip包
echo "🔥 动态页面zip包开始生成"
rm -f ${WorkspacePath}/tools_dynamic/zip/*.zip
parseDart2Json "file" "${PatchFiles}" "${WorkspacePath}/tools_dynamic/zip"
if [[ $? -ne 0 ]]; then
    echo "❌ 动态页面zip包生成失败"
    exit 1
fi
echo "✅ 动态页面zip包生成成功"

# 3. 拿到zip文件后就可以上传到阿里云OSS
zipFilePath=${WorkspacePath}/tools_dynamic/zip/main.zip
timestamp=$(echo "$BuildString" | sed "s/-//g" | sed "s/ //g" | sed "s/://g")
fileName=${AppIdentifier}_${AppPackageType}_${BuildVersion}_patch_${PatchVersion}_${timestamp}.zip
uploadFileToAliyun $zipFilePath $fileName
if [[ $? -ne 0 ]]; then
    exit 1
fi

# 4. 将信息更新到数据库
# appType: 1-铁军, 2-物流, 3-对客, 4-商户
appType=2
if [[ $AppIdentifier = "merchant" ]]; then
    appType=1
elif [[ $AppIdentifier = "customer" ]]; then
    appType=3
elif [[ $AppIdentifier = "hatch" ]]; then
    appType=4
fi

echo "🔥 开始上传动态更新包到服务器..."

url="${DynamicHostEnv}/api-dtr/api/v1/resource/addResource"
echo "发送请求：curl -d 'bundleId=$AppPackageId' -d 'appType=${appType}' -d 'systemType=${PlatformPretty}' -d 'appVersion=$BuildVersion' -d 'resourceVersion=$PatchVersion' -d 'resourceContent=$PatchDesc' -d 'resourceUrl=$AliyunUploadFileUrl' $url"
result=$(curl \
    -d "appType=$appType" \
    -d "systemType=${PlatformPretty}" \
    -d "appVersion=${BuildVersion}" \
    -d "resourceVersion=${PatchVersion}" \
    -d "resourceContent=${PatchDesc}" \
    -d "resourceUrl=${AliyunUploadFileUrl}" \
    $url)
echo "result = $result"
success=${result#*success\":}
success=${success%%,*}
if [[ $success != "true" ]]; then
    echo "❌ 动态包发布失败，错误：$result"
    exit 1
fi
echo "✅ 动态包版本发布成功"

# # 增加版本
# curl -X POST \
#         -d "bundleId=com.znlh.as.bussiness" \
#         -d "systemType=iOS" \
#         -d "appVersion=1.0.0" \
#         -d "appUrl=www.baidu.com" \
#         -d "updateContent=测试版本发布" \
#         http://sit.pla.zuul.znlhzl.org/api-dtr/api/v1/version/addVersion

# # 增加资源
# curl \
#     -d "bundleId=com.znlh.as.bussiness" \
#     -d "resourceVersion=1.0.1" \
#     -d "systemType=iOS" \
#     -d "appVersion=1.0.0" \
#     -d "resourceContent=修复页面bug" \
#     -d "resourceUrl=www.baidu.com" \
#     http://sit.pla.zuul.znlhzl.org/api-dtr/api/v1/resource/addResource
