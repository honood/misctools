# frozen_string_literal: true

require 'pathname'
require 'date'
require 'fileutils'

require_relative '../utils'

class OmniFocusCleaner
  def self.default_backups_dir
    if Gem::Version.new(Utils.app_version('OmniFocus')) < Gem::Version.new('4.0.0')
      '~/Library/Containers/com.omnigroup.OmniFocus3/Data/Library/Application Support/OmniFocus/Backups'
    else
      '~/Library/Containers/com.omnigroup.OmniFocus4/Data/Documents/Backups'
    end
  end

  # @param [Pathname] backups_path
  #        OmniFocus 备份文件存放目录路径。
  #
  def initialize(backups_path = Pathname(OmniFocusCleaner.default_backups_dir).expand_path)
    raise ArgumentError, %(Invalid backups path for OmniFocus: "#{backups_path.to_path}") unless backups_path.exist?

    @backups_path = backups_path
  end

  attr_reader :backups_path

  # @return [Array<Pathname>] 返回从旧到新排序的备份文件列表
  #
  def sort_backups
    pattern = /^OmniFocus\s+(.*)\s+(.*)$/
    backup_list = backups_path.glob('*').select do |path|
      path.basename(path.extname).to_s.match?(pattern)
    end

    backup_list.sort do |left, right|
      l_md = left.basename(left.extname).to_s.match(pattern)
      l_date = l_md[1].split('-').map(&:to_i)
      l_date = Date.new(*l_date)
      l_other = l_md[2].to_i

      r_md = right.basename(right.extname).to_s.match(pattern)
      r_date = r_md[1].split('-').map(&:to_i)
      r_date = Date.new(*r_date)
      r_other = r_md[2].to_i

      if l_date < r_date
        -1
      elsif l_date > r_date
        1
      elsif l_other < r_other
        -1
      elsif l_other > r_other
        1
      else
        0
      end
    end
  end

  def find_latest_backup
    sort_backups.last
  end

  def cleanup_outdated
    sorted_backups = sort_backups
    if sorted_backups.size == 1
      puts '[INFO] 仅有一份备份，无须删除'
      return
    end

    latest = sorted_backups[-1]
    to_delete = sort_backups[0...-1]

    puts '[INFO] 最新的备份文件是：'
    puts latest
    puts ''
    puts '[INFO] 下列备份文件将被删除：'
    puts to_delete
    print '[MARK] 确认删除请输入 YES, 否则请输入 NO: '
    confirm = gets.chomp
    return unless confirm == 'YES'

    to_delete.each { |filepath| FileUtils.rm_rf(filepath) }
    puts '[INFO] 删除完成'
  end
end

OmniFocusCleaner.new.cleanup_outdated
