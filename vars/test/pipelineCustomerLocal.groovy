pipeline {
    agent any
    parameters {
      string(name: 'MainBranch', defaultValue: "master", description: '主工程分支，包括子模块的分支')
      string(name: 'ModuleBranch', defaultValue: "master", description: '业务库库分支')
      string(name: 'BuildVersion', defaultValue: "9.9.9", description: '版本号，可以为空，空的话取工程中的设置')
      choice(name: 'FlutterMode', choices: ['debug', 'release'], description: 'Flutter 打包模式，影响xcodebuild的-configuration参数和FLUTTER_BUILD_MODE参数')
      string(name: 'AppPackageType', defaultValue: "development", description: 'IPA包类型，会影响证书和描述文件的设置。\ndevelopment：开发包；adhoc：内测包；enterprise：企业包；appstore：应用商店上架包')
      choice(name: 'AppHostEnv', choices: "debug", description: 'App内接口环境以及第三方key环境，如高德地图，极光推送。\ndebug: 测试环境, uat1: uat1环境, uat2: uat2环境, release: 生产环境')
    }
    environment {
      AppPackageId = "com.znlhzl.znlhzl.credit"
      DevelopTeam = "FQDS669M2L"
      CodeSignIdentityDev = "iPhone Developer: Qianjun Wang"
      CodeSignIdentityDis = "iPhone Distribution: Zhongneng United Digital Technology Co., Ltd."
      ProvisioningProfileDev = "zn_credit_dev"
      ProvisioningProfileAdhoc = "zn_credit_adhoc"
      ProvisioningProfileRelease = "zn_credit_dis"
      BuildString = "2020-11-11_12:00:00"
      BuildNumber = "20201111120000"
      AppIdentifier = "customer"
    }
    stages {
      stage('主工程代码下载') {
        steps {
          echo "主工程代码下载 ${MainBranch}"
          git(url: "git@192.168.2.246:mobile-dev/zn_united_rentals.git", branch: "master", changelog: true, credentialsId: "git.znlh.com")
          sh label: '拷贝脚本文件', script:
          '''
            # 文件不能放在子模块目录下，因为子模块会在更新代码阶段删除重新下载
            # 1. 拷贝脚本文件
            sourceDir=${WORKSPACE}/../${JOB_NAME}@libs/pipeline-shared-library-ios/scripts
            if [[ -d "$sourceDir" ]]; then
              targetDir=${WORKSPACE}/scripts
              mkdir -p ${targetDir}
              cp -r ${sourceDir}/* ${targetDir}/
            fi

            # 2. 拷贝资源文件
            sourceDir=${WORKSPACE}/../${JOB_NAME}@libs/pipeline-shared-library-ios/resources/export_plist_files/${AppIdentifier}
            if [[ -d "$sourceDir" ]]; then
              targetDir=${WORKSPACE}/export_plist_files
              mkdir -p ${targetDir}
              cp -r ${sourceDir}/* ${targetDir}/
            fi
          '''
        }
      }
      stage('下载子模块和第三方插件代码') {
        steps {
          dir('./scripts') {
            sh "./check_third_library.sh"
            sh label: '下载第三方库', script:
            '''
              ./update_code.sh \
                --has-submodule=1 \
                --modules="ModuleBranchName" \
                --branches="${ModuleBranch}"
            '''
          }
        }
      }
      stage('环境检测') {
        steps {
          dir('./scripts') {
            sh "./check_env_code.sh --check-shell-file=customer_check_settings"
          }
        }
      }
      stage('编译') {
        steps {
          dir('./scripts') {
            sh "./compile.sh"
          }
        }
      }
      stage('打包IPA包') {
        steps {
          dir('./scripts') {
            sh "./make_package.sh"
          }
          dir('./ios/build') {
            archiveArtifacts '*.ipa'
          }
        }
      }
      stage('上传蒲公英') {
        steps {
          dir('./scripts') {
            sh "./upload_pgy.sh"
          }
        }
      }
    }
  }