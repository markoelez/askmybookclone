#!/usr/bin/env ruby
require "dotenv"
require "ruby/openai"
require 'openssl'
require 'pdf-reader'
require 'csv'
require 'optparse'

Dotenv.load

COMPLETIONS_MODEL = "text-davinci-003"
MODEL_NAME = "curie"
DOC_EMBEDDINGS_MODEL = "text-search-#{MODEL_NAME}-doc-001"

raise 'Missing OpenAI API key' unless openai_access_key = ENV['OPENAI_API_KEY']

$client = OpenAI::Client.new(access_token: openai_access_key)

def get_embeddings(text)
  response = $client.embeddings(
      parameters: {
          model: DOC_EMBEDDINGS_MODEL,
          input: text
      }
  )
  return response['data'][0]['embedding']
end

def parse_pdf(path)
  reader = PDF::Reader.new('test.pdf')
  pages = reader.pages.map{|page| page.text.gsub /\s+/, ' '}.compact
  pages = pages.reject { |p| p.empty? }
  return pages
end

def dump_pages(pages, out)
  CSV.open(out, "w") do |csv|
    csv << ['title', 'content']
    pages.each_with_index do |p, i|
      csv << ["Page #{i + 1}"] + [p]
    end
  end
end

def dump_embeddings(pages, out)
  CSV.open(out, "w") do |csv|
    csv << ['title'] + (0..4095).to_a
    pages.each_with_index do |p, i|
      embeddings = get_embeddings(p)
      if embeddings.empty?
        raise Exception.new "Failed to retrieve embeddings"
      end
      csv << ["Page #{i + 1}"] + embeddings
    end
  end
end

options = {}
OptionParser.new do |opt|
  opt.on('--pdf PDF') { |o| options[:pdf_path] = o }
end.parse!

fpath = options[:pdf_path]

raise OptionParser::MissingArgument if fpath.nil?

pages = parse_pdf(fpath)

out_pages = "#{fpath}.pages.csv"
out_embeddings = "#{fpath}.embeddings.csv"

dump_pages(pages, out_pages)
puts "dumped pages to #{out_pages}"

dump_embeddings(pages, out_embeddings)
puts "dumped embeddings to #{out_embeddings}"

