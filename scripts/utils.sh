#!/bin/bash

# 获取App安装后的名称
function getAppNameAndroid() {
  local file=${WorkspacePath}/android/app/src/main/res/values/strings.xml

  # 获取指定字符串在第几行
  local n=`sed -n "/\"app_name_${AppPackageType}\"/=" ${file}`
  if [[ -z $n ]]; then
    # echo "文件[$file]没有找到app_name_${AppPackageType}的配置信息"
    n=`sed -n "/\"app_name\"/=" ${file}`
  fi
  # echo "getAppNameAndroid 行信息：[$n]"
  if [[ -z $n ]]; then
    # echo "文件[$file]没有找到app_name的配置信息"
    return 1
  fi

  local appName=$(cat ${file} | awk "NR==$n")
  if [[ -z "$appName" ]]; then
    # echo "文件[$file]的第 $n 行内容为空"
    return 1
  fi

  appName=${appName#*>}
  appName=${appName%<*}
  echo $appName
}
function getAppNameIOS() {
  local appName=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" $InfoPlistFile)
  if [[ -z "$appName" ]]; then
    appName=$(/usr/libexec/PlistBuddy -c "Print CFBundleName" $InfoPlistFile)
  fi
  echo $appName
}
function getAppName() {
  if [[ "$Platform" = "android" ]]; then
    getAppNameAndroid
  else
    getAppNameIOS
  fi
}

# 获取工程名称
function getProjectNameIOS() {
  name=$(find ${ProjectPath} -name *.xcodeproj -maxdepth 1 | awk -F "[/.]" '{print $(NF-1)}')
  echo "$name"
}
function getProjectNameAndroid() {
  echo "app"
}
function getProjectName() {
  if [[ "$Platform" = "android" ]]; then
    getProjectNameAndroid
  else
    getProjectNameIOS
  fi
}

# 获取配置文件中的版本号
function getBuildVersionAndroid() {
  local version=$(cat ${ManifestFilePath} | awk 'NR==6')
  version=$(echo ${version#*\"})
  version=$(echo ${version%\"*})
  echo "${version}"
}
function getBuildVersionIOS() {
  local version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $InfoPlistFile)
  if [[ "$version" =~ "MARKETING_VERSION" ]]; then
    local projectFilePath=${ProjectPath}/${ProjectName}.xcodeproj/project.pbxproj
    version=$(grep -rn MARKETING_VERSION ${projectFilePath} | tail -n 1 | awk -F "[=;]" '{print $2}')
  fi
  echo "${version}"
}
function getBuildVersion() {
  if [[ "$Platform" = "android" ]]; then
    getBuildVersionAndroid
  else
    getBuildVersionIOS
  fi
}

# 获取build number,
# 安卓是version code, 和版本号有关系;
# iOS是CFBundleVersion, 和构建时间有关系
function getBuildNumberAndroid() {
  local number=$(cat ${ManifestFilePath} | awk 'NR==5')
  number=$(echo ${number#*\"})
  number=$(echo ${number%\"*})
  echo $number
}
function getBuildNumberIOS() {
  local number=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $InfoPlistFile)
  echo $number
}
function getBuildNumber() {
  if [[ "$Platform" = "android" ]]; then
    getBuildNumberAndroid
  else
    getBuildNumberIOS
  fi
}

# 更新版本信息
function updateVersionInfoAndroid() {
  echo "开始更新${Platform}版本信息，新版本号：$BuildVersion"

  local newVersionName=$BuildVersion
  if [[ -z "$newVersionName" ]]; then
    echo "  ❌❌❌ updateVersionInfoAndroid failed, 参数为空"
    return 1
  fi
  # 去掉.号，不足 6 位的，后面补齐 0
  local newVersionCode=$(echo $newVersionName | sed 's/\.//g' | awk '{width=6; printf("%d",$1); for(i=0;i<width-length($1);++i) printf "0"; print ""}')
  local oldVersionName=$(getBuildVersion)
  local oldVersionCode=$(getBuildNumber)
  echo "oldVersionName = $oldVersionName, oldVersionCode = $oldVersionCode"
  echo "newVersionName = $newVersionName, newVersionCode = $newVersionCode"

  replaceTextBySearchKeyBetweenDoubleQuotes "android:versionCode=" "$newVersionCode" "${ManifestFilePath}"
  replaceTextBySearchKeyBetweenDoubleQuotes "android:versionName=" "$newVersionName" "${ManifestFilePath}"
  if [[ $? -ne 0 ]]; then
    echo "  ❌❌❌ replaceTextBySearchKeyBetweenDoubleQuotes 命令执行失败"
    echo "  replaceTextBySearchKeyBetweenDoubleQuotes \"android:versionName=\" \"$oldVersionName\" \"${ManifestFilePath}\""
    return 1
  fi
  echo "  更新后版本号如下：$(getBuildVersion)"
  echo "  更新后版本Code如下：$(getBuildNumber)"
  echo "���结束更新${Platform}版本信息"
  return 0
}
function updateVersionInfoIOS() {
  echo "开始更新${Platform}版本信息，新版本号：$BuildVersion, build number: $BuildNumber"
  if [[ -z "$BuildVersion" ]]; then
    echo "❌❌❌ updateVersionInfoIOS failed, 参数为空"
    return 1
  fi
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${BuildVersion}" ${InfoPlistFile}
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BuildNumber" ${InfoPlistFile}
  if [[ $? -ne 0 ]]; then
    echo "  ❌❌❌ PlistBuddy命令执行失败"
    return 1
  fi
  echo "  更新后版本号如下：$(getBuildVersion)"
  echo "  更新后版本Code如下：$(getBuildNumber)"
  echo "结束更新${Platform}版本信息"
  return 0
}
function updateVersionInfo() {
  if [[ "$Platform" = "android" ]]; then
    updateVersionInfoAndroid
  else
    updateVersionInfoIOS
  fi
  return $?
}

# 更新工程文件
function updateProjectConfigFileAndroid() {
  echo "😃😃😃更新工程文件, ${Platform}无需操作"
}
function updateProjectConfigFileIOS() {
  cd ${ProjectPath}/${ProjectName}.xcodeproj
  echo "🍎🍎🍎开始更新工程文件，路径 = $(PWD)"

  local CODE_SIGN_IDENTITY=${CodeSignIdentityDis}
  if [[ "${AppPackageType}" = "development" ]]; then
    CODE_SIGN_IDENTITY=${CodeSignIdentityDev}
  fi

  local PROVISIONING_PROFILE=${ProvisioningProfileRelease}
  local PROVISIONING_PROFILE_UUID=${ProvisioningProfileUUIDRelease}
  if [[ "${AppPackageType}" = "development" ]]; then
    PROVISIONING_PROFILE=${ProvisioningProfileDev}
    PROVISIONING_PROFILE_UUID=${ProvisioningProfileUUIDDev}
  elif [[ "${AppPackageType}" = "adhoc" ]]; then
    PROVISIONING_PROFILE=${ProvisioningProfileAdhoc}
    PROVISIONING_PROFILE_UUID=${ProvisioningProfileUUIDAdhoc}
  fi
  echo "  证书： ${CODE_SIGN_IDENTITY}, 描述文件：$PROVISIONING_PROFILE"

  ${xsed} -i "s/CODE_SIGN_STYLE =.*;/CODE_SIGN_STYLE = Manual;/" ./project.pbxproj
  ${xsed} -i "s/PRODUCT_BUNDLE_IDENTIFIER =.*;/PRODUCT_BUNDLE_IDENTIFIER = ${AppPackageId};/" ./project.pbxproj
  ${xsed} -i "s/CODE_SIGN_IDENTITY =.*;/CODE_SIGN_IDENTITY = \"${CODE_SIGN_IDENTITY}\";/" ./project.pbxproj
  ${xsed} -i "s/\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\" =.*;/\"CODE_SIGN_IDENTITY[sdk=iphoneos*]\" = \"${CODE_SIGN_IDENTITY}\";/" ./project.pbxproj
  ${xsed} -i "s/DEVELOPMENT_TEAM =.*;/DEVELOPMENT_TEAM = ${DevelopTeam};/" ./project.pbxproj
  ${xsed} -i "s/PROVISIONING_PROFILE = .*;/PROVISIONING_PROFILE = \"${PROVISIONING_PROFILE_UUID}\";/" ./project.pbxproj
  ${xsed} -i "s/PROVISIONING_PROFILE_SPECIFIER =.*;/PROVISIONING_PROFILE_SPECIFIER = ${PROVISIONING_PROFILE};/" ./project.pbxproj
  if [[ $? -ne 0 ]]; then
    echo "  ❌❌❌updateProjectConfigFileIOS 命令执行失败"
    echo "${xsed} -i 's/PROVISIONING_PROFILE_SPECIFIER =.*;/PROVISIONING_PROFILE_SPECIFIER = ${PROVISIONING_PROFILE};/' ./project.pbxproj"
    return 1
  fi
  echo "🍎🍎🍎结束更新工程文件"
  return 0
}
function updateProjectConfigFile() {
  if [[ "$Platform" = "android" ]]; then
    updateProjectConfigFileAndroid
  else
    updateProjectConfigFileIOS
  fi
}

# 更新Flutter Mode配置
function updateFlutterModeAndroid() {
  echo "😃😃😃更新Flutter Mode配置, ${Platform}无需操作"
}
function updateFlutterModeIOS() {
  local configFilePath=${ProjectPath}/Flutter/Generated.xcconfig
  local line=$(grep -n "FLUTTER_FRAMEWORK_DIR=" "${configFilePath}")
  local lineNumber=$(echo $line | awk -F "[:]" '{print $1}')
  local lineContent=${line#$lineNumber:}
  local frameworkFileName=${lineContent##*/}
  local frameworkFileDir=${lineContent%/*}
  echo $line
  echo $frameworkFileName
  echo $frameworkFileDir

  newFrameworkFileName="ios-release"
  if [[ "${FlutterMode}" = "debug" ]]; then
      newFrameworkFileName="ios"
  fi
  echo "newFrameworkFileName = $newFrameworkFileName"
  local newFrameworkFilePath="$frameworkFileDir/$newFrameworkFileName"
  replaceTextBySearchKey "$lineContent" "$newFrameworkFilePath" "$configFilePath"
  return $?
}
function updateFlutterMode() {
  if [[ "$Platform" = "android" ]]; then
    updateFlutterModeAndroid
  else
    updateFlutterModeIOS
  fi
}

# 替换指定文件中指定搜索关键字匹配行中的双引号内的内容
function replaceTextBySearchKeyBetweenDoubleQuotes() {
  # 设置分隔符为换行，而不是空格
  oldifs="$IFS"
  IFS=$'\n'

  local searchKey=$1
  local newText=$2
  local targetFilePath=$3

  echo "✈️✈️✈️准备修改文件：$targetFilePath"
  local lines=$(grep -n "$searchKey" $targetFilePath)
  if [[ -z "$lines" ]]; then
    echo "  ❌❌❌replaceTextBySearchKeyBetweenDoubleQuotes error"
    echo "[$searchKey] in [$targetFilePath] not exists" 
    return 1
  fi

  for line in $lines; do
    # 去除首尾空格
    local lineNumber=$(echo $line | awk -F "[:]" '{print $1}')
    # 去除行号和冒号
    local lineContent=${line#$lineNumber:}
    lineContent=$(echo $lineContent | awk '$1=$1')
    #    echo "lineContent = $lineContent"
    # 获取前2个字符
    local prefix=${lineContent:0:2}
    if [[ "$prefix" = "//" ]]; then
      continue
    fi
    echo "  行号：$lineNumber, 修改前：$lineContent"

    # 找到替换的字符串
    local oldText=${lineContent#*\"}
    oldText=${oldText%\"*}
    echo "  准备替换内容[$oldText]为[$newText]"

    # 转义斜杠，否则sed命令会报错
    # oldText=${oldText//\//\\\/}
    # newText=${newText//\//\\\/}
    # 用#号代替斜杠，避免斜杠需要转义，代码更加简洁
    ${xsed} -i "${lineNumber}s#$oldText#$newText#g" $targetFilePath
    if [[ $? -ne 0 ]]; then
      echo "sed命令执行失败，命令如下"
      echo "${xsed} -i '${lineNumber}s#$oldText#$newText#' $targetFilePath"
      return 1
    fi
    newLineContent=$(cat ${targetFilePath} | awk "NR==$lineNumber")
    echo "  行号：$lineNumber, 修改后：$newLineContent"

    local updatedText=${newLineContent#*\"}
    updatedText=${updatedText%\"*}
    if [[ "$updatedText" != "$newText" ]]; then
      echo "  ❌❌❌ 修改失败"
      return 1
    else
      echo "  ✅✅✅ 修改成功"
    fi
  done
  echo "✈️✈️✈️结束修改文件：$targetFilePath"
  IFS="$oldifs"
  return 0
}
# replaceTextBySearchKeyBetweenDoubleQuotes "String realHttpHost =" "https://uatdmo.znlhzl.cn" "zn_http_config.dart"


# 替换的内容就是searchKey匹配的内容
function replaceTextBySearchKey() {
  oldifs="$IFS"
  IFS=$'\n'

  local searchKey=$1
  local newText=$2
  local targetFilePath=$3
  
  echo "✈️✈️✈️准备修改文件：$targetFilePath"
  local lines=$(grep -n "$searchKey" $targetFilePath)
  if [[ -z "$lines" ]]; then
    echo "  replaceTextBySearchKey error"
    echo "[$searchKey] in [$targetFilePath] not exists" 
    return 1
  fi

  for line in $lines; do
    # 去除首尾空格
    local lineNumber=$(echo $line | awk -F "[:]" '{print $1}')
    # 去除行号和冒号
    local lineContent=${line#$lineNumber:}
    lineContent=$(echo $lineContent | awk '$1=$1')
    # 获取前2个字符
    local prefix=${lineContent:0:2}
    if [[ "$prefix" = "//" ]]; then
      continue
    fi
    echo "  行号：$lineNumber, 修改前：$lineContent"

    ${xsed} -i "${lineNumber}s#$searchKey#$newText#g" $targetFilePath
    if [[ $? -ne 0 ]]; then
      echo "sed命令执行失败，命令如下"
      echo "${xsed} -i '${lineNumber}s#$searchKey#$newText#' $targetFilePath"
    fi
    newLineContent=$(cat ${targetFilePath} | awk "NR==$lineNumber")
    echo "  行号：$lineNumber, 修改后：$newLineContent"

    if [[ "$newLineContent" =~ "$newText" ]]; then
      echo "  ✅✅✅ 修改成功"
    else
      echo "  ❌❌❌ 修改失败"
      exit 1
    fi
  done
  echo "✈️✈️✈️结束修改文件：$targetFilePath"

  IFS="$oldifs"
  return 0
}
# replaceTextBySearchKey "miniProgram.miniprogramType =.*;" "miniProgram.miniprogramType = ${type};" "zn_http_config.dart"

# 替换关键字后的所有内容
function replaceContentStartWithSearchKey() {
  oldifs="$IFS"
  IFS=$'\n'

  local searchKey=$1
  local newText=$2
  local targetFilePath=$3
  
  echo "✈️✈️✈️准备修改文件：$targetFilePath"
  local lines=$(grep -n "$searchKey" $targetFilePath)
  if [[ -z "$lines" ]]; then
    echo "  replaceTextBySearchKey error"
    echo "[$searchKey] in [$targetFilePath] not exists"
    return 1
  fi

  for line in $lines; do
    # 去除首尾空格
    local lineNumber=$(echo $line | awk -F "[:]" '{print $1}')
    # 去除行号和冒号
    local lineContent=${line#$lineNumber:}
    lineContent=$(echo $lineContent | awk '$1=$1')
    # 获取前2个字符
    local prefix=${lineContent:0:2}
    if [[ "$prefix" = "//" ]]; then
      continue
    fi
    echo "  行号：$lineNumber, 修改前：$lineContent"

    local newContent="$searchKey $newText"
    local newSearchKey="$searchKey.*"
    newSearchKey=${newSearchKey//\#/\\#}
    newContent=${newContent//\#/\\#}
    
    ${xsed} -i "$lineNumber s#$newSearchKey#$newContent#g" $targetFilePath
    echo "${xsed} -i '$lineNumber s#$newSearchKey#$newContent#g' $targetFilePath"
    if [[ $? -ne 0 ]]; then
      echo "sed命令执行失败"
    fi
    newLineContent=$(cat ${targetFilePath} | awk "NR==$lineNumber")
    echo "  行号：$lineNumber, 修改后：$newLineContent"

    if [[ "$newLineContent" =~ "$newText" ]]; then
      echo "  ✅✅✅ 修改成功"
    else
      echo "  ❌❌❌ 修改失败"
      exit 1
    fi
  done
  echo "✈️✈️✈️结束修改文件：$targetFilePath"

  IFS="$oldifs"
  return 0
}

# 获取flutter版本号
function getFlutterVersion() {
  FlutterSDKVersion=$(cat ${FlutterSDKHome}/version)
  echo $FlutterSDKVersion
}

function getFileSize() {
  local filePath=$1
  if [[ ! -f $filePath ]]; then
    return 1
  fi

  local desc=$(ls -lh $filePath)
  if [[ "${desc}" =~ "\Domain" ]]; then
    echo "$desc" | awk '{print $6}'
  else
    echo "$desc" | awk '{print $5}'
  fi
}
