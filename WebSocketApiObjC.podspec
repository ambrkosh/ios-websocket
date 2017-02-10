#
# Be sure to run `pod lib lint WebSocketApiObjC.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WebSocketApiObjC'
  s.version          = '0.1.0'
  s.summary          = 'WebSocketApiObjC allows for the communication between a server and client using web sockets.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
WebSocketApiObjC is a simple api that uses SocketRocket to allow for communication between a server and client using web sockets.  CocoaPods installation is required.
                       DESC

  s.homepage         = 'https://github.com/ambrkosh/ios-websocket'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'David Ye' => 'ambrkosh@gmail.com' }
  s.source           = { :git => 'https://github.com/ambrkosh/ios-websocket.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.2'

  s.source_files = 'WebSocketApiObjC/Classes/**/*'
  
  # s.resource_bundles = {
  #   'WebSocketApiObjC' => ['WebSocketApiObjC/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SocketRocket', '~> 0.5.1'
end
