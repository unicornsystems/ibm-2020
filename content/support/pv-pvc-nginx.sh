#! /bin/bash

# Example of creation in on-prem cluster with PV and PVC

oc apply -f <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  nfs:
    server: kubernetes.nfs
    path: "/volumes"
EOF

oc apply -f <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
EOF


##############################################
# create nginx in IBM Cloud with PVC

oc apply -f <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-pv
spec:
  volumes:
    - name: nginx-with-pv
      persistentVolumeClaim:
        claimName: nfs-pvc
  containers:
    - name: nginx-with-pv
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: nginx-with-pv
EOF

kubernetes.master$ kubectl get pod
kubernetes.master$ echo "hello world!" > /volumes/index.html

kubernetes.master$ kubectl exec -it [nginx-pod-name] /bin/bash
nginx-pod# curl http://localhost

################################################################

# crate new project
oc new-project storage
oc create namespace storage
oc delete namespace storage

# create PVC
oc apply -f -<<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nginx-pvc
  namespace: storage
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: ibmc-file-gold
  volumeMode: Filesystem
EOF

# list pv,pvc in project
oc get pvc,pv

oc apply -f -<<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  # labels:
  #   app: nginx
spec:
  volumes:
    - name: nginx-with-pv
      persistentVolumeClaim:
        claimName: nginx-pvc
  containers:
    - name: nginx-with-pv
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: nginx-with-pv
EOF

# try run in container
oc exec -it nginx /bin/bash
  curl http://localhost


oc exec nginx -- echo "IBM world" > /usr/share/nginx/html/index.html
# add static page
oc exec -it nginx /bin/bash
  echo "IBM world!" > /usr/share/nginx/html/index.html
  curl http://localhost

# expose pod as a service
oc expose pod nginx
# expose service as a route
oc expose service nginx

# test if service run
curl nginx-storage.unicornoshift1-6bd0706b35e7120f414eb855444c8ecb-0000.eu-de.containers.appdomain.cloud 


# delete pod
oc delete pod nginx
# check which pvc exists
oc get pvc

# create again pod with manifest above ^^^^
# test if exist data that was created before pod removing
oc exec nginx -- cat /usr/share/nginx/html/index.html

# try exposed service 
curl nginx-storage.unicornoshift1-6bd0706b35e7120f414eb855444c8ecb-0000.eu-de.containers.appdomain.cloud 

# service is not available because out pod not related with exist services
# uncomment labels in POD manifest above and recreate again

# try again and service is available now
curl nginx-storage.unicornoshift1-6bd0706b35e7120f414eb855444c8ecb-0000.eu-de.containers.appdomain.cloud 

# list services and routes
oc get svc,route

# list endpoints and explain how are related to services and why automatically bind to pod...
oc get endpoints

