# -*- encoding: utf-8 -*-
# stub: chosen-awesome-rails 1.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "chosen-awesome-rails"
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["heaven"]
  s.date = "2015-03-24"
  s.description = "Chosen is a javascript library of select box enhancer for jQuery, integrates with Rails asset pipeline for ease of use."
  s.email = ["alex@codeart.pw"]
  s.files = [".gitignore", "Gemfile", "Gemfile.lock", "LICENSE.txt", "README.md", "Rakefile", "chosen-awesome-rails.gemspec", "lib/chosen-awesome-rails.rb", "lib/chosen-awesome-rails/engine.rb", "lib/chosen-awesome-rails/engine3.rb", "lib/chosen-awesome-rails/version.rb", "vendor/assets/images/chosen-arrow.gif", "vendor/assets/javascripts/chosen.js.coffee", "vendor/assets/javascripts/chosen/chosen.js.coffee", "vendor/assets/javascripts/chosen/multiple.js.coffee", "vendor/assets/javascripts/chosen/parser.js.coffee", "vendor/assets/javascripts/chosen/single.js.coffee", "vendor/assets/stylesheets/chosen.css.scss", "vendor/assets/stylesheets/chosen/bootstrap2.css.scss", "vendor/assets/stylesheets/chosen/bootstrap3.css.scss", "vendor/assets/stylesheets/chosen/default.css.scss"]
  s.homepage = "https://github.com/heaven/chosen-awesome-rails"
  s.rubygems_version = "2.5.1"
  s.summary = "Integrate Chosen javascript library with Rails asset pipeline"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>, [">= 3.0"])
      s.add_runtime_dependency(%q<coffee-rails>, [">= 3.2"])
      s.add_runtime_dependency(%q<sass-rails>, [">= 3.2"])
      s.add_development_dependency(%q<bundler>, [">= 1.0"])
      s.add_development_dependency(%q<rails>, [">= 3.0"])
    else
      s.add_dependency(%q<railties>, [">= 3.0"])
      s.add_dependency(%q<coffee-rails>, [">= 3.2"])
      s.add_dependency(%q<sass-rails>, [">= 3.2"])
      s.add_dependency(%q<bundler>, [">= 1.0"])
      s.add_dependency(%q<rails>, [">= 3.0"])
    end
  else
    s.add_dependency(%q<railties>, [">= 3.0"])
    s.add_dependency(%q<coffee-rails>, [">= 3.2"])
    s.add_dependency(%q<sass-rails>, [">= 3.2"])
    s.add_dependency(%q<bundler>, [">= 1.0"])
    s.add_dependency(%q<rails>, [">= 3.0"])
  end
end
