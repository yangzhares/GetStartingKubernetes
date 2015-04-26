## Kubernetes REST Object 

###1. Storage
Storage是k8s RESTful Storage服务的通用接口，导入到APIServer的RESTful API需实现该接口，New返回一个空的指针对象，返回指针对象是为了给Codec.DecodeInto([]byte, runtime.Object)使用，一旦客户端请求数据被存入其中，可以通过这些数据创建和更新对象。几乎所有的k8s RESTful对象都实现该接口。

	type Storage interface {
		New() runtime.Object
	}

###2. Lister
Lister用于从APIServer检索匹配field和lable准则的资源，所有的List对象都实现该接口，同Storage的New一样，也是返回指针对象。

	type Lister interface {
		NewList() runtime.Object
		List(ctx api.Context, label labels.Selector, field fields.Selector) (runtime.Object, error)
	}
	
###3. Getter
该接口主要用于检索给定名字的资源，如果不能检索不到，则返回不存在的错误信息。

	type Getter interface {
	// Get finds a resource in the storage by name and returns it.
	// Although it can return an arbitrary error value, IsNotFound(err) is true for the
	// returned error value err when the specified resource is not found.
		Get(ctx api.Context, name string) (runtime.Object, error)
	}

###4. GetterWithOptions
同Getter，但是在请求中提供了额外的选项。

	type GetterWithOptions interface {
		Get(ctx api.Context, name string, options runtime.Object) (runtime.Object, error)
		NewGetOptions() (runtime.Object, bool, string)
	}

###5. Deleter
Deleter接口从APIServer删除给定名字的资源，如果删除的资源不存在，返回删除资源不存在的错误信息。

	type Deleter interface {
	Delete(ctx api.Context, name string) (runtime.Object, error)
}

###6. GracefulDeleter
GracefulDeleter接口使得根据提供删除选项从APIServer延迟删除资源，其他跟Deleter接口一样。
	
	type GracefulDeleter interface {
		Delete(ctx api.Context, name string, options *api.DeleteOptions) (runtime.Object, error)
	}
GracefulDeleteAdapter通过Deleter实现接口GracefulDeleter。

	type GracefulDeleteAdapter struct {
		Deleter
	}
	
	func (w GracefulDeleteAdapter) Delete(ctx api.Context, name string, options *api.DeleteOptions) (runtime.Object, error) {
		return w.Deleter.Delete(ctx, name)
	}

###7. Creater
Creater接口创建RESTful对象。
	
	type Creater interface {
		New() runtime.Object
		Create(ctx api.Context, obj runtime.Object) (runtime.Object, error)
	}

###8. Updater
Updater接口更新RESTful对象。
	
	type Updater interface {
		New() runtime.Object
		Update(ctx api.Context, obj runtime.Object) (runtime.Object, bool, error)
	}

###9. CreaterUpdater
CreaterUpdater接口创建和更新既支持创建有支持更新的RESTful对象。
	
	type CreaterUpdater interface {
		Creater
		Update(ctx api.Context, obj runtime.Object) (runtime.Object, bool, error)
	}

###10. Patcher
Patcher接口支持Get和Update RESTful对象
	
	type Patcher interface {
		Getter
		Updater
	}

###11. Watcher
所有想通过Watcher接口提供的watch API监测变化的RESTful对象都应实现该接口。

	type Watcher interface {
		Watch(ctx api.Context, label labels.Selector, field fields.Selector, resourceVersion string) (watch.Interface, error)
	}

###12. StandardStorage
	
	type StandardStorage interface {
		Getter
		Lister
		CreaterUpdater
		GracefulDeleter
		Watcher
	}

###13. Redirector
Redirector接口用于返回远程资源的位置信息。
	
	type Redirector interface {
		ResourceLocation(ctx api.Context, id string) (remoteLocation *url.URL, transport http.RoundTripper, err error)
	}
	
###14. ResourceStreamer
实现该接口的对象优先采用流的方式而不是直接解码。
	
	type ResourceStreamer interface {
		InputStream(apiVersion, acceptHeader string) (stream io.ReadCloser, flush bool, mimeType string, err error)
	}

###15. StorageMetadata
	
	type StorageMetadata interface {
		ProducesMIMETypes(verb string) []string
	}
	