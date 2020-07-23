# K8S疑问

+ metadata: labels \ selector:matchLabels \ template:metadata:lables 的关系？

+ Service Pod Deployment 端口号的关系？怎么一层层映射的？从宿主机是怎么找到底层容器的某个app的？

  ![](../img/k8s各层级端口对应关系.png)

+ Service是不是依赖Calico等网络插件实现负载均衡的？

+ deployment部署的一个pod有多个tomcat容器如何修改端口映射防止冲突？

+ 同一个Namespace的多个service可以互通么？

  可以互通。不同命名空间的pod也可以互相通信。

  可以通过 podName.serviceName.namespace 访问。

+ StatefulSet podManagementPolicy 有两种pod管理策略（OrderedReady／Parallel），使用什么时候使用OrderedReady何时使用Parallel?
  个人认为在一个service有多个相互依赖的容器时需要使用OrderedReady，比如有tomcat容器和mysql容器，

  tomcat容器依赖mysql容器。

+ StatefulSet如何部署有依赖关系的容器？

  如tocmat依赖mysql。部署３个tomcat, １主2从mysql集群。

  

  