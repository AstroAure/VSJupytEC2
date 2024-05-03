#!/bin/bash
sed -i -E "s/HostName (.*)/HostName $1/" /PATH/TO/SSH-CONFIG
