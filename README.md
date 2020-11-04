## Disclaimer
This project is a proof of concept based on our perception about how a cloud infrastructure should be so it not guarantee any best practices nor any 'ready to production' examples.  
Because the project is a bit too complex and has many concepts, the documentation does not fully cover them.  
https://iservit.ro/tutorial/gcp-infrastucture-overview/
# Requirement:

We need to design a continuous delivery architecture for a scalable and secure tree tier app

### detailed:
web and api should  
- be accesible through a public ip
- autoscale
- update without downtime
- automated ci/cd
- handle instance failures
- serve static content through CDN

database should  
- not be accesible
- have daily backups
- fault tolerant

the infrastructure should present relevant  
- logs
- historical metrics ( at least the four golden signs )

# Design
> arch.png illustrates the project overview  

We choose Google Cloud to implement this infrastructure. The infrastructure will be provisioned with Terraform, database tier will be two PostgreSQL db instances which resides in different zones for high availability, backed up daily and have a 'Point in time recovery' enabled.  
The computational power will be served through a Google Kubernetes Engine in a single namespace for production, having a simple ingress to manage traffic between live and cannary deploys.  
Logging will be managed with fluentd and displayed through Kibana.  
Monitoring is setted up with Prometheus and Grafana.  
Despite that we host this code on GitHub, the CI/CD pipeline is built for GitLab. The `.gitlab-ci.yml` have some basic stages to build and push the image to Google Cloud Registry and deploy it to k8s. More info's here -> https://iservit.ro/tutorial/gitlab-ci-cd-pipeline-push-image-to-grc-and-cannary-deploy-to-gke-gcp-infrastructure-overview/

# Project setup
The following settings are tested on MacOS environment
> For a fully functional infrastructure all steps are required

1. install Cloud SDK which contains gcloud and kubectl
2. gcloud auth login
3. gcloud config set project isv-294609 - set up default project on your local machine
4. gcloud config set compute/zone europe-west4 - set up default zone where you will create the cluster

5. brew tap hashicorp/tap && brew install hashicorp/tap/terraform && terraform -install-autocomplete - install terraform

6. create GKP access key - https://console.cloud.google.com/apis/credentials/serviceaccountkey | New service account | Project -> Editor ( https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build?in=terraform/gcp-get-started )
   add 'Editor' and 'Compute Network Admin' roles

## Googleapis
### Required Google API's to be enabled
The api's are enabled by terraform, however, this are the required api's for the project
https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=isv-294609
https://console.developers.google.com/apis/api/container.googleapis.com/overview?project=isv-294609
https://console.developers.google.com/apis/api/compute.googleapis.com/overview?project=isv-294609
https://console.developers.google.com/apis/api/sqladmin.googleapis.com/overview?project=isv-294609
https://console.developers.google.com/apis/api/servicenetworking.googleapis.com/overview?project=isv-294609
gcloud projects add-iam-policy-binding isv-294609 \
    --member=serviceAccount:isv-633@isv-294609.iam.gserviceaccount.com --role=roles/servicenetworking.networksAdmin

## GStorage
Create storage bucket for terraform state
- gsutil mb -p isv-294609 -c regional -l europe-west4 gs://terraform-gstate-isv/
- gsutil versioning set on gs://terraform-gstate-isv/
- gsutil iam ch serviceAccount:isv-633@isv-294609.iam.gserviceaccount.com:legacyBucketWriter gs://terraform-gstate-isv/

## Terraform
Update terraform.tfvars file, set credentials path to local service-account.json key
- terraform plan - plan changes
- terraform apply - apply changes
- terraform taint google_compute_instance.vm_instance - mark resource to recreate

## GCloud
- gcloud container clusters get-credentials isv-294609-gke --zone europe-west4 --project isv-294609 - get credentials
	> gcloud container clusters get-credentials $CLUSTER_NAME \ --zone $PROJECT_ZONE \ --project $PROJECT_ID
	> gcloud container clusters get-credentials isv-294609-gke-cluster
- gcloud container clusters list
- gcloud compute addresses list
- gcloud compute networks describe isv-294609-gke-cluster-network-<id>
- gcloud compute networks subnets describe isv-294609-gke-cluster-network-gke-subnetwork-<id>

## Cloud SQL
- gcloud sql instances promote-replica <replica_name> - create a new instance, can't be undone
- gcloud sql instances failover <instance_name> - failover PostgreSQL instance

