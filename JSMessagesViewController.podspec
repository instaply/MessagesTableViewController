Pod::Spec.new do |s|
	s.name				= 'JSMessagesViewController'
	s.version			= '4.0.4'
	s.summary			= 'A messages UI for iPhone and iPad. Customized for Instaply'
	s.homepage			= 'https://github.com/instaply/MessagesTableViewController'
	s.social_media_url	= 'https://twitter.com/instaply'
	s.license			= 'MIT'
	s.authors			= { 'Jesse Squires' => 'jesse.squires.developer@gmail.com', 'Sebastien Arbogast' => 'sebastien@instaply.com' }
	s.source			= { :git => 'https://github.com/instaply/MessagesTableViewController.git', :tag => s.version.to_s }
	s.platform			= :ios, '6.0'
	s.source_files		= 'JSMessagesViewController/Classes/**/*'
	s.resources			= 'JSMessagesViewController/Resources/**/**/*'
	s.frameworks		= 'QuartzCore'
	s.requires_arc		= true

	s.dependency 'JSQSystemSoundPlayer'
end
