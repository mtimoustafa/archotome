require_relative 'file_helper'

class LanguageInfoFileHelper < FileHelper
  class << self
    private

    def input_root_node_name
      'LanguageInfo'
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

      if entry_nodes.first == "credits"
        credits_path = [output_root_node_name, entry_nodes.first].join(' > ')

        if doc.at_css(credits_path).nil?
          doc.at_css(output_root_node_name) << Nokogiri::XML::Node.new('credits', doc)
        end
        
        if doc.at_css(entry_path).nil?
          node = Nokogiri::XML::Node.new('li', doc)
          node['Class'] = 'CreditRecord_Role'

          doc.at_css(credits_path) << node
        end
      end

      node = Nokogiri::XML::Node.new(entry_name, doc)
      node.content = entry.translated? ? entry.msgstr : entry.previous_msgid

      doc.at_css(entry_path) << node
    end
  end
end
