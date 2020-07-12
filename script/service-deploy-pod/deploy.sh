#!/usr/bin/env bash

#分别通过pod和deployment的方式各创建两个pod, 标签都是"whoami-pod"
kubectl apply -f pod-whoami-01.yaml
kubectl apply -f pod-whoami-02.yaml
kubectl apply -f deploy-whoami.yaml
#创建service绑定"whoami-pod",将service的8888端口指向pod的8000端口
kubectl apply -f service-whoami.yaml

#测试
#kubectl exec -it mynginx bash
#curl 10.96.23.243:8888
#curl whoami-service:8888
