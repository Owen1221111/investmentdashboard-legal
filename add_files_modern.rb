#!/usr/bin/env ruby
require 'xcodeproj'

# 專案路徑
project_path = 'InvestmentDashboard.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 找到主要 target
target = project.targets.first

# 要添加的文件
files_to_add = [
  'InvestmentDashboard/EditLoanAmountsView.swift',
  'InvestmentDashboard/EditInvestmentDataView.swift',
  'InvestmentDashboard/LoanInvestmentOverviewChart.swift'
]

# 嘗試找到或創建 InvestmentDashboard 群組
main_group = nil
begin
  # 嘗試不同的方法找到群組
  main_group = project.main_group['InvestmentDashboard']

  # 如果找不到，嘗試遍歷所有群組
  if main_group.nil?
    project.main_group.groups.each do |group|
      if group.display_name == 'InvestmentDashboard' || group.name == 'InvestmentDashboard'
        main_group = group
        break
      end
    end
  end

  # 如果還是找不到，使用 main_group
  main_group = project.main_group if main_group.nil?
rescue => e
  puts "⚠️  無法找到 InvestmentDashboard 群組，使用主群組: #{e.message}"
  main_group = project.main_group
end

puts "使用群組: #{main_group.display_name || main_group.name}"

files_to_add.each do |file_path|
  # 檢查文件是否存在
  unless File.exist?(file_path)
    puts "⚠️  文件不存在: #{file_path}"
    next
  end

  # 獲取文件名
  file_name = File.basename(file_path)

  puts "處理文件: #{file_name}"

  # 檢查文件是否已經在 target 的 sources 中
  already_added = target.source_build_phase.files.any? do |build_file|
    build_file.file_ref && build_file.file_ref.path == file_name
  end

  if already_added
    puts "ℹ️  文件已存在於專案中: #{file_name}"
    next
  end

  begin
    # 添加文件引用到群組
    file_ref = main_group.new_reference(file_path)

    # 添加到 target 的 sources build phase
    target.source_build_phase.add_file_reference(file_ref)

    puts "✅ 已添加文件: #{file_name}"
  rescue => e
    puts "❌ 添加文件失敗 #{file_name}: #{e.message}"
  end
end

# 保存專案
begin
  project.save
  puts "\n🎉 完成！專案已更新。"
rescue => e
  puts "\n❌ 保存專案失敗: #{e.message}"
  puts "請手動在 Xcode 中添加這些文件。"
end
