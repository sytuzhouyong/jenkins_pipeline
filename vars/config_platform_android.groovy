
def call() {
    def map = [:]

    // 平台标识
    map.put('Platform', 'android')
    map.put('PlatformPretty', 'Android')
    map.put('PlatformLowerCase', 'android')
    map.put('PlatformUpperCase', 'ANDROID')

    map.put('AppPackageType', '''\
release
debug
''')

    // ⚠️ 路径不能使用~等缩写，否则通过全路径执行 flutter 命令时，会报找不到 fluter 文件的错误
    def flutterVersions = '''\
/opt/flutter1.17.3
/opt/sdk/flutter1.17.3
/Users/lk/flutter1173
'''
    map.put('FlutterSDKHome', flutterVersions)
    
    map.put('isLegu', false)

    return map
}