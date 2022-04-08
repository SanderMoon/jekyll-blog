FROM ruby:2.7.1-buster AS build
COPY . /app
WORKDIR /app
RUN bundle install \
    && jekyll build

FROM arm64v8/nginx:1.21.6-alpine AS final
COPY --from=build /app/_site /usr/share/nginx/html