Pod::Spec.new do |s|
  s.name                  = 'TCBuildtools'
  s.version               = '1.0.0'
  s.license               = 'Apache 2.0'
  s.summary               = 'Scripts to improve the Xcode workflow.'
  s.homepage              = 'https://github.com/tcurdt/TCBuildtools'
  s.author                = { 'Torsten Curdt' => 'tcurdt@vafer.org' }
  s.source                = { :git => 'https://github.com/tcurdt/TCBuildtools.git', :tag => '1.0.0' }

  s.requires_arc          = false
  s.osx.source_files      = 'Sources/*.{h,m}'
  s.osx.deployment_target = '10.7'
  s.ios.source_files      = 'Sources/*.{h,m}'
  s.ios.deployment_target = '6.0'
end