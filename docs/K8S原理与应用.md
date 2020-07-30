# K8S原理与应用

## K8S架构与工作原理

![](../img/k8s架构图.png)

## 使用k8s部署一个应用

### 命令行部署

使用kubectl和docker镜像创建部署(以Nginx应用为例)

```shell
kubectl create deployment mynginx --image=nginx
kubectl expose deployment mynginx --port=80 --type=NodePort	#会将容器内部80端口随机暴露到外部, 可以通过　kubectl get service 查看暴露到了k8smaster主机的哪个端口
kubectl scale --replicas=3 deployment/mynginx

# 部署应用时发现一直处于ContainerCreating状态，报 Error response from daemon: cgroup-parent for systemd cgroup should be a valid slice named as "xxx.slice"
kubectl describe pod mynginx-5966bfc495-5szw9
# 修改/etc/docker/deamon.json cgroupdrvier从systemd改为cgroupfs
"exec-opts": ["native.cgroupdriver=cgroupfs"]
# 修改后重启docker发现pod成功部署
kubectl get pod -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP              NODE        NOMINATED NODE   READINESS GATES
mynginx-5966bfc495-5szw9   1/1     Running   0          66m   10.244.249.65   k8snode01   <none>           <none>
```

### Yaml文件部署

打印Deployment部署的yaml文件

```shell
# 查看某Deployment yaml部署文件
kubectl get deploy mynginx -o yaml	#可以看到虽然这个deploy是两行命令行创建的，但是其实还有很多默认配置项。
```

生成的yaml配置

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2020-06-26T10:22:48Z"
  generation: 2
  labels:
    app: mynginx
  name: mynginx
  namespace: default
  resourceVersion: "56747"
  selfLink: /apis/apps/v1/namespaces/default/deployments/mynginx
  uid: 632fc9ee-26fc-41f7-bf04-54ff03682a6f
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: mynginx
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: mynginx
    spec:
      containers:
      - image: nginx
        imagePullPolicy: Always
        name: nginx
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2020-06-26T11:23:19Z"
    lastUpdateTime: "2020-06-26T11:23:19Z"
    message: ReplicaSet "mynginx-5966bfc495" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  - lastTransitionTime: "2020-06-26T11:33:44Z"
    lastUpdateTime: "2020-06-26T11:33:44Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  observedGeneration: 2
  readyReplicas: 2
  replicas: 2
  updatedReplicas: 2
```

使用yaml文件部署

```shell
kubectl create -f nginx.yaml
kubectl apply -f nginx.yaml
```

Yaml文件中各字段含义参考 《Kubernetes in Action》 3.2 Creating pods from YAML or JSON descriptors。

这些字段对应着Api。

[K8S API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#)

```yaml
# api版本,deployment对应的apps/v1和pod对应的v1什么区别？
apiVersion: apps/v1		
# 当前文件定义的k8s对象或资源类型：Deployment/Pod/Namespace/ReplicationController/ReplicaSet/DaemonSet/Job/Endpoints/Service/Ingress/...
kind: Deployment		
# k8s对象或资源的元数据
metadata:
  annotations:					# 
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2020-06-26T10:22:48Z"		# 
  generation: 2					#
  labels:						#
    app: mynginx				#
  name: mynginx					#Deployment的名称
  namespace: default			#命名空间
  resourceVersion: "56747"
  selfLink: /apis/apps/v1/namespaces/default/deployments/mynginx
  uid: 632fc9ee-26fc-41f7-bf04-54ff03682a6f
# k8s对象或资源的参数说明
spec:
  progressDeadlineSeconds: 600　#
  #控制副本创建的几个标签：replicas、selector、template
  replicas: 2					#要创建的副本的数量
  selector:						#选择
    matchLabels:
      app: mynginx
  template:						#用于创建新Pod的模板
    metadata:
      creationTimestamp: null
      labels:					#指定新创建的Pod的标签
        app: mynginx
    spec:
      containers:				#Deployment容器详情，如果要添加多个容器可以使用 "- image"
      - image: nginx
        imagePullPolicy: Always
        name: nginx
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      - image: tomcat:7 		#又添加了一个容器
      	name: tomcat
        
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
  revisionHistoryLimit: 10
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
# 
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2020-06-26T11:23:19Z"
    lastUpdateTime: "2020-06-26T11:23:19Z"
    message: ReplicaSet "mynginx-5966bfc495" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  - lastTransitionTime: "2020-06-26T11:33:44Z"
    lastUpdateTime: "2020-06-26T11:33:44Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  observedGeneration: 2
  readyReplicas: 2
  replicas: 2
  updatedReplicas: 2
