# sysdig-fargate

[Serverless Agents を利用して ECS Fargate 環境で Sysdig Secure を利用してみた〜Terraform 編〜](https://dev.classmethod.jp/articles/sysdig-secure-ecs-fargate-setting-up-terraform-overview/)のサンプルコードです。

## 前提条件

- AWS アカウントを持っていること
- Sysdig Secure のアカウントを持っていること

## 構成図

<img src="./image/Severless%20Agents.png">

### 通信要件

<img src="./image/Severless%20Agents_communicate.png">

## セットアップ方法

#### 初期化

```
terraform init
```

#### 作成

```
terraform apply
```

#### 削除

```
terraform destroy
```
