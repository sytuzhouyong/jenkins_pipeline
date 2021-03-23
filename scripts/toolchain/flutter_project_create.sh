#!/bin/bash

function echoResult() {
    if [[ $? -eq 0 ]]; then
        echo "成功"
    else
        echo "失败, 返回值：$?"
        exit 1
    fi
}

function addYamlLibConfig() {
    local libRefType=$1
    local libName=$2

    local file_name=pubspec.yaml
    local line_index=0
    cat $file_name | while read line
    do
        line_index=`expr $line_index + 1`
        trip_line=`echo $line`

        if [[ "$trip_line" == "dev_dependencies:" ]]; then
            
            # +2 是为了跳过flutter_test的配置
            line_index=`expr $line_index + 2`

            gsed -i "`expr $line_index + 0`G" $file_name

            if [[ "$libRefType" = "path" ]]; then
                libPath=$3
                gsed -i "`expr $line_index + 1`a\ \ ${libName}:" $file_name
                gsed -i "`expr $line_index + 2`a\ \ \ \ path: ${libPath}" $file_name
                break
            elif [[ "$libRefType" = "version" ]]; then
                libVersion=$3
                gsed -i "`expr $line_index + 1`a\ \ ${libName}: $libVersion" $file_name
                break
            elif [[ "$libRefType" = "git" ]]; then
                libGitUrl=$3
                libGitVersion=$4
                gsed -i "`expr $line_index + 1`a\ \ ${libName}:" $file_name
                gsed -i "`expr $line_index + 2`a\ \ \ \ git:" $file_name
                gsed -i "`expr $line_index + 3`a\ \ \ \ \ \ ref: ${libGitVersion}" $file_name
                gsed -i "`expr $line_index + 4`a\ \ \ \ \ \ url: ${libGitUrl}" $file_name
                break
            fi
        fi
    done
}

# 增加common_pods函数声明和调用
function initCommonPods() {
    local file_name=Podfile
    local line_index=0

    cat $file_name | while read line
    do
        line_index=`expr $line_index + 1`
        trip_line=`echo $line`

        if [[ "$trip_line" == "target 'Runner' do" ]]; then
            # 先增加调用函数的代码，再增加函数体
            # 1. 函数调用
            gsed -i "`expr $line_index`a\ \ common_pods" $file_name

            # 在指定行前面添加空行
            gsed -i "`expr $line_index`{x;p;x;}" $file_name
            # 在指定行后面添加空行
            # gsed -i "`expr $line_index + 1`G" $file_name
            
            # 2. 函数体
            gsed -i "`expr $line_index - 1`adef common_pods" $file_name
            gsed -i "`expr $line_index + 0`aend" $file_name
            
            return
        fi
    done
}

function addPodLibConfig() {
    local libRefType=$1
    local libName=$2

    local file_name=Podfile
    local line_index=0
    local targetLineIndex=0

    cat $file_name | while read line
    do
        line_index=`expr $line_index + 1`
        trip_line=`echo $line`

        if [[ "$trip_line" == "def common_pods" ]]; then
            targetLineIndex=$line_index
            echo $targetLineIndex
            continue
        fi

        if [[ "$trip_line" == "end" && $targetLineIndex != 0 ]]; then
            targetLineIndex=$line_index

            if [[ "$libRefType" = "version" ]]; then
                libVersion=$3
                gsed -i "`expr $targetLineIndex - 1`a\ \ pod '$libName', '$libVersion'" $file_name
            elif [[ "$libRefType" = "git" ]]; then
                libGitUrl=$3
                libGitVersion=$4
                gsed -i "`expr $targetLineIndex - 1`a\ \ pod '$libName', :git => '$libGitUrl',:tag => '$libGitVersion'" $file_name
                break
            fi
            return
        fi
    done
}

