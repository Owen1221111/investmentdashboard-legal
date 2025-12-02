#!/usr/bin/env ruby
require 'xcodeproj'

# 專案路徑
project_path = 'InvestmentDashboard.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 找到主要 target
target = project.targets.first

# 找到 InvestmentDashboard 群組
main_group = project.main_group.find_subpath('InvestmentDashboard', true)

# 要添加的文件
files_to_add = [
  'InvestmentDashboard/FieldConfigurationManager.swift',
  'InvestmentDashboard/AssetFieldConfigurationView.swift',
  'InvestmentDashboard/LoanInvestmentOverviewChart.swift',
  'InvestmentDashboard/EditLoanAmountsView.swift',
  'InvestmentDashboard/EditInvestmentDataView.swift'
]

files_to_add.each do |file_path|
  # 檢查文件是否存在
  unless File.exist?(file_path)
    puts "⚠️  文件不存在: #{file_path}"
    next
  end

  # 獲取文件名
  file_name = File.basename(file_path)

  # 檢查文件是否已經在專案中
  existing_file = main_group.files.find { |f| f.path == file_name }
  if existing_file
    puts "ℹ️  文件已存在於專案中: #{file_name}"
    next
  end

  # 添加文件到專案
  file_ref = main_group.new_reference(file_path)
  target.add_file_references([file_ref])

  puts "✅ 已添加文件: #{file_name}"
end

# 保存專案
project.save

puts "\n🎉 完成！專案已更新。"
