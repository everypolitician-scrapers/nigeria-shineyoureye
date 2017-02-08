#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraperwiki'
require 'json'
require 'date'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def scrape_json(url, positions)
  popolo = JSON.parse(open(url).read)
  popolo.each { |p| scrape_person(p, positions) }
end

def get_contact(type, person)
  # sometimes contacts are '...' instead of blank
  person['contact_details'].find(-> { {} }) { |i| i['type'] == type }['value'].gsub('...', '') rescue ''
end

def get_identifier(scheme, person)
  id = person['identifiers'].find(-> { {} }) { |i| i['scheme'] == scheme }['identifier']
end

def get_image(person)
  person['images'].map { |i| i['url'] || '' }[0] rescue ''
end

def parse_date(date)
  Date.parse(date) rescue Date.today()
end

def get_positions(url)
  positions = JSON.parse(open(url).read)
  today = Date.today()

  positions.find_all { |p|  ( p['role'] == 'Senator' || p['role'] == 'Federal Representative' ) && parse_date(p['end_date']) > today }.map { |p| [ p['person_id'], p ] }.to_h
end

def get_gender(person)
  if person['gender'] == 'male' or person['gender'] == 'female'
    return person['gender']
  end
  return ''
end

def scrape_person(person, positions)
  email = get_contact('email', person)

  data = {
    id:           person['id'],
    name:         person['name'],
    email:        email,
    birth_date:   person['birth_date'],
    gender:       get_gender(person),
    image:        get_image(person),
    slug:         get_identifier('pombola-slug', person),
  }

  if positions[person['id']]
    data['position'] = positions[person['id']]['role']
  end

  ScraperWiki.save_sqlite(%i(id), data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
positions = get_positions('http://www.shineyoureye.org/media_root/popolo_json/memberships.json')
scrape_json('http://www.shineyoureye.org/media_root/popolo_json/persons.json', positions)
