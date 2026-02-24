# Hybrid Architecture: AIX / PowerVM から AWS への段階的移行モデル

本リポジトリは、オンプレミスの AIX / PowerVM 環境から AWS へ段階的に移行するための  
**ハイブリッド構成設計モデル（Terraformプロトタイプ）** です。

単なるAWSリソース構築ではなく、

- ハイブリッド接続設計
- DNS統合
- 段階移行思想
- IaCによる再現性

を示すことを目的としています。

---

## 1. 設計コンセプト

### Phase 1：ハイブリッド基盤確立

オンプレミスを停止せずに AWS を拡張し、

- ネットワーク接続（VPN）
- ルーティング
- 双方向DNS統合

を確立します。

将来的なアプリ移行は Phase 2 以降で実施します。

---

## 2. 想定オンプレミス環境（架空）

| 項目 | 値 |
|------|------|
| Primary DC | 172.16.0.0/16 |
| DR Site | 172.24.0.0/16 |
| DNS Domain | kuromimishowkai.local |
| OS | AIX / PowerVM |
| 想定構成 | SANブート / PowerHA |

※ すべて架空値です（設計モデル提示のみが目的）

---

## 3. AWS環境

- Region: ap-northeast-1（東京）
- VPC: 10.0.0.0/16
- Public Subnet ×2
- Private Subnet ×2
- Internet Gateway
- Private Route Tables

Private Route Tables には以下を設定：

- 172.16.0.0/16 → VGW
- 172.24.0.0/16 → VGW

---

## 4. 全体構成図

### ① Before / Hybrid / Cloud-Native（3段階の全体像）
``` mermaid
flowchart LR
  %% BEFORE
  subgraph B["Before（オンプレ中心）"]
    B1["AIX / PowerVM (LPAR)\nSAN Boot / PowerHA"]
    B2["On-Prem Apps & MW"]
    B3["On-Prem DB / Storage"]
    B1 --> B2 --> B3
  end

  %% HYBRID
  subgraph H["Hybrid（Phase 1：接続＋統合）"]
    H1["On-Prem AIX / PowerVM\n(既存は維持)"]
    H2["Site-to-Site VPN / (将来DX)"]
    H3["AWS VPC\nPrivate Subnets"]
    H4["Route 53 Resolver\nOutbound/Inbound"]
    H5["Private Hosted Zone\naws.kuromimishowkai.local"]
    H1 --> H2 --> H3
    H4 --> H5
    H1 --- H4
  end

  %% CLOUD NATIVE
  subgraph C["Cloud-Native（Phase 2：段階移行後）"]
    C1["Container / Managed Compute\n(ECS/Fargate, etc.)"]
    C2["Managed DB\n(Aurora, etc.)"]
    C3["Observability / Security\n(CloudWatch, Config, etc.)"]
    C1 --> C2
    C1 --- C3
    C2 --- C3
  end

  B --> H --> C
```

### 段階的アーキテクチャ進化モデル

本モデルは「一気にクラウド化」ではなく、段階的な進化を前提としています。

- **Before**  
  AIX / PowerVM 上で PowerHA と SAN ブートにより可用性を確保

- **Hybrid（Phase 1）**  
  既存環境を維持したまま AWS と接続  
  ネットワークおよび DNS 統合を確立

- **Cloud-Native（Phase 2）**  
  アプリケーションおよびデータを段階移行し、  
  マネージドサービス中心の構成へ転換

リスクを最小化しながら構造転換を実現するモデルです。



### ② 移行シナリオの粒度（LPAR単位 → App単位 → DB単位）
``` mermaid
flowchart TB
  subgraph P1["Step 1：LPAR単位（現行把握・接続・依存関係固定）"]
    S1A["LPAR / OS\n(AIX / PowerVM)\nインベントリ/依存関係/通信整理"]
    S1B["Hybrid Connectivity\nVPN / Routing / DNS"]
    S1A --> S1B
  end

  subgraph P2["Step 2：App単位（アプリ移行・再配置）"]
    S2A["App Tier\n移行方式選定\nRehost/Replatform/Refactor"]
    S2B["Compute on AWS\n(ECS/Fargate/EC2)"]
    S2C["データ接続\nOn-Prem DB ↔ AWS App\n段階的切替"]
    S2A --> S2B --> S2C
  end

  subgraph P3["Step 3：DB単位（データ移行・最終切替）"]
    S3A["DB Migration\nCDC/Replication/Batch"]
    S3B["Managed DB\n(Aurora etc.)"]
    S3C["Cutover\n性能/整合性/復旧手順\n最終確認"]
    S3A --> S3B --> S3C
  end

  P1 --> P2 --> P3
```

### 移行の粒度を段階化する理由

移行は「サーバ単位」ではなく、以下の順序で段階化します。

