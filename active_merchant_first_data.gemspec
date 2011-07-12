# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "active_merchant_first_data"
  s.version     = "1.0.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Edgars Beigarts"]
  s.email       = ["edgars.beigarts@makit.lv"]
  s.homepage    = "https://github.com/ebeigarts/active_merchant_first_data"
  s.summary     = "First Data Latvia gateway for Active Merchant"
  s.description = s.summary

  s.files         = Dir.glob("{lib}/**/*") + %w(README.md LICENSE)
  s.require_paths = ["lib"]

  s.add_runtime_dependency "activemerchant", [">= 1.15.0"]

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", ["~> 2.6.0"]
  s.add_development_dependency "vcr"
  s.add_development_dependency "fakeweb"
end
