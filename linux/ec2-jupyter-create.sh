#!/bin/bash
ID=${1:-'YOUR-INSTANCE-ID'}
aws ec2 start-instances --instance-ids $ID
IPV4="$(aws ec2 describe-instances --instance-ids $ID --query 'Reservations[].Instances[].PublicDnsName' --output text)"
ec2-jupyter-start $IPV4
ec2-configure $IPV4