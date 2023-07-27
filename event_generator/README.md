# sysdig-fargate

[Serverless Agentsを利用してECS Fargate環境でSysdig Secureを利用してみた〜Terraform編〜](https://dev.classmethod.jp/etc/sysdig-secure-ec…rraform-overview/)のサンプルコードです。

## 前提条件

- AWSアカウントを持っていること
- Sysdig Secureのアカウントを持っていること

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