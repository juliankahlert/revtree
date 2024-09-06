VERSION := $(shell ruby -e "puts Gem::Specification.load('revtree.gemspec').version")

all: revtree-$(VERSION).gem

clean:
	rm --force revtree-*.gem

Gemfile.lock: Gemfile
	bundler install

install: revtree-$(VERSION).gem
	gem install --local $<

uninstall:
	gem uninstall revtree

revtree-$(VERSION).gem: revtree.gemspec lib/revtree.rb Gemfile.lock
	bundler install
	gem build $<

test: Gemfile.lock
	bundler install
	rufo -c lib/
	rspec

.PHONY: all clean install uninstall test
