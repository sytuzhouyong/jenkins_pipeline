#!/bin/bash

if [[ -z "${FlutterSDKHome}" ]]; then
    echo "没有选择 flutter 版本，使用系统配置的"
    flutterPath=$(which flutter)
    echo "flutter path = $flutterPath"
    export FlutterSDKHome=${flutterPath%%/bin*}
    echo "FlutterSDKHome = $FlutterSDKHome"
else
    export FLUTTER_HOME=${FlutterSDKHome}
    export DART_HOME=${FlutterSDKHome}/bin/cache/dart-sdk
    export PUB_CACHE=${FlutterSDKHome}/.pub_cache
    export PUB_HOSTED_URL=https://pub.flutter-io.cn
    export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
    export PATH=${FlutterSDKHome}/bin:${DART_HOME}/bin:${PUB_CACHE}/bin:$PATH
    echo "PATH = $PATH"
    xflutter=${FlutterSDKHome}/bin/flutter
    export xflutter
fi

echo "🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶开始执行 flutter --version "
flutter --version
echo "🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶结束执行 flutter --version "
