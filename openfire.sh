#!/bin/sh

# REQUIRE: FILESYSTEMS
# REQUIRE: NETWORKING
# PROVIDE: openfire

. /etc/rc.subr

name="openfire"
rcvar="openfire_enable"
start_cmd="openfire_start"
stop_cmd="openfire_stop"
OPENFIRE_HOME="/openfire"
pidfile="/var/run/${name}.pid"

load_rc_config ${name}

openfire_start()
{
  if checkyesno ${rcvar}; then
    echo "Starting Openfire controller. "
    echo "" | nc -l 127.0.0.1 666 >/dev/null &
    OPENFIRE_LIB="${OPENFIRE_HOME}/lib"
    OPENFIRE_OPTS="${OPENFIRE_OPTS} -DopenfireHome=\"${OPENFIRE_HOME}\" -Dopenfire.lib.dir=\"${OPENFIRE_LIB}\""
    LOCALCLASSPATH=$OPENFIRE_LIB/startup.jar
    /usr/local/bin/java -server $OPENFIRE_OPTS -classpath $LOCALCLASSPATH -jar $OPENFIRE_LIB/startup.jar &
    echo $! > $pidfile

  fi
}

openfire_stop()
{

  if [ -f $pidfile ]; then
    echo -n "Waiting for the Openfire controller to stop (this can take a long time)..."
    pkill -F $pidfile
    # ...then we wait until the service identified by the pid file goes away:
    while [ `pgrep -F $pidfile` ]; do
      echo -n "."
      sleep 5
    done

    # Remove the pid file:
    rm $pidfile

    echo " stopped.";
  else
    echo "There is no pid file. The controller may not be running."
  fi
}

run_rc_command "$1"