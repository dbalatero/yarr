=begin
  Copyright (c) 2009 bithive
  
  "Album Art Exchange" finder for Yarr
  
  AAE has got a large collection of covers, all of which conform to a naming
  convention which is easy to generate, meaning no actual search is required;
  the request is the search.
  
  e.g. Weird Al - Bad Hair Day
  
  http://www.albumartexchange.com/gallery/images/public/we/weirda-badhai.jpg
  http://www.albumartexchange.com/gallery/images/public/we/weirda-badhai_2.jpg
  http://www.albumartexchange.com/gallery/images/public/we/weirda-badhai_<n>.jpg
  
  We simply make these requests and increment <n> until we get a 404.
 
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

module Yarr
  class AlbumArtExchange < Finder
    PREFIX = "http://www.albumartexchange.com/gallery/images/public"
    def find
      artist = @artist.gsub(/\s/, '')
      hash   = artist[0..1]
      artist = artist[0..5]
      album  = @album.gsub(/\s/, '')[0..5]
      base   = "#{PREFIX}/#{hash}/#{artist}-#{album}"

      v  = 0
      rv = fetch('Front', "#{base}.jpg")

      while cached?('Front', rv)
        v   += 1
        url = "#{base}_#{(v + 1).to_s.rjust(2,'0')}.jpg"
        break unless rv = fetch(url)
      end
    end
  end
end
