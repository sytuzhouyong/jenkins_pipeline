#!/bin/bash

source ./get_project_info.sh

ALIYUN_HOST="https://oss-znlhzl.oss-cn-shanghai.aliyuncs.com"

# 获取阿里云SecretToken数据
function fetchAliyunSecretToken() {
    local url="https://api.znlhzl.cn/api-oss/api/v2/oss/passFlag/getSecurityToken"
    local data=$(curl $url)

    local success=${data#*success\":}
    success=${success%%,*}
    # echo "success = $success"
    if [[ "$success" != "true" ]]; then
        return 1
    fi

    local securityToken=${data#*securityToken\":\"}
    securityToken=${securityToken%%\"*}
    # echo "securityToken = $securityToken"

    local accessKeySecret=${data#*accessKeySecret\":\"}
    accessKeySecret=${accessKeySecret%%\"*}
    # echo "accessKeySecret = $accessKeySecret"

    local accessKeyId=${data#*accessKeyId\":\"}
    accessKeyId=${accessKeyId%%\"*}

    local infos=($securityToken $accessKeySecret $accessKeyId)
    echo ${infos[@]}
    return 0
}

# 上传到阿里云
function uploadFile() {
    local filePath=$1
    if [[ -z "$filePath" || ! -f "$filePath" ]]; then
        echo "❌ 文件[$filePath]不存在"
        exit 1
    fi

    local uploadParams=($(fetchAliyunSecretToken))
    # echo "uploadParams = ${uploadParams[@]}"
    local count=${#uploadParams[*]}
    if [[ $count -ne 3 ]]; then
        echo "❌ 获取secret token信息失败"
        exit 1
    fi

    local securityToken=${uploadParams[0]}
    local accessKeySecret=${uploadParams[1]}
    local accessKeyId=${uploadParams[2]}
    local suffix=$(uname)
    # 会返回policy的base64字符串以及signature签名字符串
    local infos=($(${PipelineScriptsPath}/utils_aliyun_upload_tools_${suffix} $accessKeySecret))
    local keyCount=${#infos[*]}
    if [[ $keyCount -ne 2 ]]; then
        echo "❌ [${PipelineScriptsPath}/utils_aliyun_upload_tools_${suffix} $accessKeySecret]命令数据返回异常"
        exit 1
    fi
    local policyBase64=${infos[0]}
    local signatureText=${infos[1]}
    echo "signatureText = $signatureText"

    curl \
        -F "chunk=0" \
        -F "key=$2" \
        -F "policy=$policyBase64" \
        -F "OSSAccessKeyId=${accessKeyId}" \
        -F "signature=$signatureText" \
        -F "x-oss-security-token=$securityToken" \
        -F "success_action_status=200" \
        -F "Access-Control-Allow-Origin=*" \
        -F "file=@${filePath}" \
        $ALIYUN_HOST
    return $?
}

# 上传文件到阿里云 参数1：本地文件路径，参数2：上传key，也就是上传后的路径
function uploadFileToAliyun() {
    echo "🔥 开始上传文件[$1][$2]到阿里云"
    uploadFile $1 $2
    if [[ $? -ne 0 ]]; then
        echo "❌ 文件[$1]上传阿里云失败, 错误码：$?"
        return 1
    fi

    AliyunUploadFileUrl=$ALIYUN_HOST/$2
    echo "✅ 文件[$1]上传阿里云成功, url = $AliyunUploadFileUrl"
    
    # 导出供外部使用
    export AliyunUploadFileUrl
    return 0
}
