Pod::Spec.new do |s|
  s.name         = "Stated"
  s.version      = "1.2.0"
  s.summary      = "Swift state machine with a beautiful DSL"
  s.homepage     = "git@github.com:jordanhamill/Stated"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Jordan Hamill" => "jordan.hamill22@gmail.com" }
  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.9"
  s.source       = { :git => "git@github.com:jordanhamill/Stated.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
end
