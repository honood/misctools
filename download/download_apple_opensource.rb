# frozen_string_literal: true

require 'faraday'
require 'nokogiri'
require 'json'

# rubocop:disable Lint/ShadowingOuterLocalVariable

module Download
  module AppleOpenSource
    HOMEPAGE = 'https://opensource.apple.com/'

    module_function

    def parse_homepage
      # @type [Faraday::Response]
      homepage_html_resp = Faraday.get(HOMEPAGE)
      raise %([ERROR] Fail to request `#{HOMEPAGE}`) unless homepage_html_resp.success?

      all_release_data = Nokogiri::HTML(homepage_html_resp.body).css('div.product.release-list').each_with_object({}) do |e, h|
        product_name = e.css('.product-name')[0].children.find { |e| e.type == Nokogiri::XML::Node::TEXT_NODE }.text
        h[product_name] = e.css('div.release-list-button').each_with_object({}) do |e, h|
          # References:
          #
          # 1. Difference between |= and ^= css
          # https://stackoverflow.com/questions/15678037/difference-between-and-css
          #
          # 2. Selectors Level 4
          # https://www.w3.org/TR/selectors-4/#overview
          #
          major_version = e.css(%(span[id|="list-header-#{product_name}"]))[0].children.find { |e| e.type == Nokogiri::XML::Node::TEXT_NODE }.text
          release_sublist = e.next_element.css(%(li > a[href^="/release/"]))
          release_sublist_size = release_sublist.size
          puts "\n[INFO] Analyzing #{major_version} (#{release_sublist_size}):"
          h[major_version] = release_sublist.each.with_index(1).with_object({}) do |(e, i), h|
            release_version = e.text.tr("\u00a0", ' ').strip
            release_page_url = URI.join(HOMEPAGE, e['href'])
            puts "[INFO]   [#{i}/#{release_sublist_size}] Analyzing `#{release_version}` at `#{release_page_url}`."
            h[release_version] = parse_release_page(release_version, release_page_url)
          end
        end
      end

      save_disk(JSON.pretty_generate(all_release_data))
    end

    # @param [String] release_version
    # @param [String] release_page_url
    #
    def parse_release_page(release_version, release_page_url)
      ret_hash = {
        'release_version' => release_version,
        'release_page_url' => release_page_url
      }

      # @type [Faraday::Response]
      release_page_resp = Faraday.get(release_page_url)
      unless release_page_resp.success?
        ret_hash['error'] = "Fail to request `#{release_page_url}`."
        warn "[WARNING] Fail to request `#{release_page_url}`."
        return ret_hash
      end

      page = Nokogiri::HTML(release_page_resp.body)
      page_header_name = page.css('#apple-logo-text')[0].children.find { |e| e.type == Nokogiri::XML::Node::TEXT_NODE }.text
      ret_hash['release_page_name'] = page_header_name

      project_list = page.css('#project-list')[0]
      project_rows = project_list.css('tr.project-row')
      ret_hash['projects'] = project_rows.each_with_object([]) do |e, a|
        h = {}

        project_name = e.css('td.project-name')[0]
        h['name'] = project_name.text.tr("\u00a0", ' ').strip.gsub(/\s+/, ' ')

        h['updated'] = !e.css('td.newproject')[0].nil?
        # Just an assert!
        project_updated = !e.css('td.project-updated')[0].text.tr("\u00a0", ' ').strip.empty?
        raise %([ERROR] Something is wrong with project update status!) unless project_updated == h['updated']

        unless (temp = project_name.css('a')[0]).nil?
          h['source_url'] = URI.join(release_page_url, temp['href'])
        end

        project_licenses = e.css('td.project-licenses')[0]
        unless project_licenses.nil?
          h['licenses'] = project_licenses.text.tr("\u00a0", ' ').strip.gsub(/\s+/, ' ')
        end

        project_download = e.css('td.project-downloads > a')[0]
        unless project_download.nil?
          h['download_url'] = URI.join(release_page_url, project_download['href'])
        end

        a << h
      end

      ret_hash
    end

    # @param [String] contents
    # @param [String, nil] file_path
    #
    def save_disk(contents, file_path = nil)
      file_path = Dir.pwd if file_path.nil? || file_path&.empty?
      File.write(File.join(file_path, 'apple_opensource.json'), contents, encoding: 'UTF-8', mode: 'wt')
    end
  end
end

# rubocop:enable Lint/ShadowingOuterLocalVariable

if __FILE__ == $PROGRAM_NAME
  Download::AppleOpenSource.parse_homepage
end
