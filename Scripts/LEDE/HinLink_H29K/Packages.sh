#!/bin/bash

# 安装和更新软件包
UPDATE_PACKAGE() {
    local PKG_NAME=$1
    local PKG_REPO=$2
    local PKG_BRANCH=$3
    local PKG_SPECIAL=$4
    local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
    local REPO_NAME=${PKG_REPO#*/}

    echo

    # 删除本地可能存在的不同名称的软件包
    for NAME in "${PKG_LIST[@]}"; do
        echo "搜索目录：$NAME"
        local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)
        if [ -n "$FOUND_DIRS" ]; then
            while read -r DIR; do
                rm -rf "$DIR"
                echo "删除目录：$DIR"
            done <<< "$FOUND_DIRS"
        else
            echo "未找到目录：$NAME"
        fi
    done

    # 克隆 GitHub 仓库
    git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git" || {
        echo "克隆仓库失败：$PKG_REPO"
        return
    }

    # 处理克隆的仓库
    if [[ $PKG_SPECIAL == "pkg" ]]; then
        find "./$REPO_NAME/" -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
        rm -rf "./$REPO_NAME/"
    elif [[ $PKG_SPECIAL == "name" ]]; then
        mv -f "$REPO_NAME" "$PKG_NAME"
    fi
}

# 更新软件包版本
UPDATE_VERSION() {
    local PKG_NAME=$1
    local PKG_MARK=${2:-false}
    local PKG_FILES
    IFS=$'\n' read -rd '' -a PKG_FILES <<< "$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")"

    if [ ${#PKG_FILES[@]} -eq 0 ]; then
        echo "$PKG_NAME 未找到!"
        return
    fi

    echo -e "\n$PKG_NAME 版本更新开始！"

    for PKG_FILE in "${PKG_FILES[@]}"; do
        local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" "$PKG_FILE")
        local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" \
                        | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

        local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
        local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
        local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
        local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

        local PKG_URL=$([[ $OLD_URL == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")
        local NEW_VER=$(echo "$PKG_TAG" | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
        local NEW_URL=$(echo "$PKG_URL" | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
        local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

        echo "旧版本：$OLD_VER $OLD_HASH"
        echo "新版本：$NEW_VER $NEW_HASH"

        if [[ $NEW_VER =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
            sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
            sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
            echo "$PKG_FILE 版本已更新！"
        else
            echo "$PKG_FILE 版本已经是最新的！"
        fi
    done
}

# 调用示例
UPDATE_PACKAGE "luci-app-tailscale"   "asvow/luci-app-tailscale"   "main" ""
UPDATE_PACKAGE "qmodem"               "FUjr/modem_feeds"           "main" ""
UPDATE_PACKAGE "vnt"                  "lmq8267/luci-app-vnt"       "main" ""
UPDATE_PACKAGE "homeproxy"            "immortalwrt/homeproxy"      "master" ""

# —— 新增：EasyTier 应用 —— 
UPDATE_PACKAGE "luci-app-easytier"    "EasyTier/luci-app-easytier" "main" ""

# 更新软件包版本
UPDATE_VERSION "sing-box"
UPDATE_VERSION "tailscale"
