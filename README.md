# zabbix_partition_utility

## LICENSE
This software is released under the MIT License, see LICENSE.txt.
## 概要
MariaDB で作成された Zabbix DB に RANGE パーティションを作成する SQLコマンドを書き出す補助スクリプトです。

## 仕様
本スクリプトは MariaDB で稼働している Zabbix の DB を1か月単位の RANGE でパーティショニングするための SQLコマンドを作成、表示します。
SQL コマンドは以下の仕様に沿って作成されます。

- MariaDB で稼働している Zabbix の DB を1か月単位の RANGE でパーティショニングします。
- スクリプト実行日時の月を初月として12か月分のパーティションを作成します。
- パーティションは以下テーブルに対して作成します。
    - history
    - history_uint
    - history_str
    - history_log
    - history_text
    - trends
    - trends_uint
### メモ
- 現時点より過去の月のパーティションを作成したい場合にや12か月分以上のパーティションを作成したい場合には、スクリプトの DEFINITION にある変数を編集して実行してください。

## 注意事項
- 本スクリプトで作成される SQL コマンドで作成されるパーティションは MAXVALUE は設定していません。適宜新しいパーティションを作成して運用してください。
- 本スクリプトで作成される SQL コマンドは初回パーティショニング作成用です。冪等性はありません。
## 使用方法
- パーティショニングを実施したいサーバーに本リポジトリを展開
- 展開したリポジトリ配下に移動
- 以下のコマンドを実行して SQLコマンドが記載されたファイルを作成

```
sh make_partition_mariadb_sql.sh > create.sql
```

- 以下のコマンドで sql を実行

```
mysql -u <db_username> -p zabbix < create.sql
```

## 参考
### パーティションの状態確認
DB にログインして以下のコマンドを実行

```
SELECT TABLE_NAME,PARTITION_NAME,DATA_FREE,TABLE_ROWS FROM INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_SCHEMA = 'zabbix' AND TABLE_NAME = '<テーブル名>';
```
