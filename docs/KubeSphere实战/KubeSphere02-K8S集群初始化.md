#  K8S集群初始化

## 集群方案

![](../../img/kubeadm-ha-topology-stacked-etcd.svg)

集群节点资源配置：

操作系统：CentOS7.8

| Hostname | CPU核心 | 内存 | 硬盘(动态分配) | IP            |
| -------- | ------- | ---- | -------------- | ------------- |
| k8s-m1   | 2       | 2G   | 20G            | 192.168.2.191 |
| k8s-m2   | 2       | 2G   | 20G            | 192.168.2.192 |
| k8s-m3   | 2       | 2G   | 20G            | 192.168.2.193 |
| k8s-n1   | 2       | 2G   | 20G            | 192.168.2.194 |
| k8s-n2   | 2       | 2G   | 20G            | 192.168.2.195 |
| k8s-n3   | 2       | 2G   | 20G            | 192.168.2.196 |

## KubeSphere的两种安装方式

### 在Linux上安装

尽量先将所有Docker镜像下载下来再安装，否则安装速度很慢。

[Multi-Node模式](https://kubesphere.com.cn/docs/zh-CN/installation/multi-node/)

### 在已有的K8S集群上安装

#### 安装Helm2

只需要将压缩包下载下来后解压，将二进制文件放到`/usr/local/bin`。

```shell
# 创建helm-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
   
# 初始化tiller,注意这里的镜像一定要指定好
helm init --service-account=tiller --tiller-image=sapcc/tiller:v2.16.7   --history-max 300
```

#### 完整安装KubeSphere

```shell
kubectl apply -f https://raw.githubusercontent.com/kubesphere/ks-installer/master/kubesphere-complete-setup.yaml
```

## 安装完成后访问dashboard

```shell
#查看安装日志
kubectl logs -n kubesphere-system $(kubectl get pod -n kubesphere-system -l app=ks-install -o jsonpath='{.items[0].metadata.name}') -f

```



