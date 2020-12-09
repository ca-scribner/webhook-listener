# Summary

A basic REST listener to test out receiving/reacting to webhooks within a kubernetes cluster

# Local testing

Using `minikube`, the following works:

(intra-cluster communication follows:)
*	http://sereviceName.namespace.svc.cluster.local:port
*	http://webhook-listener-service.default.svc.cluster.local:5000

```
minikube start

# Build the webhook listener and put it somewhere accessible
docker build -t scribby182/webhook-listener .
docker push scribby182/webhook-listener

# Start a deployment based on the above (from dockerhub), and a service to route intra-k8s traffic to it
kubectl apply -f webhook-listener-deployment_dockerhub.yaml
kubectl apply -f webhook-listener-service.yaml

# (wait for deployment to come online, checking with)
kubectl get pods,deployments,services
# kubectl describe pod PODNAME

# Use curl to post to the listener from inside the k8s cluster
# Note that if we do this directly from our terminal, we'll be connecting from outside the cluster!  
# So instead we start a new pod using a curl docker image

# Interactively:
kubectl run -it -n default curl-image-interactive --image curlimages/curl:latest sh
# then inside the running pod: 
#   curl -v --header "Content-Type: application/json" -d "{\"value\": \"test\"}" http://webhook-listener-service.default.svc.cluster.local:5000/webhook

# in one command:
# Couldn't get this to work.  I think I couldn't figure out the quoting/escaping...
# kubectl run -n default curl-image-batch --image curlimages/curl:latest 'curl -v --header "Content-Type: application/json" -d "{"value": "test"}" http://webhook-listener-service.default.svc.cluster.local:5000/webhook'
```

# Testing on cluster

Istio gets in the way, requiring additional info.  We can start via running the following a notebook server:

```
# Start a deployment based on the above (from dockerhub), and a service to route intra-k8s traffic to it
kubectl apply -f webhook-listener-deployment.yaml
kubectl apply -f webhook-listener-service.yaml

# (wait for deployment to come online, checking with)
kubectl get pods,deployments,services
# kubectl describe pod PODNAME
```

As we're in a cluster pod we don't need to `kubectl run ...` anything.  But if we try to curl we get issues:

```
NAMESPACE="andrew-scribner"
curl -v --header "Content-Type: application/json" -d "{\"value\":\"test\"}" http://webhook-listener-service.$NAMESPACE.svc.cluster.local:5000/webhook
# Result: 
# ...
```

Justin mentioned istio needs a header with your email as the userid, something like:
`kubeflow-userid: <your-email>`

Trying this we get...

```
# with http:
curl -v --header "Content-Type: application/json" --header "kubeflow-userid: andrew.scribner@cloud.statcan.ca" -d "{\"value\":\"test\"}" http://webhook-listener-service.andrew-scribner.svc.cluster.local:5000/webhook
#	*   Trying 10.0.135.134:5000...
#	* Connected to webhook-listener-service.andrew-scribner.svc.cluster.local (10.0.135.134) port 5000 (#0)
#	> POST /webhook HTTP/1.1
#	> Host: webhook-listener-service.andrew-scribner.svc.cluster.local:5000
#	> User-Agent: curl/7.69.1
#	> Accept: */*
#	> Content-Type: application/json
#	> kubeflow-userid: andrew.scribner@cloud.statcan.ca
#	> Content-Length: 16
#	> 
#	* upload completely sent off: 16 out of 16 bytes
#	* Empty reply from server
#	* Connection #0 to host webhook-listener-service.andrew-scribner.svc.cluster.local left intact
#	curl: (52) Empty reply from server

http:
different usename:
	curl -v --header "Content-Type: application/json" --header "kubeflow-userid: andrew.scribner" -d "{\"value\":\"test\"}" http://webhook-listener-service.andrew-scribner.svc.cluster.local:5000/webhook
	-- curl: (52) Empty reply from server

https:
curl -v --header "Content-Type: application/json" --header "kubeflow-userid: andrew.scribner@cloud.statcan.ca" -d "{\"value\":\"test\"}" https://webhook-listener-service.andrew-scribner.svc.cluster.local:5000/webhook
#	*   Trying 10.0.135.134:5000...
#	* Connected to webhook-listener-service.andrew-scribner.svc.cluster.local (10.0.135.134) port 5000 (#0)
#	* ALPN, offering http/1.1
#	* successfully set certificate verify locations:
#	*   CAfile: /opt/conda/ssl/cacert.pem
#	  CApath: none
#	* TLSv1.3 (OUT), TLS handshake, Client hello (1):
#	* OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to webhook-listener-service.andrew-scribner.svc.cluster.local:5000 
#	* Closing connection 0
#	curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to webhook-listener-service.andrew-scribner.svc.cluster.local:5000 
```
