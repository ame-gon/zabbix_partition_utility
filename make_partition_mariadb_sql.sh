#!/bin/bash

# 動作仕様
# 以下のようなSQL文をテーブル毎 (history, history_uint, history_str, history_text, history_log, trends, trends_uint) に作成する
#
# ALTER TABLE `history` PARTITION BY RANGE (clock) (
# PARTITION p2021_06 VALUES LESS THAN (UNIX_TIMESTAMP("2021-07-01 00:00:00")) ENGINE = InnoDB,
# PARTITION p2023_08 VALUES LESS THAN (UNIX_TIMESTAMP("2023-09-01 00:00:00")) ENGINE = InnoDB
# );

# 外部定義ファイルの読み込み
source ./config.txt

### DEFINITION：外部ファイルから読み込み
# 現在時から過去何か月分さかのぼったパーティションを作成するか指定
GLOBAL_PAST_PARTITION_COUNT=$GLOBAL_PAST_PARTITION_COUNT
# 全部で何か月分のパーティションを作成するか指定
GLOBAL_PARTITION_COUNT=$GLOBAL_PARTITION_COUNT

### 関数

# set_primarykey_sql
#
# テーブルのプライマリキー設定を変更するコマンドを記載
# 引数
#    なし
#
function set_primarykey_sql () {
    # history
    echo "DROP INDEX \`history_1\` ON \`history\`;"
    echo "ALTER TABLE \`history\` ADD PRIMARY KEY (\`itemid\`, \`clock\`, \`ns\`);"
    # history_uint
    echo "DROP INDEX \`history_uint_1\` ON \`history_uint\`;"
    echo "ALTER TABLE \`history_uint\` ADD PRIMARY KEY (\`itemid\`, \`clock\`, \`ns\`);"
    # history_str
    echo "ALTER TABLE \`history_str\` ADD PRIMARY KEY (\`itemid\`, \`clock\`, \`ns\`);"
    # history_text
    echo "ALTER TABLE \`history_text\` ADD PRIMARY KEY (\`itemid\`, \`clock\`, \`ns\`);"
    # history_log
    echo "ALTER TABLE \`history_log\` ADD PRIMARY KEY (\`itemid\`, \`clock\`, \`ns\`);"
}

# make_partition_sql_by_table
#
# テーブル用のパーティション作成コマンドを表示する
# 引数
#    $1 テーブル名
#    $2 パーティションの作成開始年
#    $3 パーティションの作成開始月
#    $4 作成するパーティションの数
#
function make_partition_sql_by_table () {
    # 引数をセット
    TABLE_NAME=$1
    START_PARTITION_YEAR=$2
    START_PARTITION_MONTH=$3
    PARTITION_COUNT=$4

    # 作成するパーティション数 = ループ回数としてセット
    ROOP_COUNT=$PARTITION_COUNT

    echo "ALTER TABLE \`${TABLE_NAME}\` PARTITION BY RANGE (clock) ("

    PARTITION_YEAR=$START_PARTITION_YEAR
    PARTITION_MONTH=$START_PARTITION_MONTH

    for i in `seq 1 $ROOP_COUNT`
    do
        # ループの初回以外は必要に応じてパーティション月のカウントアップを行う。
        if [[ $i -ne 1 ]]; then
            PARTITION_MONTH=$(expr $PARTITION_MONTH + 1)

            # パーティション作成月が13になった場合、パーティション作成年を +1 して作成付きは 1 にする 。
            if [[ $PARTITION_MONTH -eq 13 ]]; then
                PARTITION_MONTH=1
                PARTITION_YEAR=$(expr $PARTITION_YEAR + 1)
            fi
            if [[ ${PARTITION_MONTH} =~ ^[0-9]$ ]]; then
                PARTITION_MONTH="0${PARTITION_MONTH}"
            fi
        fi
        PARTITION_NAME="p${PARTITION_YEAR}${PARTITION_MONTH}"

        # UNIX_TIMESTAMP に渡す年月を作成する：パーティション名の年月より1か月後を指定！
        # UNIX_TIMESTAMP 用の変数を初期化
        UNIX_TIMESTAMP_PARTITION_YEAR=$PARTITION_YEAR
        UNIX_TIMESTAMP_PARTITION_MONTH=$PARTITION_MONTH

        # まず月を１か月後に設定
        UNIX_TIMESTAMP_PARTITION_MONTH=$(expr $PARTITION_MONTH + 1)
        # パーティション作成月が13になった場合、パーティション作成年を +1 して作成付きは 1 にする 。
        if [[ $UNIX_TIMESTAMP_PARTITION_MONTH -eq 13 ]]; then
            UNIX_TIMESTAMP_PARTITION_MONTH=1
            UNIX_TIMESTAMP_PARTITION_YEAR=$(expr $PARTITION_YEAR + 1)
        fi
        if [[ ${UNIX_TIMESTAMP_PARTITION_MONTH} =~ ^[0-9]$ ]]; then
            UNIX_TIMESTAMP_PARTITION_MONTH="0${UNIX_TIMESTAMP_PARTITION_MONTH}"
        fi

        # 行末にカンマをつけるかどうか確認。
        # つける必要がある場合には END_CUNMA にカンマをセット。
        END_CUNMA=""
        if [[ $i -ne $ROOP_COUNT ]]; then
            END_CUNMA=","
        fi

        echo "PARTITION ${PARTITION_NAME} VALUES LESS THAN (UNIX_TIMESTAMP(\"${UNIX_TIMESTAMP_PARTITION_YEAR}-${UNIX_TIMESTAMP_PARTITION_MONTH}-01 00:00:00\")) ENGINE = InnoDB${END_CUNMA}"

    done

    # 最終行に記載
    echo ");"
}

### Main

# 現在日時から日付情報を取得
CURRENT_YEAR=`date '+%Y'`
CURRENT_MONTH=`date '+%m'`

START_PARTITION_YEAR=$CURRENT_YEAR
START_PARTITION_MONTH=$CURRENT_MONTH

# 過去のパーティション作成用の調整
PAST_PARTITION_COUNT=$GLOBAL_PAST_PARTITION_COUNT

if [[ $PAST_PARTITION_COUNT -gt 0 ]]; then
    for i in `seq 1 $PAST_PARTITION_COUNT`
    do
        START_PARTITION_MONTH=$(expr $START_PARTITION_MONTH - 1)

        if [[ $START_PARTITION_MONTH -eq 0 ]]; then
            START_PARTITION_MONTH=12
            START_PARTITION_YEAR=$(expr $START_PARTITION_YEAR - 1)
        fi
        if [[ ${START_PARTITION_MONTH} =~ ^[0-9]$ ]]; then
            START_PARTITION_MONTH="0${START_PARTITION_MONTH}"
        fi
    done
fi

# プライマリキーの設定
set_primarykey_sql

# SQL文作成処理(テーブル毎に実行)
for table_name in "history" "history_uint" "history_str" "history_log" "history_text" "trends" "trends_uint"
do
    make_partition_sql_by_table $table_name $START_PARTITION_YEAR $START_PARTITION_MONTH $GLOBAL_PARTITION_COUNT
done
