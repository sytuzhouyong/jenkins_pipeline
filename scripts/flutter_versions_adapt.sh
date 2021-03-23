#!/bin/bash

source ./get_project_info.sh
source ./utils.sh

# pod install前的适配
function pod_install_pre_handler_ios() {
    local FlutterSDKVersion=$(getFlutterVersion)
    echo "FlutterSDKVersion = ${FlutterSDKVersion}"

    if [[ ! "${FlutterSDKVersion}" =~ "1.7.8" ]]; then
        echo "删除Flutter.framework，确保每次都是最新的"
        rm -rf ${ProjectPath}/Flutter/Flutter.framework
    else
        echo "无需处理 pod_install_pre_handler"
    fi
}

# 编译前的适配
function compile_pre_handler_ios() {
    local FlutterSDKVersion=$(getFlutterVersion)
    echo "FlutterSDKVersion = ${FlutterSDKVersion}"

     #flutter 1.7.8_hotfix4之后，Flutter.framework都重新生成一下
    if [[ ! "${FlutterSDKVersion}" =~ "1.7.8" ]]; then
        echo "需要更新project.pbxproj，删除Flutter.framework的embed操作"
        ProjectConfigFile=${ProjectPath}/${ProjectName}.xcodeproj/project.pbxproj
        ${xsed} -i "/Flutter.framework in Embed Frameworks/d" $ProjectConfigFile
    else
        echo "无需处理 compile_pre_handler_ios"
    fi
}