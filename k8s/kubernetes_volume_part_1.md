## Kubernetes Volume Part 1

###1. Volume
Volume是可被容器访问的文件目录，也许该文件目录包含有数据，k8s中通过ContainerManifest指定需要的Volume。对k8s中的Volume，其跟Docker Volume即相似又有不同之处。在容器中，进程能看到的文件系统有2部分组成，一个Docker Image和0个或多个Volume组成，Docker Image是根文件系统，任何Volume都是挂载在Docker Image之上，Volume不会挂载在其他Volume之上，当然也不会跟链接到其他Volume。在Pod中，每个容器可以通过VolumeMounts属性相互独立地挂载在它的Image之上。下面首先看Volume的定义，然后会详细介绍每种Volume。
	
	type Volume struct {
		Name string `json:"name"`
		VolumeSource `json:",inline,omitempty"`
	}
从定义可知每个Volume需有相应的Name，以及定义Volume使用何种类型的VolumeSource，对VolumeSource，当前k8s支持多种不同的Volume Plugin，但是只能选择其中一种挂载到Pod，不能同时选择多种。
	
	type VolumeSource struct {
		HostPath *HostPathVolumeSource `json:"hostPath"`
		EmptyDir *EmptyDirVolumeSource `json:"emptyDir"`
		GCEPersistentDisk *GCEPersistentDiskVolumeSource `json:"gcePersistentDisk"`
		AWSElasticBlockStore *AWSElasticBlockStoreVolumeSource `json:"awsElasticBlockStore"`
		GitRepo *GitRepoVolumeSource `json:"gitRepo"`
		Secret *SecretVolumeSource `json:"secret"`
		NFS *NFSVolumeSource `json:"nfs"`
		ISCSI *ISCSIVolumeSource `json:"iscsi"`
		Glusterfs *GlusterfsVolumeSource `json:"glusterfs"`
	}
接下来对每种VolumeSource进行分析讲解：

####1.1. HostPathVolumeSource
	type HostPathVolumeSource struct {
		Path string `json:"path"`
	}
HostPathVolumeSource定义将host目录映射到Pod，通常使用这种方式是因为做一些特权事情或者是系统客户端需要访问host目录或文件，大部分情形下不需要这种方式。而且k8s正在对谁能挂载host目录及哪些host目录能被挂载做一些限制的尝试。

####1.2. EmptyDir
当新建的Pod绑定到特定节点后EmptyDir被创建，Pod中的所有容器可以对EmptyDir中的文件进行读写，一旦Pod从该节点解绑定，则EmptyDir被永久删除。通常EmptyDir主要用于做缓存空间，如基于磁盘的合并排序和长时间的checkpoints运算，还有如Pod中内容管理容器负责填充内容，而消耗容器如webserver容器负责消耗填充的内容。当前，用户可以指定EmptyDir使用何种存储媒介，默认所有的EmptyDir都创建在本地硬盘上，当使用tmpfs时，可以指定存储媒介为内存。
	
	type EmptyDirVolumeSource struct {
		Medium StorageType `json:"medium"`
	}
EmptyDirVolumeSource定义使用何种存储介质Medium，当前k8s支持2种媒介：StorageTypeDefault和StorageTypeMemory，StorageTypeDefault是默认方式，使用本地硬盘，而StorageTypeMemory使用内存。

####1.3. GCEPersistentDiskVolumeSource
GCEPersistentDiskVolumeSource表示将GCE Disk挂载到Kubelet节点上，而且只能挂载一个节点，然后暴露给相应的Pod。
	
	type GCEPersistentDiskVolumeSource struct {
		PDName string `json:"pdName"`
		FSType string `json:"fsType,omitempty"`
		Partition int `json:"partition,omitempty"`
		ReadOnly bool `json:"readOnly,omitempty"`
	}
