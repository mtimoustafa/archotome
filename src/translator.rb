require 'fileutils'

require_relative 'helpers/def_injected_file_helper'
require_relative 'helpers/keyed_file_helper'
require_relative 'helpers/language_info_file_helper'
require_relative 'helpers/strings_file_helper'
require_relative 'logger'

# TODO: make paths OS agnostic
# TODO: use dirname for paths instead of hardcoding them
class Translator
  attr_accessor :source_directory, :translation_directory, :destination_directory, :force_translation_directory

  def initialize(source_directory:, translation_directory:, destination_directory:, force_translation_directory:)
    @source_directory = source_directory
    @translation_directory = translation_directory
    @destination_directory = destination_directory
    @force_translation_directory = force_translation_directory
  end

  def build_translation_directory
    unless File.directory?(source_directory)
      logger.fatal "Unknown source directory path: #{source_directory}"
      exit
    end

    logger.info 'Building PO translation directory'

    overwrite_existing_translation_directory

    Dir["#{source_directory}/Languages/English/LanguageInfo.xml"].each do |file_path|
      LanguageInfoFileHelper.create_po_file(translation_file_path: file_path, po_file_path: po_file_path(file_path))
    end

    Dir["#{source_directory}/Languages/English/Keyed/*.xml"].each do |file_path|
      KeyedFileHelper.create_po_file(translation_file_path: file_path, po_file_path: po_file_path(file_path))
    end

    Dir["#{source_directory}/Defs/**/*.xml"].each do |file_path|
      DefInjectedFileHelper.create_po_file(
        translation_file_path: file_path,
        # Target path is actually source_directory/DefInjected/*Def/*.xml
        po_file_path: po_file_path(file_path.sub('/Defs/', '/DefInjected/').gsub('Defs', 'Def'))
      )
    end

    Dir["#{source_directory}/Languages/English/Strings/**/*.txt"].each do |file_path|
      StringsFileHelper.create_po_file(translation_file_path: file_path, po_file_path: po_file_path(file_path))
    end
  end

  def generate_translation_output
    Dir["#{translation_directory}/LanguageInfo.xml.po"].each do |file_path|
      LanguageInfoFileHelper.upsert_destination_file(po_file_path: file_path, destination_file_path: destination_file_path(file_path))
    end

    Dir["#{translation_directory}/Keyed/*.xml.po"].each do |file_path|
      KeyedFileHelper.upsert_destination_file(po_file_path: file_path, destination_file_path: destination_file_path(file_path))
    end

    Dir["#{translation_directory}/DefInjected/**/*.xml.po"].each do |file_path|
      DefInjectedFileHelper.upsert_destination_file(po_file_path: file_path, destination_file_path: destination_file_path(file_path))
    end

    Dir["#{translation_directory}/Strings/**/*.txt.po"].each do |file_path|
      StringsFileHelper.upsert_destination_file(po_file_path: file_path, destination_file_path: destination_file_path(file_path))
    end
  end

  private

  def po_file_path(file_path)
    File.join(
      translation_directory,
      relative_file_path(file_path: file_path, parent_directory: source_directory)
    ) + '.po'
  end
  
  def destination_file_path(file_path)
    file_path.sub(translation_directory, destination_directory).sub(/\.po$/, '')
  end

  def relative_file_path(file_path:, parent_directory:)
    file_path.sub(/^#{parent_directory}/, '').sub(/Languages\/English\//, '')
  end

  def overwrite_existing_translation_directory
    if File.directory?(translation_directory)
      if force_translation_directory
        logger.info '-f flag set; deleting existing PO translation directory'
        FileUtils.rm_r(translation_directory, force: true)
      else
        logger.fatal 'PO translation directory already exists. If you meant to overwrite it, please delete it first or set the -f flag'
        exit
      end
    end
  end
end
