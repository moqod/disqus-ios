Pod::Spec.new do |spec|
  spec.name         = "iOS Disqus API"
  spec.version      = "0.0.1"
  spec.summary      = "The project has been created by Moqod team to help many developers searching for this solution on Stackoverflow and else where. Special thanks to Disqus for answering support questions promptly! When integrating this solution to your project, please, spare us a like on Facebook, follow us on Twitter or spread a good word about us!"
  spec.homepage     = "https://disqus.com/"
  spec.license      =  {:type => 'MIT', :file => 'COPYRIGHT' }
  spec.author       = { 'Moqod' => 'info@moqod.com', 'Andrew Kopanev' => 'andrew@moqod.com' }
  spec.source       = { :git => "https://github.com/appunite/disqus-ios.git", :tag => "0.0.1" }
  
  spec.platform     = :ios
  spec.ios.deployment_target = '6.0'
  spec.requires_arc = true

  spec.frameworks   = ['CoreGraphics', 'UIKit', 'Foundation']
  spec.dependency 'AFNetworking', '~> 2.2.1'
  spec.source_files = 'Disqus/DisqusComponent/*.h,*.m'

end

