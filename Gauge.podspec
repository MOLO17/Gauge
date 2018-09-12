#
# Be sure to run `pod lib lint Gauge.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Gauge'
  s.version          = '1.0.0'
  s.summary          = 'Gauge is custom control for iOS applications to display a value of a range in a circular gauge.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Gauge is a simple widget to show a value within a range in a circular gauge. It has default settings, but you can customize the visuals in  many ways and achieve a totally different result.
                       DESC

  s.homepage         = 'https://github.com/MOLO17/Gauge'
  s.screenshots     = 'https://raw.githubusercontent.com/MOLO17/Gauge/master/assets/default-gauge.png', 'https://raw.githubusercontent.com/MOLO17/Gauge/master/assets/custom-gauge.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alessandro Vendruscolo' => 'alessandro.vendruscolo@gmail.com' }
  s.source           = { :git => 'https://github.com/MOLO17/Gauge.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/MisterJack'

  s.platform = :ios, '9.0'
  s.ios.deployment_target = '9.0'

  s.source_files = 'Gauge/Classes/**/*'

  s.frameworks = 'UIKit'
  s.dependency 'TinyConstraints', '~> 3.2.1'

  s.swift_version = '4.2'
end