使用GCE PD需要注意的是在将其挂载给容器时必须存在，而且PD须跟Kubelet节点有相同的zone和GCE Project。从上可知，定义一PD需指定名字PDName，文件系统FSType，Disk分区Partition以及PD的读写权限ReadOnly，默认ReadOnly为false。
####1.4. AWSElasticBlockStoreVolumeSource
AWSElasticBlockStoreVolumeSource是将AWS Elastic Block存储挂载到Kubelet节点上，然后暴露给相应的Pod。
	
	type AWSElasticBlockStoreVolumeSource struct {
		VolumeID string `json:"volumeID"`
		FSType string `json:"fsType,omitempty"`
		Partition int `json:"partition,omitempty"`
		ReadOnly bool `json:"readOnly,omitempty"`
	}
AWS Elastic Block的具体使用要求跟GCE PD相似。

####1.5. GitRepoVolumeSource
故名思议，GitRepoVolumeSource表示特定版本的Git Repo，其实质是当Pod创建时根据Repo URL将指定版本的Repo从Git上pull下来。

	type GitRepoVolumeSource struct {
		Repository string `json:"repository"`
		Revision string `json:"revision"`
	}

####1.6. SecretVolumeSource
`secret`是用于存储敏感信息，如密码、OAuth tokens、ssh keys等，通过把这些信息放在`secret`里比直接放在Pod定义或者Dock Image里更加安全及灵活。

	type Secret struct {
		TypeMeta   `json:",inline"`
		ObjectMeta `json:"metadata,omitempty"`
		Data map[string][]byte `json:"data,omitempty"`
		Type SecretType `json:"type,omitempty"`
	}
对Secret的Data属性，其存储`secret`数据，它的key必须是合法的[DNS_SUBDOMAIN](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/design/identifiers.md)，数据基于base64加密，整个数据大小不能超过1024*1024字节。k8s还给`secret`定义了SecretType，当前支持SecretTypeOpaque，表示任意用户定义的数据。`secret`的详细使用可参考[这里](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/secrets.md)。

	type SecretVolumeSource struct {
		SecretName string `json:"secretName"`
	}
SecretVolumeSource的SecretName须和Secret定义的Name一致。

####1.7. NFSVolumeSource
NFSVolumeSource表示暴露给Pod的NFS挂载点，其定义如：
	
	type NFSVolumeSource struct {
		Server string `json:"server"`
		Path string `json:"path"`
		ReadOnly bool `json:"readOnly,omitempty"`
	}
NFSVolumeSource指定了提供NFS存储的Server地址，NFS挂载路径以及读写权限，详细参考这个[例子](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/examples/nfs)。

####1.8. ISCSIVolumeSource
同GCE PD一样，ISCSI Disk只能被挂载一节点，
	
	type ISCSIVolumeSource struct {
		TargetPortal string `json:"targetPortal,omitempty"`
		IQN string `json:"iqn,omitempty"`
		Lun int `json:"lun,omitempty"`
		FSType string `json:"fsType,omitempty"`
		ReadOnly bool `json:"readOnly,omitempty"`
	}
从上可知，ISCSIVolumeSource定义了使用ISCSI存储时需要具备哪些条件，其中包括TargetPortal，即ISCSI的目标portal，该portal既可以是IP地址，此时端口是默认的，也可以是IP:Port的形式；IQN是目标ISCSI的合法名字；Lun是目标ISCSI的lun序号；FSType表示挂载时的文件系统；ReadOnly表示读写权限，具体如何使用可参考该[例子](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/examples/iscsi)。

####1.9. GlusterfsVolumeSource
GlusterfsVolumeSource表示挂载到Kubelet节点的Glusterfs挂载点信息，
	
	type GlusterfsVolumeSource struct {
		EndpointsName string `json:"endpoints"`
		Path string `json:"path"`
		ReadOnly bool `json:"readOnly,omitempty"`
	}
