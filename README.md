```
wget https://download.jetbrains.com/idea/ideaIU-243.20847.40.tar.gz -O idea.tar.gz

tar -xzf idea.tar.gz

CWM_HOST_STATUS_OVER_HTTP_TOKEN=gitpod ./idea-IU-243.20847.40/bin/remote-dev-server.sh run /workspace/empty/test

# code ~/.cache/JetBrains/IntelliJIdea2024.3/log/idea.log
# curl http://127.0.0.1:63342/codeWithMe/unattendedHostStatus?token=gitpod
# lsof | grep 2009 | grep "(LISTEN)" | code -
```

Replace `243.20847.40` to a target build when needed