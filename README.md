# Rclone

For this template we are using the official [rclone docker image](https://hub.docker.com/r/rclone/rclone) in docker hub.

In order to install this version of the template into a namespace do:

```bash
$ oc create -f rclone.yaml
template.template.openshift.io/rclone created
```

Then use the template from the web interface, or from the command line:

```bash
$ oc process rclone \
    ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
    SECRET_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
    BUCKET_DIR=existing_bucket/existing/path
```

## Command line tests

In `rclone.conf`, replace the credentials (`${ACCESSKEY}` and `${SECRETKEY}`) and the endpoint (`${S3HOST}`) with their appropriate values.

```bash
$ cp rclone.conf ~/.config/rclone/
$ docker run --rm \
    --volume ~/.config/rclone:/config/rclone \
    --volume ~/data:/data:shared \
    --user $(id -u):$(id -g) \
    --volume /etc/passwd:/etc/passwd:ro --volume /etc/group:/etc/group:ro \
    --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
    rclone/rclone \
    listremotes
```

Should output:

```bash
default:
```

Then, in order to list the buckets in the project:

```bash
$ docker run --rm \
    --volume ~/.config/rclone:/config/rclone \
    --volume ~/data:/data:shared \
    --user $(id -u):$(id -g) \
    --volume /etc/passwd:/etc/passwd:ro --volume /etc/group:/etc/group:ro \
    --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
    rclone/rclone \
    lsd default:
```

With this information, it is possible to mount a remote S3 remote bucket into a local folder:

```bash
$ sudo chcon -Rt svirt_sandbox_file_t ~/data
$ sudo docker run --rm \
    --volume ~/.config/rclone:/config/rclone \
    --volume ~/data:/data:shared \
    --device /dev/fuse --cap-add SYS_ADMIN \
    rclone/rclone mount default:28022020-gonzalez /data/home
```

Meanwhile the docker command is running, you can read the files in the bucket from a different terminal (as root):

```bash
sudo ls ~/data
```

## Obtain the S3 credentials

We will use the command line to obtain the credentials. First install the command line client:

```bash
pip install python-openstackclient
```

Then go to [Access & Security](https://pouta.csc.fi/dashboard/project/access_and_security/), download the OpenStack RC File v2.0, and source it:

```bash
$ source ~/Downloads/project_XXXXXXX-openrc.sh
Please enter your OpenStack Password for project project_2001316 as user <USER>:

```

Finally you can list the credentials:

```bash
openstack ec2 credentials list -f yaml
```

We are interested in `Access:` and `Secret:`.
