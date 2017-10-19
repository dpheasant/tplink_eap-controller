#!/bin/sh

## set a sensible default for $EAP_HOME if not already set by image
[[ -z "${EAP_HOME}" ]] && export EAP_HOME=/opt/tplink/EAP_Controller

## set some variables...
export DB_HOST='localhost'
export DB_PORT='27017'
export APP_HOST='localhost'
export APP_PORT='8088'
export JAVA_HOME=${EAP_HOME}/jre
export PATH=$PATH:$JAVA_HOME/bin

## echo some useful debugging info...
echo "-------------------------------------------------------------"
echo "EAP_HOME  : ${EAP_HOME}"
echo "JAVA_HOME : ${JAVA_HOME}"
echo "PATH      : ${PATH}"
echo "-------------------------------------------------------------"

## gracefully stops the application
function stop() {
    signal=$1
    echo ""
    echo "!!!! Caught $signal !!!!"
    echo "Stopping application...."

    java \
     -Deap.home="${EAP_HOME}" \
     -cp ${EAP_HOME}"/lib/com.tp-link.eap.start-0.0.1-SNAPSHOT.jar:"${EAP_HOME}"/lib/*:"${EAP_HOME}"/external-lib/*" \
     com.tp_link.eap.start.EapMain stop 2>&1
}

## function to check if host is listening on port
function isOpen() {
    host=$1
    port=$2
    ( < /dev/tcp/$host/$port ) 2>/dev/null
    return $?
}

# signals to trap for graceful shutdown
trap "stop SIGINT"  INT
trap "stop SIGTERM" TERM

## create a directory for the logs...
[ ! -d "${EAP_HOME}/logs" ] && mkdir "$EAP_HOME/logs"

## start the application in the background
echo "Starting application..."
java -server   \
     -Xms128m  \
     -Xmx1024m \
     -XX:MaxHeapFreeRatio=60 \
     -XX:MinHeapFreeRatio=30 \
     -XX:+UseSerialGC \
     -XX:+HeapDumpOnOutOfMemoryError \
     -Deap.home="${EAP_HOME}" \
     -cp ${EAP_HOME}"/lib/com.tp-link.eap.start-0.0.1-SNAPSHOT.jar:"${EAP_HOME}"/lib/*:"${EAP_HOME}"/external-lib/*" \
     com.tp_link.eap.start.EapMain start 2>&1 &

## test for database availability
until isOpen $DB_HOST $DB_PORT; do
  echo "Database starting..."
  sleep 2
done
echo "Database started!"

## test for application availability
until isOpen $APP_HOST $APP_PORT; do
  echo "Application starting..."
  sleep 2
done
echo "Application started!"

## wait on child process(es) to finish
wait