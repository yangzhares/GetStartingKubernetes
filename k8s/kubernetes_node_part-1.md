## Kubernetes Node Part 1

###1. Node
在Kubernetes中，Node表示一个工作节点。

	type Node struct {
		TypeMeta   `json:",inline"`
		ObjectMeta `json:"metadata,omitempty"`
		Spec NodeSpec `json:"spec,omitempty"`
		Status NodeStatus `json:"status,omitempty"`
	}
###2. TypeMeta
其中TypeMeta用描述API响应和请求中各个对象的类型和API版本，

	type TypeMeta struct {
		Kind string `json:"kind,omitempty"`
		APIVersion string `json:"apiVersion,omitempty"`
	}
###3. ObjectMeta
而ObjectMeta是所有持久性资源必须包含的元数据，也包括所有用户必须创建的对象。
	
	type ObjectMeta struct {
		Name string `json:"name,omitempty"`
		GenerateName string `json:"generateName,omitempty"`
		Namespace string `json:"namespace,omitempty"`
		SelfLink string `json:"selfLink,omitempty"`
		UID types.UID `json:"uid,omitempty"`
		ResourceVersion string `json:"resourceVersion,omitempty"`
		CreationTimestamp util.Time `json:"creationTimestamp,omitempty"`
		DeletionTimestamp *util.Time `json:"deletionTimestamp,omitempty"`
		Labels map[string]string `json:"labels,omitempty"`
		Annotations map[string]string `json:"annotations,omitempty"`
	}
下面看ObjectMeta的一些主要属性：

* Name：一些资源可以允许客户端请求创建一个自动产生的名字，但是大部分资源在创建资源时须指定其名字，而且同一namespace中，资源名字必须是唯一的；
* Namespace：namespace使得定义在其空间的名字必须唯一，一个空的namespace等价于默认"default" namespace，k8s定义了一些默认namespace，如：NamespaceDefault，即default，如果客户端没有指定namespace，则使用NamespaceDefault；NamespaceAll，即""，当想要查看和过滤所有namespace的资源时，可指定此namespace；NamespaceNone，即""，故名思议没有namespace。
* SelfLink：SelfLink表示一对象的URL；
* Labels：labels是键值对，通常用于查找和鉴别特定的对象，其key定义为如下形式：

	* label-key ::= prefixed-name | name
	* prefixed-name ::= prefix '/' name
	* prefix ::= DNS_SUBDOMAIN
	* name ::= DNS_LABEL

	prefix是可选的，如果没有指定prefix，则认为这个key是用户私有的，其他系统需要使用这个key必须指定prefix以进行区分。

###4. NodeSpec
	
	type NodeSpec struct {
		PodCIDR string `json:"podCIDR,omitempty"`		
		ExternalID string `json:"externalID,omitempty"`
		Unschedulable bool `json:"unschedulable,omitempty"`
	}
NodeSpec用于描述一个被创建的节点的属性，其中

* PodCIDR：PodCIDR表示在此节点上Pod可用的IP范围；
* ExternalID：ExternalID通常由cloud提供商指定，如果没有cloud提供商，则被设置为节点IP地址；
* Unschedulable：Unschedulable用于控制新建的Pod是否可以调度到该节点，默认是可以调度的。

###5. NodeStatus

	type NodeStatus struct {
		Capacity ResourceList `json:"capacity,omitempty"`
		Phase NodePhase `json:"phase,omitempty"`
		Conditions []NodeCondition `json:"conditions,omitempty"`
		Addresses []NodeAddress `json:"addresses,omitempty"`
		NodeInfo NodeSystemInfo `json:"nodeInfo,omitempty"`
	}
NodeStatus包含节点当前的状态信息，主要如Capacity、Phase、Conditions、Addresses以及NodeInfo。

* Capacity：Capacity表示当前该节点可用的资源，主要资源包括CPU、Memory及Storage，它们是通过ResourceList设置该节点的CPU、Memory、Storage资源信息。
* Phase：Phase表示当前该节点的生命周期状态信息，现今k8s定义了三种Phase信息：Pending，意味着该节点已加入k8s集群，但未配置；Running，意味着该节点已加入k8s集群，且已配置成k8s集群的一部分；Terminated表示改节点已从k8s集群移除。
* Conditions

		type NodeCondition struct {
			Type               NodeConditionType `json:"type"`
			Status             ConditionStatus   `json:"status"`
			LastHeartbeatTime  util.Time         `json:"lastHeartbeatTime,omitempty"`
			LastTransitionTime util.Time         `json:"lastTransitionTime,omitempty"`
			Reason             string            `json:"reason,omitempty"`
			Message            string            `json:"message,omitempty"`
		}
Conditions表示当前节点condtions信息，如Type，表示kubelet是否健康，是否可以接受调度的pods；而Status有3种状态：ConditionTrue、ConditionFalse、ConditionUnknown，分别表示某种资源满足条件、不满足及未知。其他如最后一次对节点的probe时间等信息。
* Addresses：如果指定了cloud provider，Addresses是从cloud provider查询得到。NodeAddress定义如：
			
		type NodeAddress struct {
			Type    NodeAddressType `json:"type"`
			Address string          `json:"address"`
		}
k8s提供了4种NodeAddressType：LegacyHostIP、Hostname、ExternalIP及InternalIP。
* NodeSystemInfo：NodeSystemInfo是当前节点系统的详细信息，如果machineID、uuid、kernel版本等，详细如下：

		type NodeSystemInfo struct {
			MachineID string `json:"machineID"`
			SystemUUID string `json:"systemUUID"`
			BootID string `json:"bootID"`
			KernelVersion string `json:"kernelVersion""`			
			OsImage string `json:"osImage"`
			ContainerRuntimeVersion string `json:"containerRuntimeVersion"`
			KubeletVersion string `json:"kubeletVersion"`
			KubeProxyVersion string `json:"kubeProxyVersion"`
		}

