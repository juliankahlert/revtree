# revtree.gemspec
Gem::Specification.new do |spec|
  spec.name = 'revtree'
  spec.version = '0.1.2'
  spec.authors = ['Julian Kahlert']
  spec.email = ['90937526+juliankahlert@users.noreply.github.com']

  spec.summary = %q{A tool to build and compare file trees with revisions.}
  spec.description = %q{RevTree builds a recursive directory tree and compares file revisions. It can mark files and folders as added, removed, modified, or unmodified. For convenience, RevTree also allows you to watch for changes in a directory tree.}
  spec.homepage = 'https://github.com/juliankahlert/revtree'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir['lib/**/*', 'README.md']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'yard', '~> 0.9', '>= 0.9.37'
  spec.add_development_dependency 'rspec', '~> 3', '>= 3.4'
  spec.required_ruby_version = '>= 3.0.0'
end
