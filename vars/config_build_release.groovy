
def call(Map platformMap) {
    def map = [:]
    // IPA包类型，会影响证书和描述文件的设置
    // development: 开发包 - 对应开发环境
    // adhoc: 内测包 - 对应UAT环境
    // enterprise: 企业包 目前不支持 2020-05-15
    // appstore: AppStore上架包
    println("release platformMap = " + platformMap)
    if (platformMap) {
        def type = "release"
        def isLegu = false
        if (platformMap["Platform"].equalsIgnoreCase("ios")) {
            type = "appstore"
            isLegu = true
        }
        map.put("AppPackageType", type)
        map.put('isLegu', isLegu)
    }

    // Flutter Mode
    map.put('FlutterMode', 'release')

    // 分享出去的小程序类型 覆盖 baseconfig 中的配置
    map.put('MiniProgrameType', 'release')

    // Host切换开关
    map.put('ApiHostSwitchOptions', '关')
    // 是否开启自动化测试，默认关闭
    map.put('EnableAutoTest', '关')

    return map
}