#!/bin/bash
# Copyright (c) 2026 Hygon Information Technology Co., Ltd.
# SPDX-License-Identifier: Apache-2.0
#
# 在【联网机器】上执行：构建离线构建镜像，并导出为可拷贝到离线 DCU 机器的 tar 包。
#
# 用法：
#   ./build/build-image.sh                 # 构建 + 导出 build/hcu-dcgm-build.tar
#   ./build/build-image.sh --no-export     # 仅构建镜像，不导出 tar
#   GO_VERSION=1.23.4 ./build/build-image.sh  # 指定 Go 版本（需与 go.mod 兼容）
#
# 产物：build/hcu-dcgm-build.tar（内含镜像 hcu-dcgm-build:latest）
# 拷贝：scp build/hcu-dcgm-build.tar user@dcu-host:/tmp/
# 导入：docker load -i /tmp/hcu-dcgm-build.tar

set -euo pipefail

cd "$(dirname "$0")/.."

IMAGE_NAME="${IMAGE_NAME:-hcu-dcgm-build}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
GO_VERSION="${GO_VERSION:-1.22.8}"
DO_EXPORT=1

for arg in "$@"; do
  case "$arg" in
    --no-export) DO_EXPORT=0 ;;
    *) echo "未知参数: $arg" >&2; exit 1 ;;
  esac
done

echo "==> 构建离线构建镜像 ${IMAGE_NAME}:${IMAGE_TAG} (Go ${GO_VERSION})"
docker build \
  --build-arg GO_VERSION="${GO_VERSION}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  -f build/Dockerfile.build \
  .

if [ "${DO_EXPORT}" -eq 1 ]; then
  OUTFILE="build/${IMAGE_NAME}-${IMAGE_TAG}.tar"
  echo "==> 导出镜像到 ${OUTFILE}"
  docker save -o "${OUTFILE}" "${IMAGE_NAME}:${IMAGE_TAG}"
  echo "==> 完成。离线机器导入命令："
  echo "    docker load -i ${OUTFILE}"
fi
