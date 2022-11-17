# syntax=docker/dockerfile:1
FROM ubuntu:20.04

# install app dependencies
RUN apt-get update && \
    apt-get install -y cscope exuberant-ctags global make python3 tree && \
    rm -rf /var/lib/apt/lists/* && apt clean

# setup container
RUN mkdir -p  /usr/local/bin/ /root/__ktags
RUN ln -sf /usr/bin/python3 /usr/local/bin/python

# install package
COPY ./__ktags /root/__ktags
RUN chown -vR $USER:$USER /root/__ktags
COPY ktags.out /usr/local/bin/ktags

# final configuration
EXPOSE 8080
WORKDIR /root/__ktags
CMD /usr/bin/htags-server -b 0.0.0.0 8080

#EOC
