#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "awesome_print"
require "active_support/core_ext"
require "csv"

raise "You need to specify a CSV file" unless file = ARGV[0]
raise "You need to specify a default namespace for ntriple generation" unless ns = ARGV[1]

def skip?(line)
  line["Keyword Deutsch"].blank?
end

table = CSV.read(file, :col_sep => ";", :headers => true)

table.each do |line|
  next if skip?(line)

  subject = if line["Zeile"]
    "_#{line["Zeile"]}"
  else
    "#{line["Keyword Deutsch"]}".parameterize
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
    puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#topConceptOf> <#{ns}scheme> ."
    narrowers = table.select { |l| l["Parent Zeile"].present? && l["Parent Zeile"] == line["Zeile"] }
    narrowers.each do |n|
      puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#narrower> <#{ns}_#{n["Zeile"]}> ."
    end
  end

  if translation = line["Keyword Übersetzung"]
    puts "<#{ns}#{subject}> <http://www.w3.org/2004/02/skos/core#altLabel> \"#{translation.strip}\"@de ."
  end
end
