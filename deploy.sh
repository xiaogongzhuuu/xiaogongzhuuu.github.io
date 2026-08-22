#!/usr/bin/env bash
# 一键发布:本地构建站点,推送到 publish 分支,GitHub Pages 自动上线
set -euo pipefail
cd "$(dirname "$0")"

echo "==> 构建站点..."
hugo --gc --minify

DEPLOY_DIR="$(mktemp -d)"
trap 'rm -rf "$DEPLOY_DIR"' EXIT

# 取出 publish 分支(首次部署则新建空仓库)
if git rev-parse --verify --quiet origin/publish >/dev/null 2>&1; then
  git clone -q --depth 1 --branch publish "$(git remote get-url origin)" "$DEPLOY_DIR"
else
  git -C "$DEPLOY_DIR" init -q
  git -C "$DEPLOY_DIR" checkout -q --orphan publish
  git -C "$DEPLOY_DIR" remote add origin "$(git remote get-url origin)"
fi

# 清空旧内容,写入新的构建产物
find "$DEPLOY_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
cp -R public/. "$DEPLOY_DIR"/
touch "$DEPLOY_DIR/.nojekyll"

# 没有变化就不推
git -C "$DEPLOY_DIR" add -A
if git -C "$DEPLOY_DIR" diff --cached --quiet; then
  echo "没有变化,跳过发布。"
  exit 0
fi

echo "==> 推送到 publish 分支..."
git -C "$DEPLOY_DIR" commit -q -m "deploy: $(git log -1 --format=%h)"
git -C "$DEPLOY_DIR" push -q -u origin publish

echo "✅ 已发布: https://xiaogongzhuuu.github.io/ (稍等约 1 分钟生效)"
