#!/bin/bash
# Script that starts Jetty and sets Jetty specific system properties based on
# environment variables set for all runtime implementations.
if [ -z "$RUNTIME_DIR" ]; then
  echo "Error: Required environment variable RUNTIME_DIR is not set."
  exit 1
fi
HEAP_SIZE_FRAC=0.8
RAM_RESERVED_MB=150
HEAP_SIZE=$(awk -v frac=$HEAP_SIZE_FRAC -v res=$RAM_RESERVED_MB /MemTotal/'{
  print int($2/1024*frac-res) "M" } ' /proc/meminfo)
echo "Info: Limiting Java heap size to: $HEAP_SIZE"

# Increase initial permsize.
PERM_SIZE=64M  # Default = 21757952 (20.75M)
MAX_PERM_SIZE=166M  # Default = 174063616 (166M)

DBG_AGENT=
PROFILER_AGENT=

if [[ "$GAE_PARTITION" = "dev" ]]; then
  if [[ -n "$DBG_ENABLE" ]]; then
    echo "Running locally and DBG_ENABLE is set, enabling standard Java debugger agent"
    DBG_PORT=${DBG_PORT:-5005}
    DBG_AGENT="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${DBG_PORT}"
    PROFILER_AGENT="-agentpath:/var/lib/yourkit/libyjpagent.so=port=1099,delay=10000,disablestacktelemetry,disableexceptiontelemetry"
  fi
else
  if [[ -n "$DBG_ENABLE" ]]; then
    echo "Running locally and DBG_ENABLE is set, enabling standard Java debugger agent"
    DBG_PORT=${DBG_PORT:-5005}
    DBG_AGENT="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${DBG_PORT}"
    PROFILER_AGENT="-agentpath:/var/lib/yourkit/libyjpagent.so=port=1099,delay=10000,disablestacktelemetry,disableexceptiontelemetry"
  fi
fi

JETTY_HOME=${RUNTIME_DIR}
JETTY_VERSION=9.2.5.v20141112

# to generate the good, fast cli:
#/usr/bin/java -Djetty.home=${RUNTIME_DIR} -Djetty.base=${RUNTIME_DIR} -jar ${RUNTIME_DIR}/start.jar --dry-run

/usr/bin/java ${JAVA_OPTS} ${DBG_AGENT} ${PROFILER_AGENT} \
-Djava.io.tmpdir=/tmp \
-Djetty.home=${JETTY_HOME} \
-Djetty.base=${JETTY_HOME} \
-Xms${HEAP_SIZE} -Xmx${HEAP_SIZE} \
-XX:PermSize=${PERM_SIZE} -XX:MaxPermSize=${MAX_PERM_SIZE} \
-cp \
${JETTY_HOME}/lib/ext/appengine-api-1.0-sdk-1.9.17.jar:\
${JETTY_HOME}/lib/ext/appengine-jetty-managed-runtime-1.9.17.jar:\
${JETTY_HOME}/lib/ext/appengine-managed-runtime-1.9.17.jar:\
${JETTY_HOME}/lib/apache-jsp/org.eclipse.jetty.apache-jsp-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/apache-jsp/org.eclipse.jetty.orbit.org.eclipse.jdt.core-3.8.2.v20130121.jar:\
${JETTY_HOME}/lib/apache-jsp/org.mortbay.jasper.apache-el-8.0.9.M3.jar:\
${JETTY_HOME}/lib/apache-jsp/org.mortbay.jasper.apache-jsp-8.0.9.M3.jar:\
${JETTY_HOME}/lib/apache-jstl/org.apache.taglibs.taglibs-standard-impl-1.2.1.jar:\
${JETTY_HOME}/lib/apache-jstl/org.apache.taglibs.taglibs-standard-spec-1.2.1.jar:\
${JETTY_HOME}/lib/servlet-api-3.1.jar:\
${JETTY_HOME}/lib/jetty-schemas-3.1.jar:\
${JETTY_HOME}/lib/annotations/asm-5.0.1.jar:\
${JETTY_HOME}/lib/annotations/asm-commons-5.0.1.jar:\
${JETTY_HOME}/lib/annotations/javax.annotation-api-1.2.jar:\
${JETTY_HOME}/lib/jndi/javax.mail.glassfish-1.4.1.v201005082020.jar:\
${JETTY_HOME}/lib/jndi/javax.transaction-api-1.2.jar:\
${JETTY_HOME}/lib/jetty-http-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-server-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-xml-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-util-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-io-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-jndi-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-security-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-servlet-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-webapp-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-deploy-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-plus-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-annotations-${JETTY_VERSION}.jar:\
${JETTY_HOME}/lib/jetty-quickstart-${JETTY_VERSION}.jar \
org.eclipse.jetty.xml.XmlConfiguration \
http.timeout=30000 \
jetty.dump.start=false \
jetty.dump.stop=false \
jetty.output.buffer.size=32768 \
jetty.port=8080 \
jetty.request.header.size=8192 \
jetty.response.header.size=8192 \
jetty.send.date.header=false \
jetty.send.server.version=true \
jsp-impl=apache \
threads.max=200 \
threads.min=10 \
threads.timeout=60000 \
${JETTY_HOME}/etc/jetty.xml \
${JETTY_HOME}/etc/jetty-http.xml \
${JETTY_HOME}/etc/jetty-deploy.xml \
${JETTY_HOME}/etc/jetty-plus.xml \
${JETTY_HOME}/etc/jetty-annotations.xml