1. **LPAR単位**  
   現行構成・依存関係・通信経路を可視化  
   ハイブリッド接続で安定稼働を確保

2. **アプリ単位**  
   再ホスト / 再プラットフォーム / 再設計の選定  
   一部ワークロードからAWSへ移行

3. **DB単位**  
   データ同期（CDC等）を経て段階切替  
   Aurora等のマネージドDBへ移行

この順序により、業務停止リスクを最小化します。



### ③ PowerHA → Aurora への思想転換（可用性の捉え方）
``` mermaid
flowchart LR
  subgraph ONP["On-Prem（PowerHAの世界）"]
    O1["PowerHA Cluster\nActive/Standby"]
    O2["Shared Storage\nSAN Boot / FC"]
    O3["Failover\nIP引継ぎ / リソース制御"]
    O1 --- O2
    O1 --> O3
  end

  subgraph AWS["AWS（Auroraの世界）"]
    A1["Aurora Cluster\nWriter + Readers"]
    A2["Storage\nDistributed / Managed"]
    A3["Failover\nManaged failover\nMulti-AZ"]
    A4["App Tier\nStateless化\n(原則)"]
    A1 --- A2
    A1 --> A3
    A4 --- A1
  end

  ONP -->|"思想転換：\n「クラスタ制御」→「マネージド冗長」\n「共有ストレージ」→「分散管理ストレージ」"| AWS
```

### 可用性モデルの思想転換

オンプレミスでは：

- 共有ストレージ（SAN）
- OSレベルクラスタ（PowerHA）
- IP引継ぎによるフェイルオーバー

によって可用性を実現します。

一方、AWSでは：

- 分散管理ストレージ
- マネージドフェイルオーバー
- アプリケーションのステートレス化

へと設計思想が変化します。

これは単なる「移行」ではなく、  
**可用性モデルそのものの転換** です。


------------------------------------------------------------------------

## 5. ハイブリッド接続（VPN）

### Terraformで構築：

-   Virtual Private Gateway
-   Customer Gateway（ダミーIP）
-   Site-to-Site VPN
-   Static Routes
-   Private Route Table 設定

⚠ VPNトンネルは未接続のため DOWN 状態が正常です。

------------------------------------------------------------------------

## 6. ハイブリッドDNS設計

### 6.1 Outbound Resolver（AWS → On-Prem）

-   kuromimishowkai.local
-   On-Prem DNS（172.16.10.10 / 172.24.10.10）へ FORWARD

### 6.2 Inbound Resolver（On-Prem → AWS）

-   On-Prem DNS が Inbound Endpoint IP に転送
-   AWS VPC 内 Private Hosted Zone を参照可能

------------------------------------------------------------------------

## 7. Private Hosted Zone

### 作成済み：
```text
aws.kuromimishowkai.local
```

### サンプルレコード：
```text 
app.aws.kuromimishowkai.local → 10.0.10.100
```

### 想定動作：
```text 
On-Prem → Inbound Endpoint → PHZ → 応答
```

------------------------------------------------------------------------

## 8. Terraform Outputs（dev環境）
```text
onprem_cidr_blocks = [
  "172.16.0.0/16",
  "172.24.0.0/16",
]

vpc_id            = "vpc-xxxxxxxx"
vpn_gateway_id    = "vgw-xxxxxxxx"
vpn_connection_id = "vpn-xxxxxxxx"

resolver_inbound_ip_addresses = [
  "x.x.x.x",
  "x.x.x.x"
]
```

------------------------------------------------------------------------

## 9. ディレクトリ構成
```
modules/
  ├── vpc
  ├── vpn_s2s
  ├── route53_resolver
  ├── private_hosted_zone

envs/
  └── dev
```

------------------------------------------------------------------------

## 10. デプロイ手順

``` bash
cd envs/dev

terraform init
terraform validate
terraform plan
terraform apply
```

削除：
``` bash
terraform destroy
```

------------------------------------------------------------------------

## 11. 移行ロードマップ

### Phase 1（本リポジトリ）

-   ハイブリッド接続確立
-   双方向DNS統合
-   IaC化

### Phase 2（想定）

-   アプリケーション再設計
-   コンテナ化
-   マネージドDB移行
-   運用監視統合


------------------------------------------------------------------------

## 12. 設計思想

本モデルは以下を前提とします：
-   エンタープライズAIX環境
-   SANブート
-   PowerHA構成
-   段階移行前提

単純な Lift & Shift ではなく、
**制御された変革（Controlled Transformation）** を目指します。

------------------------------------------------------------------------

## Author

関野 智勝[@TomomasaSekino](https://github.com/TomomasaSekino)
AIX / PowerVM インフラエンジニア
AWS ハイブリッド設計への移行を推進中

本リポジトリは「AWS構築」ではなく
移行設計力の提示 を目的としています。
