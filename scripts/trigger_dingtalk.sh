#!/bin/bash

source ./get_project_info.sh
source ./utils.sh
source ./utils_date.sh

# 钉钉机器人webhook值
# if [[ "x$DingTalkAccessToken" = "x" ]]; then
# fi

if [[ "$Platform" = "android" ]]; then
  DingTalkAccessToken="f25aa842ab28cb6c602df9e9792257347eae58ace128b021a5292d7a6fef8e3a"
else
  DingTalkAccessToken="41f0fd8e41ef84895b9dfc8affc67bc0ec5cfce845c9560dde6ccd631c8f2042"
fi
DingTalkWebhook="https://oapi.dingtalk.com/robot/send?access_token=${DingTalkAccessToken}"
echo "webhook = ${DingTalkWebhook}"

function dingTalkSuccess() {
  AppName=$(getAppName)
  BuildVersion=$(getBuildVersion)
  BuildNumber=$(getBuildNumber)
  VersionInfo="${BuildVersion} - ${BuildNumber}"
  echo "AppName = $AppName, BuildVersion = $BuildVersion, BuildNumber = $BuildNumber"

  BranchesDesc="\n\n"
  if [[ -f ${BranchInfoFile} ]]; then
    echo `cat ${BranchInfoFile}`
    for line in `cat ${BranchInfoFile}`
    do
      # 等号替换成中文冒号
      line=${line//=/：}
      BranchesDesc="${BranchesDesc}> ${line}\n\n"
    done
  fi
  echo "BranchesDesc = ${BranchesDesc}"
  if [[ -z ${BranchesDesc}  ]]; then
    echo "分支信息获取失败"
    return 1
  fi

  # 环境信息
  HostEnvText="${AppHostEnv}"
  # 小程序环境
  MiniProgrameTypeText="${MiniProgrameType}"
  # 构建时长
  local buildDuration=''
  # 包大小
  local buildSize=''
  if [[ -f ${BuildInfoFilePath} ]]; then
    buildDuration=`cat ${BuildInfoFilePath} | awk 'NR==1' | awk '{print $1}'`
    echo "build duration = ${buildDuration}"
    buildDuration=$(timestamp2TimeDesc $buildDuration)
    buildSize=`cat ${BuildInfoFilePath} | awk 'NR==2' | awk '{print $1}'`
    echo "build size = ${buildSize}"
  fi

  if [[ "${AppIdentifier}" = "hatch" ]]; then
    HostEnvText="${AppHostEnvNew} ${AppHostEnvOld}"
    MiniProgrameTypeText="无"
  fi

  ContentStr="""版本号：${VersionInfo}\n\n
  > 构建时间：${BuildString}\n\n
  > 构建序号：${BUILD_NUMBER}\n\n
  > 编译时长：${buildDuration}\n\n
  > 文件大小：${buildSize}\n\n
  > Flutter版本号：$(getFlutterVersion)\n\n
  > App环境：${HostEnvText}\n\n
  > 小程序分享类型：${MiniProgrameTypeText}\n\n
  > 分支信息：\n\n> ${BranchesDesc}
  """

  QRCodeURL=""
  if [[ -f $QRCodeFile ]]; then
      QRCodeURL=`cat ${QRCodeFile}`
      QRCodeURL=${QRCodeURL#*\"}
      QRCodeURL=${QRCodeURL%\"*}
      # appstore包不上传蒲公英
      # if [[ -z $QRCodeURL ]]; then
      #     echo "二维码信息获取失败"
      #     exit 1
      # fi
  fi

  DingText="\"### ${AppName}-${AppPackageType}-${Platform}\n\n> ${ContentStr}\n\n"
  if [[ -n $QRCodeURL ]]; then
      DingText="""${DingText}\n\n
> 扫描二维码安装${Platform} ${AppPackageType}包
> ![screenshot](${QRCodeURL})\n
"""
  fi
  DingText="${DingText}\""

  result=$(curl ${DingTalkWebhook} \
  -H 'Content-Type: application/json' \
  -d """
{\"msgtype\": \"markdown\",
\"markdown\": {
\"title\":\"${AppName}有新版本啦\",
\"text\": ${DingText}
},
\"at\": {\"isAtAll\": false}
}""")

  echo "result = $result"
  if [[ ! "${result}" =~ "\"errcode\":0," ]]; then
    echo "钉钉消息发送失败"
    return 1
  fi
  echo "钉钉消息发送成功"
  return 0
}

function dingTalkFailed() {
  local content="{
    'msgtype': 'link',
    'link': {
      'title': \"${JOB_NAME} #${BUILD_NUMBER}\",
      'text': '构建失败，点击标题查看详情',
      'picUrl': 'http://ww1.sinaimg.cn/large/005tJjtHgy1gm5primktdj305k05k746.jpg',
      'messageUrl': \"${BUILD_URL}\"
    }
  }"

  result=$(curl ${DingTalkWebhook} \
    -H 'Content-Type: application/json' \
    -d "${content}"
  )
  echo "result = $result"
  if [[ ! "${result}" =~ "\"errcode\":0," ]]; then
    echo "钉钉消息发送失败"
    return 1
  fi
  echo "钉钉消息发送成功"
  return 0
}

type=$1
echo "type = ${type}"
if [[ "${type}" = "failed" ]]; then
  dingTalkFailed
else
  dingTalkSuccess
fi


