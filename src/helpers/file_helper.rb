require 'fileutils'
require 'nokogiri'
require 'poparser' # TODO: just roll your own, gem is outdated

class FileHelper
  class << self
    def create_po_file(po_file_path:, translation_file_path:)
      logger.debug po_file_path
      translation_content = translation_file_contents(translation_file_path)

      if translation_content.nil?
        logger.info "Empty input; skipping #{translation_file_path}"
        return
      end

      upsert_file_path(po_file_path)

      logger.info "Updating #{po_file_path}"

      po_parser = PoParser.parse_file(po_file_path)
      # po_parser << po_headers # TODO: headers are bugged in gem

      translation_content.each do |key, value|
        # TODO: don't overwrite file completely (compendium mode?)
        po_parser << {
          # flag: 'fuzzy', # TODO: only flag as fuzzy when merging from existing
          previous_msgid: value.gsub('"', '\"'),
          msgid: key.gsub('"', '\"'),
          msgstr: ""
        }
      end

      logger.info "All: #{po_parser.entries.length}. " \
        "Untranslated: #{po_parser.untranslated.length}. " \
        "Fuzzy: #{po_parser.fuzzy.length}. " \
        "Translated: #{po_parser.translated.length}."

      po_parser.save_file
    end

    def upsert_destination_file(po_file_path:, destination_file_path:)
      po_parser ||= PoParser.parse_file(po_file_path)

      doc = Nokogiri::XML(nil)
      doc << Nokogiri::XML::Node.new(output_root_node_name, doc)

      po_parser.entries.each do |entry|
        build_destination_doc!(doc: doc, entry: entry)
      end

      if doc.children.empty? || doc.root.children.empty?
        logger.info "Empty output; skipping #{destination_file_path}"
        return
      end

      upsert_file_path(destination_file_path)

      File.open(destination_file_path, 'w') do |file|
        logger.info "Updating #{destination_file_path}"
        file << doc.to_xml(encoding: 'UTF-8')
      end
    end

    private

    def input_root_node_name
      raise NotImplementedError
    end

    def output_root_node_name
      raise NotImplementedError
    end

    def build_destination_doc!
      raise NotImplementedError
    end

    def translation_file_contents(file_path)
      File.open(file_path) do |file|
        doc = Nokogiri::XML(file)
        build_translation_content_hash(doc.css(':root > *'))
      end
    end

    def sanitize_content(content)
      content.gsub(/\n/, '')
    end

    def po_headers
      # TODO: move some of these into config
      {
        project_id: '1.0',
        # 'Report-Msgid-Bugs-To': 'me', # TODO: this is bugged in gem
        pot_creation_date: DateTime.now.strftime("%Y-%m-%d %H:%M"),
        po_revision_date: DateTime.now.strftime("%Y-%m-%d %H:%M"),
        last_translator: 'me',
        team: 'me',
        # 'MIME-Version': '1.0', # TODO: not supported by gem
        charset: 'text/plain; charset=utf-8',
        encoding: '8bit'
      }
    end

    def upsert_file_path(file_path)
      file_directory = File.dirname(file_path)

      unless File.directory?(file_directory)
        logger.info "Creating #{file_directory}"
        FileUtils.mkpath(file_directory)
      end

      unless File.exist?(file_path)
        logger.info "Creating #{file_path}"
        File.new(file_path, 'w').close
      end
    end
  end
end
