def call() {
    def map = [:]
    
    // 版本号
    map.put('BuildVersion', '9.9.9')

    // 构建时间
    def buildTime = new Date()
    def buildTimeString = buildTime.format("yyyy-MM-dd_HH:mm:ss")
    def buildTimeNumber = buildTime.format("yyyyMMddHHmmss")
    map.put('BuildString', buildTimeString)
    map.put('BuildNumber', buildTimeNumber)

    // 分享出去的小程序类型
    def miniProgrameType = '''\
preview
release
'''
    map.put('MiniProgrameType', miniProgrameType)
	
	def apiHostSwitchOptions = '''\
开
关
'''
	map.put('ApiHostSwitchOptions', apiHostSwitchOptions)

    // 是否开启自动化测试，默认关闭
    def enableAutoTestOptions = '''\
关
开
'''
    map.put('EnableAutoTest', enableAutoTestOptions)


    return map
}