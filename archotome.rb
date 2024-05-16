#! /usr/bin/env ruby

require 'optparse'

require_relative 'src/constants'
require_relative 'src/logger'
require_relative 'src/translator'


def sanitize_path(path)
  File.expand_path(path).chomp('/')
end

args = {
  destination_directory: sanitize_path("./#{DESTINATION_DIRECTORY_NAME}"),
  force_translation_directory: false,
  source_directory: sanitize_path(DEFAULT_SOURCE_DIRECTORY),
  translation_directory: sanitize_path("./#{TRANSLATION_DIRECTORY_NAME}")
}

OptionParser.new do |opts|
  opts.banner = "Usage: archotome.rb [init|generate] [options]"

  opts.on(
    '-dDIRECTORY',
    '--dest=DIRECTORY',
    'Directory to create game translation files. Defaults to Arabic/ in current directory.' # TODO: more language agnostic?
  ) do |destination_directory|
    args[:destination_directory] = File.join(sanitize_path(destination_directory), DESTINATION_DIRECTORY_NAME)
  end

  opts.on('-f', '--force', 'Delete existing PO translation directory.') do
    args[:force_translation_directory] = true
  end

  opts.on('-h', '--help', 'Prints this help message.') do
    puts opts
    exit
  end

  opts.on(
    '-sDIRECTORY',
    '--source=DIRECTORY',
    'RimWorld Data/Core path. Defaults to expected installation path.'
  ) do |source_directory|
    args[:source_directory] = sanitize_path(source_directory)
  end

  opts.on(
    '-tDIRECTORY',
    '--trans=DIRECTORY',
    'Directory to create PO translation files. Defaults to po/ in current directory.'
  ) do |translation_directory|
    args[:translation_directory] = File.join(sanitize_path(translation_directory), TRANSLATION_DIRECTORY_NAME)
  end
end.parse!

case ARGV.first
when 'init'
  Translator.new(**args).build_translation_directory
when 'generate'
  Translator.new(**args).generate_translation_output
else 
  logger.fatal "#{ARGV.first} is not a correct execution mode.\n" \
    "Please provide 'init' for creating new PO files or 'generate' " \
    "for generating game translation files from existing PO files."
  exit
end
