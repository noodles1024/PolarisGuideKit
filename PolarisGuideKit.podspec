Pod::Spec.new do |s|
  s.name = "PolarisGuideKit"
  s.version = "1.0.0"
  s.summary = "iOS Onboarding guide components with focus highlighting and step orchestration."
  s.description = <<-DESC
PolarisGuideKit provides a step-based onboarding guide with focus highlighting,
overlay transitions, customizable buddy views, and optional plugins.
  DESC
  s.homepage = "https://github.com/noodles1024/PolarisGuideKit"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { 'noodles' => 'robert1111@qq.com' }
  s.source = { :git => "https://github.com/noodles1024/PolarisGuideKit", :tag => s.version.to_s }
  s.ios.deployment_target = "12.0"
  s.swift_version = "5.0"
  s.source_files = "Sources/**/*.{swift}"
  s.requires_arc = true
end
