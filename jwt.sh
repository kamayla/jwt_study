#!/bin/zsh

# 実際にはBase64UrlEncodeだがコマンドがないのでここではBase64

# 秘密鍵
SECRET=hogehoge

# JWTのHeaderを作る
HEADER=$(echo -n '{"alg": "HS256", "typ": "JWT"}' | base64)

# PAYLOADを作る
# subの値がUserIDだったりする認証主体の識別子
# iatはissued atの略でJWTを発行した時刻が入る
PAYLOAD=$(echo -n '{"sub": 1, "iat": 1516239022}' | base64)

echo "ここまでが署名なしToken"
echo "$HEADER.$PAYLOAD"

echo "ここから著名を作る"

SIGN=$(echo -n "$HEADER.$PAYLOAD" | \
openssl dgst -binary -sha256 -hmac $SECRET | \
base64)

# HEADERとPAYLOADの後ろにSIGNをつけてJWTトークンの完成
JWT=$(echo "$HEADER.$PAYLOAD.$SIGN")

echo "$JWT"

# 例えばこのJWTトークンがフロントエンドからAuthorizationヘッダーに乗せて送られてきたら
# jwtのHEADER.PAYLOADの部分をバックエンドのSECRETで検証して改ざんがないか調べる

ARR=($(echo $JWT | tr "." "\n")) # jwtトークンをピリオドで三分割して配列にする

VERIFY=$(echo -n "${ARR[1]}.${ARR[2]}" | \
openssl dgst -binary -sha256 -hmac $SECRET | \
base64)

echo $VERIFY

if [ $VERIFY = $SIGN ]; then
  echo "認証成功"

  # 認証成功だったらpayloadからsubを抜き出しDBアクセスしてUserリソースを取得する
  echo -n $PAYLOAD | base64 -d | jq '.sub'
fi

