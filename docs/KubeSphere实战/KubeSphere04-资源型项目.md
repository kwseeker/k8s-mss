# 资源型项目

项目创建流程（假设容器仓库、镜像都准备就绪）：

１）创建Deployment/StatefulSet，以及对应的Service。（外部服务的话只有Service）

２）创建Ingress路由

​		ａ）创建TLS证书密钥（用于https协议）

​		ｂ）配置路由规则





## 项目配置

### 应用负载

#### 应用

#### 服务 

用于创建Deployment/StatefulSet。

```yaml
apiVersion: apps/v1
kind: Deployment				#Deployment
metadata:
  namespace: demo-project
  labels:
    app: tea-svc
  name: tea-svc-u78qyi
  annotations:
    kubesphere.io/alias-name: 茶水点餐系统
    kubesphere.io/minAvailablePod: '2'
    kubesphere.io/maxSurgePod: '3'
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tea-svc
  template:
    metadata:
      labels:
        app: tea-svc
      annotations:
        kubesphere.io/containerSecrets: null
    spec:
      containers:
        - name: container-55z4dq
          type: worker
          imagePullPolicy: IfNotPresent
          resources:
            requests:
              cpu: '0.01'
              memory: 10Mi
            limits:
              cpu: '0.22'
              memory: 500Mi
          image: 'nginxdemos/hello:plain-text'
          ports:
            - name: tcp-80
              protocol: TCP
              containerPort: 80
              servicePort: 80
      serviceAccount: default
      affinity:
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: tea-svc
                topologyKey: kubernetes.io/hostname
      initContainers: []
      imagePullSecrets: null
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
---
apiVersion: v1
kind: Service					# Service
metadata:
  namespace: demo-project
  labels:
    app: tea-svc
  annotations:
    kubesphere.io/serviceType: statelessservice
    kubesphere.io/alias-name: 茶水点餐系统
  name: tea-svc
spec:
  sessionAffinity: ClientIP
  selector:
    app: tea-svc
  ports:
    - name: tcp-80
      protocol: TCP
      port: 80
      targetPort: 80
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
  #type: NodePort
```

创建两个服务后查看命名空间

```shell
[root@ks-allinone ~]# kubectl get all -n demo-project
NAME                                     READY   STATUS    RESTARTS   AGE
pod/coffee-svc-i0jaeb-7654864546-hlkcl   1/1     Running   0          3m36s
pod/coffee-svc-i0jaeb-7654864546-kspkt   1/1     Running   0          3m36s
pod/tea-svc-u78qyi-548d98cf57-56ngj      1/1     Running   0          8m49s
pod/tea-svc-u78qyi-548d98cf57-8dsgt      1/1     Running   0          8m49s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/coffee-svc   ClusterIP   10.233.11.205   <none>        80/TCP    3m36s
service/tea-svc      ClusterIP   10.233.12.92    <none>        80/TCP    8m49s

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/coffee-svc-i0jaeb   2/2     2            2           3m36s
deployment.apps/tea-svc-u78qyi      2/2     2            2           8m49s

NAME                                           DESIRED   CURRENT   READY   AGE
replicaset.apps/coffee-svc-i0jaeb-7654864546   2         2         2       3m36s
replicaset.apps/tea-svc-u78qyi-548d98cf57      2         2         2       8m49s
```



#### 工作负载

#### 任务

#### 应用路由

KubeSphere内置了路由控制器 (Ingress Controller)，在K8S中也是Pod形式存在的，用作全局的负载均衡器，为了代理不同后端服务 (Service) 而设置的负载均衡服务，用户访问 URL 时，应用路由控制器可以把请求转发给不同的后端服务。

实现基于Ingress网络。

需要先打开负载均衡配置。然后创建应用路由。

> 注意：Ingress网络是部署在Node节点的，Master节点无法部署。AllInOne模式有点忧伤了。

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  namespace: demo-project
  labels:
    app: cafe-ingress
  name: cafe-ingress
spec:
  rules:
    - host: cafe.kwseeker.top
      http:
        paths:
          - path: /coffee
            backend:
              serviceName: coffee-svc
              servicePort: 80
          - path: /tea
            backend:
              serviceName: tea-svc
              servicePort: 80
```



#### 容器组

### 存储卷

### 配置中心

### 构建项目

### 项目设置