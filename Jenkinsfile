pipeline {
    agent any
    stages {
        stage('fetch terraform') {
            sh """
            wget https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_amd64.zip
            unzip terraform_0.12.8_linux_amd64.zip
            chmod 755 terraform
            ./terraform -version
            """
        }
        stage('test azure credentials') {
            steps {
                withCredentials([azureServicePrincipal('azurejenkins')]) {
                    sh 'az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID'
                    ./terraform plan
                }
            }
        }
    }
}

