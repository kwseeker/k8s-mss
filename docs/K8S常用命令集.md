# K8S常用命令集

```shell
# 查看API资源（pod、service等都是API资源）
kubectl api-resources
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
# 更新操作
kubectl set image deployment/nginx busybox=busybox nginx=nginx:1.9.1	#更新现有的资源对象的容器镜像
# 删除操作
kubectl delete deploy mynginx						#删除Deployment
kubectl delete pod mynginx-5966bfc495-5szw9			#删除Pod
kubectl delete -f stateful-tomcat-2.yaml
# 进入pod内部
kubectl exec -it <podId> bash
kubectl exec -it <podId> -c <containerName> bash 	#进入pod的某个容器内部
# 查看pod/service/...的基本信息和日志事件
kubectl describe pod <podId/serviceId/...>
# 查看某yaml文件所有字段
kubectl explain deployment --recursive=true
kubectl explain deployment.spec.template.spec.containers.ports --recursive=true
# 日志查看(如pod)
kubectl logs pod <podName>
# 部署更新回滚（类比git的提交回滚，比如某个部署修改了３次，最后一次修改错误，想要回滚到之前的状态
kubectl rollout history deployment.apps/whoami-deploy
kubectl rollout undo deployment.apps/whoami-deploy		#回滚到上一版本
kubectl rollout history deployment.apps/whoami-deploy --to-revision=1	#回滚到第一个版本
kubectl rollout pause deployment.v1.apps/nginx-deployment 	#暂停记录版本
kubectl rollout resume deployment.v1.apps/nginx-deployment	#恢复记录版本
# 命令行监控
watch -n 1 kubectl get pod -l app=stateful-tomcat -o wide
```

