docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep '^andrew/' | awk '{print $2}' | xargs docker rmi -f
rm -f minimal_example/_github
rm -f minimal_example/github