## Kubectl
- kubectl config current-context
- kubectl get nodes
- kubectl get all
- kubectl exec --stdin --tty -n prod web-7c4f668c7f-pptgt -- /bin/bash
- kubectl -n dev describe ingress app-ingress

### set up nginx ingress (Optional)
- kubectl create clusterrolebinding cluster-admin-binding   --clusterrole cluster-admin   --user $(gcloud config get-value account)
- kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.40.2/deploy/static/provider/cloud/deploy.yaml

### autoscaling - based on cpu averageUtilization
- kubectl -n prod get hpa

## Logging
### Set up fluentd
- kubectl create clusterrolebinding cluster-admin-binding   --clusterrole cluster-admin   --user isv-633@isv-294609.iam.gserviceaccount.com
- kubectl port-forward kibana-768c8fc454-rmzpx 5601:5601 --namespace=kube-logging | http://localhost:5601/  
    Management -> Create index -> "logstash-\*" -> Time Filter field name -> '@timestamp'
- kubect port-forward elasticsearch-69d7479778-4mvqm 9200:9200 --namespace=kube-logging | curl http://localhost:9200/_cluster/state?pretty

## Monitoring
### Set up prometheus and grafana - fresh install
The Prometheus and Grafana install from k8s/monitoring/ is working good but grafana dashboards are not available. Needs a custom json with all dashboard config in place.

### Set up prometheus and grafana - with helm
- kubectl create ns kube-monitoring
- helm repo add stable https://kubernetes-charts.storage.googleapis.com
- helm install prometheus stable/prometheus-operator --namespace kube-monitoring

### usefull commands
- kubectl --namespace kube-monitoring get pods -l "release=prometheus"
- kubectl port-forward -n kube-monitoring prometheus-prometheus-oper-operator-85cc758cdb-8c9tc 9090 - access prometheus from localhost
- kubectl --namespace kube-monitoring get pods -l "release=prometheus"
- kubectl get pod -n kube-monitoring | grep grafana
- kubectl port-forward -n kube-monitoring prometheus-grafana-86f84b5c6c-sslnk 3000 - acces grafana from localhost
- kubectl get secret -n kube-monitoring prometheus-grafana -o yaml - get Grafana credentials

## Git
Optional, create branch for all apps and add deploy.yml and cannary.yml files to app project and add two new pipelines in .gitlab-ci.yml with `when: node-api-master` commits ot tags trigger

- git checkout --orphan node-api-master           - create new empty branch
- git checkout infra-v1 -- app/api/               - copy app from infra-v1 branch
- git tag 0.0.1                                   - tag - can be included in deploy vars
- git push --tags origin

## CI/CD
**gitlab-ci.yml** defines a pipeline for test, build, push image to Google Container Registry and deploy apps to Google Kubernetes Engine.

Variables defined in GitLab -> Settings -> CI/CD -> Variables:
- $GCP_SA_KEY is the serice-account.json encoded in base64 variable defined in GitLab -> Settings -> CI/CD -> Variables.
	> To encode the json in base64: base64 project-292212-69fc45252989.json > project-292212-69fc45252989-base64.json
- $GOOGLE_CLOUD_ACCOUNT is the service account json key as file
- $CI_COMMIT_TITLE is a gitlab environment variable containing the commit title
Last step waits to manually promote deploy to production, if the cannary looks good.

# Further work
- ssl  
cert manager - https://medium.com/@betandr/kubernetes-ingress-with-tls-on-gke-744efd37e49e

- monitoring  
fix grafana-dashboard-cm ConfigMap to load and apply dashboard.json config file  
https://www.metricfire.com/blog/monitoring-kubernetes-with-prometheus/  
https://grafana.com/docs/grafana/latest/best-practices/common-observability-strategies/  
https://sysdig.com/blog/monitor-istio/  

# Some useful resources
https://kubernetes.io/docs/concepts/configuration/overview/  
https://vinta.ws/code/the-complete-guide-to-google-kubernetes-engine-gke.html  
https://github.com/epiphone/gke-terraform-example  
https://github.com/CloudNativeTech/gdg-terraform-gcp-workshop  

- sql  
https://www.terraform.io/docs/providers/google/r/sql_database_instance.html  
https://cloudywithachanceofbigdata.com/google-cloud-sql-ha-backup-and-recovery-replication-failover-and-security-for-postgresql-part-i/  

- logging  
https://mherman.org/blog/logging-in-kubernetes-with-elasticsearch-Kibana-fluentd/  
https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes#conclusion  
