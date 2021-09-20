# frozen_string_literal: true

# https://github.com/be5invis/Iosevka
# https://github.com/be5invis/Sarasa-Gothic

# "Sarasa Gothic" 字体的本地存储目录路径
#
# @return [Pathname]
#
def sarasa_gothic_ttf_dir
  Pathname('~/Library/Fonts/sarasa-gothic-ttf-0.34.3').expand_path.tap do |pn|
    raise "`#{pn}` directory does not exist!" unless pn.directory?
  end
end

def separate
  sarasa_gothic_ttf_dir.each_child.with_object([[], []]) do |pn, h|
    next unless pn.extname == '.ttf'

    if pn.basename.to_s.include?('-sc-')
      h[0] << pn
    else
      h[1] << pn
    end
  end
end

def delete_non_hc_style_fonts
  to_keep, to_delete = separate
  
  puts "下面 #{to_keep.size} 个字体文件将保留："
  to_keep.each.with_index(1) do |pn, idx|
    puts "  [#{idx}][✓] #{pn}"
  end

  return if to_delete.empty?

  puts "\n下面 #{to_delete.size} 个字体文件将删除："
  to_delete.each.with_index(1) do |pn, idx|
    puts "  [#{idx}][✕] #{pn}"
  end

  print "\n[MARK] 确认删除请输入 Y, 否则请输入 N: "
  confirm = gets.chomp
  return unless confirm == 'Y'

  to_delete.each(&:delete)
end

def main
  delete_non_hc_style_fonts
end

main if $PROGRAM_NAME == __FILE__
