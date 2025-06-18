---
trigger: always_on
description: 在模型生成完所有的代码或做完所有的代码更新完后自动激活本规则
---

- 所有的代码生成完以后或更新完以后，用xcode的命令行xcodebuild进行build
    - 采用重定向将build的结果保存到 logs/build.log 文件中
    - build时采用iphone16仿真器
- 日志文件写入完成后，立即分析日志文件的内容判断是否存在问题
    - 如果存在编译错误 error ，则逐个解决
    - 如果出现警告 warning ， 也尝试解决
- 不是项目的必要成分，不要生成脚本程序，给出解决方案，并调用终端工具，一步步执行