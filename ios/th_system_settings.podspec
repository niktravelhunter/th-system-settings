Pod::Spec.new do |s|
  s.name             = 'th_system_settings'
  s.version          = '0.1.0'
  s.summary          = 'Reads three iOS system settings.'
  s.description      = <<-DESC
Reads Reduce Transparency and its change notice, reads and asks the notification permission,
and opens the app's notification settings page.
                       DESC
  s.homepage         = 'https://github.com/niktravelhunter/th-system-settings'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = 'Niklas Brenner'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
