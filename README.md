# VSJupytEC2

This repository provides short bash scripts to start an [AWS EC2 instance](https://aws.amazon.com/ec2/) and automatically create a Jupyter server inside that you can easily use in VS Code to run notebooks even when you shutdown your computer.

## Prerequisites
* Have an AWS EC2 account and the ability to launch an instance
* Have created an [EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html) with a key pair you saved on your computer
* In VS Code, install the [Remote-SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extention
* Be able to run bash scripts (native on Linux, through [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) on Windows)
* Have installed `AWS CLI` where you'll execute the bash scripts. This can be done through `pip install awscli` (more infos [here](https://docs.aws.amazon.com/cli/v1/userguide/install-linux.html))

## Setup

Download the scripts to [install on your computer](linux). Put them where you want

#### VS Code SSH configuration file
For it to work, you will have to create the configuration file first. This can be done by launching VS Code with `> Remote-SSH: Open SSH configuration file...` or by clicking on the $_>^<$ symbol in the bottom left corner and selecting `Connect to Host` and then `Configure SSH hosts`. It will create a `config` file in which you have to copy the following text, by repalcing `PATH/TO/EC2-KEY.pem` with the path to your EC2 key file. You can then save this file.
```
Host my-aws-ec2
    HostName XXX
    User ec2-user
    IdentityFile PATH/TO/EC2-KEY.pem
```

#### Jupyter server security
Before starting a Jupyter server on the EC2 instance, you will have to run the following commands in a terminal in your EC2 instance to secure it.

* Choose a password for your Jupyter server
```
jupyter notebook password
```

* Create a SSL certifcate and key
```
mkdir ~/ssl
cd ~/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout jupyter-key.key -out jupyter-cert.pem
```

## Workflow

1. Start the EC2 instance and Jupyter server. In a Linux terminal, run `ec2-jupyter-create`.
2. Open VS Code, click on the $_>^<$ symbol in the bottom left corner, select `Connect to Host` and choose your instance (by default `my-aws-ec2`).
3. You're connected in your EC2 instance ! You can choose your working directory, open a Git repository or clone one.
4. To run a Jupyter notebook on the EC2-Jupyter server, open your notebook (in the VS Code connected to your EC2 instance), click `Select Kernel`, select `Existing Jupyter server...` and type `http://localhost:8888`. You will just have to enter the password you defined during setup.
5. Congratulations ! You're now running a Jupyter notebook on an EC2 instance, all with the comfort of VS Code.
6. To stop your instance, in your Linux terminal (outside VS Code), run `ec2-jupyter-kill`.

## Scripts

The following part presents the scripts to start an EC2 instance using bash commands, connect to it through VS Code, start a Jupyter server on the instance, use the server in VS Code to run Jupyter notebooks. It is recommended to read it to modify path to different files.

### Create the Jupyter server in EC2

The following scripts:
* starts your EC2 instance (**replace `YOUR-EC2-ID` with the instance ID you want to use**, and which can be found in your EC2 instances dashboard),
* recovers its public IPv4 address
* starts a Jupyter server in the EC2 instance
* configures the SSH configuration file for VS Code

#### `ec2-jupyter-create`
```bash
#!/bin/bash
ID=${1:-'YOUR-EC2-ID'}
aws ec2 start-instances --instance-ids $ID
IPV4="$(aws ec2 describe-instances --instance-ids $ID --query 'Reservations[].Instances[].PublicDnsName' --output text)"
ec2-jupyter-start $IPV4
ec2-configure $IPV4
```
*NB: You can also give the instance ID you want to use as an argument to this script when running it*

This script uses two sub-commands that you will have to install (or expand in this script) : `ec2-jupyter-start` and `ec2-configure`.

#### `ec2-jupyter-start`
`ec2-jupyter-start` connects via SSH to your EC2 instance and starts a Jupyter server in it. **You'll have to replace `PATH/TO/EC2-KEY.pem` with the path to your EC2 key file.**

```bash
#!/bin/bash
ssh -i "PATH/TO/EC2-KEY.pem" ec2-user@$1 jupyter-start -oStrictHostKeyChecking=no
```
This script runs the `jupyter-start` script in your EC2 instance. You then should have set it up there.

#### `jupyter-start`
`jupyter-start` creates a screen named `jupyter` where it launches the `jupyter-server` script before detaching and leaving it running in background.
```bash
#!/bin/bash
screen -S jupyter -d -m "jupyter-server"
```

#### `jupyter-server`
`jupyter-server` creates a Jupyter server, protected by SSL.
```bash
#!/bin/bash
jupyter notebook --certfile=~/ssl/jupyter-cert.pem --keyfile ~/ssl/jupyter-key.key
```

#### `ec2-configure`
`ec2-configure` edits the SSH configuration file to allow you to connect to your EC2 instance with VS Code. **You'll have to replace `/PATH/TO/SSH-CONFIG` with the path to your VS Code SSH configuration file** (by default, `/mnt/c/Users/USERNAME/.ssh/config`). If you've never used SSH with VS Code, see [here](#vs-code-ssh-configuration-file) how to create this file.

**WARNING**: Note that this script is very simple and will mess with your configuration if you have other registered SSH hosts in VS Code !

```bash
#!/bin/bash
sed -i -E "s/HostName (.*)/HostName $1/" /PATH/TO/SSH-CONFIG
```

### Kill the Jupyter server

You can kill the Jupyter server simply by stopping your EC2 instance, but here are some scripts to do it more cleanly.

#### `ec2-jupyter-kill`
This script stops the Jupyter server running on your EC2 instance and stops the EC2 instance. **You'll have to replace `YOUR-EC2-ID` by the EC2 instance ID you used.**
```bash
#!/bin/bash
ID=${1:-'YOUR-EC2-ID'}
IPV4="$(aws ec2 describe-instances --instance-ids $ID --query 'Reservations[].Instances[].PublicDnsName' --output text)"
ec2-jupyter-quit $IPV4
aws ec2 stop-instances --instance-ids $ID
```
*NB: You can also give the instance ID you used as an argument to this script when running it*

This script uses one sub-command that you will have to install (or expand in this script) : `ec2-jupyter-quit`.

#### `ec2-jupyter-quit`
`ec2-jupyter-quit` connects via SSH to your EC2 instance and stops the Jupyter server in it. **You'll have to replace `PATH/TO/EC2-KEY.pem` with the path to your EC2 key file.**

```bash
#!/bin/bash
ssh -i "PATH/TO/EC2-KEY.pem" ec2-user@$1 jupyter-quit -oStrictHostKeyChecking=no
```
This script runs the `jupyter-quit` script in your EC2 instance. You then should have set it up there.

#### `jupyter-quit`
`jupyter-quit` attaches back to the `jupyter` screen and quits it, stopping the Jupyter server.
```bash
#!/bin/bash
screen -S jupyter -X quit
```

### Utilities

#### `ec2-ssh`
`ec2-ssh` allows easy SSH connection to your EC2 instance. This is not that useful since you can connect via SSH in VS Code and open a terminal there.
```bash
#!/bin/bash
ID=${1:-'YOUR-EC2-ID'}
aws ec2 start-instances --instance-ids $ID
IPV4="$(aws ec2 describe-instances --instance-ids $ID --query 'Reservations[].Instances[].PublicDnsName' --output text)"
ssh -i "PATH/TO/EC2-KEY.pem" ec2-user@$IPV4 -oStrictHostKeyChecking=no
```

#### `ec2-jupyter-connect`
`ec2-jupyter-connect` creates a SSH tunnel to connect to your Jupyter server from outside the EC2 instance. It's not that useful since you can connect directly to the Jupyter server in the EC2 instance via VS Code.
```bash
#!/bin/bash
ssh -i "PATH/TO/EC2-KEY.pem" -N -f -L $2:localhost:8888 ec2-user@$1
echo "https://localhost:$2"
```
* Note: This script takes as first argument the IPv4 address of your instance, and as second argument the port (4 digit number) you want to use to connect to your Jupyter server*

#### `ec2-type`
`ec2-type` is useul to quickly change the type of your EC2 instance without needing to use the online interface. This requires the instance to be stopped.
```bash
#!/bin/bash
ID=${2:-'YOUR-EC2-ID'}
aws ec2 modify-instance-attribute --instance-id $ID --instance-type "{\"Value\": \"$1\"}"
```
This script takes as first argument the new instance type (e.g. `c6a.xlarge`) and as second argument (optional) the instance ID from the instance you want to modify.

#### `mount-storage`
`mount-storage` is a script you can install in your EC2 instance. It allows to mount a SSD drive (only available for certain instances families, such as `c5d` or `c6id`) to have more storage on your EC2 instance. 

**WARNING**: This storage will be erased when you stop the instance and you have to mount it every time to re-start the instance.

```bash
#!/bin/bash
sudo mkfs.ext4 -E nodiscard /dev/nvme1n1
sudo mount -o discard /dev/nvme1n1 /$1/
sudo chown ec2-user /$1
```
This script takes as argument the name of the SSD storage you chose when creating your instance.
