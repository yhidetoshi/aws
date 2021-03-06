## Terraform + Ansible + Git + CIを用いてAWSをInfrastructure as Codeで管理する

![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/Terraform/terraform-small2-icon.jpg)
![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/gitlab/gitlab-logo2.png)
![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/Jenkins/jenkins-icon2.jpeg)
![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/Ansible_dev/ansible-small-logo.png)
 
## Infrastructure as Codeとは
![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/Terraform/infra-as-code-icon2.jpg)

```
Infrastructure as Codeは自動化、バージョン管理、テスト、継続的インテグレーションといった、ソフトウェア開発のプラクティスを
システム管理に応用するための方法論のこと。
```
→ インフラがクラウド化(AWS/GCP/Azure..)ホストが仮想化(VM/コンテナ)していて、ソフトウェア的に制御できるようになった。
  
  → じゃあ、Gitでインフラをバージョン管理して、構築・運用・テストを自動化しよう。
 
### Infrastructure as Codeを実践するためにいくつかのOSSを活用する
- **Cloudインフラをオーケストレーションで管理することが可能**
  - Terraform
    - AWSをコードで管理する
      - EC2/VPC/IAM/Kinesis/SNS/Cloudwatch/...etc

**Instanceの構築・設定・保守の自動化**
```
- 構成管理ツール(Ansible/Chef)
　　　- Cloudwatch-カスタムメトリクス
　　　　　- Memory使用率の取得可能に
　　　　　　- 特定のプロセス監視を可能に 
　　　- OSSインストール/セットアップ
　　　　　-　Nginx/Fluentd/Mongo/...etc
　 - パッチあて作業
  
      
       
- 継続的インテグレーション(CI)の連動
  - Infrastructure as Codeのワークフローに乗るために
   - Jenkins/GitLabとの連携
     - ブランチにPushしてdry-run
     - MasterブランチにMergeしてapply 
```


### 現在のAWS等の管理方法
- マネジメントコンソールでポチポチする。
- 同じ設定・作業も手動でやっている
- 作業履歴が残らない (CloudTrailを利用するとユーザ名とコールしたAPIは残る...)
- 不要なリソースの判断が難しい(何の為につくられたものなのか)
- マネジメントコンソールの操作ミスを防ぎたい

→ **ソフトウェア的に制御できるインフラのコード化することで、設定・構築・運用の自動化したい**


## Terraformとは
![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/Terraform/terraform_overview-icon.png)
※画像引用元：https://goo.gl/OR9WgP

```
Terraform は、Vagrant などで有名な HashiCorp が作っているコードからインフラリソースを作成する・コードで
インフラを管理するためのツール。AWS, GCP, Azureなどにも対応。 
```

### Terraformチュートリアル_AWS
https://www.terraform.io/docs/providers/aws/index.html

### 現在の構成(CI連携部分)
![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/Terraform/terraform-icon-slack2.png)

#### AWSのリソース追加はこんな感じに。
![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/Terraform/code-terraform2.PNG)


### 特徴
   - OSSとして利用ができ、プロダクト自体も活発に活動しているため機能が次々とリリースされている
   - Infrastructure as Codeとしてクラウドインフラを設定、運用が可能
   - PullRequestとReviewのレールにのることができる
   - APIの側面からサービスの理解が深まる。
   
   - リソース用途の目的もコメントで残すことが可能
   
   - 環境を一気にデプロイすることができる
   → `テンプレート化してモジュールとして使いまわすことができ、マルチクラウド環境(Azure/GCP)で利用することができるようになる`

ソースコードはこちら privateリポジトリで管理

