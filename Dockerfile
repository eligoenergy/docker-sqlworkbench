FROM adoptopenjdk:8-jre-hotspot
LABEL maintainer "Chris Wells <chris@cevanwells.com>"

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
&& rm -rf /var/lib/apt/lists/*

ENV SQLWB_VERSION=Build124
ENV SQLWB_SRC_URL=https://www.sql-workbench.eu/Workbench-$SQLWB_VERSION.zip
ENV SQLWB_SHARE_DIR=/usr/local/share/sqlworkbench
ENV SQLWB_APP_DIR=/app

WORKDIR $SQLWB_APP_DIR
RUN mkdir exports config sql \
    && mkdir -p $SQLWB_SHARE_DIR/config \
                $SQLWB_SHARE_DIR/sql

RUN curl -sSL $SQLWB_SRC_URL -o sqlworkbench-$SQLWB_VERSION.zip \
	&& unzip -q sqlworkbench-$SQLWB_VERSION.zip -d /usr/local/bin \
	&& chmod +x /usr/local/bin/sqlwbconsole.sh \
	&& rm -f sqlworkbench-$SQLWB_VERSION.zip

# Install PostgreSQL JDBC driver
RUN curl -sSL http://central.maven.org/maven2/org/postgresql/postgresql/9.4.1212/postgresql-9.4.1212.jar \
		 -o jdbc-postgresql.jar \
	&& mv jdbc-postgresql.jar /usr/local/lib/

# Install MariaDB (mysql) JDBC driver
RUN curl -sSL http://central.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.3.0/mariadb-java-client-2.3.0.jar \
		 -o jdbc-mariadb.jar \
	&& mv jdbc-mariadb.jar /usr/local/lib/

# Install MSSQL JDBC driver
RUN curl -sSL https://github.com/Microsoft/mssql-jdbc/releases/download/v7.1.3/mssql-jdbc-7.1.3.jre8-preview.jar \
		 -o jdbc-mssql.jar \
	&& mv jdbc-mssql.jar /usr/local/lib/

COPY bin/* /usr/local/bin/
COPY config/* $SQLWB_SHARE_DIR/config/
COPY sql/* $SQLWB_SHARE_DIR/sql/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
	&& chmod +x /usr/local/bin/docker-cmd.sh

RUN addgroup --system appworker \
	&& adduser --system \
               --disabled-password \
			   --no-create-home \
               --gecos "" \
			   --home "$SQLWB_APP_DIR" \
			   --ingroup appworker \
			   appworker \
	&& chown appworker:appworker -R $SQLWB_APP_DIR

USER appworker
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []