#!/bin/bash
# This script runs a given command in the background while monitoring the log output
# (specified by ENV variables) until the given TRIGGER string is logged,
# at which point, the final command is executed.
# Expected env vars: $CONTAINER_COMPOSE_LOG || (CONTAINER_LOG_DIR && $COMPOSE_LOG_FILE) w/ $CONTAINER_COMPOSE_LOG preceding
# TODO: USAGE:

TRIGGER_STRING="$1"
FINAL_CMD="$2"

# Where the host compose log file will be mounted within the container asynchronously waiting
LOG="$CONTAINER_LOG_DIR/$COMPOSE_LOG_FILE"
CONTAINER_COMPOSE_LOG="${CONTAINER_COMPOSE_LOG:-$LOG}"

# Log monitoring command
TAIL_CMD="exec tail -n 0 -f $CONTAINER_COMPOSE_LOG"

# Prevent logging the TRIGGER string in order to hold final command execution until the real signal is received
LOGGABLE_TRIGGER_STRING="${TRIGGER_STRING:0:1}:${TRIGGER_STRING:1}"
LOGGABLE_FINAL_CMD="${FINAL_CMD/$TRIGGER_STRING/$LOGGABLE_TRIGGER_STRING}"
echo "Waiting for trigger \"$LOGGABLE_TRIGGER_STRING\" in $CONTAINER_COMPOSE_LOG before executing \"$LOGGABLE_FINAL_CMD\""

# Wait for matching log entry && kill tail process
sed "/$TRIGGER_STRING/q" <($TAIL_CMD) && kill $!
echo done
$FINAL_CMD
