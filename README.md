# VSJupytEC2

This repository provides short bash scripts to start an [AWS EC2 instance](https://aws.amazon.com/ec2/) and automatically create a Jupyter server inside that you can easily use in VS Code to run notebooks even when you shutdown your computer.

## Prerequisites
* Have an AWS EC2 account and the ability to launch an instance
* Have created an [EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html) with a key pair you saved on your computer
* In VS Code, install the [Remote-SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extention
* Be able to run bash scripts (native on Linux, through [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) on Windows)
* Have installed `AWS CLI` where you'll execute the bash scripts. This can be done through `pip install awscli` (more infos [here](https://docs.aws.amazon.com/cli/v1/userguide/install-linux.html))

## Installation

TO DO

## Workflow and scripts

The following part presents the workflow to start an EC2 instance using bash commands, connect to it through VS Code, start a Jupyter server on the instance, use the server in VS Code to run Jupyter notebooks.

It will start with the higher level workflow. The sub-commands used in each script are described after.

### 1. Create the Jupyter server in EC2

The following script :
* starts your EC2 instance (replace `YOUR-EC2-ID` with the instance ID you want to use, and which can be found in your EC2 instances dashboard),
* recovers its public IPv4 address
* starts a Jupyter server in the EC2 instance
* configures the SSH configuration file for VS Code
```bash
#!/bin/bash
ID=${1:-'YOUR-EC2-ID'}
aws ec2 start-instances --instance-ids $ID
IPV4="$(aws ec2 describe-instances --instance-ids $ID --query 'Reservations[].Instances[].PublicDnsName' --output text)"
ec2-jupyter-start $IPV4
ec2-configure $IPV4
```

This script uses two sub-commands that you will have to install (or expand in this script) : `ec2-jupyter-start` and `ec2-configure`

`ec2-jupyter-start` connects via SSH to your EC2 instance and starts a Jupyter server in it. You'll have to replace `PATH/TO/EC2-KEY.pem` with the path to your EC2 key file.

```bash
#!/bin/bash
ssh -i "PATH/TO/EC2-KEY.pem" ec2-user@$1 jupyter-start -oStrictHostKeyChecking=no
```

`ec2-configure` edits the SSH configuration file to allow you to connect to your EC2 instance with VS Code. You'll have to replace `/PATH/TO/SSH-CONFIG` with the path to your VS Code SSH configuration file (by default, `/mnt/c/Users/USERNAME/.ssh/config`). If you've never used SSH with VS Code, see [below](#vs-code-ssh-configuration-file).

**WARNING** : Note that this script is very simple and will mess with your configuration if you have other registered SSH hosts in VS Code !

```bash
#!/bin/bash
sed -i -E "s/HostName (.*)/HostName $1/" /PATH/TO/SSH-CONFIG
```

#### VS Code SSH configuration file
For it to work, you will have to create the configuration file first. This can be done by launching VS Code with `> Remote-SSH: Open SSH configuration file...` or by clicking  on the $_>^<$ symbol in the bottom left corner and selecting `Connect to Host` and then `Configure SSH hosts`. It will create a `config` file in which you have to copy the following text, by repalcing `PATH/TO/EC2-KEY.pem` with the path to your EC2 key file. You can then save this file.

```
Host my-aws-ec2
    HostName XXX
    User ec2-user
    IdentityFile PATH/TO/EC2-KEY.pem
```

### 2. 
