# @rmw/srv

##  安装

```
yarn add @rmw/srv
```

或者

```
npm install @rmw/srv
```

## 使用

```coffee
#include ./test/index.coffee
```


给本地http用的接口
api上传文件
api上传文件夹

给nkn网络用的接口

下载文件

请求 文件路径 偏离[没有设置默认为0]
响应 文件路径 偏离 [文件大小(偏移为0的时候)] 文件内容[最多1MB]

订阅告知 请求一下 /.rmw/follow
更新告知 请求一下 /.rmw/update 频道hash


接受文件的流程

1. offset 为 0 并且 END，写入文件
2. offset 为 0 不是 END，生成请求任务队列，创建稀疏文件
3. offset 不为 0 ，写入文件，检查任务队列，看看是否完结


* [url,offset] 下次请求时间
* url 地址 list // 结尾插入4字节的数字，遇到暂停

数据库规划

任务id
任务地址
任务url


表1 redis
  任务 有待下载的offset list

表2 sqlite
  任务id 服务器地址 offset 超时时间 重试次数
  每次失败后，选择另外一个offset，如果连续失败3次，换下一个源

表3
  任务id 未使用的源 0 已经使用的源


新建任务 
  
  随机选一个地址发一个请求

  请求响应

    如果是结束，结束
    
    如果不是结束，按MB切分offset，用hset和zipint记录offset # https://github.com/rmw-lib/zipint#readme 


统计请求发送频率可以得知速度(会记住历史的请求速度用来启动)

如果任务队列中有任务，从任务队列中取任务，否则从任务池中取任务

任务队列

每分钟发出的请求数 = 上一分钟响应的请求数+16

给每个地址分配一个任务队列，如果响应了，就从自己队列中取，如果没有了，就窃取新队列的切片
每个队列每3秒发n=1个新请求（调整n可以限速），每当一个请求响应了，追加一个请求，如果连续60秒没有响应，那么

## 关于

本项目隶属于**人民网络([rmw.link](//rmw.link))** 代码计划。

![人民网络](https://raw.githubusercontent.com/rmw-link/logo/master/rmw.red.bg.svg)
