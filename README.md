# Leaf

## Introduction

Leaf 最早期需求是各个业务线的订单ID生成需求。在美团早期，有的业务直接通过DB自增的方式生成ID，有的业务通过redis缓存来生成ID，也有的业务直接用UUID这种方式来生成ID。以上的方式各自有各自的问题，因此我们决定实现一套分布式ID生成服务来满足需求。具体Leaf 设计文档见：[leaf 美团分布式ID生成服务](https://tech.meituan.com/MT_Leaf.html)

目前Leaf覆盖了美团点评公司内部金融、餐饮、外卖、酒店旅游、猫眼电影等众多业务线。在4C8G VM基础上，通过公司RPC方式调用，QPS压测结果近5w/s，TP999 1ms。

## 技术栈

| 组件 | 版本 |
| --- | --- |
| JDK | 17 |
| Spring Boot | 3.5.9 |
| 嵌入式容器 | Undertow |
| MyBatis | 3.5.16 |
| Druid | 1.2.21 |
| Curator (ZooKeeper) | 5.6.0 |
| MySQL Connector | 8.0.33 |
| JUnit | 5.10.2 |

## 环境要求

- **JDK 17** 或更高版本
- **Maven 3.6+**
- **MySQL 5.7+** （号段模式）
- **ZooKeeper 3.4+** （Snowflake模式）

## Quick Start

### Leaf Server

我们提供了一个基于 Spring Boot 的 HTTP 服务来获取ID。

#### 配置介绍

Leaf 提供两种生成ID的方式（号段模式和snowflake模式），你可以同时开启两种方式，也可以指定开启某种方式（默认两种方式为关闭状态）。

Leaf Server的配置都在 `leaf-server/src/main/resources/leaf.properties` 中

| 配置项                    | 含义                          | 默认值 |
| ------------------------- | ----------------------------- | ------ |
| leaf.name                 | leaf 服务名                   |        |
| leaf.segment.enable       | 是否开启号段模式              | false  |
| leaf.jdbc.url             | mysql 库地址                  |        |
| leaf.jdbc.username        | mysql 用户名                  |        |
| leaf.jdbc.password        | mysql 密码                    |        |
| leaf.snowflake.enable     | 是否开启snowflake模式         | false  |
| leaf.snowflake.zk.address | snowflake模式下的zk地址       |        |
| leaf.snowflake.port       | snowflake模式下的服务注册端口 |        |

#### 号段模式

如果使用号段模式，需要建立DB表，并配置 `leaf.jdbc.url`, `leaf.jdbc.username`, `leaf.jdbc.password`

如果不想使用该模式配置 `leaf.segment.enable=false` 即可。

##### 创建数据表

```sql
CREATE DATABASE leaf;

CREATE TABLE `leaf_alloc` (
  `biz_tag` varchar(128)  NOT NULL DEFAULT '',
  `max_id` bigint(20) NOT NULL DEFAULT '1',
  `step` int(11) NOT NULL,
  `description` varchar(256)  DEFAULT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`biz_tag`)
) ENGINE=InnoDB;

INSERT INTO leaf_alloc(biz_tag, max_id, step, description) VALUES('leaf-segment-test', 1, 2000, 'Test leaf Segment Mode Get Id');
```

##### 配置相关数据项

在 `leaf.properties` 中配置 `leaf.jdbc.url`, `leaf.jdbc.username`, `leaf.jdbc.password` 参数

#### Snowflake模式

算法取自twitter开源的snowflake算法。

如果不想使用该模式配置 `leaf.snowflake.enable=false` 即可。

##### 配置zookeeper地址

在 `leaf.properties` 中配置 `leaf.snowflake.zk.address`，配置 leaf 服务监听的端口 `leaf.snowflake.port`。

#### 运行Leaf Server

##### 打包服务

```shell
git clone git@github.com:Meituan-Dianping/Leaf.git
cd Leaf

# 按照上面的号段模式在工程里面配置好
mvn clean package -DskipTests

cd leaf-server
```

##### 运行服务

*注意: 首先得先配置好数据库表或者zk地址*

###### mvn方式

```shell
mvn spring-boot:run
```

###### 脚本方式

```shell
sh deploy/run.sh
```

###### JAR方式

```shell
java -jar target/leaf.jar
```

##### 测试

```shell
# segment
curl http://localhost:8080/api/segment/get/leaf-segment-test

# snowflake
curl http://localhost:8080/api/snowflake/get/test
```

##### 监控页面

号段模式：http://localhost:8080/cache

### Leaf Core

当然，为了追求更高的性能，需要通过RPC Server来部署Leaf服务，那仅需要引入 `leaf-core` 的包，把生成ID的API封装到指定的RPC框架中即可。

#### Maven 依赖

```xml
<dependency>
    <groupId>com.sankuai.inf.leaf</groupId>
    <artifactId>leaf-core</artifactId>
    <version>1.0.1</version>
</dependency>
```

## 项目结构

```
Leaf
├── leaf-core                    # 核心模块
│   └── src/main/java
│       └── com.sankuai.inf.leaf
│           ├── IDGen.java       # ID生成器接口
│           ├── common/          # 公共类
│           ├── segment/         # 号段模式实现
│           └── snowflake/       # Snowflake模式实现
├── leaf-server                  # HTTP服务模块
│   └── src/main/java
│       └── com.sankuai.inf.leaf.server
│           ├── LeafServerApplication.java
│           ├── controller/      # REST控制器
│           └── service/         # 服务层
├── scripts/
│   └── leaf_alloc.sql          # 数据库初始化脚本
└── pom.xml
```

## Undertow 配置

项目使用 Undertow 作为嵌入式服务器，可在 `application.properties` 中调整：

```properties
# Undertow 线程配置
server.undertow.threads.io=4
server.undertow.threads.worker=32
server.undertow.buffer-size=1024
server.undertow.direct-buffers=true
```

## 注意事项

1. 使用 snowflake 模式时，其获取IP的逻辑直接取首个网卡IP，特别对于会更换IP的服务要注意，避免浪费 workId。

2. 本项目需要 **JDK 17** 或更高版本，请确保环境配置正确：
   ```shell
   java -version
   # 输出应包含: openjdk version "17.x.x" 或更高
   ```

3. Spring Boot 3.x 使用 Jakarta EE 命名空间（`jakarta.*` 替代 `javax.*`）。

## License

Leaf is released under the [Apache 2.0 license](LICENSE).

```
Copyright 2018 Meituan-Dianping

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
