
<!-- README.md is generated from README.Rmd. Please edit that file -->

# kokudosuuchi

<!-- badges: start -->

[![R-CMD-check](https://github.com/yutannihilation/kokudosuuchi/workflows/R-CMD-check/badge.svg)](https://github.com/yutannihilation/kokudosuuchi/actions)
<!-- badges: end -->

**(Sorry, English version of README is not available for now.)**

国土数値情報ダウンロードサービスからダウンロードしたデータを読み込むRパッケージです。

## 利用上の注意

国土数値情報ダウンロードサービス提供のデータは、規約をご確認の上ご利用ください。

-   <https://nlftp.mlit.go.jp/ksj/other/agreement.html>

## インストール方法

kokudosuuchiはCRANからインストールできますが、国土数値情報APIが廃止される以前のものなのでおすすめしません。

``` r
# install.packages("kokudosuuchi")
```

開発版をインストールするには`devtools::install_github()`でインストールしてください。

``` r
devtools::install_github("yutannihilation/kokudosuuchi")
```

## 使用方法

### `readKSJData()`

国土数値情報ダウンロードサービスからダウンロードしてきたZIPファイル（もしくはそれを展開したディレクトリ）を指定すると、データを`sf`形式で読み込みます。

``` r
library(kokudosuuchi)

d <- readKSJData("tests/testthat/zip/L01-20_30_GML.zip")
d
#> $`L01-20_30`
#> Simple feature collection with 180 features and 130 fields
#> geometry type:  POINT
#> dimension:      XY
#> bbox:           xmin: 135.0735 ymin: 33.47266 xmax: 136.0035 ymax: 34.36412
#> geographic CRS: JGD2000
#> # A tibble: 180 x 131
#>    L01_001 L01_002 L01_003 L01_004 L01_005 L01_006 L01_007 L01_008 L01_009
#>    <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#>  1 000     001     000     001     2020    49200   1       false   false  
#>  2 000     002     000     002     2020    69200   1       false   false  
#>  3 000     003     000     003     2020    71000   1       false   false  
#>  4 000     004     000     004     2020    153000  1       false   false  
#>  5 000     005     000     005     2020    96200   1       false   false  
#>  6 000     006     000     006     2020    68700   1       false   false  
#>  7 000     007     000     007     2020    23400   1       false   false  
#>  8 000     008     000     000     2020    48200   4       false   false  
#>  9 000     009     000     009     2020    56600   1       false   false  
#> 10 000     010     000     010     2020    36300   1       false   false  
#> # … with 170 more rows, and 122 more variables: L01_010 <chr>, L01_011 <chr>,
#> #   L01_012 <chr>, L01_013 <chr>, L01_014 <chr>, L01_015 <chr>, L01_016 <chr>,
#> #   L01_017 <chr>, L01_018 <chr>, L01_019 <chr>, L01_020 <chr>, L01_021 <chr>,
#> #   L01_022 <chr>, L01_023 <chr>, L01_024 <chr>, L01_025 <chr>, L01_026 <chr>,
#> #   L01_027 <chr>, L01_028 <chr>, L01_029 <chr>, L01_030 <chr>, L01_031 <chr>,
#> #   L01_032 <chr>, L01_033 <chr>, L01_034 <chr>, L01_035 <chr>, L01_036 <chr>,
#> #   L01_037 <chr>, L01_038 <chr>, L01_039 <chr>, L01_040 <chr>, L01_041 <chr>,
#> #   L01_042 <chr>, L01_043 <chr>, L01_044 <chr>, L01_045 <chr>, L01_046 <chr>,
#> #   L01_047 <chr>, L01_048 <chr>, L01_049 <chr>, L01_050 <chr>, L01_051 <chr>,
#> #   L01_052 <chr>, L01_053 <chr>, L01_054 <chr>, L01_055 <chr>, L01_056 <chr>,
#> #   L01_057 <chr>, L01_058 <chr>, L01_059 <chr>, L01_060 <chr>, L01_061 <chr>,
#> #   L01_062 <chr>, L01_063 <chr>, L01_064 <chr>, L01_065 <chr>, L01_066 <chr>,
#> #   L01_067 <chr>, L01_068 <chr>, L01_069 <chr>, L01_070 <chr>, L01_071 <chr>,
#> #   L01_072 <chr>, L01_073 <chr>, L01_074 <chr>, L01_075 <chr>, L01_076 <chr>,
#> #   L01_077 <chr>, L01_078 <chr>, L01_079 <chr>, L01_080 <chr>, L01_081 <chr>,
#> #   L01_082 <chr>, L01_083 <chr>, L01_084 <chr>, L01_085 <chr>, L01_086 <chr>,
#> #   L01_087 <chr>, L01_088 <chr>, L01_089 <chr>, L01_090 <chr>, L01_091 <chr>,
#> #   L01_092 <chr>, L01_093 <chr>, L01_094 <chr>, L01_095 <chr>, L01_096 <chr>,
#> #   L01_097 <chr>, L01_098 <chr>, L01_099 <chr>, L01_100 <chr>, L01_101 <chr>,
#> #   L01_102 <chr>, L01_103 <chr>, L01_104 <chr>, L01_105 <chr>, L01_106 <chr>,
#> #   L01_107 <chr>, L01_108 <chr>, L01_109 <chr>, …
#> 
#> attr(,"id")
#> [1] "L01"
```

### `translateKSJData()`

国土数値情報ダウンロードサービスのデータの

-   カラム名
-   コードリスト型の列のコード

を人間が読める情報に変換します。具体的には、国土数値情報ダウンロードサービス上に記載されているメタデータとの紐づけを行います。
コードリスト型の列の変換は、コードに対応するラベルの列と、元のコードの列（列名の後ろに`_code`が付きます）の2つができます。
以下の例で言うと、（列名が長すぎて表示されていませんが、）先頭の`標準地コード_見出し番号`がラベルの列、その次の`標準地コード_見出し番号_code`が元のコードの列です。

``` r
translateKSJData(d)
#> $`L01-20_30`
#> Simple feature collection with 180 features and 130 fields
#> geometry type:  POINT
#> dimension:      XY
#> bbox:           xmin: 135.0735 ymin: 33.47266 xmax: 136.0035 ymax: 34.36412
#> geographic CRS: JGD2000
#> # A tibble: 180 x 131
#>    標準地コード_見出し番号… 標準地コード_一連番号… 前年度標準地コード_見出し番号… 前年度標準地コード_一連番号… 年度 
#>    <chr>            <chr>            <chr>            <chr>            <chr>
#>  1 住宅地           001              住宅地           001              2020 
#>  2 住宅地           002              住宅地           002              2020 
#>  3 住宅地           003              住宅地           003              2020 
#>  4 住宅地           004              住宅地           004              2020 
#>  5 住宅地           005              住宅地           005              2020 
#>  6 住宅地           006              住宅地           006              2020 
#>  7 住宅地           007              住宅地           007              2020 
#>  8 住宅地           008              住宅地           000              2020 
#>  9 住宅地           009              住宅地           009              2020 
#> 10 住宅地           010              住宅地           010              2020 
#> # … with 170 more rows, and 126 more variables: 公示価格 <chr>,
#> #   属性移動_選定状況 <chr>, 属性移動_住所漢字 <chr>, 属性移動_地積 <chr>,
#> #   属性移動_利用の現況 <chr>, 属性移動_建物構造 <chr>,
#> #   属性移動_供給施設 <chr>, 属性移動_駅からの距離 <chr>,
#> #   属性移動_法規制 <chr>, 属性移動_建ぺい率 <chr>, 属性移動_容積率 <chr>,
#> #   標準地行政コード <chr>, 標準地市区町村名称 <chr>, 住居表示 <chr>,
#> #   地積 <chr>, 利用現況 <chr>, 利用状況表示 <chr>, 建物構造 <chr>,
#> #   `供給施設有無（水道）` <chr>, `供給施設有無（ガス）` <chr>,
#> #   `供給施設有無（下水）` <chr>, 形状 <chr>, 間口比率 <chr>, 奥行比率 <chr>,
#> #   地上階層 <chr>, 地下階層 <chr>, 前面道路状況 <chr>, 前面道路の方位 <chr>,
#> #   前面道路の幅員 <chr>, 前面道路の駅前状況 <chr>, 前面道路の舗装状況 <chr>,
#> #   側道状況 <chr>, 側道の方位 <chr>, 交通施設との近接状況 <chr>,
#> #   周辺の土地利用の状況 <chr>, 駅名 <chr>, 駅からの距離 <chr>, 法規制 <chr>,
#> #   建ぺい率 <chr>, 容積率 <chr>, 共通地点 <chr>, 選定年次ビット <chr>,
#> #   S58調査価格 <chr>, S59調査価格 <chr>, S60調査価格 <chr>, S61調査価格 <chr>,
#> #   S62調査価格 <chr>, S63調査価格 <chr>, H1調査価格 <chr>, H2調査価格 <chr>,
#> #   H3調査価格 <chr>, H4調査価格 <chr>, H5調査価格 <chr>, H6調査価格 <chr>,
#> #   H7調査価格 <chr>, H8調査価格 <chr>, H9調査価格 <chr>, H10調査価格 <chr>,
#> #   H11調査価格 <chr>, H12調査価格 <chr>, H13調査価格 <chr>, H14調査価格 <chr>,
#> #   H15調査価格 <chr>, H16調査価格 <chr>, H17調査価格 <chr>, H18調査価格 <chr>,
#> #   H19調査価格 <chr>, H20調査価格 <chr>, H21調査価格 <chr>, H22調査価格 <chr>,
#> #   H23調査価格 <chr>, H24調査価格 <chr>, H25調査価格 <chr>, H26調査価格 <chr>,
#> #   H27調査価格 <chr>, 属性移動S59 <chr>, 属性移動S60 <chr>, 属性移動S61 <chr>,
#> #   属性移動S62 <chr>, 属性移動S63 <chr>, 属性移動H1 <chr>, 属性移動H2 <chr>,
#> #   属性移動H3 <chr>, 属性移動H4 <chr>, 属性移動H5 <chr>, 属性移動H6 <chr>,
#> #   属性移動H7 <chr>, 属性移動H8 <chr>, 属性移動H9 <chr>, 属性移動H10 <chr>,
#> #   属性移動H11 <chr>, 属性移動H12 <chr>, 属性移動H13 <chr>, 属性移動H14 <chr>,
#> #   属性移動H15 <chr>, 属性移動H16 <chr>, 属性移動H17 <chr>, 属性移動H18 <chr>,
#> #   属性移動H19 <chr>, 属性移動H20 <chr>, …
```

## 注意点

`translateKSJData()`による変換は、機械的な処理なので間違いがある可能性もあります（もし間違いを発見されましたら、[issues](https://github.com/yutannihilation/kokudosuuchi/issues)などからお知らせいただけるとありがたいです）。
データの詳細については必ず国土数値情報ダウンロードサービスをご確認ください。

メタデータは、[kokudosuuchi-metadata](https://github.com/yutannihilation/kokudosuuchi-metadata)レポジトリで管理しています。
