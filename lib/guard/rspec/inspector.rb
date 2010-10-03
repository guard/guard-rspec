module Guard
  class RSpec
    module Inspector
      class << self
        
        def clean(paths)
          paths.uniq!
          paths.compact!
          paths = paths.select { |p| spec_file?(p) || spec_folder?(p) }
          paths = paths.delete_if { |p| included_in_other_path?(p, paths) } 
          clear_spec_files_list
          paths
        end
        
      private
        
        def spec_folder?(path)
          path.match(/^\/?spec/) && !path.match(/\..+$/)
        end
        
        def spec_file?(path)
          spec_files.include?(path)
        end
        
        def spec_files
          @spec_files ||= Dir.glob("spec/**/*_spec.rb")
        end
        
        def clear_spec_files_list
          @spec_files = nil
        end
        
        def included_in_other_path?(path, paths)
          paths = paths.select { |p| p != path }
          paths.any? { |p| path.include?(p) && (path.gsub(p, '')).include?("/") }
        end
        
      end
    end
  end
end