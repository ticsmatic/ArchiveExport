# ArchiveExport
### 支持多项目scheme，使用配置文件分离项目配置和脚本逻辑，支持命令行方式作为输入参数，满足多scheme的自定义

## Requirements:
* Xcode 8+

## Usage:
### Xcode 9以后先使用Xcode手动导出ipa包，然后将导出包文件夹内的ExportOptions.plist文件修改名称后替换掉ArchiveExport文件夹内你需要的plist文件
### 1) 将ArchiveExport整个文件夹拖入到项目主目录
### 2) 打开archiveExport.properties文件, 配置项目参数
### 3) 打开终端, cd到ArchiveExport文件夹
### 4) 输入 ./archiveExport.sh 命令
### 😊😊😊此脚本使用配置文件的方式读取打包参数进行打包, 如果一个项目有多个scheme，只使用一个配置文件难以满足多个scheme的打包需求，
### 所以此脚本扩展了命令行参数支持，如:-p -w -s -c -e -i -a", 每次使用脚本参数来再次自定义打包参数
### 如: ./archiveExport.sh -s yourProScheme -e ArchiveExport/BBExportOptionsAppStore.plist
 
### 通常情况下, 你需要修改archiveExport.properties文件而不是当前的脚本文件

### 示例图
![PNG](https://github.com/west-east/ArchiveExport/blob/master/archive1.png)

![GIF1](https://github.com/west-east/ArchiveExport/blob/master/archive1.gif)

![GIF1](https://github.com/west-east/ArchiveExport/blob/master/archive2.gif)


