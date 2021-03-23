#!/bin/bash

source ./get_project_info.sh
source ./utils.sh
source ./utils_git.sh
source ./utils_dynamic_page.sh

# set -eu
# set -x
# set -o pipefail

# 获取传递给脚本的参数
params=("$@")
hasSubmodlue=0  # 是否有子模块
moduleNames=()  # 模块列表
branchNames=()  # 分支名列表
isDynamicProject=0 # 是否是动态化项目

for ((i=0; i<$#; i++ )); do
  item=${params[$i]}
  echo "参数 = $item"
  # 1. 是否有子模块
  if [[ $item =~ "--has-submodule" ]]; then
      if [[ $item =~ "=" ]]; then
        hasSubmodlue=${item##*=}
        if [[ -z $hasSubmodlue ]]; then
          hasSubmodlue=1
        fi
      else
        hasSubmodlue=1
      fi
      echo "hasSubmodlue = $hasSubmodlue"
      continue
  fi

  # 2. 模块列表
  if [[ $item =~ "--modules=" ]]; then
    moduleNames=(${item##*=})
    if [[ ${#moduleNames[*]} -eq 0 ]]; then
      ehco "error: 模块列表没有值"
      exit 1
    fi
    echo "moduleNames = $moduleNames, 数目：${#moduleNames[*]}"
    continue
  fi

  # 3. 分支列表
  if [[ $item =~ "--branches=" ]]; then
    branchNames=(${item##*=})
    if [[ ${#branchNames[*]} -eq 0 ]]; then
      echo "error: 分支列表没有值"
      exit 1
    fi
    echo "branchNames = $branchNames, 数目：${#branchNames[*]}"
    continue
  fi

  # 4. 是否是动态化工程
  if [[ $item =~ "--dynamic" ]]; then
      if [[ $item =~ "=" ]]; then
        isDynamicProject=${item##*=}
        if [[ -z $isDynamicProject ]]; then
          isDynamicProject=1
        fi
      else
        isDynamicProject=1
      fi
      echo "isDynamicProject = $isDynamicProject"
      continue
  fi
done

if [[ "$hasSubmodlue" = "1" ]]; then
  # 更新子模块
  cd $WorkspacePath
  rm -rf ios
  rm -rf android
  git submodule update --init

  cd $WorkspacePath/ios
  ios_git_url=`getGitRemoteUrl`
  cd $WorkspacePath
  updateGitCode --url=$ios_git_url --target-dir=./ios --ref-name=$MainBranch
  if [[ $? -ne 0 ]]; then
    exit 1
  fi

  cd $WorkspacePath/android
  android_git_url=`getGitRemoteUrl`
  cd $WorkspacePath
  updateGitCode --url=$android_git_url --target-dir=./android --ref-name=$MainBranch
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
fi

# 1. 将 ciconfig 里面的模块分支名改成指定的分支名
# 2. 将分支信息保存在临时文件中，供发送钉钉时使用
if [[ -f ${BranchInfoFile} ]]; then
  rm -f ${BranchInfoFile}
fi
touch ${BranchInfoFile}

echo "MainBranch=${MainBranch}" >> ${BranchInfoFile}

count=${#moduleNames[*]}
echo "分支个数: $count"
for ((i=0; i<${count}; i++)); do
  key=${moduleNames[i]}
  value=${branchNames[i]}
  # 前两个//表示替换所有 \/表示匹配斜杠 后面一个/是语法/, \\/表示替换成\/
  value=${value//\//\\/}
  echo "BranchName = ${key}, BranchValue = ${value}"
  echo "${key}=${value}" >> ${BranchInfoFile}
  ${xsed} -i "s/${key}=\".*\"/${key}=\"${value}\"/" ${WorkspacePath}/ciconfig.sh
  # 验证脚本
  # ${xsed} -i "s/BaseBranch=\".*\"/BaseBranch=\"feat\/logistics_detail\"/" ../../../ciconfig.sh

  if [ $? -ne 0 ]; then
    echo "修改业务分支${key} = ${value}失败"
    exit 1
  fi
done


# 更新 modlue 和 vendor 目录下的代码
source ${WorkspacePath}/ciconfig.sh

# 更新 modlue 和 vendor 目录下的代码
gitRepoCount=${#GitPath[*]}
for ((i = 1; i <= $gitRepoCount; i++)); do
  cd ${WorkspacePath}
  git_dir=${TopFoldName[i]}/${FoldName[i]}
  if [[ ! -d ./${git_dir} ]]; then
    echo "创建目录 ${git_dir}"
    mkdir -p ${git_dir}
  fi
  echo "代码目录：$git_dir"

  git_url=${GitPath[i]}
  ref_name=${RefName[i]}
  updateGitCode --url=$git_url --target-dir=$git_dir --ref-name=$ref_name
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
done

if [[ "$isDynamicProject" = "1" ]]; then
  ### 动态库相关工程
  generateMissileTool
  if [[ $? -ne 0 ]]; then
      echo "❌ 创建missile_tool工具失败"
      exit 1
  fi
  echo "✅ 创建missile_tool工具成功"

  generateScanTool
  if [[ $? -ne 0 ]]; then
      echo "❌ 创建scan_tool工具失败"
      exit 1
  fi
  echo "✅ 创建scan_tool工具成功"

  # 下载或更新mars_proxy工程
  updateMarsProxyCode
  if [[ $? -ne 0 ]]; then
      echo "❌ 更新mars_proxy工程失败"
      exit 1
  fi
  echo "✅ 更新mars_proxy工程成功"

  # 下载mars工程
  updateMarsCode
  if [[ $? -ne 0 ]]; then
      echo "❌ 更新mars工程失败"
      exit 1
  fi
  echo "✅ 更新mars工程成功"
fi
