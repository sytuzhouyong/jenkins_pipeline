
def call(Map platformMap) {
    def map = [:]
    // IPA包类型，会影响证书和描述文件的设置
    // development: 开发包 - 对应开发环境
    // adhoc: 内测包 - 对应UAT环境
    // enterprise: 企业包 目前不支持 2020-05-15
    // appstore: AppStore上架包
    println("uat platformMap = " + platformMap)
    if (platformMap) {
        def type = "release"
        if (platformMap["Platform"].equalsIgnoreCase("ios")) {
            type = "adhoc"
        }
        map.put("AppPackageType", type)
    }

    // Flutter Mode
    map.put("FlutterMode", "release")
    println("uat map = " + map)
    return map
}
