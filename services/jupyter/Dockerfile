FROM jupyter/scipy-notebook:latest

MAINTAINER Heinrich Hartmann <heinrich@heinrichhartmann.com>

#
# System
#
USER root

# Give $NB_USER passwordless sudo
RUN printf "$NB_USER\tALL=(ALL)\tNOPASSWD: ALL" > /etc/sudoers.d/$NB_USER

RUN mkdir -p /work && chmod a+w -R /work

# System packages
RUN apt-get update
RUN sudo apt-get install -y curl jq

USER $NB_USER
WORKDIR /work

#
# Python
#
# run pip as $NBUSER
#
# bash kernel: http://slhogle.github.io/2017/bash_jupyter_notebook/
RUN pip install bash_kernel && python -m bash_kernel.install

RUN pip install nbmerge jupyter_scheduler
RUN jupyter server extension enable --user --py jupyter_scheduler
