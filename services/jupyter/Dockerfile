FROM jupyter/scipy-notebook
MAINTAINER Heinrich Hartmann <heinrich@heinrichhartmann.com>

#
# System
#
USER root

# Give $NB_USER passwordless sudo
RUN printf "$NB_USER\tALL=(ALL)\tNOPASSWD: ALL" > /etc/sudoers.d/$NB_USER
RUN apt-get update && apt-get upgrade -y
RUN mkdir -p /work && chmod a+w -R /work

# System packages
RUN sudo apt-get install -y \
        curl \
        jq

USER $NB_USER
WORKDIR /work

#
# Python
#
# run pip as $NBUSER
#
RUN pip install --upgrade pip

# bash kernel: http://slhogle.github.io/2017/bash_jupyter_notebook/
RUN pip install bash_kernel && python -m bash_kernel.install
RUN pip install nbmerge
