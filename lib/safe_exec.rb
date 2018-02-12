Dir.glob(File.join(File.dirname(__FILE__), "safe_exec", "**", "*.rb")) do |f|
  require f
end

module SafeExec
end
