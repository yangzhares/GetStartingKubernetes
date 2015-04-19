## Kubernetes Pod Part 1

###1. Pod
	type Pod struct {
		TypeMeta   `json:",inline"`
		ObjectMeta `json:"metadata,omitempty"`
		Spec PodSpec `json:"spec,omitempty"`
		Status PodStatus `json:"status,omitempty"`
	}
	
Pod是容器的集合，是k8s中最小的可部署的管理单元，即可作为创建、更新的输入信息，也可作为列出和获取的输出信息，运行在同一Pod中的应用程序彼此可见、共享相同的IP地址和port空间、可使用SystemV IPC和POSIX消息队列通讯及共享同一个hostname。像Node一样，Pod也包含TypeMeta和ObjectMeta元数据，在k8s中，每个对象包含有TypeMeta和ObjectMeta元数据，在此就不再讲述，如需可查看[Kubernetes Node Part 1](https://github.com/yangzhares/GetStartingKubernetes/blob/master/k8s/kubernetes_node_part-1.md)。下面我们主要讲述Pod的PodSpec和PodStatus：
###2. PodSpec
PodSpec定义了Pod的具体行为，包括：Pod使用的Volume，Pod中定义了多少Container，Pod的重启策略，DNS策略，Node选择器，还有可以将Pod调度到指定的host以及是否使用主机网络namespace。

	type PodSpec struct {
		Volumes []Volume `json:"volumes"`
		Containers    []Container   `json:"containers"`
		RestartPolicy RestartPolicy `json:"restartPolicy,omitempty"`
		DNSPolicy DNSPolicy `json:"dnsPolicy,omitempty"`
		NodeSelector map[string]string `json:"nodeSelector,omitempty"`
		Host string `json:"host,omitempty"`
		HostNetwork bool `json:"hostNetwork,omitempty"`
	}
现分别讲述PodSpec的组件：

* Volumes：Pod中所有容器共享该Volume，其可被Pod中所有容器访问，Volume由代表Volume的Name和Volume的mount位置的VolumeSource构成，
	
		type Volume struct {
			Name string `json:"name"`
			VolumeSource `json:",inline,omitempty"`
		}

	当前VolumeSource有：

	* HostPathVolumeSource
	* EmptyDirVolumeSource
	* GCEPersistentDiskVolumeSource
	* AWSElasticBlockStoreVolumeSource
	* GitRepoVolumeSource
	* SecretVolumeSource
	* NFSVolumeSource
	* ISCSIVolumeSource
	* GlusterfsVolumeSource

	对每个Volume在此不会详细的讲解，后面会有一节专门讲解Volume。
* Containers：Containers是Pod包含的所有容器，所有这些容器共享相同的network namespace以及Volume，每个容器定义了其相关的信息，如容器的名字、使用的镜像、程序执行的命令等。

		type Container struct {
			Name string `json:"name"`
			Image string `json:"image"`
			Command []string `json:"command,omitempty"`
			Args []string `json:"args,omitempty"`
			WorkingDir string          `json:"workingDir,omitempty"`
			Ports      []ContainerPort `json:"ports,omitempty"`
			Env        []EnvVar        `json:"env,omitempty"`
			Resources      ResourceRequirements `json:"resources,omitempty"`
			VolumeMounts   []VolumeMount        `json:"volumeMounts,omitempty"`
			LivenessProbe  *Probe               `json:"livenessProbe,omitempty"`
			ReadinessProbe *Probe               `json:"readinessProbe,omitempty"`
			Lifecycle      *Lifecycle           `json:"lifecycle,omitempty"`
			TerminationMessagePath string `json:"terminationMessagePath,omitempty"`			
			Privileged bool `json:"privileged,omitempty"`
			ImagePullPolicy PullPolicy `json:"imagePullPolicy"`
			Capabilities Capabilities `json:"capabilities,omitempty"`
		}
	通过上面关于容器的定义，我们可以将其属性分为2部分，一部分是必须需要的，一部分是可选的。其中Name、Image、TerminationMessagePath、ImagePullPolicy是必须需要的，剩下的是可选的，下面会对其中一些属性进行详解：
	* Command&Args：如果没有提供Command，则image的entrypoint将会被使用；如果没有设置Args，则image中cmd的参数将被使用。对Command&Args，一旦容器运行后，不能再更改。
	* ImagePullPolicy：PullPolicy描述下载image时的策略，k8s定义了3种策略：PullAlways，kubelet总是从registry下载最新的image，如果不能下载，则创建容器失败；PullNever，kubelet总是使用本地image而不下载image，如果本地image不存在，则创建容器失败；PullIfNotPresent，kubelet首先检测image是否在本地存在，如果存在，则不下载，如果不存在，则从registry下载最新image，当本地不存在image和从registry下载image失败时，则创建容器失败。
	* Ports：ContainerPort描述单个容器的网络端口，包括HostPort和ContainerPort以及支持的网络Protocol。
			
			type ContainerPort struct {
				Name string `json:"name,omitempty"`				
				HostPort int `json:"hostPort,omitempty"`
				ContainerPort int `json:"containerPort"`
				Protocol Protocol `json:"protocol,omitempty"`
				HostIP string `json:"hostIP,omitempty"`
			}
	其中ContainerPort和Protocol属性是必须的，其他是可选的。
	* Resources：ResourceRequirements描述Pod的计算资源需求情况，
			
			type ResourceRequirements struct {
				Limits ResourceList `json:"limits,omitempty"`
				Requests ResourceList `json:"requests,omitempty"`
			}
	从上可知包括2部分，一部分描述Pod的最大资源需求，另一部分描述Pod的最小资源需求。
	* VolumeMounts：VolumeMount描述容器中Volume的mount点信息，包括mount点的名字、读写权限以及mount路径。
	
			type VolumeMount struct {
				Name string `json:"name"`
				ReadOnly bool `json:"readOnly,omitempty"`
				MountPath string `json:"mountPath"`
			}
	其中Name必须和Volume中定义的Name相同。
	* LivenessProbe&ReadinessProbe：Probe用于每隔一段时间探测容器的liveness/readiness，其包含一Handler，主要负责容器的健康检测工作，有3种方式：ExecAction，通过执行某种命令；HTTPGetAction，发送HTTP请求；TCPSocketAction，检测TCP端口是否监听。对LivenessProbe为nil或者从创建容器到当前时间差还不超过InitialDelaySeconds的情况，则认为检测liveness成功，认为容器是健康的，其他情况通过上述3种方式检测。对ReadinessProbe为nil的情况，则认为检测容器的readiness成功，如果从容器创建到当前时间差不超过InitialDelaySeconds的情况，则认为检测容器readiness失败，其他情况也通过上述3种方式检测。
		
			type Probe struct {
				Handler `json:",inline"`
				InitialDelaySeconds int64 `json:"initialDelaySeconds,omitempty"`
				TimeoutSeconds int64 `json:"timeoutSeconds,omitempty"`
			}
	* Lifecycle：Lifecycle描述k8s对容器生命周期事件采取的动作，包括PostStart和PreStop，当新建容器后，PostStart会被立即调用，如果PostStart处理失败，容器会被立即终止并重启，而在容器被终止之前，PreStop会被立即调用，容器终止的原因会传递给PreStop，无论PreStop的输出结果是什么，容器最终会被终止。
	* Capabilities：Capabilities的具体信息参考[Kuberentes官方介绍](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/containers.md#capabilities)，通过这个属性对运行的容器添加和删除Capabilities。
	
* RestartPolicy：RestartPolicy描述Pod中所有容器的重启策略，k8s定义3种重启策略：RestartPolicyAlways，RestartPolicyOnFailure，RestartPolicyNever，对这3种策略的详解可参考[Kubernetes官方介绍](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/pod-states.md#examples)。默认情况下使用RestartPolicyAlways策略。
* DNSPolicy：DNSPolicy定义怎样配置Pod的DNS，k8s定义了2中DNSPolicy：DNSClusterFirst和DNSDefault。DNSClusterFirst表示如果Cluster DNS可用，则优先使用Cluster DNS，若不可用，则使用kubelet确定的DNS设置；DNSDefault表示使用kubelet确定的DNS设置。默认DNSPolicy设置为DNSClusterFirst。
* NodeSelector：NodeSelector使得当向一个节点调度Pod时，NodeSelector选择器必须为true，否则不能将Pod调度到节点。
* Host：Host使得可以向指定的节点调度Pod。
* HostNetwork：如果HostNetwork为true，则表示该Pod使用主机网络namespace，而且ContainerPort的HostPort必须设置。默认情况下HostNetwork为false。

###3. PodStatus
PodStatus表示该Pod的状态信息，包括Phase、Conditions、Message、HostIP、PodIP及ContainerStatuses，需注意的是该信息可能相对延迟于系统信息。

	type PodStatus struct {
		Phase      PodPhase       `json:"phase,omitempty"`
		Conditions []PodCondition `json:"Condition,omitempty"`
		Message string `json:"message,omitempty"`
		HostIP string `json:"hostIP,omitempty"`
		PodIP  string `json:"podIP,omitempty"`
		ContainerStatuses []ContainerStatus `json:"containerStatuses,omitempty"`
	}
下面介绍PodStatus的各个属性：

* Phase：PodPhase表示Pod当前的状态，k8s定义了5种状态：
	* PodPending，该状态意味着Pod已经被k8s系统接受，但是可能其中的一个或多个容器还没有开始运行，该等待时间包括将Pod绑定到节点和从registry下载image的时间；
	* PodRunning，该状态意味着Pod已经被绑定到一节点，所有容器已经处于运行状态；
	* PodSucceeded，该状态意味着所有容器以退出码为0终止运行，而且系统也不会再重启这些容器；
	* PodFailed，该状态意味着所有容器已终止，但至少有一个容器以非0退出码终止；
	* PodUnknown，该状态意味着因为一些原因不能获取Pod的状态信息，可能是运行Pod的host发生通信问题。
	
* Conditions：PodCondition包含PodConditionType及ConditionStatus，
	
		type PodCondition struct {
			Type   PodConditionType `json:"type"`
			Status ConditionStatus  `json:"status"`
		}
 当前k8s定义了一种PodConditionType，即PodReady，该PodConditionType表示Pod已经可以加入到匹配该服务的loadbalance队列中提供服务请求。ConditionStatus包括ConditionTrue、ConditionFalse及ConditionUnknown。
 * Message：描述Pod在当前状态的详细信息。
 * HostIP：表示Pod绑定到该host。
 * PodIP：表示该Pod的IP地址，所有Pod中的容器共享这个IP地址。
 * ContainerStatuses：ContainerStatuses描述Pod中每个容器的详细信息，具体参考其定义：
 	
 		type ContainerStatus struct {
			Name string `name of the container; must be a DNS_LABEL and unique within the pod; cannot be updated"`
			State                ContainerState `json:"state,omitempty"`
			LastTerminationState ContainerState `json:"lastState,omitempty"`
			Ready bool `json:"ready"`
			RestartCount int `json:"restartCount"`
			Image       string `json:"image"`
			ImageID     string `json:"imageID"`
			ContainerID string `json:"containerID,omitempty"`
		}
对每个属性讲解如下：
	* Name：表示容器的名字；
	* State&LastTerminationState：ContainerState描述容器的状态，主要包括：
		* ContainerStateWaiting：描述容器等待的原因；
		* ContainerStateRunning：描述容器从什么时候开始运行；
		* ContainerStateTerminated：描述容器退出时的退出码、信号、原因、容器的开始时间及终止时间以及容器ID。
	* Ready：只是容器是否可以提供服务；
	* RestartCount：表示容器重启次数；
	* Image&ImageID：表示该容器使用的image和imageID；
	* ContainerID：当前容器的ID。
	