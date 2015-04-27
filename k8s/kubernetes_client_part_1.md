##Kubernetes Client Part 1

###1. Request
位置：pkg/client/request.go

k8s中Client是以链式的方式构建Request到APIServer，整个过程中所有错误信息一直存储，直到调用结束，因此只需对错误信息做一次检查。下面看Request的定义：

	type Request struct {
		client  HTTPClient
		verb    string
		baseURL *url.URL
		codec   runtime.Codec

		namespaceInQuery bool
		preserveResourceCase bool

		path    string
		subpath string
		params  url.Values
		headers http.Header

		namespace    string
		namespaceSet bool
		resource     string
		resourceName string
		subresource  string
		selector     labels.Selector
		timeout      time.Duration

		apiVersion string
		
		err  error
		body io.Reader
		
		req  *http.Request
		resp *http.Response
	}
对整个Request，我们分几部分来讲解，
	
* 必须部分：这部分包括client、verb、baseURL、codec、namespaceInQuery及preserveResourceCase，它们提供了Request的请求方法，基本URL及解码及编码方法。
* 可以通过Setter方法设置的通用不封，这部分包括：path、subpath、params及headers。
* 请求的结构化元素部分，它们是k8s API约定的一部分，包括：namespace、namespaceSet、resource、resourceName、resourceName、selector及timeout，还有apiVersion。
* 输出部分，这部分包括：err和body。
* 请求和响应部分：req和resp。

Request的一些主要方法：

* func NewRequest(client HTTPClient, verb string, baseURL \*url.URL, apiVersion string, codec runtime.Codec, namespaceInQuery bool, preserveResourceCase bool) \*Request，该方法构建一个访问APIServer的runtime.Objects的Request。
* func (r \*Request) Prefix(segments ...string) \*Request：该方法在访问路径之前添加一些前缀，添加动作需在设置Namespace，Resource和Name之前，最后设置AbsPath会覆盖先前设置的前缀。
* func (r \*Request) Suffix(segments ...string) \*Request：该法在子路径后添加后缀，添加动作需在设置Namespace，Resource和Name之后执行。
* func (r \*Request) Resource(resource string) \*Request：该方法设置需要访问的资源(\<resource\>/[ns/\<namespace\>/]\<name\>)。
* func (r \*Request) SubResource(subresources ...string) \*Request：该方法在资源路径后后缀之前设置子资源路径，可能包含多部分。
* func (r \*Request) Name(resourceName string) \*Request：该方法设置资源名字(\<resource\>/[ns/\<namespace\>/]\<name\>)。
* func (r \*Request) Namespace(namespace string) \*Request：该方法设置namespace(\<resource\>/[ns/\<namespace\>/]\<name\>)。
* func (r \*Request) NamespaceIfScoped(namespace string, scoped bool) \*Request：如果scoped为true，调用Namespace设置namespace。
* func (r \*Request) AbsPath(segments ...string) \*Request：该方法根据提供的segments覆盖已存在的路径，结尾的斜杠会保留。
* func (r \*Request) RequestURI(uri string) \*Request：该方法根据提供的相对url覆盖已存在的路径和参数。
* func (r \*Request) FieldsSelectorParam(s fields.Selector) \*Request：该方法将给定的field selector作为作为查询参数。
* func (r \*Request) LabelsSelectorParam(s labels.Selector) \*Request：该方法将给定的label selector作为查询参数。
* func (r \*Request) UintParam(paramName string, u uint64) \*Request：该方法用给定的值设置查询参数。
* func (r \*Request) Param(paramName, s string) \*Request：类似UintParam。
* func (r \*Request) setParam(paramName, value string) \*Request：该方法设置参数。
* func (r \*Request) Body(obj interface{}) \*Request：该方法以obj设置body参数。
* func (r \*Request) finalURL() string：该方法返回最终的URL。
* func (r \*Request) Watch() (watch.Interface, error)：该方法监测请求的位置。
* func (r \*Request) Stream() (io.ReadCloser, error)：该方法格式化并执行请求，返回的io.ReadCloser用作响应的流，任何非2xx返回状态码即产生错误，如果非2xx错误码会尝试将响应body转化为api.Status，否则返回响应的状态码及响应内容。
* func (r \*Request) Upgrade(config \*Config, newRoundTripperFunc func(\*tls.Config) httpstream.UpgradeRoundTripper) (httpstream.Connection, error)：该函数升级请求使其支持多路双向流，当前使用SPDY实现，也可以用HTTP/2替换。
* func (r \*Request) request(fn func(\*http.Request, \*http.Response)) error：该方法会在连接到服务器前发生错误，则返回错误信息，否则当服务器响应后，如果收到Retry-After响应，则会重试，直到获得非Retry-After响应，最后调用给定的函数处理响应。
* func (r \*Request) transformResponse(resp \*http.Response, req \*http.Request) Result：该方法将API响应转换为结构化API对象。
* func (r \*Request) Do() Result：该方法格式化并执行请求，返回一个Result对象使得更容易处理请求响应。
* func (r \*Request) DoRaw() ([]byte, error)：该方法与Do类似，只是放回原始数据。

Result对象：
Result存放调用Request.Do()的响应结果。
	
	type Result struct {
		body    []byte
		created bool
		err     error
		codec runtime.Codec
	}

###2. RESTClient
位置：pkg/client/restclient.go

RESTClient规定一系列资源路径的通用k8s API准则，对RESTClient的定义如下：

	type RESTClient struct {
		baseURL *url.URL
		apiVersion string
		LegacyBehavior bool
		Codec runtime.Codec
		Client HTTPClient
		Timeout time.Duration
		Throttle util.RateLimiter
	}
其在特定的资源路径上定义了通用REST函数如：Get，Put，Post及Delete，Codec用于控制如何对APIServer的响应解码和编码，如果想要使用旧版本的API，需设置LegacyBehavior为true。
	
	type tickRateLimiter struct {
		lock   sync.Mutex
		tokens chan bool
		ticker <-chan time.Time
		stop   chan bool
	}
	
	func NewTokenBucketRateLimiter(qps float32, burst int) RateLimiter {
		ticker := time.Tick(time.Duration(float32(time.Second) / qps))
		rate := newTokenBucketRateLimiterFromTicker(ticker, burst)
		go rate.run()
		return rate
	}

对Throttle，它是一限速器，是一虚拟接口，通过这个接口可以知道当前系统是否可以发起新的请求，是否可以接受新的请求等。tickRateLimiter通过使用令牌通方法实现了该接口。tickRateLimiter使得bust数量可以超过最大qps，但仍然维持平滑的qps速率，开始时，令牌桶有bust个令牌，接着tickRateLimiter启动一goroutine以1/qps的速率重填令牌，令牌最多能有bust个。

RESTClient的方法：

* func NewRESTClient(baseURL \*url.URL, apiVersion string, c runtime.Codec, legacyBehavior bool, maxQPS float32, maxBurst int) \*RESTClient：该方法创建RESTClient对象。
* func (c \*RESTClient) Verb(verb string) \*Request：该方法根据verb创建一新的Request对象。
* func (c \*RESTClient) Post() \*Request：该方法发起POST请求。
* func (c \*RESTClient) Put() \*Request：该方法发起PUT请求。
* func (c \*RESTClient) Patch(pt api.PatchType) \*Request：该方法发起PATH请求。
* func (c \*RESTClient) Get() \*Request：该法发起GET请求。
* func (c \*RESTClient) Delete() \*Request：该方法发起DELETE请求。
* func (c \*RESTClient) APIVersion() string：该方法返回期望使用的APIServer版本。

  