#!/bin/bash

set -e

# 指定されたユーザー名を削除する
USER_NAME=$1

# ユーザー名が指定されているか確認
if [ -z "$USER_NAME" ]; then
  echo "エラー: 削除するユーザー名を指定してください。"
  echo "使い方: $0 ユーザー名"
  exit 1
fi

# ユーザーにアタッチされているポリシーをすべてデタッチ
echo "ユーザー $USER_NAME にアタッチされているポリシーをデタッチ中..."
attached_policies=$(aws iam list-attached-user-policies --user-name "$USER_NAME" --query "AttachedPolicies[].PolicyArn" --output text)
for policy_arn in $attached_policies; do
  echo "ポリシー $policy_arn をデタッチします..."
  aws iam detach-user-policy --user-name "$USER_NAME" --policy-arn "$policy_arn"
done

# ユーザーのインラインポリシーをすべて削除
echo "ユーザー $USER_NAME のインラインポリシーを削除中..."
inline_policies=$(aws iam list-user-policies --user-name "$USER_NAME" --query "PolicyNames[]" --output text)
for policy_name in $inline_policies; do
  echo "インラインポリシー $policy_name を削除します..."
  aws iam delete-user-policy --user-name "$USER_NAME" --policy-name "$policy_name"
done

# ユーザーのアクセスキーを削除
echo "ユーザー $USER_NAME のアクセスキーを削除中..."
access_keys=$(aws iam list-access-keys --user-name "$USER_NAME" --query "AccessKeyMetadata[].AccessKeyId" --output text)
for access_key_id in $access_keys; do
  echo "アクセスキー $access_key_id を削除します..."
  aws iam delete-access-key --user-name "$USER_NAME" --access-key-id "$access_key_id"
done

# ユーザーのログインプロファイルを削除
echo "ユーザー $USER_NAME のログインプロファイルを削除中..."
aws iam delete-login-profile --user-name "$USER_NAME" 2>/dev/null

# MFAデバイスの削除
echo "ユーザー $USER_NAME のMFAデバイスを削除中..."
mfa_devices=$(aws iam list-mfa-devices --user-name "$USER_NAME" --query "MFADevices[].SerialNumber" --output text)
for mfa_device in $mfa_devices; do
  echo "MFAデバイス $mfa_device を削除します..."
  aws iam deactivate-mfa-device --user-name "$USER_NAME" --serial-number "$mfa_device"
  aws iam delete-virtual-mfa-device --serial-number "$mfa_device"
done

# SSH公開鍵の削除
echo "ユーザー $USER_NAME のSSH公開鍵を削除中..."
ssh_keys=$(aws iam list-ssh-public-keys --user-name "$USER_NAME" --query "SSHPublicKeys[].SSHPublicKeyId" --output text)
for ssh_key_id in $ssh_keys; do
  echo "SSH公開鍵 $ssh_key_id を削除します..."
  aws iam delete-ssh-public-key --user-name "$USER_NAME" --ssh-public-key-id "$ssh_key_id"
done

# サービス固有のサブリソース（例: CloudFrontのキーペア）を削除
echo "ユーザー $USER_NAME のCloudFrontキーペアを削除中..."
cloudfront_keys=$(aws iam list-service-specific-credentials --user-name "$USER_NAME" --query "ServiceSpecificCredentials[].ServiceSpecificCredentialId" --output text)
for key_id in $cloudfront_keys; do
  echo "CloudFrontキーペア $key_id を削除します..."
  aws iam delete-service-specific-credential --user-name "$USER_NAME" --service-specific-credential-id "$key_id"
done

# ユーザーを削除
echo "ユーザー $USER_NAME を削除中..."
aws iam delete-user --user-name "$USER_NAME"

echo "ユーザー $USER_NAME の削除が完了しました。"
