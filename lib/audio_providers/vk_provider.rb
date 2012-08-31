require 'net/http'
require 'cgi'

module AudioProviders

	class VKProvider

		def self.find_by_query(query)
			if query.blank?
				return []
			end

			site = "vk.com"
			port = 80
			
			vk_config = Rails.application.config.vk_config[:vkontakte]
			email = vk_config[:login]
			pass = vk_config[:password]
			login_page = "http://vk.com/login.php"
			
			conn = Net::HTTP.new(site, port)
			params = { m:1, email:email, pass:pass }
			resp = conn.get("#{login_page}?"+URI.encode_www_form(params))
			cookie = resp.response['set-cookie']
			sid = /remixsid=(?<data>[a-z0-9]+)/.match(resp['Set-Cookie'])['data']

			conn = Net::HTTP.new(site, port) 	
			headers = { "Cookie" => "remixsid=#{sid}; path=/; domain=.vk.com" }
			find_params = { section: "audio", q: query, name:1 }
			resp = conn.get("http://vk.com/al_search.php?" + URI.encode_www_form(find_params), headers)
			
			songs = resp.body
			
			artists_divs = songs.scan(/\/search\?section=audio.+?\<\/a\>/)
			track_name_divs = songs.scan(/span class=\"title\" id=\"title.+?\<\/a\>/)
			divs = songs.scan(/input type=\"hidden\" id=\"audio_.*\" \/\>/)

			result = []

			0.upto(divs.size-1) do |i|
				artist = /\>(?<artist>.+)\</.match(artists_divs[i])["artist"].encode('utf-8', 'windows-1251').gsub(/\<.+?\>/, '')
				artist = CGI.unescapeHTML(artist)
				
				link = /value=\"(?<url>[^,]+)/.match(divs[i])["url"]

				track_name = /\>\<a.+?\>(?<name>.+)\<\/a\>/.match(track_name_divs[i])['name'].encode('utf-8', 'windows-1251').gsub(/\<.+?\>/, '')
				track_name = CGI.unescapeHTML(track_name)

				#puts "#{artist} - #{track_name}"

				result.push({artist:artist,track_name:track_name,url:link})
			end

			result
		end

	end
end