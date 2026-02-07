require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'react-native-healthql'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = "#{package['description']} Provides SQL-like queries for HealthKit."
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platforms      = { :ios => '15.0' }
  s.swift_version  = '5.9'
  s.source         = { :git => package['repository']['url'], :tag => "v#{s.version}" }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'
  s.dependency 'HealthQL'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }

  s.source_files = "**/*.{h,m,swift}"

  s.frameworks = 'HealthKit'
end
