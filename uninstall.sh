#!/bin/bash
##########################################
# uninstaller for ALMinium
# 第1引数：データベースホスト名
# 第2引数：データベース管理者パスワード
##########################################
ALM_SRC_DIR=$(cd $(dirname $0);pwd)
ALM_ETC_DIR=${ALM_ETC_DIR:-/etc/opt/alminium}
ALM_VAR_DIR=${ALM_VAR_DIR:-/var/opt/alminium}
ALM_INSTALL_DIR=${ALM_INSTALL_DIR:-/opt/alminium}

ALM_DB_HOST=${1:-${ALM_DB_HOST}}
ALM_DB_HOST=${ALM_DB_HOST:-localhost}
ALM_DB_ROOT_PASS=${2:-${ALM_DB_ROOT_PASS}}

GEM=`which gem2.0`
GEM=${GEM:-gem}

# move to sources directry
cd ${ALM_SRC_DIR}

# include functions
source inst-script/functions.sh

# start uninstall
echo "ALMiniumをアンインストールします。"
echo ""

# remove db
echo -n "データベース(全てのRedmineの情報)とリポジトリを削除しますか?(y/N)"
read YN
if [ "$YN" = "y" ]; then
    DBCMD="mysql `db_option_root`"
    ${DBCMD} alminium -e "REVOKE ALL ON alminium.* FROM alminium@%" \
             2>/dev/null
    ${DBCMD} alminium -e "REVOKE ALL ON alminium.* FROM alminium@localhost" \
             2>/dev/null
    ${DBCMD} alminium -e "DELETE FROM mysql.user WHERE User LIKE 'alminium'"
    ${DBCMD} alminium -e "FLUSH PRIVILEGES"
    ${DBCMD} alminium -e "DROP DATABASE alminium"
    rm -fr ${ALM_INSTALL_DIR}/* ${ALM_INSTALL_DIR}/.[^.]*  ${ALM_VAR_DIR}/*
fi

# remove apache2 config
echo ""
echo -n "Apacheの設定を削除しますか?(y/N)"
read YN
if [ "$YN" = "y" ]; then
    rm -fr /etc/httpd/conf.d/{alminium}.conf
    rm -fr /etc/apache2/conf.d/{alminium}.conf
    rm -fr /etc/apache2/sites-{available,enabled}/alminium.conf
    rm -fr $ALM_ETC_DIR/*
fi

# uninstall jenkins
echo ""
echo -n "Jenkinsとその設定を削除しますか?(y/N)"
read YN
if [ "$YN" = "y" ]; then
    source jenkins/setup/uninstall.sh
fi

# remove cache
echo ""
echo -n "キャッシュされたファイルを削除しますか?(y/N)"
read YN
if [ "$YN" = "y" ]; then
    rm -fr cache *.installed
fi
