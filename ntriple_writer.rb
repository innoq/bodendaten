#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "awesome_print"
require "active_support/core_ext"
require "csv"
require "uuid"

raise "You need to specify a CSV file" unless file = ARGV[0]
raise "You need to specify a default namespace for ntriple generation" unless ns = ARGV[1]
raise "You need to specify a title for a top term" unless top_term = ARGV[2]

def skip?(line)
  line["Keyword Deutsch"].blank?
end

table = CSV.read(file, :col_sep => ";", :headers => true)

top_term_id = top_term.parameterize
tops = []

table.each do |line|
  next if skip?(line)

  subject = if line["Zeile"]
    "_#{line["Zeile"]}"
  else
    UUID.new.generate
    # "#{line["Keyword Deutsch"]}".parameterize
  end

  pref_label_de = line["Keyword Deutsch"]
  pref_label_en = line["Keyword Englisch"]
  alt_label_de = line["Keyword Abkürzung"]
  broader = table.detect { |l| line["Parent Zeile"].present? && l["Zeile"] == line["Parent Zeile"] }

  puts "<#{ns}#{subject}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2004/02/skos/core#Concept> ."
  puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#prefLabel> \"#{pref_label_de.strip}\"@de ."

  if pref_label_en
    puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#prefLabel> \"#{pref_label_en.strip}\"@en ."
  end

  if alt_label_de
    puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#altLabel> \"#{alt_label_de.strip}\"@de ."
  end

  if broader
    puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#broader> <#{ns}_#{broader["Zeile"]}> ."
  else
    narrowers = table.select { |l| l["Parent Zeile"].present? && l["Parent Zeile"] == line["Zeile"] }
    narrowers.each do |n|
      puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#narrower> <#{ns}_#{n["Zeile"]}> ."
    end
  end

  if translation = line["Keyword Übersetzung"]
    puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#altLabel> \"#{translation.strip}\"@de ."
  end

  # top terms
  if !line.has_key?("Parent Zeile") || (line.has_key?("Parent Zeile") && line["Parent Zeile"].blank?)
    puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#broader> <#{ns}#{top_term_id}> ."
    tops << subject
  end
end

puts "<#{ns}#{top_term_id}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2004/02/skos/core#Concept> ."
puts "<#{ns}#{top_term_id}> <http://www.w3.org/2004/02/skos/core#topConceptOf> <#{ns}scheme> ."
puts "<#{ns}#{top_term_id}> <http://www.w3.org/2004/02/skos/core#prefLabel> \"#{top_term}\"@de ."
tops.each do |top|
  puts "<#{ns}#{top_term_id}> <http://www.w3.org/2004/02/skos/core#narrower> <#{ns}#{top}> ."
end
