#!/bin/sh

function getCurrentBranchName() {
  echo $(git branch | awk '$1 == "*" {print $2}')
}

# 解析shell命令参数
# function parseCommandParam() {
#     local params=("$@")
#     echo "params = ${params[@]}"

#     # 参数map，需要先声明 map=(["aa"]="11" ["bb"]="22")
#     declare -a paramsMap=(["1"]="1")

#     local count=${#params[@]}
#     # 解析参数
#     for (( i=0; i<$count; i++ )); do
#         local paramItem=${params[$i]}
#     done
#     echo ${paramsMap[*]}
# }

# updateGitCode \
#   --url=git@192.168.2.246:mobile-component/zn_flu_common_business_components.git \
#   --target-dir=full/path/to/zn_flu_common_business_components \
#   --ref-name=feat/hatch
function updateGitCode() {
  # 保存脚本执行的目录，在更新完成后回退到该目录
  local oldPATH=$PWD
  local params=("$@")
  # echo "updateGitCode = ${params[@]}"
  local gitUrl=""
  local gitDir=""
  local refName="master"
  local count=${#params[@]}
  # 解析参数
  local i=0;
  for ((; i < $count; i++)); do
    local paramItem=${params[$i]}
    local key=""
    local value=""
    if [[ $paramItem =~ "=" ]]; then
      key=${paramItem%%=*}
      value=${paramItem##*=}
    else
      key=${paramItem}
    fi

    if [[ $key =~ "--url" ]]; then
      gitUrl=$value
    elif [[ $key =~ "--target-dir" ]]; then
      gitDir=$value
    elif [[ $key =~ "--ref-name" ]]; then
      refName=$value
    fi
  done
  echo "🔥 开始更新库[$gitUrl]-[$refName]到目录[$gitDir]"
  if [[ -z $gitUrl ]]; then
    echo "❌ 参数url为空，请设置git地址"
    return 1
  fi

  local repoName=${gitUrl##*/}
  repoName=${repoName%.*}

  # 1. 准备好git代码的目录
  if [[ -z $gitDir ]]; then
    gitDir=$repoName
    echo "    git更新目录为：$gitDir"
  fi
  if [[ ! -d $gitDir ]]; then
    mkdir -p $gitDir
  fi

  # 2. 检验git url是否与现有的一致
  # 是否需要重置git目录
  local needReset=0
  cd $gitDir
  if [[ -d ".git" || -f ".git" ]]; then
    local remoteUrl=`getGitRemoteUrl`
    if [[ -z "$remoteUrl" ]]; then
      echo "❌ 获取remote url失败";
      return 1
    fi
    if [[ "$remoteUrl" = "$gitUrl" ]]; then
      needReset=0
    else
      echo "    git源不一致，准备清空目录, old remote url = $remoteUrl"
      needReset=1
    fi
  else
    # 没有git配置信息说明可能有其他杂文件，需要清空
    needReset=1
  fi

  # 重置工作空间
  if [[ $needReset = 1 ]]; then
    cd $oldPATH
    rm -rf $gitDir && mkdir -p $gitDir && cd $gitDir
    git init >/dev/null 2>&1
    git remote add origin $gitUrl >/dev/null 2>&1
  fi

  # 3. 更新最新代码
  # echo "    更新tag..."
  git fetch --tags --prune --force >/dev/null 2>&1
  # echo "    更新本地版本库..."
  git fetch origin >/dev/null 2>&1

  local gitBranchState=$(git branch)
  # 如果gitBranchState为空，说明目录刚执行过git init，还没有任何文件, 这时checkout到master，将代码从仓库更新到工作区
  if [[ -z $gitBranchState ]]; then
    git checkout master >/dev/null 2>&1
  else 
    echo "    清理git目录..."
    git clean -dfx >/dev/null 2>&1
    git checkout . >/dev/null 2>&1
  fi

  # 4. 判断git目录是否处于Head Detached状态，如果是，需要将Head恢复到master分支
  local isHeadDetached=$(git status | grep 'HEAD detached at')
  if [[ -n "$isHeadDetached" ]]; then
    echo "    当前仓库Head处于垂悬状态，恢复到master分支..."
    git checkout master >/dev/null 2>&1
  fi

  # 5. 判断refName是什么类型，执行更新操作
  local refType=$(getGitRefType $refName)
  echo "    ref 类型 = $refType"
  if [[ -z "$refType" ]]; then
    echo "❌ ${repoName}仓库中不存在指定ref名称【${refName}】"
    return 1
  fi

  if [[ $refType = "branch" ]]; then
    local branchName=$(git branch | awk '$1 == "*" {print $2}')
    if [[ "$branchName" != "$refName" ]]; then
      echo "    当前分支[$branchName] != 目标分支[$refName]"
      git checkout $refName >/dev/null 2>&1
      if [[ $? -ne 0 ]]; then
        echo "❌ ${repoName}仓库中不存在分支${refName}"
        return 1
      else
        echo "    切换到分支${refName}成功"
      fi
    fi

    # 这里防止本地有提交，需要重置到远程最新代码，同时也将本地仓库更新成最新版本
    git reset --hard origin/$refName >/dev/null 2>&1
  else
    git checkout $refName >/dev/null 2>&1
    local line1=$(git branch | head -n 1)
    local commitId=${line1##* }
    commitId=${commitId%)*}
    if [[ "$commitId" = "$refName" ]]; then
      echo "    切换到$refType ${refName}成功"
    fi
  fi

  local commitMssage=$(git log -1 --pretty=oneline)
  echo "    最新更新记录：😝 ${commitMssage} 😝"
  echo "✅ 代码更新成功"
  cd $oldPATH
}

# 获取ref的类型，是tag还是分支还是commit id
function getGitRefType() {
  local refName=$1

  # tag
  local result=$(git tag -l | grep $refName)
  if [[ -n "$result" ]]; then
    echo "tag"
    return 0
  fi

  # 分支
  result=$(git branch -a | grep -w $refName)
  if [[ -n "$result" ]]; then
    echo "branch"
    return 0
  fi

  # commit id
  # 有错误说明指定的ref名称不存在
  git rev-parse $refName > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  result=$(git rev-parse $refName)
  if [[ -n "$result" ]]; then
    echo "commit_id"
    return 0
  fi

  return 1
}

# 获取远程仓库地址
function getGitRemoteUrl() {
  local remoteName=$(git remote)
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  local remoteNameLength=${#remoteName}
  local leftTripLength=$(expr $remoteNameLength + 1)
  local remoteUrl=$(git remote -v | grep origin | grep fetch)
  remoteUrl=${remoteUrl%% *}
  remoteUrl=${remoteUrl:$leftTripLength}
  echo $remoteUrl
}

  