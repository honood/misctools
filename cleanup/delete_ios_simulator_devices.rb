# frozen_string_literal: true

require 'json'
require 'tty-prompt'

require_relative '../utils'

raise 'The `xcrun` command does not exist!' unless Utils.command_exist?('xcrun')

prompt = TTY::Prompt.new

prompt.ok 'Query device installation state...'

# @type [Hash{String => Array<Hash{String => String}>}]
installed_devices = JSON.parse(`xcrun simctl list -j devices`)['devices']
if installed_devices.values.flatten.empty?
  prompt.warn 'No device installed, program will exit.'
  exit
end

# @type [Array<Hash{String => String}>]
installed_runtimes = JSON.parse(`xcrun simctl list -j runtimes`)['runtimes']
# @type [Array<String>] runtime_name_with_device_count
# @type [Array<String>] runtime_ids
runtime_name_with_device_count, runtime_ids = installed_runtimes.each_with_object([[], []]) do |i, a|
  runtime_id = i['identifier']
  a[1] << runtime_id

  runtime_name = i['name']
  a[0] << "#{runtime_name} (#{installed_devices[runtime_id].size})"
end

confirmed = prompt.yes?('Do you want to delete all available devices of a specific runtime?')
unless confirmed
  prompt.warn 'You selected `No`, program will exit.'
  exit
end

runtime_name = prompt.enum_select('Please select a runtime?', runtime_name_with_device_count)
selected_index = runtime_name_with_device_count.index(runtime_name)
selected_devices = installed_devices[runtime_ids[selected_index]]
if selected_devices.empty?
  prompt.warn 'No device of selected runtime installed, program will exit.'
  exit
end

# @type [Array<String>] selected_device_uuids
# @type [Array<String>] selected_device_descriptions
selected_device_uuids, selected_device_descriptions = selected_devices.each_with_object([[], []]) do |i, a|
  a[0] << i['udid']
  a[1] << "#{i['name']} (#{i['udid']}) (#{i['state']})"
end

prompt.warn 'The following devices will be deleted:'
index_width = selected_device_descriptions.size.digits.size
output_devices = selected_device_descriptions.map.with_index(1) do |desc, i|
  format("  [%0#{index_width}d] %s", i, desc)
end.join("\n")
prompt.ok output_devices

double_confirmed = prompt.yes?('Are you sure you want to delete them?') { |q| q.default false }
unless double_confirmed
  prompt.warn 'You selected `No`, program will exit.'
  exit
end

success = system("xcrun simctl delete #{selected_device_uuids.join(' ')}")
if success
  `xcrun simctl delete unavailable`
  prompt.ok 'You have succeeded to delete the following devices:'
else
  prompt.error 'You have failed to delete the following devices:'
end
prompt.ok output_devices
