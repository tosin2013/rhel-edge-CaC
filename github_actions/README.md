# Configure Enviornment Using GitHub Actions

## Configure Server to run pipeline against 
```
github_actions/copy-keys.sh   <username@host.com> <your_email@example.com>
```

## Configure GitHub Actions Secretes
*Under https://github.com/yourrepo/rhel-edge-CaC/settings/secrets/actions*
![20230614094258](https://i.imgur.com/JoiLGIK.png)

![20230614094321](https://i.imgur.com/QYtpePt.png)

![20230614094349](https://i.imgur.com/FZPnO36.png)

![20230614094409](https://i.imgur.com/7iHJZvg.png)

![20230614141452](https://i.imgur.com/9ytWG7K.png)
![20230614141541](https://i.imgur.com/EEsIl24.png)
![20230614174300](https://i.imgur.com/CHuySnG.png)
![20230614141724](https://i.imgur.com/3J3K8JH.png)


## Configure OpenShift GitHub Actions Runner Chart
*Use this link for self hosted runners.*
* https://github.com/redhat-actions/openshift-actions-runner-chart

WIP - https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstepsrun
```
curl \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer XXXXXXXXXX"\
    https://api.github.com/repos/tosin2013/rhel-edge-CaC/actions/workflows/pipeline-run/dispatches \
    -d '{"ref":"main", "inputs": { "name":"Command Line User", "home":"CLI" }}'
```
