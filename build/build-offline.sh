#!/bin/bash
# Copyright (c) 2026 Hygon Information Technology Co., Ltd.
# SPDX-License-Identifier: Apache-2.0
#
# 在【离线 DCU 机器】上执行：用已导入的构建镜像离线编译 hcu-dcgm 二进制。
#
# 前置：
#   1. 已导入镜像：docker load -i hcu-dcgm-build-latest.tar
#   2. 本机已安装 HCU 驱动（/opt/hyhal/lib 下存在 librocm_smi64.so、libhydmi.so 及其软链接；
#      启用 MIG 功能还需 libhydmi_mig.so）。
#   3. 源码（含 vendor/）已放到当前仓库目录。
#
# 用法（在仓库根目录执行）：
#   ./build/build-offline.sh               # 编译 HTTP 服务 + 命令行工具
#   ./build/build-offline.sh dcgmi         # 只编译命令行工具
#
# 产物默认输出到 ./bin/。

set -euo pipefail

cd "$(dirname "$0")/.."

IMAGE_NAME="${IMAGE_NAME:-hcu-dcgm-build}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
OUT_DIR="${OUT_DIR:-bin}"

if [ ! -d vendor ]; then
  echo "错误：未找到 vendor/ 目录，请先在联网机器上执行 go mod vendor。" >&2
  exit 1
fi

if [ ! -d /opt/hyhal/lib ]; then
  echo "错误：未找到 /opt/hyhal/lib，请确认已安装 HCU 驱动。" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

TARGETS=("$@")
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=("service" "cmd")
fi

for t in "${TARGETS[@]}"; do
  case "$t" in
    service|hcu-dcgm)
      echo "==> 编译 HTTP 服务二进制 hcu-dcgm"
      docker run --rm \
        -v "$(pwd)":/src \
        -v /opt/hyhal:/opt/hyhal \
        -w /src \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        go build -o /src/"${OUT_DIR}"/hcu-dcgm ./pkg/service
      ;;
    cmd|cli|dcgmi)
      echo "==> 编译命令行工具 dcgmi"
      docker run --rm \
        -v "$(pwd)":/src \
        -v /opt/hyhal:/opt/hyhal \
        -w /src \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        go build -o /src/"${OUT_DIR}"/dcgmi ./pkg/cmd
      ;;
    *)
      echo "未知目标: $t (可选: service / cmd)" >&2
      exit 1
      ;;
  esac
done

echo "==> 完成。产物位于 ${OUT_DIR}/："
ls -l "${OUT_DIR}"
