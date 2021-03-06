FROM ubuntu:16.04

MAINTAINER "James Fairbanks" <james.fairbanks@gtri.gatech.edu>

# Import MongoDB public GPG key AND create a MongoDB list file
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
RUN echo "deb http://repo.mongodb.org/apt/ubuntu $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d= -f2)/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list

#Install oracle java prerequisites
RUN apt-get update -y                                                                         \
    && apt-get dist-upgrade -y                                                                \
    && apt-get install -y software-properties-common python-software-properties apt-utils     \
    && add-apt-repository ppa:webupd8team/java

# Install oracle java for the LEAN Library not necessarily necessary anymore
RUN apt-get update -qq && apt-get upgrade -qq -y                                    \
    && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true  \
            | /usr/bin/debconf-set-selections

RUN apt-get update


# Install what we can from with APT
RUN apt-get install -qq -y \
                ant                         \
                apache2                     \
                build-essential             \
                cmake                       \
                curl                        \
                cython                      \
                ed                          \
                gfortran                    \
                git                         \
                jq                          \
                libapache2-mod-wsgi         \
                libcurl4-openssl-dev        \
                libevent-dev                \
                libmysqlclient-dev          \
                libpq-dev                   \
                libssl-dev                  \
                libxml2-dev                 \
                littler                     \
                mongodb-org-server          \
                mongodb-org-mongos          \
                mongodb-org-shell           \
                libnlopt-dev                \
                oracle-java8-installer      \
                oracle-java8-set-default    \
                python-dev                  \
                python-numpy                \
                python-scipy                \
                python-sklearn              \
                python-virtualenv           \
                r-cran-lme4                 \
                ssh                         \
                unzip                       \
                wget                        \
                vim
RUN wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py

# Binaries built with checkmake of bedrock libraries.
RUN wget --quiet http://130.207.211.77/packages/libelemental_0.84-p1-1_amd64.deb &&   \
    wget --quiet http://130.207.211.77/packages/libflame_5.0-4648_amd64.deb    && \
    wget --quiet http://130.207.211.77/packages/libopenblas_0.2.9-1_amd64.deb  && \
    wget --quiet http://130.207.211.77/packages/libsmallk_20150909-1_amd64.deb && \
    wget --quiet http://130.207.211.77/packages/openmpi_1.8.1-1_amd64.deb      && \
    wget --quiet http://130.207.211.77/packages/pysmallk_20150909-1_amd64.deb

RUN dpkg -i ./libelemental_0.84-p1-1_amd64.deb \
            ./libflame_5.0-4648_amd64.deb      \
            ./libopenblas_0.2.9-1_amd64.deb    \
            ./libsmallk_20150909-1_amd64.deb   \
            ./openmpi_1.8.1-1_amd64.deb        \
            ./pysmallk_20150909-1_amd64.deb


# Copy over and install the python requirements
COPY ./requirements.txt /var/www/bedrock-requirements.txt

RUN pip install -U pip && hash -r && pip install -r /var/www/bedrock-requirements.txt

# standard apache
EXPOSE 80
# bedrock
EXPOSE 81
# mongo
EXPOSE 27017
# mongo admin web
EXPOSE 28017
# CMD ["python", "-c ", "import scipy; print('hello from scipy')"]

ADD ./bin/                  /opt/bedrock/bin
RUN ls -lah /opt/bedrock/bin
RUN bash /opt/bedrock/bin/installR.sh

RUN mkdir -p /data/db
RUN mkdir -p /opt/bedrock/conf
RUN mkdir -p /opt/bedrock/bin
RUN mkdir -p /opt/bedrock/package
RUN mkdir -p /opt/bedrock/opals

ADD ./conf/bedrock.conf     /opt/bedrock/conf/bedrock.conf
ADD ./conf/mongod.init.d    /etc/init.d/mongod

RUN /opt/bedrock/bin/install.sh

# to test this you can run ./test_docker.sh which will build, run, and test the container.
CMD service mongod start && /usr/sbin/apache2ctl -D FOREGROUND; /usr/sbin/apache2ctl -D FOREGROUND; /usr/sbin/apache2ctl -D FOREGROUND

# install available opals
RUN pip install git+https://github.com/Bedrock-py/bedrock-core

RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-logit2
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-stan
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-statstests
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-aggregate
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-select-from-dataframe
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-dataloader-filter-truth
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-clustering
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-classification
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-visualization-roc
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-dimensionreduction
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-visualization-linechart
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-visualization-scatterplot
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-dataloader-ingest-spreadsheet
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-summarize
RUN service mongod start && pip install git+https://github.com/Bedrock-py/opal-analytics-r