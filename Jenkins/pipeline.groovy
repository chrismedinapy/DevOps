def serviceVersion = ""

def changeStatusInGithub(url, status, token, commit) {
    def message = status == 'pending' ? 'Build started' : status == 'success' ? 'Build successful' : 'Build failed'
    sh """curl -s -H \"Authorization: token ${token}\" -X POST -d '{ "state": "${status}", "target_url": "${url}", "description": "${message}", "context": "continuous-integration/jenkins" }' "https://api.github.com/repos/chrismedinapy/hola-mundo/statuses/${commit}" """
}

def sh_with_retry(times, script) {
    if (times <= 0) {
        error("""Failed to execute script: `${script}` after ${times} times, aborting""")
        return
    }
    try {
        sh(script)
    } catch (e) {
        println("Error: " + e)
        println("""Sleeping 30 sec and retrying (remaining attemps ${times})""")
        sleep(30)
        sh_with_retry(times - 1, script)
    }
}

pipeline {
    agent any
    environment {
        GIT_CREDENTIAL_ID="chrismedinapy-token-hola-mundo"
        GIT_CREDENTIAL_TOKEN="chrismedinapy-token-hola-mundo"
        NAME="jenkins"
        EMAIL="chrismedinapy@gmail.com"
    }
    stages {
	    stage('Clone') {
            steps {
                script {
                    def branch_selected = "$mergingBranch"
                    if (action == 'closed') {
                        branch_selected = "$targetBranch"
                    }
                    println("The branch selected is : " + branch_selected)

                    withCredentials([usernamePassword(credentialsId: env.GIT_CREDENTIAL_ID, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                        git credentialsId: env.GIT_CREDENTIAL_ID, url: 'https://github.com/chrismedinapy/hola-mundo.git', branch: "${branch_selected}"
                    }
                    //view node version
                    sh "node --version"
                }
            }
        }
	    stage ('Notify pending') {
            steps {
                script {
                    withCredentials([string(credentialsId: env.GIT_CREDENTIAL_ID_TOKEN, variable: 'TOKEN')]) {
                        env.commitSHA = sh(script:"git rev-parse --verify HEAD", returnStdout: true).trim()
                        changeStatusInGithub(env.BUILD_URL, 'pending', TOKEN, env.commitSHA)
                    }
                }
            }
        }
	
		
	stage ('Bump versions') {
        steps {
            script {
                if (targetBranch == "develop" && action == "closed" && merged == "true") {
                    def comments;
                    withCredentials([string(credentialsId: env.GIT_CREDENTIAL_ID_TOKEN, variable: 'TOKEN')]) {
                        def jsonComments = sh(script:"curl -X GET $commentsUrl -H 'Authorization: Token $TOKEN'", returnStdout: true).trim()
                        comments = readJSON text: jsonComments
                    }
  
                        comments.each {
                            def commentMessage = it.body
                            if (commentMessage == "major version") {
                                sh "yarn version --major"
                            } else if(commentMessage == "minor version"){
                                sh "yarn version --minor"
                            } else if (commentMessage == "patch version"){
                                sh "yarn version --patch"
                            }
                        }

                        def new_version = sh(script: "jq -r .version package.json", returnStdout: true).trim()
                        echo """Nueva version del servicio: $new_version"""

                    echo "Version final: "
                    echo "$new_version"
                    serviceVersion = new_version
                }
            }
        }
    }
    def appDir = 'app'
    stage ('Clean') {
           steps {
               script {
                   sh "rm -rf ${appDir}/node_modules"
                }
            }
        }
    stage ('Install Dependencies') {
           steps {
                script {
                    sh_with_retry(3, "cd ${appDir} && npm install")

                }
            }
            }
     stage ('Build') {
          steps {
               script {
                   sh_with_retry(3, "cd ${appDir} && npm run build")

                }
            }
        }       }
    stage ('Unit tests') {
          steps {
               script {
                   sh_with_retry(3, "cd ${appDir} && npm test")
                }
            }
        }

    stage ('Build image') {
        steps {
            script {
				if (targetBranch == "develop" && action == "closed" && merged == "true") {
                    dir ("$WORKSPACE") {

                        sh """
                            docker build \
                                -t 10.254.102.109:5000/admin/hola-mundo:latest \
                                -t 10.254.102.109:5000/admin/hola-mundo:${serviceVersion} .
                            """
                    }
				}
            }
        }
    }
    stage ('Push image') {
        steps {
            script {
				if (targetBranch == "develop" && action == "closed" && merged == "true") {
                    dir ("$WORKSPACE") {

                        sh """docker push 10.254.102.109:5000/admin/hola-mundo:latest"""
						sh """docker push 10.254.102.109:5000/admin/hola-mundo:${serviceVersion}"""
                    }
				}
            }
        }
    }
    stage ('Commit version') {
            when {
                expression { action == 'closed' && merged == "true" && targetBranch == "develop" }
            }
            steps {
                script {
                    def body = "";
                        def directory = WORKSPACE;
                        def name = "hola mundo"
                        sh """git add $directory/app/package.json"""
                        body += """\n${name}: version ${serviceVersion}"""
                    if (body != "") {
                        sh """git config user.email $EMAIL"""
                        sh """git config user.name $NAME"""

                        sh """git commit -m 'Automatic version \n $body'"""
                        withCredentials([usernamePassword(credentialsId: env.GIT_CREDENTIAL_ID, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                            sh """git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/chrismedinapy/hola-mundo.git"""
                        }
                    }
                }
            }
        }
}
post {
    success {
            script {
                if (env.merged == "true") {
                    echo "Ok"
                }
          }
    }
    always {
        script {
            def message = currentBuild.currentResult == 'SUCCESS' ? 'exitoso' : 'fallido'
            def githubStatus = currentBuild.currentResult == 'SUCCESS' ? 'success' : 'failure'
                withCredentials([string(credentialsId: env.GIT_CREDENTIAL_ID_TOKEN, variable: 'TOKEN')]) {
                    sh """curl -s  -H \"Authorization: token ${TOKEN}\" -X POST -d '{ "body": "Job ${message}. [Link to build](${env.BUILD_URL})" }' \
                        "https://api.github.com/repos/chrismedinapy/hola-mundo/issues/${pullRequestNumber}/comments"
                    """
                    changeStatusInGithub(env.BUILD_URL, githubStatus, TOKEN, env.commitSHA)
                }
            sh """docker image list | grep "10.254.102.109:5000/admin/hola-mundo/*" | awk '{print \$3}' | xargs -I {} docker rmi -f {} || true"""
            sh """docker image list | grep "<none>" | awk '{print \$3}' | xargs -I {} docker rmi -f {} || true"""
        }
    }
    cleanup {
        cleanWs()
        }
    }
}