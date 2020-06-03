# k8s-mss

是否可以通过docker镜像版本，自动部署docker容器？

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

