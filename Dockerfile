FROM ruby:2.4

RUN mkdir /usr/src/app
ADD . /usr/src/app/
WORKDIR /usr/src/app/

RUN bundle install

CMD ["/usr/src/app/test.rb"]
