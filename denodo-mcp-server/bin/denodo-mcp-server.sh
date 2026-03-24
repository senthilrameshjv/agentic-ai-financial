#!/bin/bash

# ---------------------------------------------------------------------------
# Environment variable JAVA_HOME must be set and exported
# ---------------------------------------------------------------------------

BIN_DIR=`dirname $0`
DIST_DIR=$BIN_DIR/..
LOG_FILE=$DIST_DIR/config/log4j2.xml
LIB_DIR=$DIST_DIR/lib


# ---------------------------------
# COMPUTE JAVA EXECUTABLE COMMAND
# ---------------------------------

JAVA_BIN=java
if [ -n "$JAVA_HOME" ]
then
  JAVA_BIN=$JAVA_HOME/bin/java
fi

if [ "$OSTYPE" = "cygwin" ]
then
  JAVA_BIN=`cygpath -p "$JAVA_BIN"`
fi


if [ ! -e "$JAVA_OPTS" ]
then   
    JAVA_OPTS="-Xmx1024m"
fi


# ---------------------------------
# COMPUTE JAVA VERSION
# ---------------------------------

JAVA_VERSION=`"$JAVA_BIN" -version 2>&1 | head -n 1 | cut -d\" -f 2`


# ---------------------------------
# OUTPUT EXECUTION ENVIRONMENT
# ---------------------------------

# ---------------------------------
# EXECUTE
# ---------------------------------

"$JAVA_BIN" $JAVA_OPTS -Dlogging.config="$LOG_FILE" -Dloader.path="$LIB_DIR" -jar "$LIB_DIR"/denodo-mcp-server-9-20260317.jar --spring.config.location=file:../config/
