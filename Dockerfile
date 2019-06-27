FROM adoptopenjdk:8-jre-hotspot
LABEL maintainer "Chris Wells <chris@cevanwells.com>"

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
                                                  fontconfig \
                                                  ttf-dejavu \
                                                  gettext-base \
    && rm -rf /var/lib/apt/lists/*

ENV SQLWB_LIB_DIR=/usr/local/lib
WORKDIR $SQLWB_LIB_DIR
# Install PostgreSQL JDBC driver
RUN curl -sSL http://central.maven.org/maven2/org/postgresql/postgresql/9.4.1212/postgresql-9.4.1212.jar \
		 -o jdbc-postgresql.jar

# Install MariaDB (mysql) JDBC driver
RUN curl -sSL http://central.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.3.0/mariadb-java-client-2.3.0.jar \
		 -o jdbc-mariadb.jar

# Install MSSQL JDBC driver
RUN curl -sSL https://github.com/Microsoft/mssql-jdbc/releases/download/v7.1.3/mssql-jdbc-7.1.3.jre8-preview.jar \
		 -o jdbc-mssql.jar

ENV SQLWB_BIN_DIR=/usr/local/bin \
    SQLWB_SHARE_DIR=/usr/local/share/sqlworkbench \
    SQLWB_VERSION=Build124-with-optional-libs
WORKDIR $SQLWB_SHARE_DIR
RUN curl -sSL https://www.sql-workbench.eu/Workbench-$SQLWB_VERSION.zip -o sqlworkbench-$SQLWB_VERSION.zip \
	&& unzip -q sqlworkbench-$SQLWB_VERSION.zip \
	&& chmod +x sqlwbconsole.sh \
    && ln -s `readlink -f sqlwbconsole.sh` $SQLWB_BIN_DIR/ \
	&& rm -f sqlworkbench-$SQLWB_VERSION.zip

ENV SQLWB_APP_DIR=/app
WORKDIR $SQLWB_APP_DIR
RUN mkdir -p exports config sql \
    && addgroup --system appworker \
	&& adduser --system \
               --disabled-password \
			   --no-create-home \
               --gecos "" \
			   --home "$SQLWB_APP_DIR" \
			   --ingroup appworker \
			   appworker \
	&& chown appworker:appworker -R $SQLWB_APP_DIR

WORKDIR $SQLWB_SHARE_DIR
COPY config/* ./config/
COPY sql/* ./sql/

ONBUILD COPY --chown=appworker config/* $SQLWB_APP_DIR/config/
ONBUILD COPY --chown=appworker sql/* $SQLWB_APP_DIR/sql/

WORKDIR /usr/local/bin
COPY bin/* ./
RUN chmod +x docker-entrypoint.sh docker-cmd.sh

USER appworker
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []