#
# Be sure to run `pod lib lint lowladb-objc.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "lowladb-objc"
  s.version          = "0.1.0"
  s.summary          = "Objective C wrapper for the LowlaDB database engine."
  s.homepage         = "https://github.com/lowla/lowladb-objc"
  s.license          = 'Apache 2'
  s.author           = { "Mark Dixon" => "mark_dixon@teamstudio.com" }
  s.source           = { :git => "https://github.com/lowla/lowladb-objc.git", :tag => s.version.to_s }

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
