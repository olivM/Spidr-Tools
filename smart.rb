require "thor"
require 'spidr'
require 'anemone'
require 'redis'
require 'awesome_print'

class MySpidr < Thor
	desc "Spiding the web", "Spiding the web"

	def smartTagLookup(host)

		puts "spiding http://#{host}/"

		pages = {}
		formats = {}
		urls = []

		Spidr.site("http://#{host}")	do |spider|
			spider.every_html_page do |page|
				print '-'
				pageid = nil

				page.search('//script').each do |script|

					pageid = script.content[/sas_pageid=["'](\d+\/\d+)["'];/, 1]

					unless pageid.nil?
						print '.'
						formatid = script.content[/sas_formatid=(\d+);/, 1]

						pages[pageid] = {count: 0, formats: {}} if pages[pageid].nil?
						pages[pageid][:count] = pages[pageid][:count] + 1

						pages[pageid][:formats][formatid] = 0 if pages[pageid][:formats][formatid].nil?
						pages[pageid][:formats][formatid] = pages[pageid][:formats][formatid] + 1
					end
				end

				urls << page.url

				if urls.length > 10

					p pages
					exit

				end

			end
		end

		p pages

	end
end
class MyAnemone < Thor
	desc "Spiding the web", "Spiding the web"

	def smartTagLookup(host)

		puts "spiding http://#{host}/"

		pages = {}
		formats = {}
		missings = []
		urls = []

		Anemone.crawl("http://#{host}/") do |anemone|

			anemone.storage = Anemone::Storage.Redis
			anemone.after_crawl do

				puts "#{urls.length} pages parsed"

				puts "tags found on pages : "
				ap pages

				puts "pages without tags : "
				ap missings

			end
			anemone.on_every_page do |page|

				if page.code == 200

					print '.'

					tag_found = nil

					#each page
					unless page.doc.nil?

						# each script tag
						page.doc.search('//script').each do |script|

							pageid = script.content[/sas_pageid=["'](\d+\/\d+)["'];/, 1]

							# if script is a SmartTag
							unless pageid.nil?

								tag_found = true

								formatid = script.content[/sas_formatid=(\d+);/, 1]

								pages[pageid] = {count: 0, formats: {}, urls: []} if pages[pageid].nil?

								unless pages[pageid][:urls].include? page.url.to_s
									pages[pageid][:count] = pages[pageid][:count] + 1
									pages[pageid][:urls] << page.url.to_s
								end

								pages[pageid][:formats][formatid] = 0 if pages[pageid][:formats][formatid].nil?
								pages[pageid][:formats][formatid] = pages[pageid][:formats][formatid] + 1
							end
						end

						if tag_found.nil?
							missings << page.url.to_s
							puts "missing : #{page.url.to_s}"
						end
					end

					urls << page.url.to_s

					if urls.length % 100 == 0

						puts "#{urls.length} pages parsed"

						puts "pages without tags : "
						ap missings

					end

				end

			end
		end

	end
end

MyAnemone.start(ARGV)

