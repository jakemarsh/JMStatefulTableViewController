Pod::Spec.new do |s|
	s.name 			= 'JMStatefulTableViewController'
	s.version 	= '0.0.1'
	s.license  	= 'MIT'
  s.summary 	= 'A subclass-able way to cleanly and neatly implement a table view controller that has empty, loading and error states. Supports "paging" and pull to to refresh thanks to SVPullToRefresh.'
  s.homepage 	= 'https://github.com/jakemarsh/JMStatefulTableViewController'
  s.authors 	= { 'Jake Marsh' => 'jake@deallocatedobjects.com' }
  s.source 		= { :git => 'git://github.com/jakemarsh/JMStatefulTableViewController.git', :tag => '0.0.1' }

  s.platform  = :ios

  s.source_files = ['JMStatefulTableViewControllerDemo/JMStatefulTableViewController.*', 'JMStatefulTableViewControllerDemo/JMStatefulTableViewEmptyView.*', 'JMStatefulTableViewControllerDemo/JMStatefulTableViewLoadingView.*']

	s.dependency 'SVPullToRefresh'
end