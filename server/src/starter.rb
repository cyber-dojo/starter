require 'json'
require_relative 'cacher'
require_relative 'cache_index_matcher'
require_relative 'time_now'
require_relative 'unique_id'

class Starter

  def languages_choices(current_display_name)
    cacher = Cacher.new
    cache = cacher.read_display_names_cache('languages')
    matcher = CacheIndexMatcher.new(cache)
    matcher.match_display_name(current_display_name)
    cache
  end

  # - - - - - - - - - - - - - - - - -

  def exercises_choices(current_exercise_name)
    cacher = Cacher.new
    cache = cacher.read_exercises_cache
    matcher = CacheIndexMatcher.new(cache)
    matcher.match_exercise_name(current_exercise_name)
    cache
  end

  # - - - - - - - - - - - - - - - - -

  def custom_choices(current_display_name)
    cacher = Cacher.new
    cache = cacher.read_display_names_cache('custom')
    matcher = CacheIndexMatcher.new(cache)
    matcher.match_display_name(current_display_name)
    cache
  end

  # - - - - - - - - - - - - - - - - -

  include TimeNow
  include UniqueId

  def language_manifest(display_name, exercise_name)
    # [1] Issue: [] is not a valid progress_regex. It needs two regexs.
    # This affects zipper.zip_tag()

    cacher = Cacher.new
    dir_cache = cacher.read_dir_cache('languages')
    dir = dir_cache[display_name]
    if dir.nil?
      raise ArgumentError.new('display_name:invalid')
    end

    instructions = cacher.read_exercises_cache['contents'][exercise_name]
    if instructions.nil?
      raise ArgumentError.new('exercise_name:invalid')
    end

    manifest = JSON.parse(IO.read("#{dir}/manifest.json"))

    manifest['id'] = unique_id
    manifest['created'] = time_now

    set_visible_files(dir, manifest)
    manifest['highlight_filenames'] ||= []
    set_lowlights_filenames(manifest)
    manifest['filename_extension'] ||= ''
    manifest['progress_regexs'] ||= []       # [1]
    manifest['highlight_filenames'] ||= []
    manifest['language'] = display_name.split(',').map(&:strip).join('-')
    manifest['max_seconds'] ||= 10
    manifest['tab_size'] ||= 4
    manifest['visible_files']['instructions'] = instructions
    manifest['exercise'] = exercise_name
    manifest.delete('visible_filenames')
    manifest
  end

  # - - - - - - - - - - - - - - - - -

  def custom_manifest(display_name)
    #TODO: returns the manifest for the web to pass to storer
  end

  # - - - - - - - - - - - - - - - - -

  def manifest(display_name)
    #TODO: return the language/custom manifest for the given
    #display_name. Take into account the start-point renames.
    #Will be used by storer to return a post-re-architecture
    #manifest to simplify web.
  end

  # - - - - - - - - - - - - - - - - -

  def method_missing(name, *_args, &_block)
    raise RuntimeError.new("#{name}:unknown_method")
  end

  private

  def set_lowlights_filenames(manifest)
    manifest['lowlight_filenames'] =
      if manifest['highlight_filenames'].empty?
        ['cyber-dojo.sh', 'makefile', 'Makefile', 'unity.license.txt']
      else
        manifest['visible_filenames'] - manifest['highlight_filenames']
      end
  end

  # - - - - - - - - - - - - - - - - -

  def set_visible_files(dir, manifest)
    visible_filenames = manifest['visible_filenames']
    manifest['visible_files'] =
      Hash[visible_filenames.collect { |filename|
        [filename, IO.read("#{dir}/#{filename}")]
      }]
    manifest['visible_files']['output'] = ''
  end

end
