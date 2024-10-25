```sh
rm -rf idea*
export BUILD_VERSION=243.20847.40

wget https://download.jetbrains.com/idea/ideaIU-$BUILD_VERSION.tar.gz -O idea.tar.gz

tar -xzf idea.tar.gz

CWM_HOST_STATUS_OVER_HTTP_TOKEN=gitpod "./idea-IU-$BUILD_VERSION/bin/remote-dev-server.sh" run /workspace/test/test

# curl http://127.0.0.1:63342/codeWithMe/unattendedHostStatus?token=gitpod
# code ~/.cache/JetBrains/IntelliJIdea2024.3/log/idea.log
# lsof | grep 2009 | grep "(LISTEN)" | code -
```

Replace `243.20847.40` to a target build when needed:

- 243.21155.17: https://download.jetbrains.com/idea/ideaIU-243.21155.17.tar.gz
- 243.20847.40
- 243.19420.21: https://download.jetbrains.com/idea/ideaIU-243.19420.21.tar.gz