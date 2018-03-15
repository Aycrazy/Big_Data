#!/bin/bash

set -x -e


JUPYTER_PORT=8194

JUPYTER_PASSWORD=myJupyterPassword
NOTEBOOK_DIR=s3://andrew-s3-emrcluster/notebooks
HOME=/home/hadoop

wget https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh -O /home/hadoop/miniconda.sh\
    && /bin/bash ~/miniconda.sh -b -p $HOME/conda

echo -e '\nexport PATH=$HOME/conda/bin:$PATH' >> $HOME/.bashrc
source $HOME/.bashrc

echo -e '\nexport SPARK_HOME=/usr/lib/spark' >> $HOME/.bashrc
echo -e '\nexport PATH=$PATH:$SPARK_HOME/bin' >> $HOME/.bashrc
source $HOME/.bashrc

conda config --set always_yes yes --set changeps1 no


#input package names as a string
while [ $# -gt 0 ]; do
    case "$1" in
    --python-packages)
      shift
      PYTHON_PACKAGES=$1
      ;;
    *)
      break;
      ;;
    esac
    shift
done

if [ ! "$PYTHON_PACKAGES" = "" ]; then
  conda install $PYTHON_PACKAGES || true
fi

#in the master node
# install dependencies for s3fs-fuse to access and store notebooks

# extract BUCKET and FOLDER to mount from NOTEBOOK_DIR
IS_MASTER=false
if grep isMaster /mnt/var/lib/info/instance.json|grep true;
then
    IS_MASTER=true
fi

if [ "$IS_MASTER" = true ]; 
then

    conda install -y jupyter 

    jupyter notebook -y --generate-config

    # install dependencies for s3fs-fuse to access and store notebooks
    #this works
    sudo yum -y update

    sudo yum install -y automake fuse fuse-devel gcc-c++ git libcurl-devel libxml2-devel make openssl-devel\
    cyrus-sasl cyrus-sasl-devel readline readline-devel gnuplot


    NOTEBOOK_DIR="${NOTEBOOK_DIR%/}/"
    BUCKET=$(python -c "print('$NOTEBOOK_DIR'.split('//')[1].split('/')[0])")
    FOLDER=$(python -c "print('/'.join('$NOTEBOOK_DIR'.split('//')[1].split('/')[1:-1]))")

    # jupyter configs
    mkdir -p ~/.jupyter
    touch ls ~/.jupyter/jupyter_notebook_config.py
    
    HASHED_PASSWORD=$(python -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")
    
    echo "c.NotebookApp.password = u'$HASHED_PASSWORD'" >> ~/.jupyter/jupyter_notebook_config.py

    echo "c.NotebookApp.open_browser = False" >> ~/.jupyter/jupyter_notebook_config.py

    sed -i '/c.NotebookApp.port/d' ~/.jupyter/jupyter_notebook_config.py

    echo "c.NotebookApp.port = $JUPYTER_PORT" >> ~/.jupyter/jupyter_notebook_config.py


    sed -i '/c.NotebookApp.ip/d' ~/.jupyter/jupyter_notebook_config.py
    echo "c.NotebookApp.ip = '*'" >> ~/.jupyter/jupyter_notebook_config.py

    sed -i '/c.NotebookApp.MultiKernelManager.default_kernel_name/d' ~/.jupyter/jupyter_notebook_config.py
    echo "c.NotebookApp.MultiKernelManager.default_kernel_name = 'pyspark'" >> ~/.jupyter/jupyter_notebook_config.py

    echo "c.NotebookApp.notebook_dir = '/mnt/$BUCKET/$FOLDER'" >> ~/.jupyter/jupyter_notebook_config.py
    echo "c.ContentsManager.checkpoints_kwargs = {'root_dir': '.checkpoints'}" >> ~/.jupyter/jupyter_notebook_config.py

    echo "c.Authenticator.admin_users = {'hadoop'}" >> ~/.jupyter/jupyter_notebook_config.py
    echo "c.LocalAuthenticator.create_system_users = True" >> ~/.jupyter/jupyter_notebook_config.py


    echo -e '\nexport PYSPARK_DRIVER_PYTHON=jupyter' >> $HOME/.bashrc
    echo -e '\nexport PYSPARK_DRIVER_PYTHON_OPTS="notebook"' >> $HOME/.bashrc
    echo -e '\nalias jn="jupyter notebook"'
    echo -e '\nalias ps="pyspark"'
    source $HOME/.bashrc

    echo "bucket '$BUCKET' folder '$FOLDER'"

    cd /mnt
    git clone https://github.com/s3fs-fuse/s3fs-fuse.git
    cd s3fs-fuse/
    ls -alrt
    ./autogen.sh
    ./configure
    make
    sudo make install 
    sudo su -c 'echo user_allow_other >> /etc/fuse.conf'
    mkdir -p /mnt/s3fs-cache
    mkdir -p /mnt/$BUCKET
    /usr/local/bin/s3fs -o allow_other -o iam_role=auto -o umask=0 -o url=https://s3.amazonaws.com  -o no_check_certificate -o enable_noobj_cache -o use_cache=/mnt/s3fs-cache $BUCKET /mnt/$BUCKET

    
    echo "Starting Jupyter notebook via pyspark"

fi

echo "Bootstrap action foreground process finished"



