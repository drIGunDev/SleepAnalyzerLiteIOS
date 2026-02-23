$ios_version = '18.5'
platform :ios, $ios_version

use_frameworks!
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

target 'SleepAnalyzer' do
  
  pod 'PolarBleSdk', '~> 6.15.0'
  pod 'RxCocoa'
  
  target 'SleepAnalyzerTests' do
    inherit! :search_paths
  end
  target 'SleepAnalyzerUITests' do
  end

  post_install do |installer|
    installer.generated_projects.each do |project|
      project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $ios_version
        end
      end
    end
  end
end
