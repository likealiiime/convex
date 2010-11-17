require 'rubygems'
require 'geminabox'
require 'web/web'

run Convex::Web

Geminabox.data = if File.exist? '/data/convex/shared'
  '/data/convex/shared'
else
  File.join(File.expand_path(__FILE__), 'geminabox')
end
run Geminabox