# K8S常用命令集

```shell
# 创建操作
kubectl create -f nginx.yaml						#创建
kubectl apply -f nginx.yaml							#没有则创建，有则更新
# 查看操作（包括pod、service、deployment、replicaset等信息）
kubectl get all
kubectl get deployments								#单独查看Deployment
kubectl get deploy									#简写
kubectl get pod -o wide								#单独查看Pod详情
kubectl get deployments -A							#查看所有名称空间的Deployment
kubectl get deployments --all-namespaces
kubectl get deployments -n kube-system				#查看kube-system名称空间的Deployment
# 删除操作
kubectl delete deploy mynginx						#删除Deployment
kubectl delete pod mynginx-5966bfc495-5szw9			#删除Pod
# 进入pod内部
kubectl exec -it <podId> bash
kubectl exec -it <podId> -c <containerName> bash 	#进入pod的某个容器内部
# 查看pod/service/...的基本信息和日志事件
kubectl describe pod <podId/serviceId/...>
# 查看某yaml文件所有字段
kubectl explain deployment --recursive=true
kubectl explain deployment.spec.template.spec.containers.ports --recursive=true
```

