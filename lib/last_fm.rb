=begin
  Copyright (c) 2009 bithive
 
  This file is part of Yarr.
 
  Yarr is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
 
  Yarr is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
 
  You should have received a copy of the GNU General Public License
  along with Yarr.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'cgi'
require 'net/http'
require 'xmlsimple'

module Yarr
  class LastFm < Finder
    def find
      artist = CGI.escape(@artist)
      album  = CGI.escape(@album)

      path = "/2.0/?method=album.getinfo&api_key=#{CONFIG[:lastfm_key]}&artist=#{artist}&album=#{album}"
      data = Net::HTTP.get('ws.audioscrobbler.com', path)
      xml  = XmlSimple.xml_in(data)

    	if xml['status'] == 'ok' then
        album = xml['album'][0]
        puts album.inspect
        url   = album['image'][3]['content']

        fetch('Front', url)
      end
    end
  end
end
