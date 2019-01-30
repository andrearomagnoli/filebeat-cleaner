FROM ruby:2.6.0-stretch

COPY /filebeat_cleaner.rb /filebeat_cleaner.rb

ENTRYPOINT [ "ruby", "filebeat_cleaner.rb" ]
