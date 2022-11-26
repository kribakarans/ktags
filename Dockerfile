# syntax=docker/dockerfile:1
FROM ubuntu:20.04

# install app dependencies
RUN apt update && \
    apt install -y cscope exuberant-ctags global libcgi-pm-perl make perl python3 tree && \
    apt clean && rm -rf /var/lib/apt/lists/*

# setup container
RUN mkdir -p  /usr/local/bin/ /root/__ktags
RUN ln -sf /usr/bin/python3 /usr/local/bin/python

# install package
COPY ./__ktags /root/__ktags
COPY ktags.out /usr/local/bin/ktags

# final configuration
EXPOSE 8080
WORKDIR /root/__ktags
CMD /usr/bin/htags-server -b 0.0.0.0 8080

#EOC
