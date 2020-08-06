# GitLab CICD

[GitLab Docs](https://docs.gitlab.com/ee/README.html)

Jenkins的好处就是编译服务和代码仓库分离，而且编译配置文件不需要在工程中配置，如果团队有开发、测试、配置管理员、运维、实施等完整的人员配置，那就采用jenkins，这样职责分明。不仅仅如此，**jenkins依靠它丰富的插件，可以配置很多gitlab-ci不存在的功能**，比如说看编译状况统计等。如果团队是互联网类型，讲究的是敏捷开发，那么开发=devOps，肯定是采用最便捷的开发方式，推荐gitlab-ci。

## Docker部署GitLab

```shell
docker pull gitlab/gitlab-ce:13.2.1-ce.0
GITLAB_HOME=/home/lee/docker/gitlab/repo
docker run -d \
--hostname gitlab.kwseeker.top\         # 指定容器域名,创建镜像仓库用
-p 10443:443 \                          # 容器443端口映射到主机10443端口(https)
-p 10080:80 \                           # 容器80端口映射到主机10080端口(http)
-p 10022:22 \                           # 容器22端口映射到主机10022端口(ssh)
--name gitlab \                         # 容器名称
--restart always \                      # 容器退出后自动重启
-v $GITLAB_HOME/config:/etc/gitlab \    # 挂载本地目录到容器配置目录
-v $GITLAB_HOME/logs:/var/log/gitlab \  # 挂载本地目录到容器日志目录
-v $GITLAB_HOME/data:/var/opt/gitlab \  # 挂载本地目录到容器数据目录
gitlab/gitlab-ce:13.2.1-ce.0            # 使用的镜像:版本
```

`~/.ssh/config`修改ssh访问`gitlab`的端口

```txt
host gitlab.kwseeker.top
    hostname gitlab.kwseeker.top
    user lee
    port 10022
    identityFile /home/yourname/.ssh/id_rsa
```

启动之后通过10080端口访问。

## GitLab使用CICD

[CI/CD](https://docs.gitlab.com/ee/ci/README.html)

### 开启CICD

在项目的配置项`Settings -> CI/CD`

### GitLab CICD工作原理

#### GitLab Runner

```
docker run -d --name gitlab-runner \
    -v /srv/gitlab-runner/config:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest
```



### Pipeline的基本框架

### GitLab CI/CD 基本工作流

![](https://docs.gitlab.com/ee/ci/introduction/img/gitlab_workflow_example_11_9.png)

![](https://docs.gitlab.com/ee/ci/introduction/img/gitlab_workflow_example_extended_v12_3.png)

### .gitlab-ci.yml 语法

[.gitlab-ci.yml Reference](https://docs.gitlab.com/ee/ci/yaml/README.html)

## GitLab使用目标

１）分别将unstable、master分支自动编译、打包、制Docker镜像推送到Docker镜像仓库，

２）部署到腾讯云k8s集群。

