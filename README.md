kubectl apply -k ./




Accessing MYSQL pod 

kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h wordpress-mysql -ppassword


Running shell in a pod -- kubectl exec --stdin --tty mysql-client -- /bin/bash