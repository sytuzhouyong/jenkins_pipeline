#!groovy

def call(Map map) {
  pipeline {
    agent any
    options {
      timeout(time: 1, unit: 'HOURS')
    }
    parameters {
      choice(name: 'FlutterSDKHome', choices: "${map.FlutterSDKHome}",, description: 'Flutter版本选择')
      choice(name: 'MainBranch', choices: "feat/dynamic_fix", description: '主工程分支，包括子模块的分支')
      choice(name: 'BaseBranch', choices: "${map.BaseBranch}", description: 'base库分支')
      choice(name: 'CommonBranch', choices: "${map.CommonBranch}", description: 'common库分支')
      choice(name: 'SalBranch', choices: "${map.SalBranch}", description: '销售库分支')
      choice(name: 'SevBranch', choices: "${map.SevBranch}", description: '服务库分支')
      choice(name: 'LgtBranch', choices: "${map.LgtBranch}", description: '供应链库分支')
      choice(name: 'FinBranch', choices: "${map.FinBranch}", description: '财务线库分支')
      choice(name: 'MhsBranch', choices: "${map.MhsBranch}", description: '机手线库分支')
      string(name: 'BuildVersion', defaultValue: "${map.BuildVersion}", description: '版本号，可以为空，空的话取工程中的设置')
      choice(name: 'AppHostEnv', choices: "${map.AppHostEnv}", description: 'App内接口环境')
      choice(name: 'MiniProgrameType', choices: "${map.MiniProgrameType}", description: 'App分享到小程序的版本类型。\npreview: 体验版, release: 线上版本')
      choice(name: 'ApiHostSwitchOptions', choices: "${map.ApiHostSwitchOptions}", description: 'Host切换开关。\n开：可以切换, 关：不能切换')
      string(name: 'PatchVersion', defaultValue: '9.9.9', description: '更新包版本, 例如1.1.1')
      text(name: 'PatchFiles', defaultValue: 'lib/ui/quick/quick_create.dart', description: '需要更新的文件列表，以;分隔')
      text(name: 'PatchDesc', defaultValue: '修复已知问题', description: '更新说明')
    }
    environment {
      AppPackageId = "${map.AppPackageId}"
      DevelopTeam = "${map.DevelopTeam}"
      CodeSignIdentityDev = "${map.CodeSignIdentityDev}"
      CodeSignIdentityDis = "${map.CodeSignIdentityDis}"
      ProvisioningProfileDev = "${map.ProvisioningProfileDev}"
      ProvisioningProfileAdhoc = "${map.ProvisioningProfileAdhoc}"
      ProvisioningProfileRelease = "${map.ProvisioningProfileRelease}"
      FlutterMode = "${map.FlutterMode}"
      BuildString = "${map.BuildString}"
      BuildNumber = "${map.BuildNumber}"
      AppIdentifier = "${map.AppIdentifier}"
      AppPackageType = "${map.AppPackageType}"
      Platform = "${map.Platform}"
      PlatformPretty = "${map.PlatformPretty}"
    }
    stages {
      stage('主工程代码下载') {
        steps {
          echo "主工程代码下载 ${MainBranch}"
          git(url: "${map.GitURL}", branch: "${MainBranch}", changelog: true, credentialsId: "git.znlh.com")
          sh label: '拷贝脚本文件', script:
          '''
            # 文件不能放在子模块目录下，因为子模块会在更新代码阶段删除重新下载
            # 1. 拷贝脚本文件
            sourceDir=${WORKSPACE}/pipeline-scripts/scripts
            if [[ -d "$sourceDir" ]]; then
              targetDir=${WORKSPACE}/scripts
              mkdir -p ${targetDir}
              cp -r ${sourceDir}/* ${targetDir}/
            fi

            # 2. 拷贝资源文件
            sourceDir=${WORKSPACE}/pipeline-scripts/resources/export_plist_files/${AppIdentifier}
            if [[ -d "$sourceDir" ]]; then
              targetDir=${WORKSPACE}/export_plist_files
              mkdir -p ${targetDir}
              cp -r ${sourceDir}/* ${targetDir}/
            fi
          '''
        }
      }
      stage('子模块和插件代码下载') {
        steps {
          dir('./scripts') {
            sh "./check_third_library.sh"
            sh label: '下载第三方库', script:
            '''
              ./update_code.sh \
                --has-submodule=1 \
                --modules="BaseBranch ComBranch SalBranch SevBranch LgtBranch FinBranch MhsBranch" \
                --branches="${BaseBranch} ${CommonBranch} ${SalBranch} ${SevBranch} ${LgtBranch} ${FinBranch} ${MhsBranch}" \
                --dynamic
            '''
          }
        }
      }
      stage('环境检测') {
        steps {
          dir('./scripts') {
            sh "./check_env_code.sh"
          }
        }
      }
      stage('制作Patch包') {
        steps {
          dir('./scripts') {
            sh "./dynamic_page_patch.sh"
          }
        }
      }
    }
    // post {
    //   failure {
    //     triggerFailed()
    //   }
    // }
  }
}
