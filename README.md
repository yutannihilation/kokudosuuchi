
<!-- README.md is generated from README.Rmd. Please edit that file -->
kokudosuuchi
============

[![Travis-CI Build Status](https://travis-ci.org/yutannihilation/kokudosuuchi.svg?branch=master)](https://travis-ci.org/yutannihilation/kokudosuuchi) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/yutannihilation/kokudosuuchi?branch=master&svg=true)](https://ci.appveyor.com/project/yutannihilation/kokudosuuchi) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/kokudosuuchi)](https://cran.r-project.org/package=kokudosuuchi)

**(Sorry, English version of README is not availavle for now.)**

国土数値情報ダウンロードサービス Web APIの情報を取得するRパッケージです。

国土数値情報ダウンロードサービス Web APIとは
--------------------------------------------

2014/12から国土交通省国土政策局が提供しているGISで利用可能な国土数値情報を取得できるAPIです。本パッケージはバージョン1.0bに対応しています。

公式ページ：<http://nlftp.mlit.go.jp/ksj/api/about_api.html>

利用上の注意
------------

APIの利用やAPIで得られるURL先のGISデータの利用にあたっては、国土数値情報ダウンロードサービスの利用約款、及び、同Web APIの利用規約をご確認の上ご利用ください。

-   <http://nlftp.mlit.go.jp/ksj/other/yakkan.html>
-   <http://nlftp.mlit.go.jp/ksj/api/about_api.html>

インストール方法
----------------

kokudosuuchiはCRANからインストールできます。

``` r
install.packages("kokudosuuchi")
```

開発版をインストールするには`devtools::install_github()`でインストールしてください。

``` r
devtools::install_github("yutannihilation/kokudosuuchi")
```

使用方法
--------

詳しいパラメータの意味は[公式ドキュメント](http://nlftp.mlit.go.jp/ksj/api/specification_api_ksj.pdf)（PDF）をご参照ください

### 国土数値情報の概要情報取得

``` r
library(kokudosuuchi)
#> このサービスは、「国土交通省　国土数値情報（カテゴリ名）」をもとに加工者が作成
#> 以下の国土数値情報ダウンロードサービスの利用約款をご確認の上ご利用ください：
#> 
#> http://nlftp.mlit.go.jp/ksj/other/yakkan.html

getKSJSummary()
#> # A tibble: 102 x 5
#>    identifier                title           field1       field2 areaType
#>         <chr>                <chr>            <chr>        <chr>    <chr>
#>  1        A03   三大都市圏計画区域         政策区域     大都市圏        2
#>  2        A09             都市地域 国土（水・土地）     土地利用        3
#>  3        A10         自然公園地域             地域     保護保全        3
#>  4        A11         自然保全地域             地域     保護保全        3
#>  5        A12             農業地域 国土（水・土地）     土地利用        3
#>  6        A13             森林地域 国土（水・土地）     土地利用        3
#>  7        A15           鳥獣保護区             地域     保護保全        3
#>  8        A16         人口集中地区         政策区域            -        3
#>  9        A17             過疎地域         政策区域 条件不利地域        3
#> 10        A18 半島振興対策実施地域         政策区域 条件不利地域        3
#> # ... with 92 more rows
```

### 国土数値情報のURL情報取得

``` r
# prefCodeが3で、年が2000-2010の河川のデータ
getKSJURL("W05", prefCode = 3, fiscalyear = 2000:2010)
#> # A tibble: 1 x 9
#>   identifier title            field  year areaType areaCode datum
#>        <chr> <chr>            <chr> <chr>    <chr>    <chr> <chr>
#> 1        W05  河川 国土（水・土地）  2007        3        3     1
#> # ... with 2 more variables: zipFileUrl <chr>, zipFileSize <chr>
```

### 国土数値情報のGISデータ取得

``` r
options(max.print = 20)
getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/W05/W05-07/W05-07_03_GML.zip")
```
