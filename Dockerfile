# iRODS-Client-REST-Image
#
# VERSION	1.0

##############################################
# irods-client-rest image
##############################################
FROM ubuntu:18.04
LABEL version="0.1"
LABEL description="iRODS Client Rest Image"

ARG SOURCE_REPO_URL="https://github.com/jasoncoposky/irods_client_rest_cpp.git"
ARG DEBIAN_FRONTEND=noninteractive

# Setup Utility Packages
RUN apt-get update && \
    apt-get install -y git wget build-essential apt-transport-https lsb-release

# Setup iRODS Packages
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add -
RUN echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list
RUN apt-get update && \
    apt-get install -y irods-dev irods-runtime \
                       irods-externals-cmake3.11.4-0 irods-externals-clang6.0-0 irods-externals-cppzmq4.2.3-0 \
                       irods-externals-libarchive3.3.2-1 irods-externals-avro1.9.0-0 irods-externals-boost1.67.0-0 \
                       irods-externals-clang-runtime6.0-0 irods-externals-jansson2.7-0 irods-externals-zeromq4-14.1.6-0

ENV LD_LIBRARY_PATH /opt/irods-externals/clang-runtime6.0-0/lib/
ENV PATH $PATH:/opt/irods-externals/cmake3.11.4-0/bin

# Build Pistache
WORKDIR /opt
RUN git clone https://github.com/oktal/pistache.git
WORKDIR /opt/pistache
RUN git submodule update --init
RUN mkdir build
WORKDIR /opt/pistache/build
RUN cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release .. && \
    make && make install



# Build iRODS Client Rest
WORKDIR /opt
RUN git clone ${SOURCE_REPO_URL}
WORKDIR /opt/irods_client_rest_cpp
RUN wget https://raw.githubusercontent.com/nlohmann/json/develop/single_include/nlohmann/json.hpp -P /opt/irods_client_rest_cpp/model
RUN mkdir build
WORKDIR /opt/irods_client_rest_cpp/build
RUN cmake .. && \
    make

