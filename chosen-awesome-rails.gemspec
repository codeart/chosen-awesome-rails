# -*- encoding: utf-8 -*-
# stub: chosen-awesome-rails 1.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "chosen-awesome-rails".freeze
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["heaven".freeze]
  s.date = "2015-03-24"
  s.description = "Chosen is a javascript library of select box enhancer for jQuery, integrates with Rails asset pipeline for ease of use.".freeze
  s.email = ["alex@codeart.pw".freeze]
  s.files = [".gitignore".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "chosen-awesome-rails.gemspec".freeze, "lib/chosen-awesome-rails.rb".freeze, "lib/chosen-awesome-rails/engine.rb".freeze, "lib/chosen-awesome-rails/engine3.rb".freeze, "lib/chosen-awesome-rails/version.rb".freeze, "vendor/assets/images/chosen-arrow.gif".freeze, "vendor/assets/javascripts/chosen.coffee".freeze, "vendor/assets/javascripts/chosen/chosen.coffee".freeze, "vendor/assets/javascripts/chosen/multiple.coffee".freeze, "vendor/assets/javascripts/chosen/parser.coffee".freeze, "vendor/assets/javascripts/chosen/single.coffee".freeze, "vendor/assets/stylesheets/chosen.scss".freeze, "vendor/assets/stylesheets/chosen/_bootstrap2.scss".freeze, "vendor/assets/stylesheets/chosen/_bootstrap3.scss".freeze, "vendor/assets/stylesheets/chosen/_default.scss".freeze]
  s.homepage = "https://github.com/heaven/chosen-awesome-rails".freeze
  s.rubygems_version = "2.6.10".freeze
  s.summary = "Integrate Chosen javascript library with Rails asset pipeline".freeze

  s.installed_by_version = "2.6.10" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>.freeze, [">= 3.0"])
      s.add_runtime_dependency(%q<coffee-rails>.freeze, [">= 3.2"])
      s.add_runtime_dependency(%q<sass-rails>.freeze, [">= 3.2"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.0"])
      s.add_development_dependency(%q<rails>.freeze, [">= 3.0"])
    else
      s.add_dependency(%q<railties>.freeze, [">= 3.0"])
      s.add_dependency(%q<coffee-rails>.freeze, [">= 3.2"])
      s.add_dependency(%q<sass-rails>.freeze, [">= 3.2"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.0"])
      s.add_dependency(%q<rails>.freeze, [">= 3.0"])
    end
  else
    s.add_dependency(%q<railties>.freeze, [">= 3.0"])
    s.add_dependency(%q<coffee-rails>.freeze, [">= 3.2"])
    s.add_dependency(%q<sass-rails>.freeze, [">= 3.2"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.0"])
    s.add_dependency(%q<rails>.freeze, [">= 3.0"])
  end
end
