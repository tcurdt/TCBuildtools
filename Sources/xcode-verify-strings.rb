#!/usr/bin/env ruby

require 'set'
require 'nokogiri'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

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

        # remove/ignore empty lines
        next if line.match(/^\s*$/)

        k, v = line.scan(/^"(.*)"\s*=\s*"(.*)"/).flatten

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

  def remove(key)
    @translations = @translations.reject { |t| t.key == key }
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
    @translations.sort! { |x,y| x.key.downcase <=> y.key.downcase }
    File.open(@path, 'w') do |file|
      @translations.each do |t|
        # file.puts "{t.pre}"
        file.puts "\"#{t.key}\" = \"#{t.value}\";"
      end
    end
  end
end

def strings(dirs, verbose)
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

# scan xib files

def xib_keys(dirs, verbose)
  Dir.glob(dirs.map { |arg| File.join(arg, '/**/*.xib') }, 0).each do |path|
    # next unless path =~ /SignUp/
    File.open(path, 'r') do |file|
      puts "reading #{path}" if verbose
      doc = Nokogiri::XML(file)

      doc.xpath('//string[@key="NSTitle"]').each do |node|
        key = node.content
        next if !key or key == ""
        # puts " string = '#{key}'" if verbose
        yield path, 0, key
      end

      doc.xpath('//label|//button|//textField').each do |node|
        label = node["userLabel"] || node.xpath('ancestor-or-self::*[@userLabel]/@userLabel').first().to_s
        next if label == "File's Owner"
        ignore = label.start_with? '!'
        [ "text", "title", "placeholder" ].each do |attr|
          node.xpath(".//*[@#{attr}]|.").each do |n|
            key = n[attr]
            next if !key or key == ""
            if ignore
              puts " ! #{attr} = '#{key}' (#{label})" if verbose
            else
              puts " #{attr} = '#{key}' (#{label})" if verbose
              yield path, 0, key unless ignore
            end
          end
        end
      end

    end
  end
end

# scan source files

def keys_in_line(line)
  return [] if line.start_with?('//')
  return [] if line.start_with?('/*')
  line.scan(/NSLocalizedString\(@"(.*?)",/).flatten
end

def code_keys(dirs, verbose)
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

# putting it together

def verify(dirs, verbose, fix)
  ret = 0

  strings = strings(dirs, verbose)

  # union of all the keys in the strings files
  strings_keys = strings_keys(strings)

  unused_keys = Set.new(strings_keys)
  missing_keys = Set.new

  code_keys(dirs, verbose) do |path,lc,key|
    if strings_keys.include?(key)
      unused_keys.delete(key)
    else
      missing_keys << key
      puts "%s:%d: error: code uses missing key '%s'" % [ path, lc, key ]
      ret = 1
    end
  end

  xib_keys(dirs, verbose) do |path,lc,key|
    if strings_keys.include?(key)
      unused_keys.delete(key)
    else
      missing_keys << key
      puts "%s:%d: error: xib uses missing key '%s'" % [ path, lc, key ]
      ret = 1
    end
  end

  # strings_keys.each do |o|
  #   puts "key = '#{o}'"
  # end
  # unused_keys.each do |o|
  #   puts "unused = '#{o}'"
  # end
  # missing_keys.each do |o|
  #   puts "missing = '#{o}'"
  # end

  duplicates = false

  # check for each key in all string files
  (strings_keys + missing_keys).each do |k|
    strings.each do |s|
      values = s[k]
      duplicates |= values.size > 1
      # puts "#{s.language}: #{k} -> #{values.size}"
      case values.size
      when 0
        puts "%s:%d: error: (%s) missing key '%s'" % [ s.path, 1, s.language, k ]
        missing_keys << k
        ret = 1
      when 1
        values.each do |t|
          if t.value.strip == ""
            puts "%s:%d: warning: (%s) empty key '%s'" % [ s.path, t.line, s.language, k ]
          end
        end
      else
        values.each do |t|
          puts "%s:%d: error: (%s) duplicate key '%s'" % [ s.path, t.line, s.language, k ]
          ret = 1
        end
      end
    end
  end

  # print unused keys
  unused_keys.each do |k|
    strings.each do |s|
      values = s[k]
      if values.size > 0
        values.each do |t|
          puts "%s:%d: warning: unused key '%s'" % [ s.path, t.line, k ]
          ret = 1
        end
      end
    end
  end

  # fixing

  # remove unused keys
  unused_keys.each do |k|
    strings.each do |s|
      puts "removing unused key '#{k}' from #{s.language}"
      s.remove(k)
    end
  end

  # add missing keys
  missing_keys.each do |k|
    strings.each do |s|
      values = s[k]
      if values.size == 0
        puts "adding missing key '#{k}' to #{s.language}"
        s << Translation.new('', 1, k, k, s.language)
      end
    end
  end

  if fix
    strings.each do |s|
      puts "writing #{s.path}"
      s.save
    end
  end

  return ret
end

xcode = ENV['PROJECT_DIR'].to_s != ""

if xcode
  puts "running via Xcode"
  verbose = true
  fix = false
else
  puts "running via command line"
  verbose = true
  fix = true
end

ignorefile = ".verifystringsignore"
reject = {}
if File.exists?(ignorefile)
  reject = File.open(ignorefile) { |f| f.readlines }.map { |l| l.strip }
  puts "Ingoring #{reject}"
end

dir = ENV['PROJECT_DIR'] || "."
files = Dir.glob(File.join(dir, "*"), 0).reject { |s| reject.include?(File.basename(s)) }

exit verify(files, verbose, fix)