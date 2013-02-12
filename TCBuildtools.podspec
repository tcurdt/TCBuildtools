Pod::Spec.new do |s|
  s.name                  = 'TCBuildtools'
  s.version               = '1.0.0'
  s.license               = 'Apache 2.0'
  s.summary               = 'Scripts to improve the Xcode workflow.'
  s.homepage              = 'https://github.com/tcurdt/TCBuildtools'
  s.author                = { 'Torsten Curdt' => 'tcurdt@vafer.org' }
  s.source                = { :git => 'https://github.com/tcurdt/TCBuildtools.git', :tag => '1.0.0' }
  s.preserve_paths        = 'Scripts'
  s.requires_arc          = false
  s.source_files          = 'Sources/*.{h,m}'
end