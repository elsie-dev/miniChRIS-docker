#!/bin/sh -ex
# 0. wait for CUBE to be online
# 1. create user chris:chris1234 in CUBE
# 2. add local compute environment
# 3. register pl-dircopy

docker wait cube-starting
res=$(docker inspect --format '{{ .State.ExitCode }}'  cube-starting)
if [ "$res" != "0" ]; then
  echo "Timed out waiting for ChRIS backend."
  exit 1
fi

if [ -f .setup ]; then
  echo "Already set up"
  exit 1
fi


docker exec chris python manage.py shell -c '
from core.models import ChrisInstance
inst = ChrisInstance.load()
inst.job_id_prefix = "minichris-jid-"
inst.save()'


superuser_script='
from django.contrib.auth.models import User
User.objects.create_superuser(username="chris", password="chris1234", email="dev@babymri.org")'

docker exec chris python manage.py shell -c "$superuser_script"
docker exec chris_store python manage.py shell -c "$superuser_script"

docker exec chris python plugins/services/manager.py \
  add host "http://pfcon.local:5005/api/v1/" --description "Local compute"

# pl-dircopy
docker exec chris python plugins/services/manager.py register host --pluginurl \
  https://chrisstore.co/api/v1/plugins/25/
docker pull fnndsc/pl-dircopy:2.1.0

touch .setup
