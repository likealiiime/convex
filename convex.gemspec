# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{convex}
  s.version = "1.8.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sherr\303\263d Faulks"]
  s.date = %q{2010-11-28}
  s.description = %q{Convex is a semantic conversation extractor. It uses the OpenCalais service to understand documents and generate a flurry of information which is stored and manipulated in novel ways by Convex and its lenses.}
  s.email = %q{dev@styledon.com}
  s.executables = ["chronosd", "convexd"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README",
     "Rakefile",
     "VERSION",
     "bin/chronosd",
     "bin/convexd",
     "config.ru",
     "convex.gemspec",
     "lenses/chronos/client.rb",
     "lenses/chronos/lens.rb",
     "lenses/chronos/service.rb",
     "lenses/eros/client.rb",
     "lenses/eros/lens.rb",
     "lenses/eros/report.rb",
     "lenses/eros/user.rb",
     "lib/calais_service.rb",
     "lib/command.rb",
     "lib/convex.rb",
     "lib/convex_service.rb",
     "lib/datum.rb",
     "lib/datum_type.rb",
     "lib/em-websocket/em-websocket.rb",
     "lib/em-websocket/em-websocket/connection.rb",
     "lib/em-websocket/em-websocket/debugger.rb",
     "lib/em-websocket/em-websocket/handler.rb",
     "lib/em-websocket/em-websocket/handler75.rb",
     "lib/em-websocket/em-websocket/handler76.rb",
     "lib/em-websocket/em-websocket/handler_factory.rb",
     "lib/em-websocket/em-websocket/websocket.rb",
     "lib/engine.rb",
     "lib/environment.rb",
     "lib/extensions.rb",
     "lib/logging.rb",
     "lib/service_ports.rb",
     "lib/version.rb",
     "pkg/convex-1.8.0.0.gem",
     "web/public/fonts/Quicksand License.txt",
     "web/public/fonts/Quicksand_Bold-webfont.eot",
     "web/public/fonts/Quicksand_Bold-webfont.ttf",
     "web/public/fonts/Quicksand_Bold_Oblique-webfont.eot",
     "web/public/fonts/Quicksand_Bold_Oblique-webfont.ttf",
     "web/public/fonts/Quicksand_Book-webfont.eot",
     "web/public/fonts/Quicksand_Book-webfont.ttf",
     "web/public/fonts/Quicksand_Book_Oblique-webfont.eot",
     "web/public/fonts/Quicksand_Book_Oblique-webfont.ttf",
     "web/public/fonts/Quicksand_Dash-webfont.eot",
     "web/public/fonts/Quicksand_Dash-webfont.ttf",
     "web/public/fonts/Quicksand_Light-webfont.eot",
     "web/public/fonts/Quicksand_Light-webfont.ttf",
     "web/public/fonts/Quicksand_Light_Oblique-webfont.eot",
     "web/public/fonts/Quicksand_Light_Oblique-webfont.ttf",
     "web/public/images/site/convex.png",
     "web/public/javascripts/application.js",
     "web/public/javascripts/mootools-1.2.5-core-yc.js",
     "web/public/stylesheets/application.css",
     "web/public/stylesheets/quicksand.css",
     "web/views/index.erubis",
     "web/web.rb"
  ]
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{CONVersation EXtractor}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-debug>, [">= 0"])
      s.add_runtime_dependency(%q<redis>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_runtime_dependency(%q<eventmachine>, [">= 0"])
      s.add_runtime_dependency(%q<SystemTimer>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<httparty>, [">= 0"])
      s.add_runtime_dependency(%q<postmark>, [">= 0"])
      s.add_runtime_dependency(%q<tmail>, [">= 0"])
      s.add_runtime_dependency(%q<sinatra>, [">= 0"])
      s.add_runtime_dependency(%q<erubis>, [">= 0"])
      s.add_runtime_dependency(%q<sinatra-reloader>, [">= 0"])
    else
      s.add_dependency(%q<ruby-debug>, [">= 0"])
      s.add_dependency(%q<redis>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<eventmachine>, [">= 0"])
      s.add_dependency(%q<SystemTimer>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<httparty>, [">= 0"])
      s.add_dependency(%q<postmark>, [">= 0"])
      s.add_dependency(%q<tmail>, [">= 0"])
      s.add_dependency(%q<sinatra>, [">= 0"])
      s.add_dependency(%q<erubis>, [">= 0"])
      s.add_dependency(%q<sinatra-reloader>, [">= 0"])
    end
  else
    s.add_dependency(%q<ruby-debug>, [">= 0"])
    s.add_dependency(%q<redis>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<eventmachine>, [">= 0"])
    s.add_dependency(%q<SystemTimer>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<httparty>, [">= 0"])
    s.add_dependency(%q<postmark>, [">= 0"])
    s.add_dependency(%q<tmail>, [">= 0"])
    s.add_dependency(%q<sinatra>, [">= 0"])
    s.add_dependency(%q<erubis>, [">= 0"])
    s.add_dependency(%q<sinatra-reloader>, [">= 0"])
  end
end

