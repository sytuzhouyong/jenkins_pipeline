#!/bin/bash

source ./get_project_info.sh
source ./utils.sh
source ./check_env_code_common.sh

######################################## 1. 更新 Host ########################################
# 更新host url配置代码 铁军App Android
function updateHostUrlAndroid() {
  local file=${WorkspacePath}/android/znlh_http/src/main/java/com/znlh/http/constants/HttpConstant.java
  if [[ ! -f "$file" ]]; then
    echo "❌❌❌ updateHostUrlAndroid [$file] not exitst"
    return 1
  fi
  replaceTextBySearchKeyBetweenDoubleQuotes "String RELEASE_HTTP_URL =" "$AppHostEnv" $file
  return $?
}
# 更新host url配置代码 铁军App IOS
function updateHostUrlIOS() {
  local file=${WorkspacePath}/module/zn_flu_utl_common/ios/Classes/Constant/ZNHostConfig.h
  if [[ ! -f "$file" ]]; then
    echo "❌❌❌ updateHostUrlIOS [$file] not exitst"
    return 1
  fi

  replaceContentStartWithSearchKey "#define HOST_PRO"  "@\"$AppHostEnv\"" $file
  replaceContentStartWithSearchKey "#define HOST_DEBUG"  "@\"$AppHostEnv\"" $file
  return $?
}

# 更新host url配置代码 铁军App 
function updateHostUrl() {
  if [[ "$Platform" = "android" ]]; then
    updateHostUrlAndroid
  else
    updateHostUrlIOS
  fi
  return $?
}

######################################## 2. 更新小程序分享类型 ########################################
# 更新小程序分享类型 铁军App Android
function updateMiniProgrameShareTypeAndroid() {
  # 0: 正式版 1： 测试版 2: 体验版
  local type="0"
  if [[ -n "${MiniProgrameType}" ]]; then
    if [[ ${MiniProgrameType} = "preview" ]]; then
      type="2"
    fi
  fi

  local file=${WorkspacePath}/android/znlh_weixin/src/main/java/com/znlh/weixin/WeiXinUtils.java
  if [[ ! -f $file ]]; then
    echo "❌❌❌ updateMiniProgrameShareTypeAndroid error, file[$file] not exists"
    return 1
  fi
  replaceTextBySearchKey \
    "miniProgram.miniprogramType =.*;" "miniProgram.miniprogramType = ${type};" $file
  return $?
}
# 更新小程序分享类型 铁军App IOS
function updateMiniProgrameShareTypeIOS() {
  # ios子模块下
  local type="WXMiniProgramTypeRelease"
  if [[ -n "${MiniProgrameType}" ]]; then
    if [[ "${MiniProgrameType}" = "preview" ]]; then
      type="WXMiniProgramTypePreview"
    fi
  fi
  local file=${ProjectPath}/${ProjectName}/Classes/Common/ZNShareManager.m
  if [[ ! -f $file ]]; then
    echo "❌❌❌ updateMiniProgrameShareTypeIOS error, file[$file] not exists"
    return 1
  fi
  replaceTextBySearchKey "object.miniProgramType =.*;" "object.miniProgramType = ${type};" $file
  return $?
}
# 更新小程序分享类型 铁军App 
function updateMiniProgrameShareType() {
  if [[ "$Platform" = "android" ]]; then
    updateMiniProgrameShareTypeAndroid
  else
    updateMiniProgrameShareTypeIOS
  fi
  return $?
}

######################################## 3. 更新 Host 切换开关 ########################################
# 修改 host 配置开关 Android
function updateHostSwitchAndroid() {
  echo "😃😃😃更新工程文件, ${Platform}无需操作"
}
# 修改 host 配置开关 IOS
function updateHostSwitchIOS() {
  local switch=0
  if [[ "${ApiHostSwitchOptions}" = "开" ]]; then
    switch=1
  fi

  local file=${WorkspacePath}/module/zn_flu_utl_common/ios/Classes/Constant/ZNHostConfig.h
  if [[ ! -f $file ]]; then
    echo "❌❌❌ updateHostSwitchIOS error, file[$file] not exists"
    return 1
  fi

  grep -n "HOST_CONFIG_ENABLE" $file
  if [[ $? -ne 0 ]]; then
    echo "[$file]中没有找到 HOST_CONFIG_ENABLE 宏定义，无需处理"
    return 0
  fi

  replaceTextBySearchKey "define HOST_CONFIG_ENABLE .*" "define HOST_CONFIG_ENABLE $switch" $file
  return $?
}
# 修改 host 配置开关
function updateHostSwitch() {
  if [[ "$Platform" = "android" ]]; then
    updateHostSwitchAndroid
  else
    updateHostSwitchIOS
  fi
  return $?
}


InfoShellPrefix="【铁军】"
ErrorShellPrefix="【错误】"

echo "  $InfoShellPrefix 更新 Host URL 信息 ⏩"
updateHostUrl
if [[ $? -ne 0 ]]; then
  echo "  $ErrorShellPrefix 更新 Host URL 信息 ⏪"
  exit 1
fi
echo "  $InfoShellPrefix 更新 Host URL 信息 ⏪"

echo "  $InfoShellPrefix 更新小程序分享类型 ⏩"
updateMiniProgrameShareType
if [[ $? -ne 0 ]]; then
  echo "  $ErrorShellPrefix 更新小程序分享类型 ⏪"
  exit 1
fi
echo "  $InfoShellPrefix 更新小程序分享类型 ⏪"

echo "  $InfoShellPrefix 更新环境配置开关 ⏩"
updateHostSwitch
if [[ $? -ne 0 ]]; then
  echo "  $ErrorShellPrefix 更新环境配置开关 ⏪"
  exit 1
fi
echo "  $InfoShellPrefix 更新环境配置开关 ⏪"
