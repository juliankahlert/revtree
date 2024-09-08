# RevTree

[![Build Status](https://github.com/juliankahlert/revtree/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/juliankahlert/revtree)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/t/juliankahlert/revtree)](https://github.com/juliankahlert/revtree/commits/)
[![GitHub Tag](https://img.shields.io/github/v/tag/juliankahlert/revtree)](https://github.com/juliankahlert/revtree)
[![Gem Version](https://img.shields.io/gem/v/revtree)](https://rubygems.org/gems/revtree)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ac169e80b46b4d78a1a3e8e15be24c2f)](https://app.codacy.com/gh/juliankahlert/revtree/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/ac169e80b46b4d78a1a3e8e15be24c2f)](https://app.codacy.com/gh/juliankahlert/revtree/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_coverage)

## Introduction

`RevTree` is a Ruby library for tracking and comparing directory structures.
It calculates the MD5 hash for files and directories to determine their revisions and supports detecting changes like additions, removals, and modifications.
It also provides methods to print and serialize the tree structure, as well as traverse it for specific statuses.

## Features

- **Directory and File Tracking**: Handles both directories and files, including recursive directory structures.
- **Revision Tracking**: Computes and tracks revisions using MD5 hashes.
- **Change Detection**: Identifies and marks changes such as additions, deletions, and modifications.
- **Serialization**: Supports serialization to and from JSON format for easy storage and transfer.
- **Pretty Printing**: Provides a method to print the directory tree with statuses.
- **Iterate with `for_each`**: Traverse the tree and apply a block to files matching specific statuses.
- **Watch for Changes**: Automatically monitors a directory for changes with `watch`, and triggers actions based on file changes.
- **Customizable Watch Interval**: Set a custom interval between checks with the `with_interval` method.

## Install

The supported tools are:

- gitpack
- make
- gem

### gitpack

```sh
gitpack add juliankahlert/revtree
```

### make

```sh
git clone https://github.com/juliankahlert/revtree.git
cd revtree
sudo make install
```

### gem (local)

```sh
git clone https://github.com/juliankahlert/revtree.git
cd revtree
gem build revtree.gemspec
sudo gem install --local revtree-0.1.6.gem
```

## API Documentation

### `RevTree.new(path, whitelist = nil)`

- **Parameters**:
  - `path` (`String`): The path to the file or directory.
  - `whitelist` (`Array<String>`): List of patterns to include in the tree.

### `#print_tree(indent = 0)`

- **Parameters**:
  - `indent` (`Integer`): Number of spaces to indent each level of the tree.

### `#to_h`

- **Returns**: A `Hash` representation of the `RevTree` object.

### `#to_json`

- **Returns**: A `JSON` representation of the `RevTree` object.

### `#for_each(status_whitelist, &block)`

- **Parameters**:
  - `status_whitelist` (`Array<Symbol>`): List of statuses to include (e.g., `[:added, :removed]`).
  - `&block` (`Proc`): A block to execute for each file matching the given statuses.
- **Behavior**: Iterates over files in the tree, executing the block for each file whose status matches one of the statuses in the whitelist.

### `#watch(status_whitelist = [:modified, :added, :removed], &block)`

- **Parameters**:
  - `status_whitelist` (`Array<Symbol>`): List of statuses to watch (e.g., `[:added, :removed]`).
  - `&block` (`Proc`): A block to execute when a file matching the given statuses is changed.

### `#with_interval(interval)`

- **Parameters**:
  - `interval` (`Integer`): Interval (in seconds) between checks for changes.
- **Returns**: The `RevTree` instance, enabling method chaining.

### `RevTree.from_h(h)`

- **Parameters**:
  - `h` (`Hash`): A `Hash` representation of a `RevTree` object.
- **Returns**: A `RevTree` object.

### `RevTree.from_json(json_str)`

- **Parameters**:
  - `json_str` (`String`): A `JSON` string representing a `RevTree` object.
- **Returns**: A `RevTree` object.

## Example Usage

### Comparing two directory structures

```ruby
#!/bin/env ruby

require 'revtree'

# Let's simulate two different directory structures to compare
file_tree_old = RevTree.new('./', ['*.rb', '*.md'])
file_tree_new = RevTree.new('./', ['*.rb'])

# Compare the two trees
result_tree = RevTree.compare(file_tree_old, file_tree_new)

# Print the resulting tree with change statuses
result_tree.print_tree

# Example of using for_each
result_tree.for_each([:added, :removed]) do |file, full_path|
  p "File #{file.name} in #{full_path} was added/removed"
end
```

### Watching a directory for changes

```ruby
#!/bin/env ruby

require 'revtree'

# Create a RevTree for the current directory, including only .rb and .md files
file_tree = RevTree.new('./', ['*.rb', '*.md'])

# Watch for changes in the directory
file_tree.with_interval(10).watch([:modified, :added, :removed]) do |file, full_path|
  puts "File #{file.name} #{file.status} in #{full_path}"
end
```

This second example demonstrates the `watch` method, which continuously monitors the directory tree for changes and triggers a block of code when changes (additions, modifications, or deletions) are detected. The `with_interval` method customizes the time between checks.

## Encouragement for Contribution

Contributions from the community are welcome!
If you find any issues or have ideas for new features, please feel free to submit a pull request or open an issue.
Your input helps make RevTree better for everyone.

## License

RevTree is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
