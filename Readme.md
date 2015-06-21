# Nenga::Send - 年賀状の宛名画像を作成する

年賀状の裏面は毎回絵を描いて自作するので、年賀状制作をフリー化するため宛名部分を作成した。

……よく考えたらこれHagaki::Atenaだけど気にしない。

## 必要要件

- Perl 5.8?以上

## 必要モジュール

- Getopt::Long
- GD
- Image::ExifTool
- Mouse
- Mouse::Util::TypeConstraints

てきとうに`cpan -i GD`とかしてください。

## 使い方

### nengasend.pl

Nenga::Sendライブラリを使って宛名画像を作成する。

まず宛名を書いたsend.tsvを用意する

    # 氏名	敬称	郵便番号	住所
    # タブ区切り
    # 先頭が#だとコメント
    
    # 氏名にはてきとうに空白を入れたり入れなかったりして調整する
    # 敬称は「様」なら省略可能
    # 住所を2行にする場合分けたいところに空白を入れる
    梶原 恵太	様	2561024	ミドリ市花山町12-1 サンシャインコーポ12
    奈良阪隆志	様	2561024	ミドリ市花山町12-1 サンシャインコーポ42

そして以下を実行する

```
perl nengasend.pl --output=output_dir --font=C:\Windows\Fonts\KozMinPro-Heavy.otf --preview=0 --from_name="奈良阪 某" --from_postcode=5121024 --from_address="奈良市奈良阪1-1-1 トリプルエー102" --margin_left=2.88 --margin_top=2.88 --margin_right=2.88 --margin_bottom=2.88 send.tsv
```

バッチファイルにしておくと便利

```
@echo off
set FILES=send.tsv
set OUTPUT="./out/2015"
set FONT="C:\Windows\Fonts\KozMinPro-Heavy.otf"
set PREVIEW=0
set FROM_NAME="奈良阪 某"
set FROM_POSTCODE=5121024
set FROM_ADDRESS="奈良市奈良阪1-1-1 トリプルエー102"
set MARGINS_V=2.88
set MARGINS_H=2.88

if %PREVIEW% == 1 (set PREVIEW_OPTION="nenga.png")
@echo on
perl nengasend.pl --output=%OUTPUT% --font=%FONT% --preview=%PREVIEW_OPTION% --from_name=%FROM_NAME% --from_postcode=%FROM_POSTCODE% --from_address=%FROM_ADDRESS% --margin_left=%MARGINS_H% --margin_top=%MARGINS_V% --margin_right=%MARGINS_H% --margin_bottom=%MARGINS_V% %FILES%
```

### Nenga::Sendライブラリ

```
my $ns = Nenga::Send->new(resolution => 300);
$ns->from_postcode('112-0013');
$ns->from_address("京都府丹波橋\n　　南京終町1-24");
$ns->from_name('奈良阪 某');
$ns->build(to_postcode => '001-0001', to_address => "ミドリ市花山町12-1", to_name => "梶原 恵太\n奈良阪隆志")->write(file_name => 'n.png');
```

## ライセンス

[MITライセンス](http://narazaka.net/license/MIT?2015)の元で配布いたします。
