require_relative 'file_helper'

class StringsFileHelper < FileHelper
  class << self
    def upsert_destination_file(po_file_path:, destination_file_path:)
      po_parser ||= PoParser.parse_file(po_file_path)

      if po_parser.entries.empty?
        logger.info "Empty output; skipping #{destination_file_path}"
        return
      end

      upsert_file_path(destination_file_path)

      File.open(destination_file_path, 'w') do |file|
        logger.info "Updating #{destination_file_path}"

        po_parser.entries.each do |entry|
          file << "#{(entry.translated? ? entry.msgstr : entry.previous_msgid)}\n"
        end
      end
    end

    private

    # NOTE: we might need to handle this:
    # .txt files need their empty lines preserved, as each translation is indexed by its line number.
    # This is the quickest way to do that.
    # In the future, we should do something more clever.
    def translation_file_contents(file_path)
      content = {}

      File.readlines(file_path, chomp: true).each do |line|
        value = line.gsub("\ufeff", '') # No idea what this character is doing in the files. Some form of &nbsp; maybe?

        next if value.empty?
        content[value] = value
      end

      content
    end
  end
end
