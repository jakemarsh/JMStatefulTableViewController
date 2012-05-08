Pod::Spec.new do
	name 'JMStatefulTableViewController'
	authors 'Jake Marsh' => 'jake@deallocatedobjects.com'
	version '0.0.1'
	summary 'A subclass-able way to cleanly and neatly implement a table view controller that has empty, loading and error states. Supports "paging" and pull to to refresh thanks to SVPullToRefresh.'
	source :git => 'git://github.com/jakemarsh/JMStatefulTableViewController.git'

	platforms 'iOS'
	sdk '>= 5.0'
end