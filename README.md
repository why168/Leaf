# Leaf

> 🍃 基于 [美团 Leaf](https://github.com/Meituan-Dianping/Leaf) 的分布式ID生成服务

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![JDK](https://img.shields.io/badge/JDK-17+-green.svg)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.9-brightgreen.svg)](https://spring.io/projects/spring-boot)

## 📖 简介

本项目 Fork 自 [Meituan-Dianping/Leaf](https://github.com/Meituan-Dianping/Leaf)，在原有基础上进行了现代化升级和优化。

Leaf 是美团开源的分布式ID生成服务，提供 **号段模式** 和 **Snowflake模式** 两种方案，覆盖了美团点评公司内部金融、餐饮、外卖、酒店旅游、猫眼电影等众多业务线。在 4C8G VM 基础上，通过 RPC 方式调用，QPS 压测结果近 5w/s，TP999 1ms。

📄 设计文档：[Leaf——美团点评分布式ID生成系统](https://tech.meituan.com/MT_Leaf.html)

## ✨ 本 Fork 版本的改进

| 改进项 | 原版本 | 本版本 |
| --- | --- | --- |
| JDK | 8 | **17** |
| Spring Boot | 2.x | **3.5.9** |
| 嵌入式容器 | Tomcat | **Undertow** |
| 命名空间 | javax.* | **jakarta.*** |
| MyBatis | 3.4.x | **3.5.16** |
| Curator | 2.x | **5.6.0** |
| JUnit | 4 | **5.10.2** |

## 🛠️ 技术栈

| 组件 | 版本 |
| --- | --- |
| JDK | 17+ |
| Spring Boot | 3.5.9 |
| Undertow | 2.3.20 |
| MyBatis | 3.5.16 |
| Druid | 1.2.21 |
| Curator (ZooKeeper) | 5.6.0 |
| MySQL Connector | 8.0.33 |
| JUnit | 5.10.2 |

## 📋 环境要求

- **JDK 17** 或更高版本
- **Maven 3.6+**
- **MySQL 5.7+** （号段模式）
- **ZooKeeper 3.4+** （Snowflake模式）

## 🚀 快速开始

### 配置说明

Leaf 提供两种 ID 生成方式，可同时开启或单独使用（默认均为关闭状态）。

配置文件位于：`leaf-server/src/main/resources/leaf.properties`

| 配置项 | 说明 | 默认值 |
| --- | --- | --- |
| `leaf.name` | 服务名称 | - |
| `leaf.segment.enable` | 是否开启号段模式 | false |
| `leaf.jdbc.url` | MySQL 数据库地址 | - |
| `leaf.jdbc.username` | MySQL 用户名 | - |
| `leaf.jdbc.password` | MySQL 密码 | - |
| `leaf.snowflake.enable` | 是否开启 Snowflake 模式 | false |
| `leaf.snowflake.zk.address` | ZooKeeper 地址 | - |
| `leaf.snowflake.port` | 服务注册端口 | - |

### 号段模式

#### 1. 创建数据库

```sql
CREATE DATABASE leaf;

CREATE TABLE `leaf_alloc` (
  `biz_tag` varchar(128) NOT NULL DEFAULT '',
  `max_id` bigint(20) NOT NULL DEFAULT '1',
  `step` int(11) NOT NULL,
  `description` varchar(256) DEFAULT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`biz_tag`)
) ENGINE=InnoDB;

-- 插入测试数据
INSERT INTO leaf_alloc(biz_tag, max_id, step, description) 
VALUES('leaf-segment-test', 1, 2000, 'Test leaf Segment Mode Get Id');
```

#### 2. 配置数据库连接

编辑 `leaf.properties`：

```properties
leaf.segment.enable=true
leaf.jdbc.url=jdbc:mysql://localhost:3306/leaf?useUnicode=true&characterEncoding=utf8
leaf.jdbc.username=root
leaf.jdbc.password=your_password
```

### Snowflake 模式

基于 Twitter 开源的 Snowflake 算法实现。

编辑 `leaf.properties`：

```properties
leaf.snowflake.enable=true
leaf.snowflake.zk.address=localhost:2181
leaf.snowflake.port=8080
```

### 构建与运行

```bash
# 克隆项目
git clone https://github.com/why168/Leaf.git
cd Leaf

# 打包（跳过测试）
mvn clean package -DskipTests

# 进入服务模块
cd leaf-server
```

**运行方式（三选一）：**

```bash
# 方式一：Maven
mvn spring-boot:run

# 方式二：脚本
sh deploy/run.sh

# 方式三：JAR
java -jar target/leaf.jar
```

### 接口测试

```bash
# 号段模式
curl http://localhost:8080/api/segment/get/leaf-segment-test

# Snowflake 模式
curl http://localhost:8080/api/snowflake/get/test
```

### 监控页面

- 号段模式监控：http://localhost:8080/cache

## 📁 项目结构

```
Leaf/
├── leaf-core/                      # 核心模块
│   └── src/main/java/
│       └── com.sankuai.inf.leaf/
│           ├── IDGen.java          # ID生成器接口
│           ├── common/             # 公共类
│           ├── segment/            # 号段模式实现
│           └── snowflake/          # Snowflake模式实现
│
├── leaf-server/                    # HTTP服务模块
│   └── src/main/java/
│       └── com.sankuai.inf.leaf.server/
│           ├── LeafServerApplication.java
│           ├── controller/         # REST控制器
│           └── service/            # 服务层
│
├── scripts/
│   └── leaf_alloc.sql              # 数据库初始化脚本
│
└── pom.xml                         # Maven父工程配置
```

## ⚙️ 性能调优

### Undertow 配置

在 `application.properties` 中调整 Undertow 参数：

```properties
# IO 线程数（建议设置为 CPU 核心数）
server.undertow.threads.io=4

# Worker 线程数（建议设置为 IO 线程数的 8 倍）
server.undertow.threads.worker=32

# 缓冲区大小
server.undertow.buffer-size=1024

# 是否使用直接内存
server.undertow.direct-buffers=true
```

## ⚠️ 注意事项

1. **WorkerId 分配**：Snowflake 模式获取 IP 的逻辑直接取首个网卡 IP，对于会更换 IP 的服务要特别注意，避免浪费 workerId。

2. **JDK 版本**：本项目需要 JDK 17 或更高版本：
   ```bash
   java -version
   # 输出应包含: openjdk version "17.x.x" 或更高
   ```

3. **Jakarta EE**：Spring Boot 3.x 使用 Jakarta EE 命名空间（`jakarta.*` 替代 `javax.*`）。

## 🔗 相关链接

- 原项目：[Meituan-Dianping/Leaf](https://github.com/Meituan-Dianping/Leaf)
- 设计文档：[Leaf——美团点评分布式ID生成系统](https://tech.meituan.com/MT_Leaf.html)

## 📄 License

本项目基于 [Apache 2.0](LICENSE) 许可证开源。

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

---

<p align="center">
  ⭐ 如果这个项目对你有帮助，欢迎 Star！
</p>
