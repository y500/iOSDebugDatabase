#
# Be sure to run `pod lib lint YYDebugDatabase.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YYDebugDatabase'
  s.version          = '2.0.9'
  s.summary          = 'easy way to process splite database'

  s.homepage         = 'https://y500.me'
  s.license          = { :type => 'None', :file => 'LICENSE' }
  s.author           = { 'y500' => 'yanqizhou@126.com' }
  s.source           = { :git => 'https://github.com/y500/YYDebugDatabase.git', :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'
  
  s.dependency 'GCDWebServer'
  s.dependency 'FMDB'

  s.source_files = 'DebugDatabase/**/*.{h,m}', 'DebugDatabase/*.{h,m}'
  s.public_header_files = 'DebugDatabase/DebugDatabaseManager.h'
  s.resource = "DebugDatabase/Web.bundle"

  s.requires_arc = true
  s.frameworks = 'Foundation'
  s.library = 'sqlite3'
    
end
