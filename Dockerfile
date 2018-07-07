FROM ruby:2.5
ENV LANG C.UTF-8
RUN apt-get update -qq && apt-get install -y build-essential mysql-client
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn
WORKDIR /tmp
COPY Gemfile* /tmp/
COPY Gemfile.lock /tmp/Gemfile.lock
RUN bundle
WORKDIR /app
COPY . /app
