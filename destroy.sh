#!/bin/bash

# destroy all the terrafom resources
cd ./compute_env
terraform destroy --auto-approve
