VERSION := $(shell ruby -e "puts Gem::Specification.load('revtree.gemspec').version")

all: revtree-$(VERSION).gem

clean:
	rm --force revtree-*.gem

install: revtree-$(VERSION).gem
	gem install --local $<

uninstall:
	gem uninstall revtree

revtree-$(VERSION).gem: revtree.gemspec lib/revtree.rb Gemfile.lock
	gem build $<

test: lib/revtree.rb Gemfile.lock
	rufo -c lib/
	yard
	rspec

.PHONY: all clean install uninstall test
