#!/bin/bash

echo "======================================"
echo "  打開 Xcode 專案和新增檔案位置"
echo "======================================"
echo ""

# 專案目錄
PROJECT_DIR="/Users/chehungliu/Desktop/superdesign-template拷貝/InvestmentDashboard"
XCODE_PROJECT="$PROJECT_DIR/InvestmentDashboard.xcodeproj"
FILES_DIR="$PROJECT_DIR/InvestmentDashboard"

# 檢查專案是否存在
if [ ! -d "$XCODE_PROJECT" ]; then
    echo "❌ 找不到 Xcode 專案"
    exit 1
fi

# 打開 Xcode 專案
echo "📱 正在打開 Xcode 專案..."
open "$XCODE_PROJECT"

# 等待一秒
sleep 1

# 在 Finder 中打開檔案目錄
echo "📂 正在打開檔案目錄..."
open "$FILES_DIR"

echo ""
echo "✅ 已完成！"
echo ""
echo "接下來請："
echo "1. 在 Finder 視窗中找到以下檔案："
echo "   - FieldConfigurationManager.swift"
echo "   - AssetFieldConfigurationView.swift"
echo ""
echo "2. 在 Xcode 中，將這兩個檔案拖放到左側的"
echo "   InvestmentDashboard 資料夾中"
echo ""
echo "3. 在彈出的對話框中："
echo "   ✅ 勾選 'Copy items if needed'"
echo "   ✅ 確認 'Add to targets' 中勾選了 InvestmentDashboard"
echo "   然後點擊 'Finish'"
echo ""
echo "詳細步驟請參考：新增檔案到Xcode指南.md"
echo ""
