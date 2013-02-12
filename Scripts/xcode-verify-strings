#!/usr/bin/env ruby
require 'set'

class Translation
  attr_reader :pre, :key, :value, :line, :language

  def initialize(pre, line, key, value, language, track_unused = true)
    @pre = pre
    @key = key
    @value = value
    @line = line
    @language = language
    @track_unused = track_unused
  end

  def track_unused?
    @track_unused
  end

end

class Strings
  attr_reader :path, :language

  def initialize(language)
    @translations = []
    @language = language
  end

  def load(path)
    @path = path
    File.open(path, 'r') do |file|
      # puts "Loading #{path}"
      pre = ''
      lc = 0
      while (line = file.gets)
        lc += 1
        # next if line.match(/#{@language}/)
        line = "/* */" if line.match(/No comment provided/)
        next if line.match(/^\s*$/)

        k, v = line.scan(/"(.*)"\s*=\s*"(.*)"/).flatten
        # puts "#{@language}: #{k} = #{v}"
        if k and v
          @translations << Translation.new(pre, lc, k, v, language, ! (line =~ /#\s+external\s*$/))
          pre = ''
        else
          pre += line
        end
      end
    end
    self
  end

  def keys
    @translations.map { |t| t.key }
  end

  def [](key)
    @translations.select { |t| t.key == key }
  end

  def <<(translation)
    @translations << translation
  end

  def save
    # @translations.sort! { |x,y| x.key.downcase <=> y.key.downcase }
    File.open(@path, 'w') do |file|
      @translations.each do |t|
        file.puts "#{t.pre}"
        file.puts "\"#{t.key}\" = \"#{t.value}\";"
        file.puts
      end
    end
  end
end

class Strings
  attr_reader :path, :language

  def initialize(language)
    @translations = []
    @language = language
  end

  def load(path)
    @path = path
    File.open(path, 'r') do |file|
      # puts "Loading #{path}"
      pre = ''
      lc = 0
      while (line = file.gets)
        lc += 1
        line = "/* */" if line.match(/No comment provided/)
        next if line.match(/^\s*$/)
        k, v = line.scan(/"(.*)"\s*=\s*"(.*)"/).flatten
        if k and v
          @translations << Translation.new(pre, lc, k, v, language, ! (line =~ /#\s+external\s*$/))
          pre = ''
        else
          pre += line
        end
      end
    end
    self
  end

  def keys
    @translations.map { |t| t.key }
  end

  def [](key)
    @translations.select { |t| t.key == key }
  end

  def <<(translation)
    @translations << translation
  end
end


def xib_keys(dirs)
  keys = Set.new
  Dir.glob(dirs.map { |arg| File.join(arg, '/**/*.xib') }, 0).each do |path|
    File.open(path, 'r') do |file|
      while (line = file.gets)
        key = line.scan(/<string key="NSTitle">(.*?)<\/string>/).flatten.first
        keys.add(key) if key
      end
    end
  end
  keys
end

def strings(dirs)
  ret = []
  Dir.glob(dirs.map { |arg| File.join(arg, '/**/*.lproj/*.strings') }, 0).each do |path|
    language = path.scan(/([^\/]*)\.lproj/).flatten.first
    strings = Strings.new(language).load(path)
    ret << strings
  end
  ret
end

def strings_keys(strings)
  keys = Set.new
  strings.each do |s|
    keys.merge(s.keys)
  end
  keys
end

def keys_in_line(line)
  return [] if line.start_with?('//')
  return [] if line.start_with?('/*')
  line.scan(/NSLocalizedString\(@"(.*?)",/).flatten
end

def code_keys(dirs)
  Dir.glob(dirs.map { |arg| File.join(arg, '/**/*.m') }, 0).each do |path|
    File.open(path, 'r') do |file|
      lc = 0
      while (line = file.gets)
        lc += 1
        keys_in_line(line.strip).each do |key|
          yield path, lc, key
        end
      end
    end
  end
end

def verify(dirs)
  ret = 0
  strings = strings(dirs)
  xib_keys = xib_keys(dirs)
  keys = strings_keys(strings) + xib_keys

  # check for each key in all string files
  keys.each do |k|
    translations = []
    strings.each do |s|
      values = s[k]
      translations += values
      if values.size == 0
        puts "%s:%d: warning: missing key '%s'" % [ s.path, 0, k ]
        s << Translation.new('', 0, k, '', s.language)
      elsif values.size > 1
        values.each do |t|
          puts "%s:%d: error: duplicate key '%s'" % [ s.path, t.line, k ]
        end
      end
    end
  end

  unused_keys = Set.new(keys)
  code_keys(dirs) do |path,lc,key|
    if keys.include?(key)
      unused_keys.delete(key)
    else
      puts "%s:%d: error: missing key '%s'" % [ path, lc, key ]
      ret = 1
    end
  end

  unused_keys.subtract(xib_keys)

  # print unused keys
  unused_keys.each do |key|
    strings.each do |s|
      s[key].each do |t|
        if t.track_unused?
          puts "%s:%d: warning: unused key '%s'" % [ s.path, t.line, key ]
          ret = 1
        end
      end
    end
  end

  return ret
end

ret = if ARGV.length == 0
  ignorefile = ".verifystringsignore"
  reject = {}
  if File.exists?(ignorefile)
    reject = File.open(ignorefile) { |f| f.readlines }.map { |l| l.strip }
    puts "Ingoring #{reject}"
  end
  verify(Dir.glob(File.join(ENV['PROJECT_DIR'] || ".", "*"), 0).reject { |s| reject.include?(File.basename(s)) })
else
  verify(ARGV)
end

exit ret