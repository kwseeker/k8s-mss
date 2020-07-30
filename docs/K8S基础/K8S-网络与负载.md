# 网络与负载

+ Service四种网络类型，原理
+ nodePort、port、targetPort的含义
+ 同一个Pod内部容器通信的原理、不同Pod的容器间通信的原理、外部访问内部容器的通信原理
+ Ingress工作原理，Ingress Controller部署到哪里了
  + 访问域名是怎么找到Ingress的？或Ingress是怎么知道我访问了域名某路由？

## Service与Ingress

参考：

[Kubernetes NodePort vs LoadBalancer vs Ingress? When should I use what?](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0)

[kube-proxy工作原理](https://cloud.tencent.com/developer/article/1097449)



Ingress为所有Node节点都开了80、443端口。

