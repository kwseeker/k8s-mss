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

#### 应用暴露的三种方式

+ ClusterIP

  这种方式通过访问Service集群IP和端口(或service名加端口)，可以负载均衡到Pod的IP和端口。

  但是只是暴露到集群内部。外部无法访问。

+ NodePort（NAT）

  将端口同时暴露到集群外部。

+ LoadBalancer

  依靠第三方负载均衡策略。

### 负载均衡与Pod调度



### 存储技术



### 亲和、反亲和、安全管理



## 微服务实战









