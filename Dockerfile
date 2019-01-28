FROM ruby:2.3-stretch

RUN apt-get update && apt-get install -qy uuid-dev

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock /app/
RUN bundle install --without "development deployment test" --with docker --clean --deployment --no-cache --jobs=2

ENV RAILS_ENV production
ENV RACK_ENV production

ENV SERVE_STATIC_ASSETS=true
ENV MYSQL_USERNAME newssniffer
ENV MYSQL_PASSWORD newssniffer
ENV MYSQL_DB newssniffer_production
ENV MYSQL_HOST localhost

COPY . /app
COPY config/database.yml.docker /app/config/database.yml

EXPOSE 9292
#RUN bundle exec rake assets:precompile

CMD bundle exec puma -v
