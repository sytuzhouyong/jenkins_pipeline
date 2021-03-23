#!/bin/bash

set -eu
set -o pipefail

# 打包
source ./get_project_info.sh

function makePackageAndroid() {
  # 当前目录是在 scripts 目录下，所以要进入工作空间目录
  cd $WorkspacePath

  # 因为商户端和对客端没有统一生成 bakApk 目录，这里做个统一处理，
  # 除了NMLGB，我还能说什么呢
  BakApkDir=build/app/bakApk
  if [[ ! -d $BakApkDir ]]; then
    mkdir -p $BakApkDir

    # 找到 outputs 目录下的 apk 文件，然后拷贝到 bakApk 目录下
    SrcApkFileDir=build/app/outputs/apk
    SrcApkFilePath=`find $SrcApkFileDir -name "*.apk" | tail -n 1`
    if [[ -z "$SrcApkFilePath" ]]; then
      echo "在[$SrcApkFilePath]下没有找到 apk 文件"
      exit 1
    fi

    # 去掉年
    NewBuildString=${BuildString#*-}
    DstApkFileDir=$BakApkDir/${NewBuildString}
    mkdir -p $DstApkFileDir
    cp -r $SrcApkFilePath $DstApkFileDir
  fi

  # 拷贝文件到 build/app 目录下
  cd $WorkspacePath/$BakApkDir
  dirName=$(ls | tail -n 1 | awk '{print $1}')
  echo "dir name = $dirName"
  apkFileDir=$BakApkDir/${dirName}

  cd $WorkspacePath
  apkFilePaths=`find ${apkFileDir} -name "*.apk"`
  echo "apkFilePaths = [$apkFilePaths]"

  if [[ -z "${apkFilePaths}" ]]; then
    echo "没有找到 apk 文件"
    exit 1
  fi

  # 保存文件大小信息
  local firstApkFilePath=`find ${apkFileDir} -name "*.apk"  | tail -n 1`
  saveFileSize "${firstApkFilePath}"

  for file in $apkFilePaths; do
    echo "file = ${file}"
    fileTitle=${AppIdentifier}_${AppPackageType}_${BuildString}
    if [[ "$file" =~ "legu" ]]; then
      fileTitle=${fileTitle}_legu
    fi
    fileTitle=${fileTitle}.apk
    cp -r $file build/app/${fileTitle}
  done

  # 为了适配channelPackages不存在的情况下，archiveArtifacts命令报错的问题
  mkdir -p $WorkspacePath/channelPackages

  # apk 包加固
  if [[ "${isLegu}" = "true" ]]; then
    echo "需要加固"
    if [[ ! -f $WorkspacePath/buildsystem/auto_package_legu_channel_all_remote_release.sh ]]; then
      echo "没有加固脚本，无需加固"
      exit 0
    fi

    cd $WorkspacePath/buildsystem

    version=$(getBuildVersionAndroid)
    echo "加固程序参数：apkFileDir = [$apkFileDir], version = [$version]"
    bash auto_package_legu_channel_all_remote_release.sh ${apkFileDir} ${version}
  fi
}

function makePackageIOS() {
  cd ${BuildPath}
  rm -f *.ipa

  ArchiveFileTitle=${PackageFileTitle}
  IPAFileName=${ArchiveFileTitle}.ipa
  echo "IPAFileName = ${IPAFileName}"

  if [[ "${AppPackageType}" = "development" ]]; then
    AppFilePath=$(find . -name "*.app") # path/to/Runner.app
    AppFileName=${AppFilePath##*/} # Runner.app
    AppFileTitle=${AppFileName%.*} # Runner

    mkdir -p ./${AppFileTitle}/Payload
    cp -r ${AppFilePath} ./${AppFileTitle}/Payload/${AppFileName}
    cd ${AppFileTitle}
    zip -r ${AppFileTitle}.ipa Payload iTunesArtwork

    cp ${AppFileTitle}.ipa ../${IPAFileName}
    # 保存文件大小信息
    saveFileSize ${BuildPath}/${AppFileTitle}.ipa
  else
    ArchiveFilePath=$(find . -name "*.xcarchive") # path/to/XXX.xcarchive
    ArchiveFileName=${ArchiveFilePath##*/} # XXX.xcarchive
    ArchiveFileTitle=${ArchiveFileName%.*} # XXX

    ExportPath=${BuildPath}/ipa
    ArchivePlistFilePath="${WorkspacePath}/export_plist_files/export_${AppPackageType}.plist"

    xcodebuild -exportArchive \
        -archivePath ${ArchiveFilePath} \
        -exportPath ${ExportPath} \
        -exportOptionsPlist ${ArchivePlistFilePath}

    IPAFilePath=$(find . -name "*.ipa")
    if [[ ! -f ${IPAFilePath} ]]; then
      echo "导出 ipa 包失败"
      exit 1
    fi
    echo "IPAFilePath = ${IPAFilePath}"
    cp ${IPAFilePath} ./${IPAFileName}
    # 保存文件大小信息
    saveFileSize ${BuildPath}/${IPAFilePath}

    # 保存 dysm文件 和 ipa 包
    if [[ "${AppPackageType}" = "appstore" ]]; then
      dateString=${BuildString%%_*}
      timeString=${BuildString##*_}
      targetSavePath=$HOME/Desktop/${AppIdentifier}-pipeline-ipas/${dateString}/${timeString}
      echo "targetSavePath = ${targetSavePath}"
      
      local dsymFileName=$(ls ${ArchiveFilePath}/dsyms)
      mkdir -p ${targetSavePath}
      cp -r ${ArchiveFilePath}/dsyms/${dsymFileName} ${targetSavePath}/${ArchiveFileTitle}.app.dSYM
      cp ./${IPAFileName} ${targetSavePath}
    fi
  fi
}

function saveFileSize() {
  local filePath=$1
  local size=$(getFileSize $filePath)
  echo "文件大小: $size"
  echo $size >> $BuildInfoFilePath
}

function makePackage() {
  mkdir -p ${WorkspacePath}/ios/build
  mkdir -p ${WorkspacePath}/build/app
  mkdir -p ${WorkspacePath}/channelPackages

  if [[ "$Platform" = "android" ]]; then
    makePackageAndroid
  else
    makePackageIOS
  fi
  return $?
}

# 创建快照文件
function creatGitInfoFile() {
  # 只有appstore包才记录git信息
  if [[ "${AppPackageType}" = "appstore" ]]; then
    source $WorkspacePath/scripts/code_snapshot.sh

    echo "⭕️⭕️⭕️开始快照git提交信息"
    cd $WorkspacePath
    local gitInfo=$(snapshotGitInfo "$WorkspacePath" "$WorkspacePath")
    export LANG="en_US.UTF-8"
    echo -e $gitInfo > $WorkspacePath/scripts/${AppIdentifier}_git_snapshot.txt
    echo "💯💯💯结束快照git提交信息"
  fi
}

makePackage
if [[ $? -ne 0 ]]; then
  echo "打包失败"
  exit 1
fi

creatGitInfoFile
if [[ $? -ne 0 ]]; then
  echo "快照Git信息失败"
  exit 1
fi


