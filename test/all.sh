#!/usr/bin/env bash

set -e

on_exit() {
  exitcode=$?
  if [ $exitcode != 0 ] ; then
    echo -e '\e[41;33;1m'"Failure encountered!"'\e[0m'
    exit ${exitcode}
  fi
}

trap on_exit EXIT

test() {
  set -e
  base_dir="$(cd "$(dirname $0)" ; pwd )"
  if [ -f "${base_dir}/../out" ] ; then
    cmd="../out"
  elif [ -f /opt/resource/out ] ; then
    cmd="/opt/resource/out"
  fi

  cat <<EOM >&2
------------------------------------------------------------------------------
TESTING: $1

Input:
$(cat ${base_dir}/${1}.out)

Output:
EOM

  result="$(cd $base_dir && cat ${1}.out | $cmd . 2>&1 | tee /dev/stderr)"
  echo >&2 ""
  echo >&2 "Result:"
  echo "$result" # to be passed into jq -e
}

# simulate environment as in executing the resource in Concourse
export BUILD_ID=10
export BUILD_PIPELINE_NAME='my-pipeline'
export BUILD_JOB_NAME='my-job'
export BUILD_NAME='my-build'
export BUILD_TEAM_NAME='main'
export ATC_EXTERNAL_URL='http://concourse.local'

# run test cases
test 'simple_metric' | jq -e "
    .pushgw_url == $(echo 'http://pushgw:9091' | jq -R .) and
    .body == $(echo 'simple_metric 0' | jq -R .) and
    .job == $(echo 'simple_metric' | jq -R .)"

test 'jobname_override' | jq -e "
    .pushgw_url == $(echo 'http://pushgw:9091' | jq -R .) and
    .body == $(echo 'simple_metric 0' | jq -R .) and
    .job == $(echo 'override' | jq -R .)"

expected_body='metric_with_kv{key-1=\"value-2\"} 0'
test 'metric_with_kv' | jq -e "
    .pushgw_url == $(echo 'http://pushgw:9091' | jq -R .) and
    .body == \"${expected_body}\" and
    .job == $(echo 'metric_with_kv' | jq -R .)"

expected_body='complex_metric{label_1=\"value-1\", label_2=\"value-2\"} 1'
test 'complex_metric' | jq -e "
    .pushgw_url == $(echo 'http://pushgw:9091' | jq -R .) and
    .body == \"${expected_body}\" and
    .job == $(echo 'metric_with_kv' | jq -R .)"

expected_body='metric_with_env_vars{BUILD_ID=\"'$BUILD_ID'\", BUILD_PIPELINE_NAME=\"'$BUILD_PIPELINE_NAME'\", BUILD_JOB_NAME=\"'$BUILD_JOB_NAME'\", BUILD_NAME=\"'$BUILD_NAME'\", BUILD_TEAM_NAME=\"'$BUILD_TEAM_NAME'\", ATC_EXTERNAL_URL=\"'$ATC_EXTERNAL_URL'\"} 0'
test 'metric_with_env_vars' | jq -e "
    .pushgw_url == $(echo 'http://pushgw:9091' | jq -R .) and
    .body == \"${expected_body}\" and
    .job == $(echo 'metric_with_env_vars' | jq -R .)"
