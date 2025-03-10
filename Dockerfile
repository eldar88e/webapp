FROM ruby:3.3.7-alpine3.21 AS miniapp

RUN apk --update add --no-cache \
    build-base \
    yaml-dev \
    tzdata \
    yarn \
    libc6-compat \
    postgresql-dev \
    postgresql-client \
    redis \
    curl \
    libffi-dev \
    ruby-dev \
    vips \
    vips-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libheif-dev \
    imagemagick \
    imagemagick-dev \
    && rm -rf /var/cache/apk/*

ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test"

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem update --system 3.6.5
RUN gem install bundler -v $(tail -n 1 Gemfile.lock)
RUN bundle check || bundle install
RUN bundle clean --force

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
# RUN rm -rf node_modules

COPY . .

RUN bandle exec assets:precompile
# RUN bundle exec bootsnap precompile app/ lib/
# ENTRYPOINT ["/app/bin/docker-entrypoint"]

RUN addgroup -g 1000 deploy && adduser -u 1000 -G deploy -D -s /bin/sh deploy
RUN chown -R deploy:deploy /app # db log storage tmp
RUN bandle exec assets:precompile

USER deploy:deploy

EXPOSE 3000
