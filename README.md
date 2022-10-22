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
- 利用に際しては十分検証を行った上でご利用ください。本スクリプトの利用によって発生した事故や事象についての責任は負いません。

## 使用方法
### 事前準備
- conf.txt.org をコピーして conf.txt として保存
- 必要に応じて conf.txt 内の設定を調整
    - 設定できるパラメータの詳細は conf.txt 内のコメントを参照してください。

### 実行方法
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

history テーブルを確認した例

```
MariaDB [zabbix]> SELECT TABLE_NAME,PARTITION_NAME,DATA_FREE,TABLE_ROWS FROM INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_SCHEMA = 'zabbix' AND TABLE_NAME = 'history';
+------------+----------------+-----------+------------+
| TABLE_NAME | PARTITION_NAME | DATA_FREE | TABLE_ROWS |
+------------+----------------+-----------+------------+
| history    | p202210        |         0 |       4707 |
| history    | p202211        |         0 |          0 |
| history    | p202212        |         0 |          0 |
| history    | p202301        |         0 |          0 |
| history    | p202302        |         0 |          0 |
| history    | p202303        |         0 |          0 |
| history    | p202304        |         0 |          0 |
| history    | p202305        |         0 |          0 |
| history    | p202306        |         0 |          0 |
| history    | p202307        |         0 |          0 |
| history    | p202308        |         0 |          0 |
| history    | p202309        |         0 |          0 |
+------------+----------------+-----------+------------+
12 rows in set (0.00 sec)

MariaDB [zabbix]>
```
