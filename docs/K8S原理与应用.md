# K8S原理与应用

## K8S架构与工作原理

## 使用k8s部署一个应用

使用kubectl和docker镜像创建部署

```shell
kubectl create deployment mynginx --image=nginx
kubectl expose deployment mynginx --port=80 --type=NodePort	#会将容器内部80端口随机暴露到外部
kubectl scale --replicas=3 deployment/mynginx	#这里副本数是怎么算的？

# 部署应用时发现一直处于ContainerCreating状态，报 Error response from daemon: cgroup-parent for systemd cgroup should be a valid slice named as "xxx.slice"
kubectl describe pod mynginx-5966bfc495-5szw9
# 修改/etc/docker/deamon.json cgroupdrvier从systemd改为cgroupfs
"exec-opts": ["native.cgroupdriver=cgroupfs"]
# 修改后重启docker发现pod成功部署
kubectl get pod -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP              NODE        NOMINATED NODE   READINESS GATES
mynginx-5966bfc495-5szw9   1/1     Running   0          66m   10.244.249.65   k8snode01   <none>           <none>
```

查看部署结果

```shell
# 查看所有（包括pod、service、deployment、replicaset等信息）
kubectl get all
# 单独查看 Deployment
kubectl get deployments
# 单独查看 Pod
kubectl get pods -o wide
# 查看所有名称空间的 Deployment
kubectl get deployments -A
kubectl get deployments --all-namespaces
# 查看 kube-system 名称空间的 Deployment
kubectl get deployments -n kube-system
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