function parseScriptParams() {
    # params 这样获取才能保证内部的空格不会影响参数的判断
    params=$1
    count=${#params[@]}
    for ((i=0; i<count; i++ )); do
      item=${params[$i]}
      echo "参数 = $item"

      paramKey=${item%%=*}
      paramValue=${item#*=}
      echo "key = $paramKey, value = $paramValue"
      if [[ "$paramKey" = "--name" ]]; then
          ProjectName=$paramValue
          continue
      fi

      if [[ "$paramKey" = "--flutter-libs" ]]; then
          FlutterLibs=($paramValue)
          continue
      fi

      if [[ "$paramKey" = "--flutter-libs-infos" ]]; then
          FlutterLibsInfos=($paramValue)
          continue
      fi

      if [[ "$paramKey" = "--ios-libs" ]]; then
          iOSLibs=($paramValue)
          continue
      fi

      if [[ "$paramKey" = "--ios-libs-infos" ]]; then
          iOSLibsInfos=($paramValue)
          continue
      fi
    done

    echo "ProjectName = $ProjectName"
    echo "FlutterLibs = ${FlutterLibs[*]}, count = ${#FlutterLibs[@]}"
    echo "FlutterLibsInfos = ${FlutterLibsInfos[*]}, count = ${#FlutterLibsInfos[@]}"
    echo "iOSLibs = ${iOSLibs[*]}, count = ${#iOSLibs[@]}"
    echo "iOSLibsInfos = ${iOSLibsInfos[*]}, count = ${#iOSLibsInfos[@]}"

    FlutterLibsCount=${#FlutterLibs[@]}
    FlutterLibsInfosCount=${#FlutterLibsInfos[@]}
    iOSLibsCount=${#iOSLibs[@]}
    iOSLibsInfosCount=${#iOSLibsInfos[@]}

    if [[ $FlutterLibsCount -ne $FlutterLibsInfosCount ]]; then
        echo "fluter库的数目和对应版本信息的数目不一致，请检查"
        exit 1
    fi

    if [[ $iOSLibsCount -ne $iOSLibsInfosCount ]]; then
        echo "iOS库的数目和对应版本信息的数目不一致，请检查"
        exit 1
    fi
}

# params 格式
# sh ./gen.sh \
#    --name=proj1 \
#    --flutter-libs="url_launcher sqflite flutter_swiper flutter_boost" \
#    --flutter-libs-infos="v~4.0.3 v~1.0.0 v~1.0.6 g~git@192.168.2.246:mobile-component/flutter_boost.git~fix_1.7.8" \
#    --ios-libs="YYWebImage MBProgressHUD TZImagePickerController" \
#    --ios-libs-infos="v~1.0.5 v~1.1.0 g~git@192.168.2.246:mobile-thirdparty/TZImagePickerController.git~v2.0.1.1" \
#
params=("$@")

ProjectName=""
FlutterLibs=()
FlutterLibsInfos=()
iOSLibs=()
iOSLibsInfos=()

parseScriptParams $params 

PROJECT_DIR=`PWD`/${ProjectName}
PLUGIN_DIR=${PROJECT_DIR}/plugins
PLUGIN_NAME=plugin_placeholder
PODFILE_DIR=$PROJECT_DIR/ios
PODFILE_PATH=$PODFILE_DIR/Podfile
PLISTFILE_PATH=$PROJECT_DIR/ios/Runner/Info.plist

if [[ -z "$ProjectName" ]]; then
  echo "需要提供一个工程名称参数"
  exit 1
fi

echo "1. 创建Flutter工程"
flutter create --template=app $ProjectName > /dev/null
echoResult

echo "2. 创建占位plugin，为了自动生成iOS工程下的Podfile"
if [[ ! -d $ProjectName ]]; then
  echo "主工程生成失败"
  exit 1
fi
cd $PROJECT_DIR
mkdir -p plugins
cd plugins
flutter create --template=plugin plugin_placeholder > /dev/null
echoResult

cd $PROJECT_DIR 
echo `PWD`

echo "4. 添加plugin配置"
addYamlLibConfig "path" $PLUGIN_NAME "./plugins/${PLUGIN_NAME}"

echo "5. 配置Flutter第三方库信息"
index=0
for lib in ${FlutterLibs[@]}; do
    libInfo=${FlutterLibsInfos[$index]}
    echo "lib = $lib, libInfo = $libInfo"
    infoItems=(${libInfo//\~/ })
    echo "infos = ${infoItems[*]}"

    refType=${infoItems[0]}
    if [[ $refType = "ver" ]]; then
        addYamlLibConfig "version" $lib "${infoItems[1]}"
    elif [[ $refType = "git" ]]; then
        url=${infoItems[1]}
        version=${infoItems[2]}
        addYamlLibConfig "git" $lib $url $version
    fi
    index=`expr $index + 1`
done

echo "6. 执行 flutter pub get"
flutter pub get
echoResult

echo "7. 更新Podfile文件"
cd $PODFILE_DIR
if [[ ! -f $PODFILE_PATH ]]; then
    echo "Podfile文件不存在，请检查${PLUGIN_NAME}在pubspec.yaml中是否配置成功"
    exit 1
fi

initCommonPods
index=0
for lib in ${iOSLibs[*]}; do
    libInfo=${iOSLibsInfos[$index]}
    echo "lib = $lib, libInfo = $libInfo"
    infoItems=(${libInfo//\~/ })
    echo "infos = ${infoItems[*]}"

    refType=${infoItems[0]}
    if [[ $refType = "ver" ]]; then
        addPodLibConfig "version" $lib "${infoItems[1]}"
    elif [[ $refType = "git" ]]; then
        url=${infoItems[1]}
        version=${infoItems[2]}
        addPodLibConfig "git" $lib $url $version
    fi
    index=`expr $index + 1`
done
echoResult

echo "8. 执行pod install"
cd $PODFILE_DIR
pod install --verbose

echo "9. 更新设备权限配置"
/usr/libexec/PlistBuddy -c "ADD :NSCameraUsageDescription  string 发布内容时可选择您拍摄的照片" $PLISTFILE_PATH
/usr/libexec/PlistBuddy -c "ADD :NSContactsUsageDescription string 查看手机号需要通许录权限" $PLISTFILE_PATH
/usr/libexec/PlistBuddy -c "ADD :NSPhotoLibraryUsageDescription string App需要您的同意,才能访问本地照片" $PLISTFILE_PATH
/usr/libexec/PlistBuddy -c "ADD :NSLocationAlwaysUsageDescription string 定位时需要获取定位权限" $PLISTFILE_PATH

echoResult
echo "============ success"
