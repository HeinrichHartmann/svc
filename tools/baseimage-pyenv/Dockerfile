FROM ubuntu:20.04

RUN apt-get -y update && apt-get -y upgrade

#
# pyenv Version manager
# https://github.com/pyenv/pyenv
#
RUN apt-get -y install curl git
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
ENV PATH="$HOME/.pyenv/bin:$PATH"

#
# Install python version
#
# Python build dependencies https://realpython.com/intro-to-pyenv/
ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Berlin
RUN apt-get -y install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl
RUN /root/.pyenv/bin/pyenv install 3.8.6
ENV PATH="/root/.pyenv/bin:$PATH"
RUN pyenv global 3.8.6
ENV PATH="/root/.pyenv/shims:${PATH}"
ENV PYENV_SHELL=bash
RUN python -m pip install --upgrade pip
