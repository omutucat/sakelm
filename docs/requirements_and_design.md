# お酒レビューWebアプリ 要件・設計書

## 1. プロジェクト概要

### 1.1 目的

複数人でお酒のレビューを共有し、評価できるWebアプリケーションを開発する。ユーザーは様々な種類のお酒（ビール、ワイン、日本酒など）のレビューを投稿し、他のユーザーのレビューを閲覧することができる。

### 1.2 プロジェクト名

**SakElm** - お酒（Sake）とElmを組み合わせた名称

## 2. 機能要件

### 2.1 ユーザー管理

- ユーザー登録・ログイン・ログアウト機能
- プロフィール編集機能
- お気に入りのお酒カテゴリ設定

### 2.2 お酒レビュー機能

- レビュー投稿（テキスト、評価点数、写真）
- レビュー一覧表示
- レビュー検索・フィルター機能
- レビューへのいいね、コメント機能

### 2.3 お酒データベース

- カテゴリ別お酒一覧（ビール、ワイン、日本酒、焼酎、ウイスキーなど）
- お酒の詳細情報（製造元、度数、特徴など）
- 新しいお酒の登録・編集機能

### 2.4 ソーシャル機能

- フォロー/フォロワー機能
- お気に入りレビュー保存
- レビュー共有機能

### 2.5 レコメンデーション

- ユーザーの嗜好に基づいたお酒のレコメンド
- 人気ランキング表示

## 3. 非機能要件

### 3.1 パフォーマンス

- ページ読み込み時間： 3秒以内
- レビュー投稿反映： リアルタイム

### 3.2 セキュリティ

- ユーザー認証・認可
- データのバックアップと復旧対策
- 個人情報の保護

### 3.3 ユーザビリティ

- モバイルフレンドリーなレスポンシブデザイン
- 直感的なUIデザイン
- アクセシビリティへの配慮

## 4. 技術スタック

### 4.1 フロントエンド

- **言語/フレームワーク**: Elm
- **UIライブラリ**: tailwind CSS
- **状態管理**: Elm Architecture
- **ビルドツール**: Vite or Parcel

### 4.2 バックエンド

- **Firebase**
  - Firestore: データベース
  - Authentication: ユーザー認証
  - Storage: 画像保存
  - Functions: サーバーレスファンクション
  - Hosting: Webホスティング

### 4.3 その他ツール

- Git: バージョン管理
- GitHub Actions: CI/CD
- Jest/Elm-test: テスト

## 5. システム設計

### 5.1 アーキテクチャ図

```txt
+-----------------+     +------------------+
|                 |     |                  |
|  Elmフロントエンド  <---->  Firebase Services |
|                 |     |                  |
+-----------------+     +------------------+
                             ^
                             |
                             v
                        +---------+
                        |         |
                        |   User  |
                        |         |
                        +---------+
```

### 5.2 データモデル

#### ユーザー (users)

```txt
{
  id: string,
  username: string,
  email: string,
  profileImage: string,
  favoriteCategories: string[],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### お酒 (beverages)

```txt
{
  id: string,
  name: string,
  category: string,
  manufacturer: string,
  country: string,
  alcoholPercentage: number,
  description: string,
  imageUrl: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### レビュー (reviews)

```txt
{
  id: string,
  userId: string,
  beverageId: string,
  rating: number (1-5),
  title: string,
  content: string,
  imageUrls: string[],
  likes: number,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### コメント (comments)

```txt
{
  id: string,
  reviewId: string,
  userId: string,
  content: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 5.3 Elm アプリケーション構造

```txt
src/
  ├── Main.elm        # エントリーポイント
  ├── Model.elm       # アプリケーション全体のモデル定義
  ├── Msg.elm         # メッセージ定義
  ├── Update.elm      # 更新ロジック
  ├── View.elm        # メインビュー
  ├── Api/            # Firebase連携
  ├── Page/           # 各ページコンポーネント
  │   ├── Home.elm
  │   ├── Login.elm
  │   ├── Register.elm
  │   ├── Profile.elm
  │   ├── BeverageList.elm
  │   ├── BeverageDetail.elm
  │   ├── ReviewForm.elm
  │   └── ...
  ├── Component/      # 再利用可能なUIコンポーネント
  │   ├── Header.elm
  │   ├── Footer.elm
  │   ├── ReviewCard.elm
  │   └── ...
  └── Utils/          # ユーティリティ関数
```

### 5.4 Firebase連携

- Elm Portsを使用してFirebase SDKと連携
- FirestoreからのデータフェッチおよびFirestoreへのデータ送信
- 認証状態の管理
- 画像アップロード処理

## 6. 実装計画

### フェーズ1: 基本機能実装

- 環境構築
- 認証機能実装（サインアップ/ログイン）
- お酒データベース基本CRUD
- 簡易レビュー機能

### フェーズ2: コア機能強化

- レビュー詳細機能
- コメント・いいね機能
- ユーザープロフィール
- UI/UX改善

### フェーズ3: 拡張機能

- ソーシャル機能実装
- レコメンデーション機能
- モバイル対応の強化
- パフォーマンス最適化

## 7. 課題・リスク

- Elm-Firebaseの連携複雑性
- 画像アップロード・管理のパフォーマンス
- ユーザー数増加時のスケーラビリティ

以上の要件・設計に基づき開発を進め、必要に応じて適宜更新する。
