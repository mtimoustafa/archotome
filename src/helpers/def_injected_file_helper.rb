require_relative 'file_helper'

class DefInjectedFileHelper < FileHelper
  class << self
    def upsert_destination_file(po_file_path:, destination_file_path:)
      po_parser ||= PoParser.parse_file(po_file_path)
      @@output_root_node_name = po_parser.entries.first.msgid.to_s.split('.').first
      super
    end

    private

    def input_root_node_name
      'Defs'
    end

    def output_root_node_name
      @@output_root_node_name
    end

    def translatable_labels
      # TODO: find all translatable labels in the XML files
      [
        'title',
        'titleShort',
        'titleShortFemale',
        'titleFemale',
        'label',
        'labelShort',
        'description'
      ].join(', ')
    end

    # TODO: find all these, then integrate them into the building method below.
    #       these are labels that are nested deeper than the other translatable labels.
    #       We can also combine both nested and unnested, then make the building method recursive?
    def nested_translatable_labels
    end

    def build_translation_content_hash(nodes)
      content = {}

      def_type = nodes.first&.name
      return if def_type.nil?

      nodes.each do |node|
        def_name = node.at_css('defName')
        next if def_name.nil?

        labels = node.css(translatable_labels)
        next if labels.empty?

        key_base = [def_type, def_name].join('.')

        unless labels.empty?
          labels.each do |label|
            content["#{key_base}.#{label.name}"] = sanitize_content(label.content)
          end
        end
      end

      content.length > 0 ? content : nil
    end

    def build_destination_doc!(doc:, entry:)
      entry_nodes = entry.msgid.to_s.split('.')
      entry_name = entry_nodes[1..].inject(nil) do |name, node|
        [
          name,
          # Replace li[N] with N-1. E.g. foo.bar.li[1].baz => foo.bar.0.baz. This is the expected DefInjected format.
          node.gsub(/.*\[(?<n>[0-9]+)\]/, '\k<n>').gsub(/[0-9]+/) { |n| "#{n.to_i - 1}" }
        ].compact.join('.')
      end

      node = Nokogiri::XML::Node.new(entry_name, doc)
      node.content = entry.translated? ? entry.msgstr : entry.previous_msgid

      doc.root << node
    end
  end
end
