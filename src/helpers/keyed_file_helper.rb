require_relative 'file_helper'

class KeyedFileHelper < FileHelper
  class << self
    private

    def input_root_node_name
      'LanguageData'
    end

    def output_root_node_name
      input_root_node_name
    end

    def build_translation_content_hash(nodes)
      content = {}

      nodes.each do |node|
        if node.css('> *').empty?
          content[node.path.sub(/^\/#{input_root_node_name}\//, '').gsub('/', '.')] = sanitize_content(node.content)
        else
          content.merge!(build_translation_content_hash(node.css('> *')))
        end
      end

      content
    end

    def build_destination_doc!(doc:, entry:)
      entry_nodes = entry.msgid.to_s.split('.')
      entry_name = entry_nodes.last
      entry_path = [output_root_node_name, *entry_nodes[...-1]].join(' > ')

      node = Nokogiri::XML::Node.new(entry_name, doc)
      node.content = entry.translated? ? entry.msgstr : entry.previous_msgid
      doc.at_css(entry_path) << node
    end
  end
end