## 利用しているリソースの一覧 (Sum 30 resource types)
![Alt Text](https://github.com/yhidetoshi/Pictures/blob/master/Terraform/Terraform-aws-fig.png)

|サービス      |resource     |
|:-----------|:------------|
| EC2-instance | aws_instance|
| EC2-SecurityGroup | aws_security_group |
| S3         | aws_s3_bucket|
| IAM-User   | aws_iam_user|
| IAM-User   | aws_iam_access_key|
| IAM-Group  | aws_iam_group|
| IAM-Policy | aws_iam_policy| 
| SNS        | aws_sns_topic|
| SNS        | aws_sns_topic_subscription|
| ELB        | aws_elb|
| VPC        | aws_vpc|
| VPC        | aws_internet_gateway|
| VPC        | aws_route_table|
| VPC        | aws_route|
| VPC        | aws_route_table|
| VPC        | aws_subnet|
| VPC        | aws_eip|
| VPC        | aws_nat_gateway|
| VPC        | aws_route_table_association|
| Cloudwatch | aws_cloudwatch_metric_alarm|
|Kinesis_Stream|aws_kinesis_stream|
|EC2 AMI|aws_ami|
|EC2 AMI|aws_ami_from_instance|
|Route53|aws_route53_zone|
|Route53|aws_route53_record|
|EC2 EBS|aws_ebs_volume|
|EC2 EBS|aws_ebs_snapshot|
|RDS|aws_db_parameter_group|
|RDS|aws_db_instance|
|RDS|aws_db_subnet_group|


- `terraform.tfvars`　(AWSのAPIをコールするので、このファイル名に鍵情報をセットする。)
```
aws_access_key = "aws_access_key"
aws_secret_key = "aws_secret_key"
```

- `main.tf` (モジュールを呼び出すmain.tfの一部抜粋)
```
### VPC
module "vpc" {
   source = "./modules/vpc"
   name = "terraform-test-vpc"

   cidr = "192.168.0.0/16"
   private_subnets = ["192.168.1.0/24", "192.168.2.0/24"]
   public_subnets  = ["192.168.10.0/24", "192.168.11.0/24"]

   enable_nat_gateway = "true"

   azs = ["ap-northeast-1a", "ap-northeast-1c"]
   tags {
     "Terraform" = "true"
   }
}
```

## Terraformコマンドのまとめ
- moduleセットコマンド: `$ terraform get`
- dry-runコマンド: `$ terraform plan`
- 適用コマンド(apply):`$ terraform apply`
- dry-run-destroy: `$ terraform plan --destroy`
- 適用コマンド(destroy): `$ terraform destroy`
- 管理状況の確認: `$ terraform show`


### Terraformでサポートしている機能としていないのがあればメモしていきます。
#### Not Supported
- SNS
  - Emai
  
## Terraform 現在のディレクトリ構成(今後変更しますがとりあえず。)
- ソースコードはprivate repoで管理
```
$ tree .
.
├── autoscale-policy.tf
├── autoscale.tf
├── aws-variables.tf
├── cloudwatch.tf
├── ec2_alb.tf
├── ec2_ami.tf
├── ec2_ami_launch_permission.tf
├── ec2_clb.tf
├── ec2_elastic_ip.tf
├── ec2_elb_attach.tf
├── ec2_instance.tf
├── ec2_keyPair.tf
├── ec2_nic.tf
├── ec2_security-group.tf
├── ec2_target-group.tf
├── elasticache.tf
├── external
│   ├── as-launch-config
│   │   ├── backend-api_lc.sh
│   │   ├── backend-inputEC2NameTag.sh
│   │   ├── frontend-web_lc.sh
│   │   └── inputEC2NameTag-Route53record.sh
│   ├── iam
│   │   ├── iam_policy.json
│   │   ├── iam_policy_AmazonEC2ReadOnlyAccess.json
│   │   ├── iam_policy_datahub-dev_ap.json
│   │   ├── iam_policy_datahub-dev_hub.json
│   │   ├── iam_policy_jenkins.json
│   │   ├── iam_policy_kinesis_hoge.json
│   │   ├── iam_policy_s3-autoscaling-log.json
│   │   ├── iam_policy_userdata.json
│   │   ├── iam_role_backend_api_asg.json
│   │   ├── iam_role_default.json
│   │   ├── iam_role_frontend_web_asg.json
│   │   └── s3-apiserver-mount.json
│   ├── s3-bucket-policy
│   │   └── s3-beaconnect-plus-elb-access-log.json
│   └── ssl-certificate-manager
│       ├── certificate_body.cert
│       ├── certificate_chain.cert
│       └── private_key.key
├── iam_group.tf
├── iam_groupMemberShip.tf
├── iam_policy.tf
├── iam_policy_attach.tf
├── iam_role.tf
├── iam_role_attache_policy.tf
├── iam_user.tf
├── kinesis.tf
├── launch_configuration.tf
├── modules
│   ├── autoscale
│   │   ├── main.tf
│   │   └── policy
│   │       ├── main.tf
│   │       └── variables.tf
│   ├── autoscale-alb
│   │   ├── main.tf
│   │   └── policy
│   │       ├── main.tf
│   │       └── variables.tf
│   ├── cloudwatch-alarm
│   │   ├── external
│   │   │   └── get-instance.sh
│   │   ├── external.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── ebs
│   │   └── create-snapshot
│   │       ├── main.tf
│   │       └── variables.tf
│   ├── ec2
│   │   ├── ami
│   │   │   ├── from-instance
│   │   │   │   ├── main.tf
│   │   │   │   └── variables.tf
│   │   │   ├── from-snapshot
│   │   │   │   ├── main.tf
│   │   │   │   └── variables.tf
│   │   │   └── launch_permission
│   │   │       └── main.tf
│   │   ├── attach_eip
│   │   │   └── main.tf
│   │   ├── attach_elb_instance
│   │   │   └── clb.tf
│   │   ├── attach_nic
│   │   │   └── main.tf
│   │   ├── elb
│   │   │   ├── alb
│   │   │   │   ├── asg-backend
│   │   │   │   │   └── main.tf
│   │   │   │   └── asg-frontend
│   │   │   │       └── main.tf
│   │   │   ├── clb
│   │   │   │   ├── asg
│   │   │   │   │   └── main.tf
│   │   │   │   ├── asg-backend
│   │   │   │   │   └── main.tf
│   │   │   │   ├── asg-frontend
│   │   │   │   │   └── main.tf
│   │   │   │   ├── dev
│   │   │   │   │   └── main.tf
│   │   │   │   ├── frontend-api-dev-clb
│   │   │   │   │   └── main.tf
│   │   │   │   └── hoge-dev
│   │   │   │       └── main.tf
│   │   │   └── target-group
│   │   │       ├── asg-backend
│   │   │       │   └── main.tf
│   │   │       └── asg-frontend
│   │   │           └── main.tf
│   │   ├── instance
│   │   │   └── main.tf
│   │   ├── key_pair
│   │   │   └── main.tf
│   │   └── security-group
│   │       ├── backend-api-asg
│   │       │   └── main.tf
│   │       ├── backend-api-dev
│   │       │   └── main.tf
│   │       ├── backend-custom-web-dev
│   │       │   └── main.tf
│   │       ├── backend-elb-asg
│   │       │   └── main.tf
│   │       ├── backend-web-asg
│   │       │   └── main.tf
│   │       ├── ci-ops
│   │       │   └── main.tf
│   │       ├── frontend-api-elb-dev
│   │       ├── frontend-elb-asg
│   │       ├── frontend-elb-dev
│   │       │   └── main.tf
│   │       ├── frontend-web-asg
│   │       │   └── main.tf
│   │       ├── frontend-web-dev
│   │       │   └── main.tf
│   │       ├── hoge
│   │       │   └── main.tf
│   │       ├── hoge-ec2
│   │       │   └── main.tf
│   │       ├── hoge-elasticache
│   │       │   └── main.tf
│   │       ├── hoge-elb-dev
│   │       ├── jump
│   │       ├── log-aggregator
│   │       │   └── main.tf
│   │       ├── other
│   │       │   ├── main.tf
│   │       │   └── output.tf
│   │       └── rds-pgsql-primary
│   ├── elasticache
│   │   └── main.tf
│   ├── iam
│   │   ├── group
│   │   │   └── main.tf
│   │   ├── group-membership-apiuser
│   │   │   └── main.tf
│   │   ├── group-membership-consoleuser
│   │   │   └── main.tf
│   │   ├── policy
│   │   │   └── main.tf
│   │   ├── policy-attach-group
│   │   │   └── main.tf
│   │   ├── policy-attach-role
│   │   │   └── main.tf
│   │   ├── policy-attach-user
│   │   │   └── main.tf
│   │   ├── role
│   │   │   └── main.tf
│   │   ├── user-api-only
│   │   │   └── main.tf
│   │   └── user-console-only
│   │       └── main.tf
│   ├── iam_modify
│   │   └── main.tf
│   ├── kinesis-stream
│   │   └── main.tf
│   ├── launch_configuration
│   │   └── main.tf
│   ├── rds
│   │   ├── rds-maz
│   │   │   └── main.tf
│   │   └── snapshot
│   │       └── main.tf
│   ├── rds-maz
│   │   └── main.tf
│   ├── route53
│   │   ├── external_dns
│   │   │   └── main.tf
│   │   └── internal_dns
│   │       ├── a_record
│   │       │   └── main.tf
│   │       ├── cname_record
│   │       │   └── main.tf
│   │       └── zone_main
│   │           └── main.tf
│   ├── s3
│   │   ├── bucket-policy
│   │   │   └── main.tf
│   │   ├── lifecycle_rule
│   │   │   └── main.tf
│   │   └── standard
│   │       └── main.tf
│   ├── sns
│   │   └── main.tf
│   ├── ssl-certificate-manager
│   │   └── main.tf
│   └── vpc
│       └── main.tf
├── rds-maz.tf
├── rds-snapshot.tf
├── route53_external.tf
├── route53_internal_custom.local.tf
├── route53_internal_hoge.tf
├── s3.tf
├── sh
│   ├── exe-apply-terraform.sh
│   └── exe-dryrun-terraform.sh
├── sns.tf
└── vpc.tf
```

### Ansible playbook(ディレクトリ構成)
```
├── README.md
├── aws-api-setup.yml
├── aws_credentials
│   ├── user1
│   └── user2
├── hosts
├── roles
│   ├── aws-api-setup
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   ├── config.j2
│   │   │   └── credentials.j2
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── cloudwatch
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   │   ├── AwsSignatureV4.pm
│   │   │   ├── CloudWatchClient.pm
│   │   │   ├── mon-get-instance-stats.pl
│   │   │   └── mon-put-instance-data.pl
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   └── awscreds.conf.j2
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── cloudwatch-alarm
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── ec2
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── iam
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   │   └── hoge.json
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   └── save_credential.j2
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── nginx
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   └── nginx.conf.j2
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── ssh
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   │   └── config
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── td-agent2
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   └── td-agent.conf.j2
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── user
│   │   ├── README.md
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   │   └── hide_id_rsa
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   └── zabbix-agent
│       ├── README.md
│       ├── defaults
│       │   └── main.yml
│       ├── files
│       │   ├── zabbix-release-2.4-1.el6.noarch.rpm
│       │   └── zabbix.repo
│       ├── handlers
│       │   └── main.yml
│       ├── meta
│       │   └── main.yml
│       ├── roles
│       ├── tasks
│       │   ├── main.yml
│       │   └── main.yml.org
│       ├── templates
│       │   └── zabbix_agentd.conf.j2
│       ├── tests
│       │   ├── inventory
│       │   └── test.yml
│       └── vars
│           └── main.yml

```
