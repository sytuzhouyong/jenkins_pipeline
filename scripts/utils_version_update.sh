#!/bin/bash

source ./get_project_info.sh

function addAppVersion() {
    echo "🔥 开始上传App包到服务器..."
    local url="${DynamicHostEnv}/api-dtr/api/v1/version/addVersion"
    # local url="http://dev.pla.zuul.znlhzl.org/api-dtr/api/v1/version/addVersion"
    echo "发送请求：curl -d 'bundleId=$AppPackageId' -d 'systemType=${PlatformPretty}' -d 'appVersion=$BuildVersion' -d 'appUrl=$1' -d 'updateContent=测试版本发布' $url"
    local result=$(curl \
        -d "bundleId=$AppPackageId" \
        -d "systemType=${PlatformPretty}" \
        -d "appVersion=$BuildVersion" \
        -d "appUrl=$1" \
        -d "updateContent=测试版本发布" \
        $url)
    echo "请求结果：$result"
    local success=${result#*success\":}
    success=${success%%,*}
    if [[ $success != "true" ]]; then
        echo "❌ App版本发布失败，错误：$result"
        return 1
    fi
    echo "✅ App版本发布成功"
    return 0
}

function addResourceVersion() {
    # appType: 1-铁军, 2-物流, 3-对客, 4-商户
   local appType=2
    if [[ $AppIdentifier = "merchant" ]]; then
        appType=1
    elif [[ $AppIdentifier = "customer" ]]; then
        appType=3
    elif [[ $AppIdentifier = "hatch" ]]; then
        appType=4
    fi

    echo "🔥 开始上传动态更新包到服务器..."
    local url="${DynamicHostEnv}/api-dtr/api/v1/resource/addResource"
    # local url="http://dev.pla.zuul.znlhzl.org/api-dtr/api/v1/resource/addResource"
    echo "发送请求：curl -d 'bundleId=$AppPackageId' -d 'appType=${appType}' -d 'systemType=${PlatformPretty}' -d 'appVersion=$BuildVersion' -d 'resourceVersion=$PatchVersion' -d 'resourceContent=$PatchDesc' -d 'resourceUrl=$AliyunUploadFileUrl' $url"
    local result=$(curl \
        -d "appType=$appType" \
        -d "systemType=${PlatformPretty}" \
        -d "appVersion=${BuildVersion}" \
        -d "resourceVersion=${PatchVersion}" \
        -d "resourceContent=${PatchDesc}" \
        -d "resourceUrl=${AliyunUploadFileUrl}" \
        $url)
    echo "请求结果：$result"
    local success=${result#*success\":}
    success=${success%%,*}
    if [[ $success != "true" ]]; then
        echo "❌ App动态包发布失败，错误：$result"
        return 1
    fi
    echo "✅ App动态包发布成功"
    return 0
}