其定义了Glusterfs的EndpointsName，挂载点路径以及读写权限，[例子](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/examples/glusterfs)给出如何使用Glusterfs Volume，需注意的是使用Glusterfs时有个Bug，具体查看[这里](https://github.com/GoogleCloudPlatform/kubernetes/issues/7317)。

##2. PersistentVolume
PersistentVolume跟Volume很相似，但PersistentVolume只有管理员可以创建。

	type PersistentVolume struct {
		TypeMeta   `json:",inline"`
		ObjectMeta `json:"metadata,omitempty"`
		Spec PersistentVolumeSpec `json:"spec,omitempty"`
		Status PersistentVolumeStatus `json:"status,omitempty"`
	}
其中PersistentVolumeSpec定义cluster拥有的Persistent Volume的详细信息，具体如：
	
	type PersistentVolumeSpec struct {
		Capacity ResourceList `json:"capacity`
		PersistentVolumeSource `json:",inline"`
		AccessModes []AccessModeType `json:"accessModes,omitempty"`
		ClaimRef *ObjectReference `json:"claimRef,omitempty"`
	}
对PersistentVolumeSpec的每个属性：

* Capacity：ResourceList表示Volume的实际资源容量；
* PersistentVolumeSource：跟VolumeSource相似，表示Volume的挂载点和类型，当前PersistentVolume包括GCEPersistentDiskVolumeSource、AWSElasticBlockStoreVolumeSource、HostPathVolumeSource及GlusterfsVolumeSource，在创建GlusterfsVolumeSource时，你只能设置其中的一个属性。

		type PersistentVolumeSource struct {
			GCEPersistentDisk *GCEPersistentDiskVolumeSource `json:"gcePersistentDisk"`
			AWSElasticBlockStore *AWSElasticBlockStoreVolumeSource `json:"awsElasticBlockStore"`
			HostPath *HostPathVolumeSource `json:"hostPath"`
			Glusterfs *GlusterfsVolumeSource `json:"glusterfs"`
		}
* AccessModes：k8s当前定义了几种AccessModeType：ReadWriteOnce，只能被挂载到一个节点；ReadOnlyMany，可以被挂载到多个节点，但只能被读取；ReadWriteMany，可以被挂载到多个节点，而且可读写。
* ClaimRef：ClaimRef是PersistentVolumeClaim的引用。

而PersistentVolumeStatus，主要描述PersistentVolume处于哪一阶段，
	
	type PersistentVolumeStatus struct {
		Phase PersistentVolumePhase `json:"phase,omitempty"`
	}
当前k8s对PersistentVolumePhase定义了3个阶段：VolumeAvailable，指示Volume处于可用阶段，但是还没有绑定；VolumeBound，指示Volume已绑定；VolumeReleased，指示绑定的Volume被释放，释放后的Volume在重新处于可用之前必须被回收。

##3. PersistentVolumeClaim
PersistentVolumeClaim表示用户请求申请PersistentVolume，

	type PersistentVolumeClaim struct {
		TypeMeta   `json:",inline"`
		ObjectMeta `json:"metadata,omitempty"`
		Spec PersistentVolumeClaimSpec `json:"spec,omitempty"`
		Status PersistentVolumeClaimStatus `json:"status,omitempty"`
	}
下面看PersistentVolumeClaim的两个主要的属性：

* Spec：PersistentVolumeClaimSpec描述存储设备的共同属性，并允许指定一些特定属性。
		
		type PersistentVolumeClaimSpec struct {
			AccessModes []AccessModeType `json:"accessModes,omitempty"`
			Resources ResourceRequirements `json:"resources,omitempty"`
		}
其中AccessModes指定AccessModes，而Resources指定计算资源的最小请求。
* Status：PersistentVolumeClaimStatus描述PersistentVolumeClaim的实际状态信息，主要包括：

		type PersistentVolumeClaimStatus struct {
			Phase PersistentVolumeClaimPhase `json:"phase,omitempty"`
			AccessModes []AccessModeType `json:"accessModes,omitempty`
			Capacity ResourceList `json:"capacity,omitempty"`
			VolumeRef *ObjectReference `json:"volumeRef,omitempty"`
		}
	* Phase：PersistentVolumeClaimPhase定义PersistentVolumeClaim所处的阶段，当前k8s有2种阶段：ClaimPending，其只是PersistentVolumeClaim还没有被绑定；ClaimBound，只是PersistentVolumeClaim已被绑定；
	* AccessModes：见上面；
	* Capacity：ResourceList描述当前实际Volume容量；
	* VolumeRef：VolumeRef是绑定到PersistentVolumeClaim的PersistentVolume引用。
