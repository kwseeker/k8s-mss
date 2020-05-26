# Jenkins&K8S持续集成

## 虚拟机创建与必备软件安装

### 创建两个Ubuntu虚拟机

分别用作K8S Master和Node节点

### 系统设置

+ **设置root用户密码**

  ```shell
  sudo passwd root
  ```

+ **关闭防火墙**

  ```shell
  ufw disable
  ```

+ **翻墙**

  参考：https://shadowsocks.org/en/download/clients.html

  ```shell
  chmod a+x Shadowsocks-Qt5-x86_64.AppImage
  ./Shadowsocks-Qt5-x86_64.AppImage
  # 然后在Shadowsocks中配置个人VPN服务器地址密码
  ```

### 软件安装

+ **ssh**

  安装ssh-server(系统默认只有ssh客户端没有服务端), 配置/etc/ssh/sshd_config允许以Root用户ssh登录, 重启sshd服务。

  ```shell
  sudo apt-get install ssh
  sudo vim /etc/ssh/sshd_config
  systemctl restart sshd
  ```

+ **Docker**
  
  + 安装
  
    ```shell
    # 快速安装
    apt-get update
    apt-get install -y docker.io
    ```
  
  + 配置加速器
  
    登录阿里云服务，选择“产品与服务”->"容器镜像服务"->“镜像加速器”。
  
    ```shell
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<-'EOF'
    {
      "registry-mirrors": ["https://<替换为自己的加速器地址>.mirror.aliyuncs.com"]
    }
    EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    ```



## Jenkins 自动编译打包代码成Docker镜像



## K8S编排系统启动

### K8S安装配置

+ 参考: 

  [官方:使用 kubeadm 引导集群](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

  [devops（1）- k8s安装记录](https://www.jianshu.com/p/9944b460f90f)

+ **前提安装好docker**

+ **安装kubeadm、kubelet、kubectl**

  [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/)是用于快速搭建K8S集群的工具。

+ 

### 初始化Master



### Kubectl解析yml启动容器

+ kubectl 启动并编排容器

  ```shell
  kubectl create -f app.yaml		# yaml定义所有服务的镜像部署配置
  ```

+ yaml配置文件详解
  + 类型kind
  
    Deployment类型表示pod部署信息(如：容器镜像、容器端口)；
  
    Service类型表示pod提供的服务信息(如：内部服务的端口)；

+ 疑问：

  １）容器升级是怎么实现的？

  ２）Jenkins持续集成＋K8S自动部署，工作流程？