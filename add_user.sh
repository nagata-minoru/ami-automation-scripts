#!/bin/bash

set -e

export LC_CTYPE=C

# 引数のチェック
if [ $# -lt 1 ]; then
  echo "Usage: $0 <username1> <username2> ..."
  exit 1
fi

# 強力なパスワードを生成する関数
generate_strong_password() {
  local length=21
  local password=""

  # 各カテゴリから少なくとも1文字ずつ取得
  lower=$(tr -dc 'a-z' < /dev/urandom | head -c 1)
  upper=$(tr -dc 'A-Z' < /dev/urandom | head -c 1)
  digit=$(tr -dc '0-9' < /dev/urandom | head -c 1)
  symbol=$(tr -dc '!@#$%^&*()_+-=[]{}|;:,.<>?' < /dev/urandom | head -c 1)

  # 残りの文字をランダムに選ぶ
  other_chars=$(tr -dc 'a-zA-Z0-9!@#$%^&*()_+-=[]{}|;:,.<>?' < /dev/urandom | head -c $((length - 4)))

  # 全ての文字を結合してシャッフル
  password="$lower$upper$digit$symbol$other_chars"
  password=$(echo "$password" | fold -w1 | shuf | tr -d '\n')

  echo "$password"
}

# ユーザ情報を格納する配列を用意
declare -a user_info_list

# 各ユーザに対して処理を行う
for username in "$@"; do
  echo "Creating user: $username"

  # パスワードを生成して変数に代入
  strong_password="$(generate_strong_password)"
  echo "生成されたパスワード for $username: $strong_password"

  # AWS IAM ユーザーを作成し、必要なポリシーをアタッチ
  aws iam create-user --user-name $username
  aws iam attach-user-policy --user-name $username --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
  aws iam create-login-profile --user-name $username --password "$strong_password" --password-reset-required

  # アカウントIDを取得
  account_id=$(aws sts get-caller-identity --query Account --output text)

  # ユーザ情報を配列に追加
  user_info_list+=("Username: $username, Password: $strong_password, AccountID: $account_id")

  # SecretAccessKey が必要な場合
  # aws iam create-access-key --user-name $username
done

# 最後にユーザ名、パスワード、アカウントIDの一覧を出力
echo -e "\nユーザ名、パスワード、アカウントIDの一覧:"
for user_info in "${user_info_list[@]}"; do
  echo "$user_info"
done
