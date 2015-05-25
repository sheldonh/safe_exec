Dir.glob(File.join(File.dirname(__FILE__), "shexec", "**", "*.rb")) do |f|
  require f
end

module Shexec
end
