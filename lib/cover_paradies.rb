=begin
  Copyright (c) 2009 bithive
 
  "Cover Paradies" finder for Yarr
  
  The somewhat sketchy cover-paradies.to has a decent amount of artwork and
  a search interface that is relatively easy to drive with mechanize.
  
  Their markup leaves something to be desired.  Instead of parsing the DOM,
  the awkward loop here looks for lines containing the keywords 'Front' and
  'Back' and then scans the previous line for the image URL.

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

require 'rubygems'
require 'mechanize'

module Yarr
  class CoverParadies < Finder
    PREFIX = "http://cover-paradies.to"
    def find
      query = [ @artist, @album ].join(' ')

      @agent = Mechanize.new {|a| a.user_agent_alias = 'Windows IE 7' }
      @search = @agent.get("#{PREFIX}/?Module=ExtendedSearch")
      @result = @search.form_with(:action => '?Module=ExtendedSearch') do |f|
        f['SearchString'] = query
        f['StringMode']   = 'Wild'
        f['DisplayStyle'] = 'Text'
        f['DateMethod']   = 'None'
      end.click_button
      
      body = @result.body.split("\n")

      body.each_index do |i|
        line = body[i]
        
        ART_TYPES.each do |cover|
          if line =~ /\(#{cover}\)/
            if href = /\.(\/res\/exe\/GetElement\.php\?ID=\d+)/.match(body[i - 1])
              url = PREFIX + href[1]
              fetch(url, cover)
            end
          end
        end
      end
    end
  end
end
