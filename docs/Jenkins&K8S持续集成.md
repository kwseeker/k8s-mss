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

[Jenkins Doc](https://www.jenkins.io/zh/doc/)

### 软件安装

+ **Jenkins启动**

  + war包启动

    1）首先安装jdk、tomcat；然后下载jenkins war包放置到tomcat的webapps目录下然后启动tomcat；

    2）输入/root/.jenkins/secrets/initialAdminPassword密码；

    3）安装额外插件：SSH、Publish Over SSH、GIT Parameter、Maven Integration；

    4）创建普通用户（默认有一个admin用户，密码是initialAdminPassword中的密码）；

  + docker镜像启动

    ```shell
    docker run -d --name jenkins-tutorial -u root -p 8080:8080 -v /home/lee/docker/jenkins/jenkins-data:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock -v /home/lee/docker/jenkins/home:/home jenkinsci/blueocean
    ```
    
  
+ git安装

+ maven安装

+ git仓库安装（可选）

  可以使用gitea、gogs等在私服上搭建私人git仓库。也可以选择使用github等。

+ docker仓库
  + docker-registry（功能太少）
  + Harbor（功能齐全）

###  Jenkins入门使用

官方文档：[用 Maven 构建 Java 应用](https://www.jenkins.io/zh/doc/tutorials/build-a-java-app-with-maven)

#### Jenkins配置

+ 全局工具配置
  + JDK
  + Git
  + Maven

#### 项目创建&配置

+ 构建的版本管理

+ Git仓库分支配置

+ Maven构建命令

+ 后续执行脚本

  Jenkins脚本1: 项目编译打包，构建docker镜像，推送到docker仓库，删除旧的docker镜像

  ```shell
  #!/bin/sh
  jarName=jenkins-deploy-example-0.0.1-SNAPSHOT.jar
  #jarFolder=ph
  projectName=jenkins-deploy-example	#docker镜像名
  echo ${WORKSPACE}
  dockerPath=${WORKSPACE}
  cp ${WORKSPACE}/targer/${jarName} ${dockerPath}
  sh root/deploy/docker/docker_build.sh ${projectName} ${dockerPath} ${jarName}
  ```

  docker_build.sh

  ```shell
  #!/bin/sh
  # 用于将jar包打包成docker镜像并推送到私有docker仓库，并删除旧的docker镜像
  set -e
  projectName=$1
  dockerPath=$2
  appName=$3
  tag=$(date +%s)
  serverPath=k8snode:5000			#私有docker仓库地址
  targetImage=${projectName}:${tag}
  echo ${targetImage}
  
  cd ${dockerPath}
  docker build --build-arg app=${appName} -t ${targetImage}
  docker tag ${targetImage} ${serverPath}/${projectName}
  echo The image's name is "${serverPath}\/${targetImage}"
  docker push ${serverPath}/${projectName}:latest
  docker rmi -f $(docker images | grep ${projectName} | grep ${tag} | awk '${print $3}' | head -n 1)
  
  ```

  Jenkins脚本2: 将项目yaml文件拷贝到k8s master服务器，并通过kubectl启动docker容器自动话部署。

  前提：将私有docker仓库配置到k8s master 的docker daemon 配置中。

  ```shell
  set -e 
  echo ${WORKSPACE}
  dockerPath=${WORKSPACE}
  scp ${WORKSPACE}/*.yaml k8smaster:/root/k8s/projects/jenkins-deploy-example
  ssh k8smaster '/usr/bin/kubectl apply -f /root/k8s/projects/jenkins-deploy-example/kube.yaml'
  ssh k8smaster '/usr/bin/kubectl get svc | grep <projectName>'
  ```

#### 项目构建

+ 启动构建

  `Build with Parameters` -> 选择用于构建的分支 -> `build` -> `Console Output`查看日志 -> 

+ 多模块构建（存在依赖关系）

+ 多项目顺序构建

+ mvn命令行

  <details>   
    <summary>mvn命令行参数</summary>   
    <pre><code>    
    	usage: mvn [options] [<goal(s)>] [<phase(s)>]
    	Options:
    	 -am,--also-make                        If project list is specified, also
                                              build projects required by the
                                              list
       -amd,--also-make-dependents            If project list is specified, also
                                              build projects that depend on
                                              projects on the list
       -B,--batch-mode                        Run in non-interactive (batch)
                                              mode (disables output color)
       -b,--builder <arg>                     The id of the build strategy to
                                              use
       -C,--strict-checksums                  Fail the build if checksums don't
                                              match
       -c,--lax-checksums                     Warn if checksums don't match
       -cpu,--check-plugin-updates            Ineffective, only kept for
                                              backward compatibility
       -D,--define <arg>                      Define a system property
       -e,--errors                            Produce execution error messages
       -emp,--encrypt-master-password <arg>   Encrypt master security password
       -ep,--encrypt-password <arg>           Encrypt server password
       -f,--file <arg>                        Force the use of an alternate POM
                                              file (or directory with pom.xml)
       -fae,--fail-at-end                     Only fail the build afterwards;
                                              allow all non-impacted builds to
                                              continue
       -ff,--fail-fast                        Stop at first failure in
                                              reactorized builds
       -fn,--fail-never                       NEVER fail the build, regardless
                                              of project result
       -gs,--global-settings <arg>            Alternate path for the global
                                              settings file
       -gt,--global-toolchains <arg>          Alternate path for the global
                                              toolchains file
       -h,--help                              Display help information
       -l,--log-file <arg>                    Log file where all build output
                                              will go (disables output color)
       -llr,--legacy-local-repository         Use Maven 2 Legacy Local
                                              Repository behaviour, ie no use of
                                              _remote.repositories. Can also be
                                              activated by using
                                              -Dmaven.legacyLocalRepo=true
       -N,--non-recursive                     Do not recurse into sub-projects
       -npr,--no-plugin-registry              Ineffective, only kept for
                                              backward compatibility
       -npu,--no-plugin-updates               Ineffective, only kept for
                                              backward compatibility
       -nsu,--no-snapshot-updates             Suppress SNAPSHOT updates
       -o,--offline                           Work offline
       -P,--activate-profiles <arg>           Comma-delimited list of profiles
                                              to activate
       -pl,--projects <arg>                   Comma-delimited list of specified
                                              reactor projects to build instead
                                              of all projects. A project can be
                                              specified by [groupId]:artifactId
                                              or by its relative path
       -q,--quiet                             Quiet output - only show errors
       -rf,--resume-from <arg>                Resume reactor from specified
                                              project
       -s,--settings <arg>                    Alternate path for the user
                                              settings file
       -t,--toolchains <arg>                  Alternate path for the user
                                              toolchains file
       -T,--threads <arg>                     Thread count, for instance 2.0C
                                              where C is core multiplied
       -U,--update-snapshots                  Forces a check for missing
                                              releases and updated snapshots on
                                              remote repositories
       -up,--update-plugins                   Ineffective, only kept for
                                              backward compatibility
       -v,--version                           Display version information
       -V,--show-version                      Display version information
                                              WITHOUT stopping build
       -X,--debug                             Produce execution debug output

### Jenkins深入使用

#### 流水线构建、测试、部署，使用Jenkinsfile



从模版中可以窥见大概的功能

```
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building..'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
```

#### 环境变量

```
pipeline {
	environment {
        DISABLE_AUTH = 'true'
        DB_ENGINE = 'sqlite'
	}
}
```

#### 代码仓访问凭据



### Jenkins实现原理

![](../img/Jenkins工作原理.png)

+ 如何监听代码更新的？

  实现文件监听的方式，只能是定期检查或者web回调（参考webhook），git仓库没有装插件的话应该就是定期检查了。像gitlab集成了插件可以通过web回调主动通知Jenkins。
  
  

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