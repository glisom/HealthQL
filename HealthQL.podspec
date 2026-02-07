Pod::Spec.new do |s|
  s.name             = 'HealthQL'
  s.version          = '1.1.0'
  s.summary          = 'SQL-like query interface for Apple HealthKit'
  s.description      = <<-DESC
    HealthQL provides a SQL-like query interface for Apple HealthKit data.
    Write familiar SQL queries to fetch and analyze health data.
  DESC
  s.homepage         = 'https://github.com/glisom/HealthQL'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Grant Isom' => 'glisom@icloud.com' }
  s.source           = { :git => 'https://github.com/glisom/HealthQL.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_version = '5.9'

  # Include both HealthQL core and HealthQLParser sources
  s.source_files = 'Sources/HealthQL/**/*.swift',
                   'Sources/HealthQLParser/**/*.swift'

  s.frameworks = 'HealthKit'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
end
