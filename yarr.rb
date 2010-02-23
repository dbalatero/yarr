=begin
  Copyright:: Copyright (c) 2010 bithive (twitter: @bithive)
  License:: GPL (http://www.gnu.org/licenses/)
  
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
require 'fileutils'
require 'yaml'

module Yarr
  VERSION    = '0.0.1'
  ART_TYPES  = [ 'Front', 'Back' ].freeze
  config     = File.join(File.expand_path(ENV['HOME']), '.yarr')

  begin
    CONFIG = YAML.load_file(config)
  rescue
    File.open(config, 'w') do |f|
      YAML.dump({
        :wget_options => '--user-agent="Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)"',
        :image_dir => '/var/tmp/yarr/covers',
        :lastfm_key => ''
      }, f)
    end
  end
  
  begin
    FileUtils.mkdir_p(CONFIG[:image_dir]) unless File.exist?(CONFIG[:image_dir])
  rescue
    puts "Please edit the .yarr file in your home directory."
    puts "Make sure you have write permission on image_dir."
    puts "You must also provide lastfm_key if you wish to use LastFm."
    exit
  end  
  
  class Finder
    attr_reader :artist
    attr_reader :album
   
    def initialize(artist, album)
      @artist = artist.dup.gsub(/[^\w\d\s]/, '').downcase
      @album  = album.dup.gsub(/[^\w\d\s]/, '').downcase

      artist = artist.dup.gsub(/[^\d\w]/, '').downcase
      album  = album.dup.gsub(/[^\d\w]/, '').downcase
      
      @slug     = album
      @hashbase = "#{artist[0..1]}/#{artist}"
      @dirbase  = "#{CONFIG[:image_dir]}/#{@hashbase}"
      @filebase = album
      @manifest = "#{@dirbase}/.nyarr"

      if File.exist?(@manifest)   	  
        @metadata = File.open(@manifest) {|f| YAML.load(f) }
      else
        @metadata = { self.class.to_s => {} }
      end
    end
    
    def cached?(cover = nil, version = nil)
      if cover and version
        Dir["#{pathbase(cover, version)}*"].size > 0
      else
        Dir["#{@dirbase}/#{@filebase}*"].size > 0
      end
    end
    
    def count
      counts = { :front => 0, :back => 0 }
      ART_TYPES.inject({ :front => 0, :back => 0}) do |counts, cover|
        glob = "#{@dirbase}/#{@filebase}-#{cover.downcase}-*"
        counts[cover.downcase.to_sym] += Dir[glob].size
        counts
      end
    end
    
    def fail!
      @metadata[self.class.to_s] = {} unless @metadata[self.class.to_s]
      @metadata[self.class.to_s][@slug] = {
        :status => 'failed',
        :failed_at => Time.now.to_i
      }
      update_metadata
    end
    
    def failed?
      begin
        @metadata[self.class.to_s][@slug][:status] == 'failed'
      rescue
        false
      end
    end
    
    def find!
      FileUtils.mkdir_p(@dirbase) unless File.exists?(@dirbase)
      failed? or find
      fail! unless cached?
    end
    
    def fetch(url, cover = 'Front')
      version = next_version(cover)
      cmd = "wget #{CONFIG[:wget_options]} #{url} -O #{pathbase(cover, version)}.tmp"

      IO.popen(cmd) do |pipe|
        Thread.new do
          sleep 0.75
          s = pipe.gets
          puts s unless s.nil?
        end.join(10)
      end

      if $?.success?
        rename_tmp_file(cover, version)
        rest
        return version
      else
        begin
          FileUtils.rm("#{pathbase(cover, version)}.tmp")
        rescue
        end
        return false
      end
    end
    
    def next_version(cover)
      version = 0
      while cached?(cover, version) do version += 1 end
      version
    end
    
    def pathbase(cover = 'Front', version = 0)
      "#{@dirbase}/#{@filebase}-#{cover.downcase}-#{version}"
    end
    
    def rename_tmp_file(cover, version)
      raise "Requested version not cached!" unless cached?(cover, version)

      ext = case `file #{pathbase(cover, version)}.tmp`
        when /JPEG/
          'jpg'
                 
        when /PNG/
          'png'
      end

      FileUtils.mv("#{pathbase(cover, version)}.tmp",
        "#{pathbase(cover, version)}.#{ext}")
    end
     
    def rest
      n = 1 + rand(5)
      n.times {|i| print "\rResting #{n - i}s"; sleep(1) }
    end
    
    def update_metadata
      File.open(@manifest, 'w') {|f| YAML.dump(@metadata, f) }
    end
  end
end

require 'lib/album_art_exchange'
require 'lib/cover_paradies'
require 'lib/last_fm'
