# Jenkins安装与使用

官方文档：[用 Maven 构建 Java 应用](https://www.jenkins.io/zh/doc/tutorials/build-a-java-app-with-maven)

解析用户写的构建脚本（shell），自动执行脚本构建部署。

## Jenkins(Blue Ocean)安装

参考《虚拟机环境搭建.md》

安装完成后测试：http://k8snode:8080/，http://k8scode:8080/blue/organizations/jenkins/pipelines

注意如果使用war包方式安装而不是使用docker镜像安装需要配置全局工具（git/maven等）。使用docker镜像安装的话，这些依赖都已经安装好了。

## Jenkins插件安装

参考：[jenkins学习3-Jenkins插件下载速度慢、安装失败](https://cloud.tencent.com/developer/article/1563303)

由于墙的原因，插件安装缓慢或者失败，修改插件仓库配置（_data/）

```xml
vi hudson.model.UpdateCenter.xml 
<?xml version='1.1' encoding='UTF-8'?>
<sites>
  <site>
    <id>default</id>
    <url>https://updates.jenkins.io/update-center.json</url>
  </site>
```

还需要修改default.json文件(_data/updates)

```
vi default.json
#替换所有插件下载的url
:1,$s/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g
#替换连接测试url
:1,$s/http:\/\/www.google.com/https:\/\/www.baidu.com/g
```

配置完成后重启Jenkins

```
#不需要重启docker镜像，浏览器访问下面url即可
http://k8scode:8080/restart
```

## Jenkins 凭据配置

## Jenkins项目构建

### 流水线项目

"新建item"-> "流水线" -> "项目配置"

流水线项目工程都存储在"/var/jenkins_home/workspace/"下。

#### 项目配置

##### General

##### 构建触发器

###### 定时构建

写crontab表达式，定时执行。

###### 轮寻SCM

每隔一段时间检查一下代码仓有没有改变，有改变则执行构建。

###### 远程构建

使用github Webhooks(可以简单理解为是方法回调)，但是需要jenkins服务器外网可访问以及授权。

##### 高级项目选项

##### 流水线

流水线构建命令通常使用“SCM”的方式，写jenkinsfile和代码一起维护。

###### 使用

**编写构建脚本的方式：**

[pipeline语法](https://www.jenkins.io/zh/doc/book/pipeline/syntax/)

> 写pipeline时对语法不熟悉可以参考项目左侧的菜单栏的”流水线语法“有”片段生成器“，”指令生成器“等帮助工具，自动生成片段脚本、指令等。

```shell
pipeline {
	#构建代理环境，即在哪里编译构建agent：jenkins接下来的流水线运行在哪个环境
	#可以为某个阶段单独设置构建环境
	# https://www.jenkins.io/doc/book/pipeline/syntax/#agent
	# agent any:任意环境（立刻就能运行，不挑环境），
	# agent none：顶级整个流水线环境，每个阶段stage，要定义自己的agent环境
	# agent { label 'my-defined-label' }
	# agent { node { label 'labelName' } } ;和agent { label 'labelName' }一个意思,
	# agent {
    #    docker {
    #        image 'maven:3-alpine'
    #        label 'my-defined-label'
    #        args  '-v /tmp:/tmp'
    #    }
    # } #指定当前流水线或者stage运行在使用docker下载来的这个环境下，容器用完即删。如果这些环境有些数据需要永久保存我们就应该挂载出来。
    agent { 
    	docker 'maven:3-alpine'
    	#mvn从网上下载jar包。下载来的东西都挂载到linux的/root/.m2，保存，避免每次都重新拉jar包
    	args '-v /root/.m2:/root/.m2'
    }	
    
    #环境变量
    environment {
        DISABLE_AUTH = 'true'
        DB_ENGINE    = 'sqlite'
    }
    
    #多阶段
    stages {
    	stage('Build') {
    		#多步骤
    		steps {
    		 	sh 'echo 编译...'
                sh 'mvn -B -DskipTests clean package'
    		}
    	}
    	stage('Test') {
    		#多步骤
    		steps {
    		 	
    		}
    	}
    	stage('Deploy') {
    		#多步骤
    		steps {
    			#人工确认，对于关键步骤通过人工检查是否继续
    		 	input "Does the staging environment look ok?"
    		 	emailext body: '环境重新部署', subject: '环境重新部署', to: 'xxx@xxx.com'
    		}
    	}
    }
    
    #后置处理，https://www.jenkins.io/zh/doc/book/pipeline/syntax/#post
   	# 可以总是触发、当阶段改变后触发、构建失败时触发、构建成功时触发、完成状态是unstable时触发、完成状态为aborted（手动停止）时触发。
   	# 后置处理操作比如释放资源，清理临时文件，发送编译失败错误信息的邮件等等。
    post {
    	always {
            sh 'echo 完成...'
        }
        aborted {
            
        }
        success {
         
        }
        failure {
           
        }
    }
}
```

**通过Jenkins(blue ocean) UI页面为项目创建Jenkinsfile文件方式**：

"blue ocean首页"-> "流水线" -> "创建流水线" -> ... 。

###### 构建原理

1. 点击构建（除了手动点击构建，还可以定时轮询、远程触发构建）Jenkins会把项目拉倒jenkins服务器，放到workspace（一般我们的源代码都会被放在这里），然后开始进行流水线处理（jenkinsfile中定义的命令）；

2. `agent { docker 'maven:3.3.3'}` 下载maven docker镜像（如果此镜像没有的话）；

3. 启动maven的docker镜像，将此项目目录映射到maven容器内部；

4. 然后就是执行pipeline中的各个阶段`stages`定义的操作；

   Jenkins本身的构建日志都在一起；blue-ocean将各个阶段的操作按stage分离开了。

## Jenkins构建docker镜像

## Docker swarm 部署docker镜像

