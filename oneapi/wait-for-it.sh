#!/bin/bash

# 用法： wait-for-it.sh 主机:端口号 [-t 超时秒数] [-- 命令 [参数…]]

# 等待指定的 TCP 主机:端口准备就绪
# -t 超时秒数 可选参数，设置超时秒数，默认为15秒
# 通过后可以选择执行后续命令

hostport=$1
timeout=15
cmdname="wait-for-it.sh"

usage() {
  cat << EOM
用法： $cmdname 主机:端口号 [-t 超时秒数] [-- 命令 [参数…]]
  -t 超时秒数  可选参数，设置超时秒数，默认为15秒
  -- 命令 [参数…]  可选参数，设置等待成功后执行的命令和参数
EOM
}

wait_for() {
  local cmdname=$1
  local timeout=$2
  local hostport=$3
  local host=$(echo $hostport | cut -d: -f1)
  local port=$(echo $hostport | cut -d: -f2)
  local start_ts=$(date +%s)
  local end_ts=$((start_ts + timeout))

  while :
  do
    nc -z "$host" "$port" &> /dev/null
    result=$?
    if [ $result -eq 0 ]; then
      end_ts=$(date +%s)
      echo "$hostport 等待成功，用时 $((end_ts - start_ts)) 秒"
      break
    fi

    cur_ts=$(date +%s)
    if [ $cur_ts -gt $end_ts ]; then
      echo "$hostport 等待超时，超时时间 $timeout 秒"
      exit 1
    fi

    sleep 1
  done
}

# 处理参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    *:* )
      hostport=$1
      shift 1
      ;;
    -t )
      timeout="$2"
      if [[ ! "$timeout" =~ ^[0-9]+$ ]]; then
        echo "错误：'-t' 参数需要是一个数字。" >&2
        usage
        exit 1
      fi
      shift 2
      ;;
    --)
      shift
      break
      ;;
    * )
      echo "错误：未知参数: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ "$hostport" = "" ]; then
  echo "错误：未提供主机:端口号。" >&2
  usage
  exit 1
fi

wait_for "$cmdname" "$timeout" "$hostport"

# 如果有命令需要执行，则执行命令
if [ $# -gt 0 ]; then
  exec "$@"
fi
