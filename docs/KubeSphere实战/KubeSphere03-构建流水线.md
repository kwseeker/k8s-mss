# 构建流水线

[Jenkinsfile in SCM](https://kubesphere.com.cn/docs/zh-CN/quick-start/devops-online/)

[图形化构建流水线 (Jenkinsfile out of SCM)](https://kubesphere.com.cn/docs/zh-CN/quick-start/jenkinsfile-out-of-scm/)

## 构建流程

**Jenkinsfile in SCM**

1) 项目准备（开发项目或从GitHub拉取测试项目到自己的Github或自己的gitlab）

2) 创建流水线项目（前提开启DevOps、多租户管理邀请成员分配好权限）

3) 创建凭证，　修改Jenkinsfile

4) 添加代码仓库，生成访问token (通过token访问账户下的仓库资源)

5) 选择需要自动化部署的项目

6) 高级设置对流水线的构建记录、行为策略、定期扫描等设置进行定制

7) 运行流水线执行自动化构建、部署

> - **阶段一. Checkout SCM**: 拉取 GitHub 仓库代码
> - **阶段二. Unit test**: 单元测试，如果测试通过了才继续下面的任务
> - **阶段三. SonarQube analysis**：sonarQube 代码质量检测
> - **阶段四. Build & push snapshot image**: 根据行为策略中所选择分支来构建镜像，并将 tag 为 `SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER`推送至 Harbor (其中 `$BUILD_NUMBER`为 pipeline 活动列表的运行序号)。
> - **阶段五. Push latest image**: 将 master 分支打上 tag 为 latest，并推送至 DockerHub。
> - **阶段六. Deploy to dev**: 将 master 分支部署到 Dev 环境，此阶段需要审核。
> - **阶段七. Push with tag**: 生成 tag 并 release 到 GitHub，并推送到 DockerHub。
> - **阶段八. Deploy to production**: 将发布的 tag 部署到 Production 环境。

8) 流水线审核（确认弹窗）

**Jenkinsfile out of SCM**(可视化方式构建流水线)

与Jenkinfile in SCM的区别是Jenkinfile的创建，Jenkinfile in SCM是提供一个写好的Jenkinsfile,

而Jenkinsfile out of SCM是通过图形化编辑生成Jenkinsfile。

**Dockerfile示例**

```
pipeline {
    agent {
        node {
          label 'maven'
        }
    }

    parameters {
        string(name:'TAG_NAME',defaultValue: '',description:'')
        string(name:'PROJECT',description:'需要构建的项目',defaultValue: '')
    }
    environment {
        DOCKER_CREDENTIAL_ID = 'aliyun_hub'
        GITHUB_CREDENTIAL_ID = 'gitee_id'
        KUBECONFIG_CREDENTIAL_ID = 'kubeconfig'
        REGISTRY = 'registry.cn-zhangjiakou.aliyuncs.com'
        DOCKERHUB_NAMESPACE = 'allenicodingdocker'
        GITHUB_ACCOUNT = 'icodingallen'
        APP_NAME = 'ocp'
        SONAR_CREDENTIAL_ID = 'sonar-token'
    }

    stages {
            stage ('代码检出') {
                steps {
                    checkout(scm)
                }
            }
            stage ('单元测试跳过') {
                steps {
                    container ('maven') {
                        sh 'pwd && ls'
                        sh 'echo $PROJECT-$TAG_NAME'
                        sh 'mvn clean -gs `pwd`/configuration/settings.xml install'
                    }
                }
            }
            stage('代码质量分析') {
              steps {
                container ('maven') {
                  withCredentials([string(credentialsId: "$SONAR_CREDENTIAL_ID", variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('sonar') {
                     sh "mvn sonar:sonar -gs `pwd`/configuration/settings.xml -Dsonar.branch=$BRANCH_NAME -Dsonar.login=$SONAR_TOKEN"
                    }
                  }
                  timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                  }
                }
              }
            }
            stage ('build & push') {
                steps {
                    container ('maven') {
                        sh 'mvn -Dmaven.test.skip=true -gs `pwd`/configuration/settings.xml clean package'
                        sh 'docker build -f Dockerfile-online -t $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER .'
                        withCredentials([usernamePassword(passwordVariable : 'DOCKER_PASSWORD' ,usernameVariable : 'DOCKER_USERNAME' ,credentialsId : "$DOCKER_CREDENTIAL_ID" ,)]) {
                            sh 'echo "$DOCKER_PASSWORD" | docker login $REGISTRY -u "$DOCKER_USERNAME" --password-stdin'
                            sh 'docker push  $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER'
                        }
                    }
                }
            }

    }
}
```



### 开启DevOps

https://kubesphere.com.cn/docs/zh-CN/installation/install-devops/

### 创建凭证

可能需要访问DockerHub、GitHub等公有仓库或者公司内部的仓库，从这些仓库拉取资源都需要配置用户凭证。

