FROM dart:stable

WORKDIR /app

COPY . .

RUN dart pub get

EXPOSE 8080

CMD ["sh", "-c", "dart run bin/server.dart ${PORT:-8080}"]
