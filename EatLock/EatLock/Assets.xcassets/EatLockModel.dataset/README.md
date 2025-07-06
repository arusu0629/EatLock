# EatLockModel プレースホルダー

このフォルダは、EatLockアプリのFoundation Modelファイルを配置するためのプレースホルダーです。

## 使用方法

1. WWDC2025のFoundation Modelフレームワークが正式リリースされた後、対応するモデルファイル（.mlpackage）をここに配置してください。

2. 現在はダミー実装が動作し、キーワードベースの簡易分析によってAIフィードバックを生成します。

## 期待されるファイル構造

```
EatLockModel.mlpackage/
├── Data/
│   └── com.apple.CoreML/
│       └── model.mlmodel
├── Metadata/
│   └── ...
└── manifest.json
```

## 注意事項

- 実際のモデルファイルが配置されるまで、アプリケーションはフォールバックとしてダミー実装を使用します
- モデルファイルのサイズは50MB以下を推奨します
- デバイスのメモリ使用量を考慮して、軽量なモデルを使用してください

## 開発者向け

LocalAIService.swift の `initializeDummyModel()` メソッドを参照して、実際のモデル読み込み処理を実装してください。