FROM ubuntu:18.04

RUN apt-get update && apt-get install -y apache2 curl wget

ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 10.16.0
ENV NVM_INSTALL_PATH $NVM_DIR/versions/node/v$NODE_VERSION

RUN mkdir -p $NVM_DIR
RUN curl --silent -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

RUN echo "source $NVM_DIR/nvm.sh && \
    nvm alias default $NODE_VERSION && \
    nvm use default" | bash

ENV NODE_PATH $NVM_INSTALL_PATH/lib/node_modules
ENV PATH $NVM_INSTALL_PATH/bin:$PATH

RUN node -v
RUN npm -v

RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
COPY 000-default.conf /etc/apache2/sites-enabled/000-default.conf
RUN bash -l -c 'a2enmod proxy && service apache2 start'

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install vim git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev imagemagick apt-utils apt-transport-https ca-certificates -y
RUN apt-get -y -q install software-properties-common && apt-get -y -q install postgresql postgresql-contrib libpq-dev libjemalloc-dev

RUN bash -l -c 'ln -fs /usr/share/zoneinfo/Mexico/General /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata'

RUN git clone https://github.com/rbenv/rbenv.git rbenv
RUN git clone https://github.com/rbenv/ruby-build.git /rbenv/plugins/ruby-build
RUN /rbenv/plugins/ruby-build/install.sh
ENV PATH /rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc
RUN echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc

ARG REQUESTED_RUBY_VERSION="2.4.4"

RUN if test -n "$REQUESTED_RUBY_VERSION" -a ! -x /rbenv/versions/$REQUESTED_RUBY_VERSION/bin/ruby; then (cd /rbenv/plugins/ruby-build  && git pull && RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install -s $REQUESTED_RUBY_VERSION) && rbenv global $REQUESTED_RUBY_VERSION && apt-get clean && rm -f /var/lib/apt/lists/*_*; fi
RUN bash -l -c 'gem install bundler -v 1.17.3'
RUN bash -l -c 'bundle config --global silence_root_warning 1'
COPY Gemfile /root/Gemfile
COPY Gemfile.lock /root/Gemfile.lock
RUN bash -l -c 'cd ~ && bundle install --without="development test" && rbenv rehash'
RUN exec $SHELL

EXPOSE 8080
CMD ["apachectl", "-D", "FOREGROUND"]
