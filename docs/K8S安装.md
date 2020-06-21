# K8S安装

目标：搭建一Master一Node的集群。

参考：https://gitee.com/salmon_163/kubernetes-ha-kubeadm/

## 虚拟机准备

虚拟机系统：CentOS-7.8

### 系统安装

注意虚拟机资源分配：至少2核，2G内存。

### 初始设置

+ **将普通用户加入sudoers**

  ```shell
  sudo -
  visudo			#最后一行插入 lee ALL=(ALL) ALL
  ```

+ **网络设置**

  ```shell
  vi /etc/sysconfig/network-scripts/ifcfg-cnp0s3	
  #修改
  #BOOTPROTO=static
  #ONBOOT=yes
  #新增
  #IPADDR=192.168.16.101 	#自定义虚拟机的ip地址（主机是192.168.0.107），必须与主机在同一网段
  #NETMASK=255.255.254.0 	#设置子网掩码，跟宿主一样
  #GATEWAY=192.168.16.1  	#默认网关，跟宿主一样
  #DNS1=8.8.8.8 					#DNS
  vi /etc/sysconfig/network
  #NETWORKING=yes
  #HOSTNAME=<...>
  service network restart
  ping www.baidu.com			#测试和外网是否连通
  ```

  > 注意网络环境变化后要改静态IP。

+ **相互注册hostname和ip**

  ```shell
  #k8smaster上的配置，k8snode类似
  [root@localhost ~]# cat /etc/hostname
  localhost.localdomain
  k8smaster
  [root@localhost ~]# cat /etc/hosts
  127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
  ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
  192.168.16.102 	k8snode
  ```


+ **ssh-sever**

  主要是为了可以在物理机终端操作。

  安装ssh-server(系统默认只有ssh客户端没有服务端), 配置/etc/ssh/sshd_config允许以Root用户ssh登录, 重启sshd服务。

  CentOS默认已经安装了，不需要再装。
  
  ```shell
	ps -ef | grep sshd	#可以看到sshd守护进程正在运行
  ```

+ **必要软件**

  ```shell
  yum update
  yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp
  ```

+ 关闭防火墙、swap、重置iptables

  ```shell l
  systemctl stop firewalld && systemctl disable firewalld
  swapoff -a
  iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT
  # 使用下面的命令对文件/etc/fstab操作，注释 /dev/mapper/centos_master-swap  swap  swap    defaults        0 0 这行
  sed -i 's/.*swap.*/#&/' /etc/fstab
  # 关闭selinux
  vi /etc/selinux/config 
  # 将SELINUX=enforcing改为SELINUX=disabled
  setenforce 0
  # 查看selinux状态
  sestatus
  # 关闭dnsmasq(否则可能导致docker容器无法解析域名)
  service dnsmasq stop && systemctl disable dnsmasq
  ```

+ 系统参数设置

  ```shell
  # 制作配置文件
  $ cat > /etc/sysctl.d/kubernetes.conf <<EOF
  net.bridge.bridge-nf-call-iptables=1
  net.bridge.bridge-nf-call-ip6tables=1
  net.ipv4.ip_forward=1
  vm.swappiness=0
  vm.overcommit_memory=1
  vm.panic_on_oom=0
  fs.inotify.max_user_watches=89100
  EOF
  # 生效文件
  $ sysctl -p /etc/sysctl.d/kubernetes.conf
  # 执行sysctl -p 时出现下面的错误
  sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-ip6tables: No such file or directory
  sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables: No such file or directory
  # 解决方法：运行命令 modprobe br_netfilter 然后再执行 sysctl -p /etc/sysctl.d/kubernetes.conf
  $ modprobe br_netfilter
  # 查看
  $ ls /proc/sys/net/bridge
  bridge-nf-call-arptables bridge-nf-filter-pppoe-tagged
  bridge-nf-call-ip6tables bridge-nf-filter-vlan-tagged
  bridge-nf-call-iptables bridge-nf-pass-vlan-input-dev
  ```

### 安装Docker

+ 安装包安装

+ 设置/etc/docker/daemon.json

  ```
  # daemon.json 详细配置示例
  {
    "debug": false,
    "experimental": false,
    "exec-opts": ["native.cgroupdriver=systemd"],
    "registry-mirrors": [
      "https://fy707np5.mirror.aliyuncs.com"
    ],
    "insecure-registries": [
      "hub.zy.com",
      "172.16.249.159:8082"
    ]
  }
  cat <<EOF > /etc/docker/daemon.json
  {
      "exec-opts": ["native.cgroupdriver=systemd"]
  }
  EOF
  # 启动docker服务
  systemctl restart docker
  ```

### 安装K8S工具

**kubeadm:** 部署集群用的命令

**kubelet:** 在集群中每台机器上都要运行的组件，负责管理pod、容器的生命周期

**kubectl:** 集群管理工具（可选，只要在控制集群的节点上安装即可）

#### 安装方法

