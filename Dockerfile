FROM ubuntu:18.04
RUN apt-get update && apt-get install -y apache2 curl wget

RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
COPY 000-default.conf /etc/apache2/sites-enabled/000-default.conf
RUN bash -l -c 'a2enmod proxy && service apache2 start'

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn imagemagick apt-utils apt-transport-https ca-certificates -y
RUN apt-get -y -q install software-properties-common && apt-get -y -q install postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6 libpq-dev htop

RUN bash -l -c 'ln -fs /usr/share/zoneinfo/America/Mexico_City /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata'

RUN git clone https://github.com/rbenv/rbenv.git rbenv
RUN git clone https://github.com/rbenv/ruby-build.git /rbenv/plugins/ruby-build
RUN /rbenv/plugins/ruby-build/install.sh
ENV PATH /rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc
RUN echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc

ARG REQUESTED_RUBY_VERSION="2.4.4"

RUN if test -n "$REQUESTED_RUBY_VERSION" -a ! -x /rbenv/versions/$REQUESTED_RUBY_VERSION/bin/ruby; then (cd /rbenv/plugins/ruby-build  && git pull && rbenv install -s $REQUESTED_RUBY_VERSION) && rbenv global $REQUESTED_RUBY_VERSION && apt-get clean && rm -f /var/lib/apt/lists/*_*; fi
RUN bash -l -c 'gem install bundler -v 1.17.3'
RUN bash -l -c 'bundle config --global silence_root_warning 1'
COPY Gemfile /root/Gemfile
COPY Gemfile.lock /root/Gemfile.lock
RUN bash -l -c 'cd ~ && bundle install --without="development test" && rbenv rehash'
RUN exec $SHELL

EXPOSE 8080
CMD ["apachectl", "-D", "FOREGROUND"]
