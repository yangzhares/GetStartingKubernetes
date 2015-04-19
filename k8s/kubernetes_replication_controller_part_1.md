## Kubernetes Replicationcontroller Part 1

###1. Replicationcontroller
Replicationcontroller是一系列Pod的集合，使用Replicationcontroller可确保整个系统中任何时候总是有指定数量的Pod在运行。由于单个Pod在绑定到一个host后不会再绑定到其他host，一旦该pod发生意外终止便不能再提供服务。所以即使应用程序只需要一个Pod，也建议使用Replicationcontroller，使用Replicationcontroller能保证在Pod在终止或者节点故障以及其他意外原因导致Pod不能再提供服务时重新再启动一新Pod的提供服务，使整个系统无服务中断情况发生。Replicationcontroller包含如下使用模式：

* Rescheduling：Replicationcontroller可确保整个系统中任何时候总是有指定数量的Pod在运行。
* Scaling：通过设置`replicas`可以方便的实现scale-up和scale-down。
* Rolling updates：通过一次升级一个pod实现滚动的升级服务。
* Multiple release tracks：通过`labels`可以实现多版本服务同时在系统中运行。

ReplicationController的定义如下：
	
	type ReplicationController struct {
		TypeMeta   `json:",inline"`
		ObjectMeta `json:"metadata,omitempty"`
		Spec ReplicationControllerSpec `json:"spec,omitempty"`
		Status ReplicationControllerStatus `json:"status,omitempty"`
	}
下面看ReplicationController的各个属性：

* Spec：ReplicationControllerSpec定义ReplicationControllerSpec的具体行为，其内部可表示TemplateRef和PodTemplateSpec。

		type ReplicationControllerSpec struct {
			Replicas int `json:"replicas"`
			Selector map[string]string `json:"selector"`
			TemplateRef *ObjectReference `json:"templateRef,omitempty"`
			Template *PodTemplateSpec `json:"template,omitempty"`
		}
	
	ReplicationControllerSpec的属性包括：
	
	* Replicas：Replicas表示ReplicationControllerSpec包含的Pod的数量，通过Replicas可以快速的scale-up和scale-down；
	* Selector：通过Selector可以查询到的Pod数量应等于Replicas；
	* TemplateRef：如果检测到replicas不足，TemplateRef描述的pod将被创建，若设置了Template，则TemplateRef被忽略；
	* Template：同TemplateRef一样，如果检测到replicas不足，PodTemplateSpec描述的pod将被创建，Template相对TemplateRef拥有更高的优先级。
		
			type PodTemplateSpec struct {
				ObjectMeta `json:"metadata,omitempty"`
				Spec PodSpec `json:"spec,omitempty"`
			}

