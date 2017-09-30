FROM alpine:3.4

WORKDIR /wordfinder

ADD . /wordfinder

RUN apk update && \
  apk add perl perl-io-socket-ssl perl-dev g++ make wget curl && \
  curl -L https://cpanmin.us | perl - App::cpanminus && \
  cpanm --installdeps . -M https://cpan.metacpan.org

EXPOSE 80

CMD script/wordfinder daemon -m production -l http://*:80
