Pod::Spec.new do |s|
  s.name             = 'pubnub_flutter'
  s.version          = '0.0.1'
  s.summary          = 'PubNub Flutter plugin.'
  s.description      = <<-DESC
The plugin allows developers to quickly integrate PubNub for iOS and Android. It allows the handling of multiple PubNub clients.
                       DESC
  s.homepage         = 'https://github.com/Ingenio/pubnub_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ingenio LLC' => 'obrand@ingenio.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'PubNub'
  s.ios.deployment_target = '8.0'
end

