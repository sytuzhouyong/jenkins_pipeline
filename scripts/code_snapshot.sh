#!/bin/bash

# 获取git相关信息
function getLatestGitInfo() {
  local path=$1
  local rootPath=$2
  cd $rootPath
  cd $path

  git log > /dev/null
  if [[ $? -ne 0 ]]; then
    echo "❌ error git info in path: [$rootPath] [$path]"
    return
  fi
  # 8位commit id
  commitId=$(git rev-parse HEAD)
  author=$(git log -1 --pretty=short | grep Author | awk -F "[:]" '{print $2}')
  commitMssage=$(git log -1 --pretty=oneline)
  commitMssage=${commitMssage:40}

  currentTag=''
  lastTag=$(git tag -l | tail -n 1)
  if [[ -n "$lastTag" ]]; then
    lastTagCommitId=$(git rev-parse $lastTag)
    lastTagCommitId=${lastTagCommitId:8}
    if [[ "$lastTagCommitId" = "$commitId" ]]; then
      currentTag=$lastTag
    fi
  fi

  remoteURL=$(git remote -v | grep origin | grep fetch)
  remoteURL=${remoteURL%%(*}
  remoteURL=${remoteURL:7}

  # 从path中将rootPath删除掉，这样就剩下相对路径
  relativePath=${path/$rootPath/}
  relativePath=".$relativePath"

  echo "dir_path: $relativePath\n"
  echo "git_url: $remoteURL\n"
  echo "commit_id: $commitId\n"
  echo "tag: $currentTag\n"
  echo "author: $author\n"
  echo "commit_message: $commitMssage\n"
  echo "\n"
}

# 获取工程内所有仓库的git信息
function snapshotGitInfo() {
  # local不能少，否则递归调用时变量值会混乱
  local path=$1
  local rootPath=$2
  if [[ (-f $path/.git) || (-d $path/.git) ]]; then
    getLatestGitInfo "$path" "$rootPath"
  fi

  # 只显示目录
  for file in $(ls -F $path | grep "/$"); do
    # file形如 xxx/ 的样式，所以要删掉最后一个斜杠
    local length=${#file}
    length=$(expr $length - 1)
    # 删除目录末尾的/
    local dirName=${file:0:$length}
    # 当目录中包含如下字符时就不递归进入了，提升效率
    if [[ "$dirName" = "build" || "$dirName" =~ "." ]]; then
      continue
    fi
    # echo "dirName = $dirName\n"

    local fullPath=$path"/"$dirName
    if [[ -d $fullPath ]]; then
      snapshotGitInfo "$fullPath" "$rootPath"
    fi
  done
}

function parseGitSnapshotInfo() {
  local workspace=$(pwd)
  local text=$(cat $1)
  oldifs="$IFS"
  IFS=$'\n'

  local repoName=""
  local commitId=""
  local repoPath=""
  local gitUrl=""

  for line in $text; do
    line=$(echo $line | sed 's/ //g')

    if [[ "$line" =~ "commit_id" ]]; then
      commitId=$(echo $line | awk -F "[:]" '{print $2}')
      echo "commitId = $commitId"
    elif [[ "$line" =~ "dir_path" ]]; then
      repoPath=$(echo $line | awk -F "[:]" '{print $2}')
      echo "repoPath = $repoPath"
    elif [[ "$line" =~ "git_url" ]]; then
      gitUrl=${line#*:}
      echo "gitUrl = $gitUrl"
    fi

    if [[ -n "$commitId" && -n "$repoPath" && -n "$gitUrl" ]]; then
      cd $workspace

      if [[ -d $repoPath && "$repoPath" != "." ]]; then
        rm -rf $repoPath
      fi
      mkdir -p $repoPath
      cd $repoPath

      echo "准备下载代码 $repoName"
      git init
      git remote add origin $gitUrl
      git fetch --tags
      # 下载指定tag的代码
      git fetch origin $commitId
      if [[ $? -ne 0 ]]; then
        echo "❌ git fetch origin $commitId"
        exit 1
      fi
      git reset --hard FETCH_HEAD
      if [[ $? -ne 0 ]]; then
        echo "❌ git reset --hard FETCH_HEAD"
        exit 1
      fi
      echo -e "${repoName}下载完成\n"

      repoName=""
      commitId=""
      repoPath=""
      gitUrl=""
    fi
  done
  IFS="$oldifs"
}
