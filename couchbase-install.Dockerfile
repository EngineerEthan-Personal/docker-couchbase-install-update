# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG REQUIRED_COUCHBASE_VERSION
FROM couchbase:${REQUIRED_COUCHBASE_VERSION}
ARG REQUIRED_COUCHBASE_VERSION
RUN echo "using image couchbase:${REQUIRED_COUCHBASE_VERSION}" && \
echo "Installing Couchbase $REQUIRED_COUCHBASE_VERSION and starting server..."

# https://dzone.com/articles/health-checking-your-docker-containers
HEALTHCHECK --interval=5s --timeout=3s CMD curl --fail http://localhost:8091/pools || exit 1;

COPY configure.sh /opt/couchbase
RUN chmod a+rx /opt/couchbase/configure.sh
CMD "/opt/couchbase/configure.sh"