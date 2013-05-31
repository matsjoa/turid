# encoding=utf-8
require 'nokogiri'
require 'open-uri'
require 'uri'

module Cinch
	module Plugins
		class Yr
			include Cinch::Plugin
			@@places = Array.new

			match /yr\s?(\p{Word}+)?\s?(\p{Word}+)?\s?(\p{Word}+)?/

			def get_places
				File.readlines(Dir.pwd + '/lib/data/noreg.csv', :encoding =>'UTF-8').map do |line|
				  @@places.push(line.split(/\t/))
				end
				@@places.sort_by! {|x,y,z|z}
			end

			def find (loc, reg1 = nil, reg2 = nil)
				# Filtering out unmatched fylke
				unless reg2.nil?
					@@places.delete_if {|knr, name, pri, tnn, tnb, ten, k, f| not f.match(/\b#{reg2}\b/i)}
				end

				# Filtering out unmatched kommune
				unless reg1.nil?
					@@places.delete_if {|knr, name, pri, tnn, tnb, ten, k, f| not k.match(/\b#{reg1}\b/i) and not f.match(/\b#{reg1}\b/i)}
				end

				# Filtering out unmatched place
				@@places.delete_if {|knr, name| not name.match(/\b#{loc}\b/i)}

				@@places.each do |place|
					if place[1].match(/\b#{loc}\b/i)
						return place[12]
					end
				end

				return "Fant desverre ikke stedet du søkte etter. Prøv et annet"
			end

			def forecast (uri)
				begin
			      doc = Nokogiri::XML(open(URI.encode(uri)))
			      name = doc.css('location name').text
			      temp = doc.css('observations weatherstation:first temperature').attr('value')
			      windDir = doc.css('observations weatherstation:first windDirection').attr('name')
			      windSpd = doc.css('observations weatherstation:first windSpeed').attr('mps')

			      return "#{name}: For øyeblikket #{temp}°C; Vind #{windSpd} m/s #{windDir}."
			    rescue OpenURI::HTTPError
			      m.reply "Får ikke kontakt med yr.no :/"
			      return
			    end
			end

			def execute(m, loc, reg1, reg2)
				get_places

				if loc.nil?
					m.reply "Bruk: .yr <sted> [<kommune> og eller <fylke>]"
					return
				end

				uri = find loc, reg1, reg2

				unless uri.nil?
					m.reply forecast uri
					return
				end

				m.reply "Fant desverre ikke stedet du søkte etter. Prøv et annet"
			end
		end
	end
end