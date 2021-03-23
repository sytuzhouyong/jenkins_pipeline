#!/bin/bash

source ./utils.sh

# 取工程目录的前提是脚本执行要在如下格式下执行脚本
# dir('./ios/scripts/pipeline') {
# 	bash "./upload_pgy.sh"
# }
#
#

# 判断系统环境，如果是 macOS, 设置 sed 命令为 gsed，否则为 sed
operateSystem=`uname`
if [[ "$operateSystem" =~ "Darwin" ]]; then
    xsed=gsed
else
    xsed=sed
fi
export xsed


# 当前目录 ./jenkins/workspace/xxxpileline/scripts
PipelineScriptsPath=$(pwd)
# 存放二维码地址的文件
QRCodeFile=${PipelineScriptsPath}/qrcode.html
# 存放分支信息的文件
BranchInfoFile=${PipelineScriptsPath}/branch.txt

WorkspacePath=${PipelineScriptsPath%/*} # 上一级目录
ProjectPath=${WorkspacePath}/${Platform} # 下一级目录 ios / android
PackageFileTitle=${AppIdentifier}_${AppPackageType}_${BuildVersion}_${BuildString}
BuildInfoFilePath=${PipelineScriptsPath}/build_info.txt

echo "WorkspacePath = ${WorkspacePath}"
echo "ProjectPath = ${ProjectPath}"
echo "PipelineScriptsPath = ${PipelineScriptsPath}"
echo "PackageFileTitle = ${PackageFileTitle}"

if [[ "${Platform}" = "ios" ]]; then
    ProjectName=$(getProjectNameIOS)
    BuildPath=${ProjectPath}/build
    InfoPlistFile=${ProjectPath}/${ProjectName}/Info.plist

    echo "BuildPath = $BuildPath"
    echo "InfoPlistFile = $InfoPlistFile"
    export BuildPath InfoPlistFile  

elif [[ "${Platform}" = "android" ]]; then
    ProjectName=$(getProjectNameAndroid)
    ManifestFilePath=${WorkspacePath}/android/app/src/main/AndroidManifest.xml

    echo "ManifestFilePath = $ManifestFilePath"
    export ManifestFilePath
fi

echo "ProjectName = ${ProjectName}"

export PipelineScriptsPath WorkspacePath ProjectPath ProjectName QRCodeFile  


