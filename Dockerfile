FROM dart:stable AS build
WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN mkdir -p build/web \
    && dart compile js -O2 web/main.dart -o build/web/main.dart.js \
    && cp web/index.html web/styles.css build/web/
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/build/web /app/web

ENV PORT=8080 DATA_FILE=/app/data/order.json WEB_DIR=/app/web
EXPOSE 8080
CMD ["/app/bin/server"]
