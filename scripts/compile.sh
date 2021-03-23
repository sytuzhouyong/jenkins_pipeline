#!/bin/bash

set -eu
set -o pipefail

source ./get_project_info.sh
source ./utils_date.sh

# 编译

function buildAndroid() {
  cd $WorkspacePath
  rm -rf ./build
  cd $ProjectPath

  local Configuration=Release
  if [[ "${AppPackageType}" = "debug" ]]; then
      Configuration=Debug
  fi

  local buildParams=""
  if [[ $AppIdentifier = "merchant" ]]; then
    # 0：禁止切换Host，1：可以切换Host
    local switch=0
    if [[ "${ApiHostSwitchOptions}" = "开" ]]; then
      switch=1
    fi
    buildParams="-PIS_APP_ENV=${switch}"
  fi

  echo "./gradlew assemble${Configuration} ${buildParams}"
  ./gradlew assemble${Configuration} ${buildParams}
  return $?
  #cd $WorkspacePath
  #flutter build apk --no-shrink
}

function buildIOS() {
  security set-key-partition-list -S apple-tool:,apple: -s -k "888888" ~/Library/Keychains/login.keychain-db > /dev/null
  source ./flutter_versions_adapt.sh

  pod_install_pre_handler_ios

  cd $ProjectPath
  pod install
  if [[ $? -ne 0 ]]; then
    echo "pod install 执行失败"
    return 1
  fi

  rm -rf ./archive
  rm -rf ./build

  compile_pre_handler_ios

  echo "AppPackageType = ${AppPackageType}"
  Configuration=Release
  if [[ "${AppPackageType}" = "development" ]]; then
    Configuration=Debug
    echo "编译Debug包"
    echo "/usr/bin/env xcrun xcodebuild \
        -configuration ${Configuration} \
        -workspace ${ProjectName}.xcworkspace \
        -scheme ${ProjectName} \
        -sdk iphoneos \
        BUILD_DIR=${BuildPath} \
        FLUTTER_SUPPRESS_ANALYTICS=true \
        -quiet \
        clean build"

    # debug 包不能通过 xcodebuild archive 命令去生成，编译会报错
    # archive 必须使用 flutter release 模式
    /usr/bin/env xcrun xcodebuild \
        -configuration ${Configuration} \
        -workspace ${ProjectName}.xcworkspace \
        -scheme ${ProjectName} \
        -sdk iphoneos \
        BUILD_DIR=${BuildPath} \
        FLUTTER_SUPPRESS_ANALYTICS=true \
        -quiet \
        clean build
  else
    echo "编译Release包"
    ArchivePath="${BuildPath}/${PackageFileTitle}.xcarchive"
    echo "xcodebuild \
        -workspace ${ProjectName}.xcworkspace \
        -scheme ${ProjectName} \
        -configuration ${Configuration} \
        -UseNewBuildSystem=YES \
        -archivePath ${ArchivePath} \
        -quiet \
        clean archive | xcpretty"
    xcodebuild \
        -workspace ${ProjectName}.xcworkspace \
        -scheme ${ProjectName} \
        -configuration ${Configuration} \
        -UseNewBuildSystem=YES \
        -archivePath ${ArchivePath} \
        -quiet \
        clean archive
  fi
  return $?

  # xcodebuild \
  #     -workspace Runner.xcworkspace \
  #     -scheme Runner \
  #     -configuration Release \
  #     -UseNewBuildSystem=YES \
  #     -archivePath ../build/adhoc.xcarchive \
  #     clean archive

  # flutter build ios --release
  # = 
  # xcodebuild \
  #     -configuration Release \
  #     -quiet \
  #     -workspace Runner.xcworkspace \
  #     -scheme Runner \
  #     BUILD_DIR=/Users/zhouyong1/Documents/flutter_project/merchant_flutter_tablecache/build/ios \
  #     -sdk iphoneos \
  #     SCRIPT_OUTPUT_STREAM_FILE=/var/folders/18/wf2lsb791rv2rfgt5dgz2k5453jr_g/T/flutter_build_log_pipe.uumDrE/pipe_to_stdout \
  #     FLUTTER_SUPPRESS_ANALYTICS=true \
  #     COMPILER_INDEX_STORE_ENABLE=NO

}

function build() {
  if [[ "$Platform" = "android" ]]; then
    buildAndroid
  else
    buildIOS
  fi
  return $?
}

startTimestamp=`currentTimestamp`
build
endTimestamp=`currentTimestamp`
buildDuration=$(($endTimestamp-$startTimestamp))
echo "$buildDuration" > ${BuildInfoFilePath}

