#!/bin/bash

source ./get_project_info.sh
source ./utils_git.sh
source ./flutter_version_active.sh
echo "xflutter = $xflutter"

# 下载工具代码并生成可执行文件
function generateMissileTool() {
    cd ${WorkspacePath}
    if [[ ! -d "./tools_dynamic" ]]; then
        mkdir -p ./tools_dynamic
    fi
    cd tools_dynamic
    updateGitCode --url="git@192.168.2.246:share/missile.git" --ref-name="feat/old"

    cd ${WorkspacePath}/tools_dynamic/missile/missile
    if [[ -f .packages ]]; then
        rm -f .packages
    fi
    $xflutter pub get

    dart2native "${WorkspacePath}/tools_dynamic/missile/missile/bin/main.dart" "${WorkspacePath}/tools_dynamic/missile_tool"
    return $?
}

# 扫描库工具
function generateScanTool() {
    cd ${WorkspacePath}
    if [[ ! -d "./tools_dynamic" ]]; then
        mkdir -p ./tools_dynamic
    fi
    cd tools_dynamic
    updateGitCode --url="git@192.168.2.246:share/scanner_proxy.git" --ref-name="master"

    cd ${WorkspacePath}/tools_dynamic/scanner_proxy
    if [[ -f .packages ]]; then
        rm -f .packages
    fi
    $xflutter pub get

    dart2native "${WorkspacePath}/tools_dynamic/scanner_proxy/main.dart" "${WorkspacePath}/tools_dynamic/scan_tool"
    return $?
}

# 更新proxy工程
function updateMarsProxyCode() {
    cd ${WorkspacePath}
    if [[ ! -d "./tools_dynamic" ]]; then
        mkdir -p ./tools_dynamic
    fi
    cd tools_dynamic
    updateGitCode --url="git@192.168.2.246:share/mars_proxy.git" --ref-name="feat/init"
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # 更新mars_proxy工程
    # ${WorkspacePath}/tools_dynamic/scan_tool \
    #     "${WorkspacePath}/lib/ui/quick" \
    #     "${WorkspacePath}/tools_dynamic/mars_proxy/pubspec.yaml" \
    #     "${WorkspacePath}" \
    #     "${WorkspacePath}/tools_dynamic/mars_proxy/lib" \
    #     "${FlutterSDKHome}" \
    #     "${WorkspacePath}/module/zn_flu_bmod_base" \
    #     "${WorkspacePath}/module/zn_flu_utl_common"

    cd ${WorkspacePath}/tools_dynamic/mars_proxy
    if [[ -f .packages ]]; then
        rm -f .packages
    fi
    $xflutter pub get
    # 这里返回0是为了防止flutter pub get出错导致流水线报错
    return 0
}

# 更新mars运行时框架代码
function updateMarsCode() {
    cd ${WorkspacePath}
    if [[ ! -d "./tools_dynamic" ]]; then
        mkdir -p ./tools_dynamic
    fi
    cd tools_dynamic
    updateGitCode --url="git@192.168.2.246:share/mars.git" --ref-name="feat/old2"
    local result=$?
    if [[ $result -ne 0 ]]; then
        return result
    fi
    cd ${WorkspacePath}/tools_dynamic/mars
    if [[ -f .packages ]]; then
        rm -f .packages
    fi
    $xflutter pub get
    # 这里返回0是为了防止flutter pub get出错导致流水线报错
    return 0
}

# dart文件转json
function parseDart2Json() {
    local missileToolPath=${WorkspacePath}/tools_dynamic/missile_tool
    if [[ ! -f $missileToolPath ]]; then
        echo "❌ 文件【${missileToolPath}】不存在"
        exit 1
    fi

    local type=$1
    local srcFile=$2
    local targetDir=$3
    if [[ "$type" != "folder" && "$type" != "file" ]]; then
        echo "❌ type参数错误，只能是folder和file中的一种"
        return -1
    fi
    cd ${WorkspacePath}
    if [[ "$type" == "folder" && ! -d $srcFile ]]; then
        echo "❌ 代码目录[$srcFile]不存在"
        return 1
    fi

    mkdir -p $targetDir

    $missileToolPath $@
    if [[ $? -ne 0 ]]; then
        echo "❌ dart转json失败: [$missileToolPath $type $srcFile $targetDir]"
        return -1
    fi
    echo "✅ dart转json文件成功 [$missileToolPath $type $srcFile $targetDir]"
    return 0
}

# 执行dart2native程序，将dart代码变成可执行程序
function dart2native() {
    # local dart2native="/Users/zhouyong1/Documents/sdks/dart-sdk/2.9.2/bin"
    local dart2native="/Users/lk/dart-sdk/2.9.2/bin/dart2native"
    if [[ "$Platform" = "android" ]]; then
        dart2native="/opt/dart-sdks/2.9.2/bin/dart2native"
    fi
    local mainFilePath=$1
    local targetExecutorFilePath=$2

    $dart2native $mainFilePath -o $targetExecutorFilePath
    if [[ $? -ne 0 ]]; then
        echo "❌ [$dart2native $mainFilePath -o $targetExecutorFilePath] failed"
        return -1
    fi
    return 0
}
