require "thor"
require 'spidr'

class SmartLookup < Thor
	desc "Spiding the web", "Spiding the web"

	def smartTagLookup(host)

		puts "spiding http://#{host}/"

		pages = {}
		formats = {}
		urls = {}

		Spidr.site("http://#{host}")	do |spider|
			spider.every_html_page do |page|
				puts '-'
				pageid = nil

				p page

				page.search('//script').each do |script|

					pageid = script.content[/sas_pageid=["'](\d+\/\d+)["'];/, 1]

					unless pageid.nil?
						puts '.'
						formatid = script.content[/sas_formatid=(\d+);/, 1]

						pages[pageid] = {count: 0, formats: {}} if pages[pageid].nil?
						pages[pageid][:count] = pages[pageid][:count] + 1

						pages[pageid][:formats][formatid] = 0 if pages[pageid][:formats][formatid].nil?
						pages[pageid][:formats][formatid] = pages[pageid][:formats][formatid] + 1
					end
				end

				urls << page.url

				if urls.length > 10

					exit

				end

			end
		end

	end
end

SmartLookup.start(ARGV)

