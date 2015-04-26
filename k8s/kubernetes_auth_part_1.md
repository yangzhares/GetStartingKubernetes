##Kubernetes Auth part 1

###1. K8S Authorization and Authentication
k8s Authorization和Authentication是相互独立的的步骤， Authorization适用于apiserver端口上所有的HTTP访问。Authorization使用访问策略，通过比较请求属性(user, resource, namespace)检查任意请求，每次API调求须通过一系列策略处理后才能被允许。当前支持如下策略：

   * --authorization_mode=AlwaysDeny
   * --authorization_mode=AlwaysAllow
   * --authorization_mode=ABAC

AlwaysDeny阻止所有请求；AlwaysAllow允许任何请求；ABAC(Attribute-Based Access Control)允许用户指定的授权策略。
###2. ABAC模式
1. Request Attributes

	请求的如下属性用来作为授权信息：
	* 用户名；
	* 请求是否是只读；
	* 什么资源可以被访问，当前只可以是API endpoints，如/api/v1beta1/pods；
	* 被访问资源的namespace；
2. Policy File Format
	对ABAC模式，需指定--authorization_policy_file=SOME_FILENAME。策略文件的每行是一个没有封闭list和map的JSON对象。每行表示一个策略对象，事实上策略对象是一个映射(map)，包括：
	
	* `user`：字符串类型，从--token_auth_file读取；
	* `readonly`：boolean类型，该策略只适用于GET操作；
	* `resource`： 字符串类型，表示资源类型，如pods；
	* `namespace`：字符串类型，表示namespace；

###3. Authorization Algorithm
在k8s中，每个API请求的属性对应着一个策略对象，当k8s APIServer收到API请求时，首先检查其属性是否被设置，如果没有设置，则设置成默认空值。一个未设置的property匹配任意对应的attribute，一个未设置的attribute匹配任意对相应的property。k8s逐一检查请求的attributes元组是否匹配策略文件中的每一条策略对象，至少需要匹配一条策略对象，该请求才能被合法授权，否则，授权失败，请求是非法请求。如果任何用户都可以做任何操作，则可把策略对象的用户property设为unset。

	1. 首先检查API请求的属性对应策略对象包含的用户名和用户组是否为空，如果都为空，直接授权成功。否则需检查策略对象提供的用户名和用户组是否匹配authorizer提供的用户名和组信息，如果匹配，则授权成功，否者授权失败；
	2. 在上一步成功后，authorizer会继续检查API请求的属性对应策略对象readonly的值，如果值为false，而且策略对象没有指定resource和namespace,则所有信息都不能查看；如果指定了resource和namespace，则只是指定的namespace的resource不能查看；如果策略对象的readonly设为true，而authorizer的readonly设为false，则用户不能查看任何信息，否则，如果策略对象没有指定resource和namespace,则用户可以查看所有信息，如果指定了resource和namespace，则只能查看查看指定的namespace的resource。

###4. User
* User Name: 鉴别所有活跃用户的唯一标识符。
* UUID: 跟特定用户关联的唯一标识符，当用户被删除时，该值会改变，如果其他用户以相同的用户名加入，该值也会被修改。
* Group: 用户所在的组。

###5. Admission
* Admit：实现admission.Interface接口，总是允许admission请求；
* Deny：实现adminssion.Interface接口，总是拒绝admission请求；
* Limitranger：实现adminssion.Interface接口，Limitranger实现namespace中资源的使用限制；
* Namespace
	* provision：实现adminssion.Interface接口，其可以看到namespace中所有的进入的请求，如果namespace不存在，则新建一个；
	* exists：实现adminssion.Interface接口，如果namespace不存在，exists拒绝所有进入namespace的请求；
	* lifecycle：实现adminssion.Interface接口，根据namespace的phase确定namespace的生命周期；
* Resourcequota：实现adminssion.Interface接口，用于资源配额限制；


