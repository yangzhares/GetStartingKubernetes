## Kubernetes Service Part 1

###1. Service
k8s中，service是一系列Pods的访问入口，service由一个服务IP地址和端口组成，使用selector决定哪个Pod给相应的请求提供服务。通过service使得前端service与后端提供服务的Pods更加松散，service不关心后端到底有多少Pods，Pods的变化对service没有任何影响，其表现为负载均衡器，总是会将请求转发给可用的Pod。

###2. 定义

	type Service struct {
		TypeMeta   `json:",inline"`
		ObjectMeta `json:"metadata,omitempty"`
		Spec ServiceSpec `json:"spec,omitempty"`
		Status ServiceStatus `json:"status,omitempty"`
	}
下面我们来看Service定义的各个属性的具体工作：

* Spec：ServiceSpec描述Service的具体行为，
		
		type ServiceSpec struct {
			Ports []ServicePort `json:"ports"`
			Selector map[string]string `json:"selector"`
			PortalIP string `json:"portalIP,omitempty"`
			CreateExternalLoadBalancer bool `json:"createExternalLoadBalancer,omitempty"`
			PublicIPs []string `json:"publicIPs,omitempty"`
			SessionAffinity AffinityType `json:"sessionAffinity,omitempty"`
		}
	ServiceSpec的各个属性具体描述了Service的特征，具体如：
	* Ports：ServicePort主要描述该服务暴露的服务端口及服务使用协议；
	* Selector：Selector用于将请求路由到匹配Selector的Pods，如果没有设置Selector，则k8s认为该服务有通过外部方式设置的endpoints，而且k8s对其不能修改；
	* PortalIP：PortalIP是一虚拟IP地址，位于一个在k8s master自定义的Portal IP地址范围内。通常该IP地址不需要手动指定，而是由master自动分配，但是你也可以指定自己需要的PortalIP，但是必须在master定义的范围内，否则视为不合法的PortalIP；
	* CreateExternalLoadBalancer，如果需要给该服务创建外部LoadBalancer，则CreateExternalLoadBalancer需设为true；
	* PublicIPs：PublicIPs通常为External LoadBalancer所需，当然你也可以将其指定为专门用于处理外部请求经过的节点地址；
	* SessionAffinity：AffinityType用来实现回话保持功能，在一定时间内，通过ClientIP将请求路由到曾经访问过的Pod。当前，k8s支持ClientIP和None两种方式。
* Status：ServiceStatus用于描述Service的状态，当前ServiceStatus没有做任何实现。
	