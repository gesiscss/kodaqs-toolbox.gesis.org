docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep '^andrew/' | awk '{print $2}' | xargs docker rmi -f
sudo rm -f demo/_github
sudo rm -f demo/github
sudo rm -f minimal_example/_github
sudo rm -f minimal_example/github
