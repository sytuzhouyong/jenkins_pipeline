#!/bin/bash

source ./utils.sh


######################################## 更新 自动化测试 开关 ########################################
function updateAutoTestSwitchAndroid() {
  local file="${WorkspacePath}/lib/my_app.dart"
  local enable=false
  if [[ "${EnableAutoTest}" = "开" ]]; then
    enable=true
  fi

  grep -n "bool gEnableAutoTest =" $file
  if [[ $? -ne 0 ]]; then
    echo "[$file]中没有找到 gEnableAutoTest 变量的定义，无需处理"
    return 0
  fi

  replaceTextBySearchKey "bool gEnableAutoTest =.*;" "bool gEnableAutoTest = ${enable};" $file
}
function updateAutoTestSwitchIOS() {
  echo "😃😃😃更新自动化开关配置, ${Platform}无需操作"
}
function updateAutoTestSwitch() {
  if [[ "$Platform" = "android" ]]; then
    updateAutoTestSwitchAndroid
  else
    updateAutoTestSwitchIOS
  fi
  return $?
}


InfoShellPrefix="【通用】"
ErrorShellPrefix="【错误】"

echo "  $InfoShellPrefix 更新自动化测试开关开始 ⏩"
updateAutoTestSwitch
if [[ $? -ne 0 ]]; then
  echo "  $ErrorShellPrefix 更新自动化测试开关 ⏪"
  exit 1
fi
echo "  $InfoShellPrefix 更新自动化测试开关结束 ⏪"
