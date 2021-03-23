#!/bin/bash

source ./get_project_info.sh
source ./utils.sh
source ./check_env_code_common.sh

######################################## 1. 更新 Host ########################################
# 更新host url配置代码 对客端
function updateHostUrl() {
  local file=${WorkspacePath}/module/zn_dmd_common/lib/zn_http_config.dart
  if [[ ! -f "$file" ]]; then
    echo "❌❌❌ updateHostUrl [$file] not exitst"
    return 1
  fi
  
  replaceTextBySearchKeyBetweenDoubleQuotes "String realHttpHost =" "$AppHostEnv" $file
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

  local file=${WorkspacePath}/vendor/zn_flu_weixin/android/src/main/java/com/znlh/zn_flu_weixin/WeiXinUtils.java
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
  local file=${ProjectPath}/${ProjectName}/Classes/Common/ZNTCShare/ZNTCShareManager.m
  if [[ ! -f $file ]]; then
    echo "❌❌❌ updateMiniProgrameShareTypeIOS error, file[$file] not exists"
    return 1
  fi
  replaceTextBySearchKey \
    "object.miniProgramType =.*;" "object.miniProgramType = ${type};" $file
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

InfoShellPrefix="【对客】"
ErrorShellPrefix="【错误】"

echo "  $InfoShellPrefix 更新 Host URL 信息 ⏩"
updateHostUrl
if [[ $? -ne 0 ]]; then
  echo "  $ErrorShellPrefix 更新 Host URL 信息失败"
  exit 1
fi
echo "  $InfoShellPrefix 更新 Host URL 信息 ⏪"

echo "  $InfoShellPrefix 更新小程序分享类型 ⏩"
updateMiniProgrameShareType
if [[ $? -ne 0 ]]; then
  echo "  $ErrorShellPrefix 更新小程序分享类型 ⏩"
  exit 1
fi
echo "  $InfoShellPrefix 更新小程序分享类型 ⏪"

