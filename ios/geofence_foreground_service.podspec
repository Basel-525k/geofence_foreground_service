# Run `pod lib lint geofence_foreground_service.podspec` to validate before publishing.

Pod::Spec.new do |s|
  s.name             = 'geofence_foreground_service'
  s.version          = '1.1.4'
  s.summary          = 'A Flutter project that creates a foreground service to handle geofencing.'
  s.description      = <<-DESC
A Flutter project that creates a foreground service to handle geofencing.
                       DESC
  s.homepage         = 'https://pub.dev/packages/geofence_foreground_service'
  s.license          = { :type => 'Apache-2.0', :file => '../LICENSE' }
  s.author           = { 'Basel' => 'basel@525k.io' }
  s.platform         = :ios, '12.0'

  s.source           = { :git => 'https://github.com/Basel-525k/geofence_foreground_service.git' }

  s.source_files     = 'Classes/**/*'

  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '' }

  s.swift_versions   = ['5.1']
  s.static_framework = true

  s.dependency 'Flutter'

  s.preserve_paths = 'Classes/**'
end
