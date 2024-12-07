FROM ruby:3.3.3-alpine AS chat

RUN apk --update add --no-cache \
    build-base \
    tzdata \
    yarn \
    libc6-compat \
    postgresql-dev \
    postgresql-client \
    redis \
    curl \
    libffi-dev \
    ruby-dev \
    && rm -rf /var/cache/apk/*

ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem update --system 3.5.23
RUN gem install bundler -v $(tail -n 1 Gemfile.lock)
RUN gem install ffi -v 1.17.0 --platform ruby
RUN bundle check || bundle install
RUN bundle clean --force

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

# RUN bundle exec bootsnap precompile app/ lib/

# RUN bundle exec rails assets:precompile

# RUN rm -rf node_modules

RUN addgroup -g 1000 rails && \
    adduser -u 1000 -G rails -D -s /bin/sh rails && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# ENTRYPOINT ["/app/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