+ 配置kubernetes的yum软件源

  ```shell
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
  [kubernetes]
  name=Kubernetes
  baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
  enabled=1
  gpgcheck=0
  repo_gpgcheck=0
  gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
         http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
  EOF
  ```

+ 安装并启动

  ```shell
  yum list kubeadm --showduplicates | sort -r
  yum install -y kubeadm-1.18.2-0 kubelet-1.18.2-0 kubectl-1.18.2-0 --disableexcludes=kubernetes
  sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  systemctl enable kubelet && systemctl start kubelet		#这时其实启动不起来
  ```

## K8S集群搭建

### 初始化Master节点

可以通过`kubeadm init`传递参数的形式执行初始化，也可以通过`--config xxx.yaml`指定yaml配置文件执行初始化。

[kubeadm init 内部流程及配置参数](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/)

[kubeadm init 配置文件](https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2)

```shell
kubeadm config print init-defaults		#查看默认配置
# 可以在这基础上进行修改
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.16.101				#用做监听的Master IP地址，改为其中一个Master的IP
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: k8smaster													#用做监听的Master的hostname
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
#imageRepository: k8s.gcr.io
imageRepository: registry.aliyuncs.com/google_containers	#改为国内镜像源
kind: ClusterConfiguration
kubernetesVersion: v1.18.2																#指定安装的kubeadm的版本号
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16    				#网络插件flannel的默认网络区段，如果选则使用calico则配置对应的网络区段
  serviceSubnet: 10.96.0.0/12					#
scheduler: {}
```

+ **方式1**

  ```shell
  kubeadm init \
    --apiserver-advertise-address=192.168.16.101 \
    --image-repository registry.aliyuncs.com/google_containers \
    --kubernetes-version v1.18.2 \
    --service-cidr=10.96.0.0/12 \
    --pod-network-cidr=10.244.0.0/16
  # --apiserver-advertise-address: 
  # --image-repository: 指定从那个仓库拉取镜像，默认值是k8s.gcr.io，国内建议改为registry.aliyuncs.com/google_containers
  # --kubernetes-version: 指定kubenets版本号，默认值是stable-1，不指定版本会导致从https://dl.k8s.io/release/stable-1.txt下载最新的版本
  # --service-cidr: 为服务的虚拟 IP 地址另外指定 IP 地址段
  # --pod-network-cidr: 指明 pod 网络可以使用的 IP 地址段。如果设置了这个参数，控制平面将会为每一个节点自动分配 CIDRs
  ```

+ **方式2**

  ```shell
  kubeadm init --config xxx.yaml
  ```

初始化完成之后：

```shell
#如果kubeadm init失败，可以kubeadm reset,然后可以重新初始化
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
#测试一下kubectl
kubectl get pods --all-namespaces

kubeadm join 192.168.16.101:6443 --token q7d89z.3qfzv04as5t23w2x \
    --discovery-token-ca-cert-hash sha256:bccb7cb9f7e856bc34c4288ecbbe6f885c8a987e29ca94a7203640d08ba1b8f5
```

### 安装插件

+ 网络插件

  Flannel:

  ```shell
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  #查看运行状态
  kubectl get pods --all-namespaces
  kubectl get nodes
  ```

### 加入其他Master节点

### 加入Node节点

+ 首次加入Node节点

  ```shell
  #Node节点执行
  kubeadm join 192.168.16.101:6443 --token q7d89z.3qfzv04as5t23w2x \
      --discovery-token-ca-cert-hash sha256:bccb7cb9f7e856bc34c4288ecbbe6f885c8a987e29ca94a7203640d08ba1b8f5
  #这个token可以通过下面命令查找
  kubeadm token list 
  #Master上执行，查看Worker节点是否成功添加
  kubectl get nodes
  #如果node是notready状态可以用下面命令查看日志
  kubectl get pods --all-namespaces -o wide
  kubectl describe pod xxxxxx -n kube-system
  #删除故障的pod
  kubectl delete pod xxxxxx -n kube-system
  ```

+ 移除Worker
+ 重新加入Worker

## 私有镜像仓库配置

需要搭建自己的私有镜像仓库，用于存储项目构建生成的镜像；

```shell
#私有镜像仓库可以放到任意服务器上，这里放到了node节点上。
docker pull registry
docker run --name=private-registry --restart=always -p 5000:5000 -v /root/registry_images:/var/lib/registry -d registry
#将私有镜像仓库添加到docker daemon.json 镜像仓库列表中。insecure-registries是不安全的镜像源列表，registry-mirrors是安全的（有证书等验证）镜像源列表；私有镜像仓库使用insecure-registries即可。
"insecure-registries":["k8snode:5000"]
systemctl daemon-reload
systemctl restart docker
#后续可以将项目打包成docker镜像上传到私有镜像仓库
docker tag <imagename> k8snode:5000/<imagename>:0.0.1
docker push k8snode:5000/<imagename>:0.0.1
```







