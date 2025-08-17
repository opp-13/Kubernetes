helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update

helm upgrade --install sonarqube sonarqube/sonarqube \
  -f values.yaml \
  --namespace devops --create-namespace \
  --set monitoringPasscode=devpasscode