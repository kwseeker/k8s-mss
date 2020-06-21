# k8s-mss

![](img/项目从开发到部署执行的工具.png)

基于K8S微服务CI/CD实现流程：

> 第一阶段：
> １）测试微服务项目开发与代码上传（git）
> ２）代码编译打包（maven + Jenkins）
> ３）docker镜像构建（docker build）
> ４）docker镜像推送到私有仓库（harbor/docker-registry）
> ５）docker run 测试镜像
> 第二阶段：
> ６）搭建k8s高可用集群（这里三主三从）
> ７）编写yaml配置文件
> ８）配置Jenkins post script, 在第一个阶段镜像生成后，驱动k8s通过yaml配置从私有仓库取镜像自动化部署
> ９）应用健康检查
> 第三阶段：（拓展）
> １０）容器管理平台构建
> １１）系统监控集成（ELK+Promethus+Grafana）
> １２）服务网格
> １３）golang微服务k8s自动化部署



疑问：

是否可以通过docker镜像版本，自动部署docker容器？



## 第一阶段

项目暂时指定一个多模块项目，只有一个模块`jenkins-deploy-example`，通过github管理, 实现每次代码更新都会通过jenkins自动编译打包、进行docker镜像的构建，并推送到私有docker仓库harbor。然后`docker run`镜像发情求，能返回正确结果。

### 微服务项目准备与代码管理

`jenkins-deploy-example`推送到当前github仓库地址。

### Maven&Jenkins编译、打包、构建镜像

#### 说明

+ Jenkins版本：blue ocean（用户体验更好）
+ docker镜像仓库：Harbor

#### 详细流程

##### 虚拟机搭建（k8scode）

这个虚拟机就专门用于项目编译打包，以及作为docker镜像仓库。

搭建流程参考：《虚拟机环境搭建.md》k8scode。















## K8S高可用集群搭建

### 软件版本

K8S：1.14.0
Docker：17.03.x
Java：1.8
Harbor：1.6.0
Prometheus：2.8.1
Istio: 1.1.2

> K8S不要选择最新版本，否则可能发现某些组件找不到。

### 部署方式

+ 二进制部署
+ kubeadm部署

### 集群组成

3个Master、2个Node。

### 插件安装

+ calico
+ coredns
+ dashboard

## 服务迁移

### 前期设置

#### Harbor仓库设置

#### 服务发现设置

#### IngressNginx设置

### 服务迁移流程

#### 服务Docker化

#### Docker化的服务在K8S中执行

#### 服务发现

#### CI/CD实现

1）代码通过git管理

2）git pull

3）maven构建

4）docker build 构建镜像

5）服务发布

6）健康检查

## 深入K8S

### 服务调度与编排

#### 健康检查

#### 调度策略

#### 部署策略

#### 深入Pod

### 落地与实现

#### Ingress-Nginx

#### PV/PVC/StorageClass

#### StatefulSet

#### Kubernetes API

### 日志与监控

#### 日志主流方案

#### 从日志采集到日志展示

#### Prometheus

## Istio

