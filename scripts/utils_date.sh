#!/bin/bash
set -e
# set +x
set -o pipefail

# https://www.cnblogs.com/yetugeng/articles/9733403.html 时间字符串和时间互转

# 返回当前时间戳, 单位秒
function currentTimestamp() {
    echo `date +%s`
    # echo "默认按照当前时间向后5min取值"
    # if [[ "${os_platform}" = "Darwin" ]]; then
    #     echo `date -v+5M +%s`000
    # elif [[ "${os_platform}" = "Linux" ]]; then
    #     echo `date -d +5min +%s`000
    # fi
}

# 时间戳转时间字符串
function timestamp2TimeString() {
    local os_platform=`uname -s`
    local dateStr=""
    if [[ "${os_platform}" = "Darwin" ]]; then
        dateStr=`date -r${timestampStr} +"%Y-%m-%d %H:%M:%S"`
    elif [[ "${os_platform}" = "Linux" ]];then
        dateStr=`date -d @${timestampStr} +"%Y-%m-%d %H:%M:%S"`
    fi
    echo "$dateStr"
}


# 时间字符串转时间戳
function timeString2Timestamp() {
    local dateStr=$1
    local format=$2
    if [[ -z "$format" ]]; then
        format="%Y-%m-%d %H:%M:%S"
    fi

    local os_platform=`uname -s`
    if [[ "${os_platform}" = "Darwin" ]]; then
        echo `date -j -f "${format}" "${dateStr}" +%s`
    elif [[ "${os_platform}" = "Linux" ]]; then
        echo `date -d "${dateStr}" +%s`
    fi
}

function timestamp2TimeDesc() {
    local timestamp=$1
    local days=0
    local hours=0
    local minutes=0
    local seconds=0
    if [[ $timestamp -ge 86400 ]]; then
        days=$(($timestamp/86400))
        timestamp=$(($timestamp-$days*86400))
    fi
    if [[ $timestamp -ge 3600 ]]; then
        hours=$(($timestamp/3600))
        timestamp=$(($timestamp-$hours*3600))
    fi
    if [[ $timestamp -ge 60 ]]; then
        minutes=$(($timestamp/60))
        timestamp=$(($timestamp-$minutes*60))
    fi
    seconds=$timestamp
    local text=""
    if [[ $days -gt 0 ]]; then
        text="${text}${days}天"
    fi
    if [[ $hours -gt 0 ]]; then
        text="${text}${hours}小时"
    fi
    if [[ $minutes -gt 0 ]]; then
        text="${text}${minutes}分"
    fi
    if [[ -n "$text" && $seconds -gt 0 ]]; then
        text="${text}${seconds}秒"
    fi
    echo "${text}"
}

