Pod::Spec.new do |s|
  s.name             = 'fcb_code_push'
  s.version          = '0.1.0'
  s.summary          = 'FCB Code Push iOS plugin'
  s.description      = 'Flutter CodePush Box native iOS plugin'
  s.homepage         = 'https://github.com/lollipopkit/fl_codepush_box'
  s.license          = { :type => 'MIT' }
  s.author           = { 'FCB' => 'fcb@dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'fcb_code_push/Sources/fcb_code_push/**/*.{h,m}'
  s.ios.deployment_target = '12.0'

  # XCFramework bundles both device (arm64) and simulator (arm64+x86_64) slices.
  # Xcode selects the correct slice at build time.
  s.vendored_frameworks = 'libfcb_updater.xcframework'

  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC',
  }

  s.dependency 'Flutter'
end
