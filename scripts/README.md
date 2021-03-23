### ciconfig.sh示例
```
#子级的git库对应区分module和vendor两个文件夹
TopFoldName=()
#对应文件夹名称数组，与git库的名称必须保持一致
FoldName=()
#git库url数组名
GitPath=()
#git库对应的tag，如果是master则置空不填
RefName=()

LastIndex=${#FoldName[*]}+1;
TopFoldName[LastIndex]="vendor"
FoldName[LastIndex]="iflyMSC"
GitPath[LastIndex]="git@192.168.2.246:mobile-thirdparty/iflyMSC.git"
RefName[LastIndex]="tag_1173"
```

### 使用方法

在 pipeline 脚本中，请使用如下方式执行脚本
```
dir('./scripts') {
  sh "./xxx.sh"
}
```

### 注意：当需要自定义xcode 工程build 目录时，需要修改的说明如下
```
# pipeline 脚本中
stage('打包IPA包') {
  steps {
    dir('./scripts') {
      sh "./make_package.sh"
    }
    // ./ios/build就是你设置的编译目录
    dir('./ios/build') {
      archiveArtifacts '*.ipa'
    }
  }
}
```
其中的archiveArtifacts脚本运行的目录是手动指定的，不是使用`get_project_info.sh` 中定义的目录
是因为dir命令不支持变量名引用，所以只能写死
如果需要自定义 build 目录，请在`get_project_info.sh`脚本中修改`BuildPath`的值，
然后再同步修改上面代码中的目录
