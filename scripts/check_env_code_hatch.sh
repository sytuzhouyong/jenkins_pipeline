#!/bin/bash

source ./get_project_info.sh
source ./utils.sh
source ./check_env_code_common.sh

######################################## 1. 更新 Host ########################################
# 更新host url配置代码 商户App 
function updateHostUrl() {
  local file=${WorkspacePath}/lib/common/zn_http_config.dart
  if [[ ! -f "$file" ]]; then
    echo "❌❌❌ updateHostUrlIOS [$file] not exitst"
    return 1
  fi

  replaceTextBySearchKeyBetweenDoubleQuotes "static String realHttpHost ="  "$AppHostEnvNew" $file
  replaceTextBySearchKeyBetweenDoubleQuotes "static String oldHttpHost ="  "$AppHostEnvOld" $file
  return $?
}

######################################## 3. 更新 Host 切换开关 ########################################
function updateHostSwitch() {
  # local file=${WorkspacePath}/lib/login/page/zn_login_page.dart
  local file=${WorkspacePath}/lib/app_config.dart
  if [[ ! -f "$file" ]]; then
    echo "❌❌❌ updateHostSwitch [$file] not exitst"
    return 1
  fi

  local switch="false"
  if [[ "${ApiHostSwitchOptions}" = "开" ]]; then
    switch="true"
  fi

  # replaceTextBySearchKey "bool hostSwitchEnabled =.*;" "bool hostSwitchEnabled = ${switch};" $file
  replaceTextBySearchKey "const bool isCanCharles =.*;" "const bool isCanCharles = ${switch};" $file
  return $?
}


InfoShellPrefix="【商户】"
ErrorShellPrefix="【错误】"

echo "  $InfoShellPrefix 更新 Host URL 信息 ⏩"
updateHostUrl
if [[ $? -ne 0 ]]; then
  echo "  $ErrorShellPrefix 更新 Host URL 信息 ⏪"
  exit 1
fi
echo "  $InfoShellPrefix 更新 Host URL 信息 ⏪"

# 导出接口环境变量，用于钉钉消息显示
AppHostEnv="$AppHostEnvNew | $AppHostEnvOld"
export AppHostEnv

echo "  $InfoShellPrefix 更新环境配置开关 ⏩"
updateHostSwitch
if [[ $? -ne 0 ]]; then
  echo "  $ErrorShellPrefix 更新环境配置开关 ⏪"
  exit 1
fi
echo "  $InfoShellPrefix 更新环境配置开关 ⏪"
