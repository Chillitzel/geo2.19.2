FROM tomcat:latest

RUN apt-get update && apt-get install -y unzip wget

RUN wget https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/2.0.6.tar.gz \
    && tar -zxf ./2.0.6.tar.gz \
    && cd libjpeg-turbo-2.0.6 && apt-get install cmake -yq && cmake -G"Unix Makefiles" && make deb \
    && dpkg -i ./libjpeg*.deb && apt-get -f install -y \
    && apt-get clean \
    && apt-get autoclean \
    && apt-get autoremove

ENV CATALINA_BASE "$CATALINA_HOME"
# set externalizations
ENV GEOSERVER_HOME="/var/geoserver"
ENV GEOSERVER_LOG_DIR="${GEOSERVER_HOME}/logs"
ENV GEOSERVER_DATA_DIR="${GEOSERVER_HOME}/datadir"
ENV GEOSERVER_LOG_LOCATION="${GEOSERVER_LOG_DIR}/geoserver.log"
ENV GEOWEBCACHE_CONFIG_DIR="${GEOSERVER_DATA_DIR}/gwc"
ENV GEOWEBCACHE_CACHE_DIR="${GEOSERVER_HOME}/gwc_cache_dir"
ENV NETCDF_DATA_DIR="${GEOSERVER_HOME}/netcdf_data_dir"
ENV GRIB_CACHE_DIR="${GEOSERVER_HOME}/grib_cache_dir"
# override at run time as needed JAVA_OPTS
ENV INITIAL_MEMORY="2G"
ENV MAXIMUM_MEMORY="4G"
ENV LD_LIBRARY_PATH="/opt/libjpeg-turbo/lib64"
ENV JAIEXT_ENABLED="true"

ENV GEOSERVER_OPTS=" \
  -Dorg.geotools.coverage.jaiext.enabled=${JAIEXT_ENABLED} \
  -Duser.timezone=UTC \
  -Dorg.geotools.shapefile.datetime=true \
  -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION} \
  -DGEOWEBCACHE_CONFIG_DIR=${GEOWEBCACHE_CONFIG_DIR} \
  -DGEOWEBCACHE_CACHE_DIR=${GEOWEBCACHE_CACHE_DIR} \
  -DNETCDF_DATA_DIR=${NETCDF_DATA_DIR} \
  -DGRIB_CACHE_DIR=${GRIB_CACHE_DIR}"

ENV JAVA_OPTS="-Xms${INITIAL_MEMORY} -Xmx${MAXIMUM_MEMORY} \
  -Djava.awt.headless=true -server \
  -Dfile.encoding=UTF8 \
  -Djavax.servlet.request.encoding=UTF-8 \
  -Djavax.servlet.response.encoding=UTF-8 \
  -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=20 -XX:ConcGCThreads=5 \
  ${GEOSERVER_OPTS}"

RUN apt-get update \
    && apt-get install --yes gdal-bin postgresql-client-11 fontconfig libfreetype6 jq \
    && apt-get clean \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/doc/* \
    && mkdir -p \
    "${GEOSERVER_DATA_DIR}" \
    "${GEOSERVER_LOG_DIR}"  \
    "${GEOWEBCACHE_CONFIG_DIR}" \
    "${GEOWEBCACHE_CACHE_DIR}" \
    "${NETCDF_DATA_DIR}" \
    "${GRIB_CACHE_DIR}"

RUN wget http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/geoserver-2.19.2-war.zip -P /home
RUN unzip /home/geoserver-2.19.2-war.zip -d /home
RUN mkdir /home/geoserver
RUN unzip /home/geoserver.war -d /home/geoserver
RUN cp -r /home/geoserver /usr/local/tomcat/webapps

WORKDIR "$CATALINA_BASE"
USER $UNAME

COPY entrypoint.sh /$CATALINA_BASE/entrypoint.sh

RUN chmod +x /$CATALINA_BASE/entrypoint.sh

ENV TERM xterm
EXPOSE 8080/tcp

CMD $CATALINA_BASE/entrypoint.sh