```

### 查看部署结果

```shell
# 查看所有（包括pod、service、deployment、replicaset等信息）
kubectl get all
# 单独查看 Deployment
kubectl get deployments
kubectl get deploy	#简写
# 单独查看 Pod
kubectl get pod -o wide
# 查看所有名称空间的 Deployment
kubectl get deployments -A
kubectl get deployments --all-namespaces
# 查看 kube-system 名称空间的 Deployment
kubectl get deployments -n kube-system
# 删除Deployment
kubectl delete deploy mynginx
# 删除Pod
kubectl delete pod mynginx-5966bfc495-5szw9
```

## 可视化界面搭建

[web用户界面](https://github.com/kubernetes/dashboard)

```shell
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
# 修改recommended.yaml,添加端口暴露配置,后面可以通过https://k8smaster:30001访问dashboard
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001				#添加这两行
  type: NodePort					#添加这两行
  selector:
    k8s-app: kubernetes-dashboard

kubectl apply -f recommended.yaml

kubectl get pod -n kubernetes-dashboard
```

创建帐号配置文件`dashboard-adminuser.yaml`并应用

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  #namespace: kubernetes-dashboard	#这个要改为下下面的命名空间不然会报一堆权限的错误
  namespace: kube-system
---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  #namespace: kubernetes-dashboard
  namespace: kube-system

kubectl apply -f dashboard-adminuser.yaml
```

获取令牌

```shell
# kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
# token
eyJhbGciOiJSUzI1NiIsImtpZCI6IjVrWmkxTVJkMTFqb081dXBna3h3eGFKSGgwaGRYSVVoMlR0RWpFSzhCSXMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLXZtbXcyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI4Y2Q2Zjk4Ni05ZmI3LTQxYmYtODA3My05MGFiODVkYzUzZmUiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06YWRtaW4tdXNlciJ9.Kpu3LFmh0iA1X6Q6Arj7bPb8gz-7cIGa58jrZO5slEfNkFZ1HCSQcEQLf3Hr9aoc-jD-QAiYeEwkNcHpa4U3SuxFtNzcK2OmPYTPflA8MOMjBDu4Z2H1_uAfpAqdcv94Mq8fkky7ufD4TieMXi2mBItFJby-LHXOjmsAKF_ftrVnSfXh-hG0MDCmHQ_b8szWIg6zVEibklAhUMiTFg41VQSqiaC4XXDvd1pBqBX6ys7qKcArEK7F0oBArp2yTo6btZXGVUIl6OYWx_lAUkWxXo7m3o5A9xA0T7niB31hyd67J8GOmjKpM5M-FJXTVBhNwY1pP0I1bXZfzUq5sOjviQ
```

访问 `https://k8smaster:30001`

## K8S详细使用分析

### 重要的概念

+ Pod (服务基本单位)

  Pod对应一个微服务，拥有独立的IP，里面可能包含一到多个Docker容器。

  通过RC(Replication Controller, 控制Pod数目与期望数目相符)、RS(Replica Set) 控制Pod的高可用。

  Pause容器：在pod中担任Linux命名空间共享的基础，启用pid命名空间，开启init进程。

+ Deployment (服务部署、更新)

  其实是对集群的复合更新操作。如滚动升级一个服务（创建一个新的RS,将新RS中Pod副本数增加到理想状态）。

+ Service (提供服务发现和负载均衡，是Pod对外的代理)

  前面已经将服务搭建起来并通过副本集实现了高可用，但是每个Pod节点都有自己的IP和端口对外提供服务；

  就需要在服务部署更新后，自动将服务绑定到新的Pod的IP和端口上。

  每个Service对应一个集群内部的虚拟IP，集群通过虚拟IP访问一个Pod服务。

+ Volume (存储卷)

  类似Docker的volume, 只不过是作用于Pod, Pod的所有容器都可以共享。

+ Namespace

  初始有两个命名空间，分别是 default、kube-system。

+ ...

### K8S对象描述文件

可以通过下面命令查看具体的配置字段即含义

```shell
kubectl explain <deployment/pod/service/...> --recursive=true
```

### Service和Label

Service的使用方式：先创建一个或一组服务(可通过deployment批量创建或pod单个创建)实例，打标签。

然后使用Selector(LabelSelector)选择前面打的标签创建Service。

> Service和Pod是多对多的关系，同一个Pod可以被多个service绑定，一个Service可以包含多个Pod。

测试文件参考：script/service-deploy-pod

Service创建yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: whoami-service
spec:
  selector:
    app: whoami-pod			#
  ports:
  - name: wai-port
    port: 8888				#Service对外（集群其他服务）端口
    targetPort: 8000		#对应的Pod的端口
  type: ClusterIP			#端口暴露到集群内部
```

#### 应用暴露（服务发现与负载）的三种方式

+ ClusterIP

  这种方式通过访问Service集群IP和端口(或service名加端口)，通过iptables规则，可以负载均衡到Pod的IP和端口。

  但是只是暴露到集群内部。外部无法访问。

+ NodePort（NAT）

  将端口同时暴露到集群外部。

  内部还是通过ClusterIP:port访问；

  外部通过NodeIP:port访问（只是多加了外部的接口映射，就像docker将端口映射到宿主机端口后，既可以通过docker内部虚拟IP加容器端口访问，也可以通过宿主机IP加映射的端口访问）。

+ LoadBalancer

  依靠第三方负载均衡策略。

另外两种拓展方式：

+ ExternalName

  用于K8S内部服务访问外部服务（比如阿里云的某个云服务）。

+ ExternalIP

  不同于NodePort会在每个Node节点上开外部端口，ExternalIP只会在指定的Node节点映射外部端口。

### 命名空间

用于实现应用资源隔离（但是网络不会隔离，通过网络可以相互访问）。

在不同的命名空间可以拥有相同名字的Pod实例。

不同的命名空间可以通过网络通信。

指定在某个命名空间的操作只需要添加`-n <yourNamespace>`，如果要访问某命名空间资源通过`.<yourNamespace>`限定（如：whoami-service.<yourNamespace>）。

默认操作都是在default命名空间，如果想在所有空间操作可以使用`-A`。

>命名空间常用的场景：
>
>１）环境隔离：可以使用命名空间分别在dev\test\prod环境下各搭建一套完全相同的环境。
>
>２）产品线隔离：如针对不同产品线（Android\IOS\后端）进行隔离。
>
>３）基于团队隔离

```shell
# 创建命名空间（也可以通过yaml创建命名空间）
kubectl create ns <newNamespace>
# 删除命名空间,会删除这个命名空间下所有资源
kubectl delete ns <newNamespace>
# 命令行将某个资源分配到某个命名空间
kubectl create deploy mydeploy --image=<imageName> --namespace=<myNamespace>
# 获取命名空间的资源(如：pod)
kubectl get pod -n <newNamespace>
```

通过yaml创建命名空间

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <newNamespace>
```

修改Service/Deployment/Pod所属的命名空间

```yaml
metadata:
  namespace: <newNamespace>
```

### 标签＆选择器

标签用于分类和选择；选择器有多种选择策略从一堆资源中通过标签选中目标资源。

选择器选择策略：

+ 等值判断
+ 集合in、notin、exists判断

查看资源的标签（如：pod）

```shell
kubectl get pod --show-labels
kubectl get pod -l app=whoami-pod	# 搜索app标签为whoami-pod的pod
```

#### 字段选择器

可以通过yaml字段筛选k8s的资源。

```shell
kubectl get pod --field-selector metadata.labels.app=whoami-pod
```

### 注解

用于定义元信息，类似Maven的<property>。　

### 容器钩子和容器生命周期

#### 容器生命周期

待创建（Pending）-> 运行中（Running）-> 成功终止（Succeeded）／失败终止（Failed） ／未知（Unknown）

#### 容器钩子

Kubernetes中为容器提供了两个 hook（钩子函数）：

+ PostStart

  此钩子函数在容器创建后将立刻执行。但是，并不能保证该钩子函数在容器的 `ENTRYPOINT` 之前执行。该钩子函数没有输入参数。

+ PreStop

  此钩子函数在容器被 terminate（终止）之前执行，例如：

  通过接口调用删除容器所在 Pod;

  某些管理事件的发生：健康检查失败、资源紧缺等。

  如果容器已经被关闭或者进入了 `completed` 状态，preStop 钩子函数的调用将失败。该函数的执行是同步的，即，kubernetes 将在该函数完成执行之后才删除容器。该钩子函数没有输入参数。

### 多容器协作&SideCar

SideCar用于处理和本职业务不相关的事务处理，如日志监控等。服务可以将日志数据交给SideCar与其他监控服务交互。这种方式类似代理，如MyCAT就是某个服务分库分表相关事务的代理（可以称MyCAT就是这个服务的SideCar）。还有一些中间件也可以称为服务的SideCar。

### Init容器

用于初始化pod, 一个pod可以拥有一个或多个Init容器，它们之间一个接一个地执行。执行完就退出。

Init容器先于业务服务容器启动。如果Init容器执行失败k8s会不断重启该pod；除非设置restartPolicy为Never。

### 探针机制

用于探测容器执行状态。每次探测都会获取“成功”、“失败”、"未知"三种状态之一。

三种处理程序：

+ ExecAction
+ TCPSocketAction
+ HttpGetAction

三种探针：

+ 存活探针 livenessProbe

  确定容器是否正在运行。如果健康检查失败，kubelete 将结束该容器，并根据 restart policy（重启策略）确定是否重启该容器。

+ 就绪探针 readinessProbe

  确定容器是否已经就绪并接收服务请求。如果就绪检查失败，kubernetes 将该 Pod 的 IP 地址从所有匹配的 Service 的资源池中移除掉。

+ 启动探针 startupProbe

使用探针机制可以实现如下功能：

１）在容器的进程无响应后，将容器 kill 掉并重启。通过指定一个健康检查 liveness probe，并同时指定 restart policy（重启策略）为 Always 或者 OnFailure。

２）等待Pod确实就绪之后才向其分发服务请求。通过指定一个就绪检查 readiness probe。

### 滚动升级＆扩缩容

#### ReplicaSet(RS) & ReplicationController(RC)

RS是RC的升级版，支持复杂的选择器。通过explain查看配置项，对比差异。

#### RS & Deployment

Deployment是RS的升级版，RS只能做副本控制，通过explain查看配置项，对比差异。

```shell
# kubectl explain ReplicaSet.spec
minReadySeconds	<integer> #最小就绪时间（就绪后可视为可用的时间）
replicas <integer> 	#副本数量（容器全部实例数量）
selector <Object>	#标签选择器
template <Object>	#Pod创建模板

# kubectl explain Deployment.spec
minReadySeconds	<integer>
paused	<boolean>	#用于滚动升级，显示deployment是否paused
progressDeadlineSeconds	<integer>	#启动就绪限时
replicas	<integer>
revisionHistoryLimit	<integer>　	#最大记录版本数
selector	<Object> -required-
strategy	<Object>	#升级策略
  rollingUpdate	<Object>	#滚动升级策略
    maxSurge				#最大增量, 每次滚动升级的实例数量（默认每次１个）或百分比
    maxUnavailable			#最大不可用量，当不可用实例数量超过这个值（整数或百分比）则停止升级
  type	<string>			#策略类型　"Recreate" or "RollingUpdate"
template	<Object> -required-
```

#### Horizontal Pod Autoscaler

可以通过CPU利用率自动伸缩RC\RS\Deployment中的Pod数量。

```shell
kubectl explain hpa
```

监控需要安装监控工具：metrics-server

#### 金丝雀部署(灰度发布)案例

使用标签选择器和Pod多标签实现。

#### StatefulSet

用于有状态服务的部署。使用StatefulSet部署的Pod,即使重新被拉起，所有的状态（如：ip）都不变。

**适用场景**：

稳定、唯一的网络标识；

每个Pod始终对应各自的存储路径；

按顺序地增加副本较少副本，并在减少副本时执行清理；

按顺序自动执行滚动更新。

**yaml配置项**：

