
<!-- README.md is generated from README.Rmd. Please edit that file -->
kokudosuuchi
============

[![CircleCI](https://circleci.com/gh/yutannihilation/kokudosuuchi.svg?style=svg)](https://circleci.com/gh/yutannihilation/kokudosuuchi) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/yutannihilation/kokudosuuchi?branch=master&svg=true)](https://ci.appveyor.com/project/yutannihilation/kokudosuuchi) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/kokudosuuchi)](https://cran.r-project.org/package=kokudosuuchi)

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
d <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/P12/P12-14/P12-14_06_GML.zip",
                cache_dir = "cached_zip")
#> Using the cached zip file: cached_zip/P12-14_06_GML.zip
#> 
#> Details about this data can be found at http://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-P12-v2_2.html

d
#> $`P12a-14_06`
#> Simple feature collection with 10 features and 7 fields
#> geometry type:  POINT
#> dimension:      XY
#> bbox:           xmin: 139.706 ymin: 37.8562 xmax: 140.5295 ymax: 39.09917
#> epsg (SRID):    NA
#> proj4string:    +proj=longlat +ellps=GRS80 +no_defs
#> # A tibble: 10 x 8
#>    P12_001                      P12_002 P12_003             P12_004
#>      <int>                        <chr>   <chr>               <chr>
#>  1   10009                       飯豊山      06               06401
#>  2   10010                       鳥海山      06               06461
#>  3   10005                         月山      06               06203
#>  4   10006                       最上川      06 06204、06367、06428
#>  5   10007                   蔵王の樹氷      06               06207
#>  6   10003               立石寺（山寺）      06               06201
#>  7   10004                 出羽三山神社      06               06203
#>  8   10002                   花笠まつり      06               06201
#>  9   10008 銀山温泉の旅館街と共同浴場群      06               06212
#> 10   10001 蔵王温泉の酸性泉と源泉浴場群      06               06201
#> # ... with 4 more variables: P12_005 <chr>, P12_006 <chr>, P12_007 <int>,
#> #   geometry <S3: sfc_POINT>
#> 
#> $`P12b-14_06`
#> Simple feature collection with 1 feature and 7 fields
#> geometry type:  LINESTRING
#> dimension:      XY
#> bbox:           xmin: 139.808 ymin: 38.72274 xmax: 140.1937 ymax: 38.92187
#> epsg (SRID):    NA
#> proj4string:    +proj=longlat +ellps=GRS80 +no_defs
#> # A tibble: 1 x 8
#>   P12_001 P12_002 P12_003             P12_004    P12_005
#>     <int>   <chr>   <chr>               <chr>      <chr>
#> 1   10006  最上川      06 06204、06367、06428 河川・峡谷
#> # ... with 3 more variables: P12_006 <chr>, P12_007 <int>, geometry <S3:
#> #   sfc_LINESTRING>
#> 
#> $`P12c-14_06`
#> Simple feature collection with 2 features and 7 fields
#> geometry type:  POLYGON
#> dimension:      XY
#> bbox:           xmin: 139.9805 ymin: 38.31176 xmax: 140.4351 ymax: 38.70308
#> epsg (SRID):    NA
#> proj4string:    +proj=longlat +ellps=GRS80 +no_defs
#> # A tibble: 2 x 8
#>   P12_001        P12_002 P12_003 P12_004          P12_005
#>     <int>          <chr>   <chr>   <chr>            <chr>
#> 1   10003 立石寺（山寺）      06   06201 神社・寺院・教会
#> 2   10004   出羽三山神社      06   06203 神社・寺院・教会
#> # ... with 3 more variables: P12_006 <chr>, P12_007 <int>, geometry <S3:
#> #   sfc_POLYGON>
```

``` r
translateKSJData(d)
#> $`P12a-14_06`
#> Simple feature collection with 10 features and 7 fields
#> geometry type:  POINT
#> dimension:      XY
#> bbox:           xmin: 139.706 ymin: 37.8562 xmax: 140.5295 ymax: 39.09917
#> epsg (SRID):    NA
#> proj4string:    +proj=longlat +ellps=GRS80 +no_defs
#> # A tibble: 10 x 8
#>    観光資源_ID                   観光資源名 都道府県コード
#>          <int>                        <chr>          <chr>
#>  1       10009                       飯豊山         山形県
#>  2       10010                       鳥海山         山形県
#>  3       10005                         月山         山形県
#>  4       10006                       最上川         山形県
#>  5       10007                   蔵王の樹氷         山形県
#>  6       10003               立石寺（山寺）         山形県
#>  7       10004                 出羽三山神社         山形県
#>  8       10002                   花笠まつり         山形県
#>  9       10008 銀山温泉の旅館街と共同浴場群         山形県
#> 10       10001 蔵王温泉の酸性泉と源泉浴場群         山形県
#> # ... with 5 more variables: 行政コード <chr>, 種別名称 <chr>,
#> #   所在地住所 <chr>, 観光資源分類コード <chr>, geometry <S3: sfc_POINT>
#> 
#> $`P12b-14_06`
#> Simple feature collection with 1 feature and 7 fields
#> geometry type:  LINESTRING
#> dimension:      XY
#> bbox:           xmin: 139.808 ymin: 38.72274 xmax: 140.1937 ymax: 38.92187
#> epsg (SRID):    NA
#> proj4string:    +proj=longlat +ellps=GRS80 +no_defs
#> # A tibble: 1 x 8
#>   観光資源_ID 観光資源名 都道府県コード 行政コード   種別名称
#>         <int>      <chr>          <chr>      <chr>      <chr>
#> 1       10006     最上川         山形県       <NA> 河川・峡谷
#> # ... with 3 more variables: 所在地住所 <chr>, 観光資源分類コード <chr>,
#> #   geometry <S3: sfc_LINESTRING>
#> 
#> $`P12c-14_06`
#> Simple feature collection with 2 features and 7 fields
#> geometry type:  POLYGON
#> dimension:      XY
#> bbox:           xmin: 139.9805 ymin: 38.31176 xmax: 140.4351 ymax: 38.70308
#> epsg (SRID):    NA
#> proj4string:    +proj=longlat +ellps=GRS80 +no_defs
#> # A tibble: 2 x 8
#>   観光資源_ID     観光資源名 都道府県コード   行政コード         種別名称
#>         <int>          <chr>          <chr>        <chr>            <chr>
#> 1       10003 立石寺（山寺）         山形県 山形県山形市 神社・寺院・教会
#> 2       10004   出羽三山神社         山形県 山形県鶴岡市 神社・寺院・教会
#> # ... with 3 more variables: 所在地住所 <chr>, 観光資源分類コード <chr>,
#> #   geometry <S3: sfc_POLYGON>
```
