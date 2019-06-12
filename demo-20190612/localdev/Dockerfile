# docker tag gcr.io/distroless/nodejs@sha256:89db50a150955f7449adf441ab2c7e81de9029b73b9552378c26cf930e9363fa builds.registry.svc.cluster.local/nodejs
# docker push docker push builds.registry.svc.cluster.local/nodejs
FROM builds.registry.svc.cluster.local/nodejs

WORKDIR /app
CMD ["index.js"]
COPY index.js /app/
