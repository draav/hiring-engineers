#!/usr/bin/env bash

echo "bootstrap.sh 1: allow apt to install through https"
sudo apt-get update
sudo apt-get install apt-transport-https

echo "bootstrap.sh 2: set up the Datadog deb repo on system and import Datadog's apt key"
sudo sh -c "echo 'deb https://apt.datadoghq.com/ stable 6' > /etc/apt/sources.list.d/datadog.list"
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 382E94DE

echo "bootstrap.sh 3: install the Agent"
sudo apt-get update
sudo apt-get install datadog-agent

echo "bootstrap.sh 4: copy the example config and plug in API key from .env"
source .env
echo "api key: $DATADOG_API_KEY"
sudo sh -c "sed 's/api_key:.*/api_key: $DATADOG_API_KEY/' /etc/datadog-agent/datadog.yaml.example > /etc/datadog-agent/datadog.yaml"

echo "bootstrap.sh 5: give agent tags"
# insert tags into already existing datadog.yaml
sudo sed -i 's/# tags:.*/tags: role:database, region:us/' /etc/datadog-agent/datadog.yaml
# change datadog default port from 5000 since python flask uses it
sudo sed -i 's/# expvar_port:.*/expvar_port: 5002/' /etc/datadog-agent/datadog.yaml

echo "bootstrap.sh 6: create postgres.yaml integration file"
#create config file inline instead of copying from example file
sudo cat > /etc/datadog-agent/conf.d/postgres.yaml <<EOF
init_config:

instances:
   -   host: localhost
       port: 5432
       username: datadog
       password: dbpass
       tags:
            - optional_tag1
            - optional_tag2
EOF

echo "bootstrap.sh 7: copy agent check files"
#create config file by copying from file stored in repo
#I think this method is the cleanest and easiest to track
sudo mv random_value.yaml /etc/datadog-agent/conf.d/random_value.yaml
sudo mv random_value.py /etc/datadog-agent/checks.d/random_value.py

echo "bootstrap.sh 8: start the datadog agent"
sudo initctl start datadog-agent

