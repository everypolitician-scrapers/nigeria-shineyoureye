#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraperwiki'
require 'json'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def scrape_json(url)
  popolo = JSON.parse(open(url).read)

  popolo.each { |p| scrape_person(p) }
end

def get_contact(type, person)
  person['contact_details'].find(-> { {} }) { |i| i['type'] == type }['value']
end

def scrape_person(person)
  email = get_contact('email', person)
  data = {
    id:           person['id'],
    name:         person['name'],
    email:        email,
    birth_date:   person['birth_date'],
    gender:       person['gender'],
  }
  ScraperWiki.save_sqlite(%i(id), data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
#scrape_json('http://localhost:8000/media_root/popolo_json/persons.json')
scrape_json('http://www.shineyoureye.org/media_root/popolo_json/persons.json')
