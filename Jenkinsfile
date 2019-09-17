pipeline {
    agent any
    stages {
        stage('clean workspace') {
            steps {
                sh 'rm -rf terraform*'
            }
        }
        stage('fetch terraform') {
            steps {
                sh '''
                wget https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_amd64.zip
                unzip terraform_0.12.8_linux_amd64.zip
                chmod 755 terraform
                ./terraform -version
                '''
            }
        }
        stage('test azure credentials') {
            steps {
                withCredentials([azureServicePrincipal(credentialsId: 'azurejenkins',
                                    subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                                    clientIdVariable: 'ARM_CLIENT_ID',
                                    clientSecretVariable: 'ARM_CLIENT_SECRET',
                                    tenantIdVariable: 'ARM_TENANT_ID')]) {
                    sh '''
                    az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET -t $ARM_TENANT_ID
                    ./terraform init -var-file=config.tfvars -no-color
                    ./terraform plan -var-file=config.tfvars -out=outfile -no-color
                    ./terraform apply outfile -no-color
                    '''
                }
            }
        }
    }
}
