kokudosuuchi
============

国土数値情報ダウンロードサービス Web APIの情報を取得するRパッケージです。


## 国土数値情報ダウンロードサービス Web APIとは

2014/12から国土交通省国土政策局が提供しているGISで利用可能な国土数値情報を取得できるAPIです。本パッケージはバージョン1.0bに対応しています。

公式ページ：http://nlftp.mlit.go.jp/ksj/api/about_api.html


## 利用上の注意

APIの利用やAPIで得られるURL先のGISデータの利用にあたっては、国土数値情報ダウンロードサービスの利用約款、及び、同Web APIの利用規約をご確認の上ご利用ください。

* http://nlftp.mlit.go.jp/ksj/other/yakkan.html
* http://nlftp.mlit.go.jp/ksj/api/about_api.html


## インストール方法

```r
devtools::install_github("yutannihilation/kokudosuuchi")
```

## 使用方法

※詳しいパラメータの意味は公式ドキュメント（[http://nlftp.mlit.go.jp/ksj/api/specification_api_ksj.pdf]）をご参照ください

### 国土数値情報の概要情報取得

```r
library(kokudosuuchi)

getKSJSummary()
#> Source: local data frame [100 x 5]
#> 
#>    identifier                title           field1       field2 areaType
#>         (chr)                (chr)            (chr)        (chr)    (chr)
#> 1         A03   三大都市圏計画区域         政策区域     大都市圏        2
#> 2         A09             都市地域 国土（水・土地）     土地利用        3
#> 3         A10         自然公園地域             地域     保護保全        3
#> ...
```

### 国土数値情報取得のURL情報取得

```r
library(kokudosuuchi)

# prefCodeが3で、年が2000-2010の河川のデータ
getKSJURL("W05", prefCode = 3, fiscalyer = 2000:2010)
#> Source: local data frame [1 x 9]
#> 
#>   identifier title            field  year areaType areaCode datum                                                        zipFileUrl
#>        (chr) (chr)            (chr) (chr)    (chr)    (chr) (chr)                                                             (chr)
#> 1        W05  河川 国土（水・土地）  2007        3        3     1 http://nlftp.mlit.go.jp/ksj/gml/data/W05/W05-07/W05-07_03_GML.zip
#>   zipFileSize
#>         (chr)
#> 1     10.42MB
```