```shell
podManagementPolicy	<string>	#pod管理策略（OrderedReady／Parallel），默认是按顺序启动／关闭
								#Parallel并行启动／删除
replicas	<integer>
revisionHistoryLimit	<integer>
selector	<Object> -required-
serviceName	<string> -required-	#管理此StatefulSet的service, 此StatefulSet的pod由该service
template	<Object> -required-
updateStrategy	<Object>
volumeClaimTemplates	<[]Object>
```

```shell
# 可以看到statefulset创建的pod不像之前那样后面添加两段随机码区分
[root@k8smaster stateful]# watch -n 1 kubectl get pod -l app=stateful-tomcat -o wide
NAME                READY   STATUS    RESTARTS   AGE     IP              NODE        NOMINATED NODE   READINESS GATES
stateful-tomcat-0   1/1     Running   0          6m57s   10.244.249.79   k8snode01   <none>           <none>
stateful-tomcat-1   1/1     Running   0          6m55s   10.244.32.135   k8snode02   <none>           <none>
stateful-tomcat-2   1/1     Running   0          6m12s   10.244.249.80   k8snode01   <none>           <none>
# 可以发现pod删除后会重新部署，pod名字不变，虽然IP会变
# 访问方式
curl stateful-tomcat-1.stateful-tomcat:8080
```

#### DaemonSet

会在集群中每个Node节点都部署文件中定义的Pod。

集群守护进程、日志收集、运行监控容器都可以通过这个将控制器部署。

#### Job & CronJob

为临时任务或定时任务创建Pod，执行完即退。注意CronJob是创建Job的，然后由Job创建Pod。

Job程序必须确保是幂等的（因为CronJob在时间计划中的每个执行时刻在少数情况可能出现创建两个Job对象或不创建Job对象）。

### Ingress网络

Ingress底层实现依赖Nginx, 工作在Service上层，为与哦嗯乎提供整个集群Service的路由访问。

### Pod调度

#### 调度原理



### 亲和、反亲和、安全管理

#### 污点与容忍

#### 权限认证



## 微服务实战

### Helm

![](../img/helm3_architecture.jpg)

- k8s的包管理工具。可以使用helm快速的分享、构建k8s应用；
- 对于使用者而言，使用helm以后不需要了解k8s的yaml语法并编写应用部署文件，可以通过helm下载并在k8s上安装应用
- helm也提供了在k8s上软件部署、删除、升级、回滚应用的强大功能
- helm的**软件包**称为**chart**，类似maven给我们会打包一个jar或者war一样
- helm软件包地址: https://github.com/helm/charts/tree/master/stable

#### 安装配置

```shell
# 安装Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
# 添加Helm仓库源，helm从仓库检索东西
helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
helm repo add apphub https://apphub.aliyuncs.com
helm repo update
helm repo list
# 使用
helm search repo mysql
helm show all apphub/mysql			#查看应用详情
helm install mysql apphub/mysql
helm list
helm uninstall mysql
# 查看所有相关创建的资源
kubectl get all | grep mysql
kubectl get pvc
```

#### 在Helm软件包基础上修改重新打包

##### 命令行修改配置

如果修改比较少，且经常变，可以直接通过命令行修改

```shell
#　查看命令行可以修改的配置
helm install mysql apphub/mysql --help
helm install mysql --set mysqlRootPassword=123456 stable/mysql
```

##### 修改配置文件重新制作软件包

```shell
# 首先下载软件包,并解压
helm pull stable/mysql
tar zxf mysql-0.3.5.tgz
tree mysql
```

文件说明：

```shell
mysql
├── Chart.yaml			# 软件包的描述文件
├── README.md			
├── templates			# 真正用于创建k8s各种资源的配置文件
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── NOTES.txt
│   ├── pvc.yaml
│   ├── secrets.yaml
│   └── svc.yaml
└── values.yaml			# 软件配置文件（这里定义了mysql的用户名密码／mysql.cnf配置文件，k8s控制器／探针／持久化卷／硬件资源限制／等的配置）
						# helm install mysql --set mysqlRootPassword=123456 stable/mysql 就是提取的values.yaml文件
```

修改values.yaml然后应用到helm app

```shell
helm install mysql -f values.yaml
helm install mysql -f values.yaml ./	#如果其他文件也有修改，可以这样替换
```











