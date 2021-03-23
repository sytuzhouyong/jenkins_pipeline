def call() {
    def map = [:]

    // 平台标识
    map.put('Platform', 'ios')
    map.put('PlatformPretty', 'iOS')
    map.put('PlatformLowerCase', 'ios')
    map.put('PlatformUpperCase', 'IOS')

    // 开发者配置
    map.put('DevelopTeam', 'FQDS669M2L')
    map.put('CodeSignIdentityDev', 'iPhone Developer: Qianjun Wang')
    map.put('CodeSignIdentityDis', 'iPhone Distribution: Zhongneng United Digital Technology Co., Ltd.')

    // IPA包类型，会影响证书和描述文件的设置
    // development: 开发包 - 对应开发环境
    // adhoc: 内测包 - 对应UAT环境
    // enterprise: 企业包 目前不支持 2020-05-15
    // appstore: AppStore上架包
    map.put('AppPackageType', '''\
appstore
adhoc
development
''')

    // ⚠️ 路径不能使用~等缩写，否则通过全路径执行 flutter 命令时，会报找不到 fluter 文件的错误
    def flutterVersions = '''\
/Users/lk/flutter1173
/Users/lk/flutter1146
/Users/zhouyong1/.fvm/versions/1173
'''
    map.put('FlutterSDKHome', flutterVersions)

    return map
}