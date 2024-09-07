# lib/revtree.rb
#
# MIT License
#
# Copyright (c) 2024 Julian Kahlert
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'digest'
require 'pathname'
require 'json'

# The `RevTree` class provides a tree structure representing file directories and
# files, allowing for version tracking based on MD5 hashes.
#
# This class can traverse directories, compare versions of trees, and serialize/deserialize
# itself to/from JSON.
class RevTree
  # @return [Array<RevTree>] the list of children in the tree (empty for files)
  attr_reader :children

  # @return [Symbol] the type of the node (:folder or :file)
  attr_reader :type

  # @return [String] the name of the file or directory
  attr_reader :name

  # @return [String] the revision (MD5 hash) of the file or directory
  attr_reader :rev

  # @return [Symbol] the status of the file or directory (:unmodified, :modified, :added, :removed)
  attr_reader :status

  # Initializes a new `RevTree` object representing a directory or file.
  #
  # @param path [String, Pathname] the path to the file or directory
  # @param whitelist [Array<String>, nil] a list of file patterns to include (optional)
  def initialize(path, whitelist = nil)
    @path = Pathname.new(path)
    @name = @path.basename.to_s
    @whitelist = whitelist || []
    @status = :unmodified

    if @path.directory?
      init_dir
    else
      init_file
    end
  end

  # Prints the tree structure, including file names and statuses, to the console.
  #
  # @param indent [Integer] the indentation level (default: 0)
  # @return [void]
  def print_tree(indent = 0)
    status_str = @status ? " (status: #{@status})" : ''
    puts "#{'  ' * indent}#{@type == :folder ? '[Folder]' : '[File]'} #{@name} (rev: #{@rev})#{status_str}"
    @children.each { |child| child.print_tree(indent + 1) }
  end

  # Serializes the `RevTree` object to a hash.
  #
  # @return [Hash] a hash representing the object
  def to_h
    {
      type: @type,
      name: @name,
      rev: @rev,
      status: @status,
      children: @children.map(&:to_h),
    }
  end

  # Converts the `RevTree` object to JSON format.
  #
  # @return [String] a JSON string representing the object
  def to_json
    JSON.pretty_generate(self.to_h)
  end

  # Reconstructs a `RevTree` object from a hash.
  #
  # @param h [Hash] the hash to deserialize
  # @return [RevTree] the reconstructed `RevTree` object
  def self.from_h(h)
    new_tree(h[:name], h[:type].to_sym, h[:rev], h[:children], h[:status])
  end

  # Reconstructs a `RevTree` object from a JSON string.
  #
  # @param json_str [String] the JSON string to deserialize
  # @return [RevTree] the reconstructed `RevTree` object
  def self.from_json(json_str)
    data = JSON.parse(json_str, symbolize_names: true)
    file_tree = from_h(data)

    file_tree
  end

  # Executes a block of code for each file matching the provided status whitelist.
  #
  # @param status_whitelist [Array<Symbol>] the list of statuses to match (:added, :modified, etc.)
  # @yield [node, full_path] the block to be executed for each matching file
  # @yieldparam node [RevTree] the current node being traversed
  # @yieldparam full_path [String] the full path of the current node
  # @return [void]
  def for_each(status_whitelist = [:unmodified, :modified, :added, :removed], &block)
    return unless block_given?

    RevTree.traverse_tree(self, status_whitelist, @path, nil, &block)
  end

  # Watches the tree for changes
  #
  # Compares the refreshed tree to its last version and calls the provided block
  # for each node that matches the statuses in the `status_whitelist`.
  #
  # @param status_whitelist [Array<Symbol>] the list of statuses to match (:added, :modified, etc.)
  # @yield [node, full_path] the block to be executed for each matching file
  # @yieldparam node [RevTree] the node that was changed
  # @yieldparam full_path [String] the full path of the node
  # @return [void]
  def watch(status_whitelist = [:modified, :added, :removed], &block)
    current_tree = self
    @interval ||= 5

    Signal.trap('INT') { exit }
    Signal.trap('TERM') { exit }
    loop do
      sleep @interval

      new_tree = RevTree.new(@path, @whitelist)
      diff_tree = RevTree.compare(current_tree, new_tree)

      next if diff_tree.nil?

      diff_tree.for_each(status_whitelist) do |node, full_path|
        block.call(node, full_path)
      end

      current_tree = new_tree
    end
  end

  # Sets the interval for the watch method's sleep duration.
  #
  # @param interval [Integer] the number of seconds to sleep between checks
  # @return [RevTree] the current instance for chaining
  def with_interval(interval)
    @interval = interval
    self
  end

  private

  # Calculates the MD5 hash for the file.
  #
  # @return [String] the MD5 hash of the file
  def calculate_file_rev
    Digest::MD5.file(@path).hexdigest
  end

  # Calculates the MD5 hash for the directory based on its children.
  #
  # @return [String] the MD5 hash of the directory
  def calculate_directory_rev
    Digest::MD5.hexdigest(@children.map(&:rev).join)
  end

  # Initializes the directory node by traversing its children.
  #
  # @return [void]
  def init_dir
    @type = :folder
    @children = @path.children
      .select { |c| include_in_tree?(c) }
      .map { |c| RevTree.new(c, @whitelist) }
    @rev = calculate_directory_rev
  end

  # Initializes the file node by calculating its revision.
  #
  # @return [void]
  def init_file
    @type = :file
    @children = []
    @rev = calculate_file_rev
  end

  # Rebuilds a `RevTree` from its serialized components.
  #
  # @param name [String] the name of the node
  # @param type [Symbol] the type of the node (:folder or :file)
  # @param rev [String] the revision hash of the node
  # @param children [Array<Hash>] the child nodes (if any)
  # @param status [Symbol] the status of the node (:unmodified, :modified, etc.)
  # @return [RevTree] the reconstructed tree
  def self.new_tree(name, type, rev, children, status = :unmodified)
    tree = allocate
    tree.instance_variable_set(:@name, name)
    tree.instance_variable_set(:@type, type.to_sym)
    tree.instance_variable_set(:@rev, rev)
    tree.instance_variable_set(:@status, status.to_sym)
    if type == :folder && children
      tree.instance_variable_set(:@children, children.map { |c| from_h(c) })
    else
      tree.instance_variable_set(:@children, [])
    end
    tree
  end

  # Determines whether a file or directory should be included in the tree.
  #
  # @param path [Pathname] the path to the file or directory
  # @return [Boolean] `true` if the path should be included, `false` otherwise
  def include_in_tree?(path)
    return false if path.directory? && path.basename.to_s.start_with?('.')

    return true if path.directory?
    return true if @whitelist.empty?

    @whitelist.any? { |p| File.fnmatch?(p, path.basename.to_s) }
  end

  # Compares two `RevTree` nodes (old and new) and returns a tree with appropriate status.
  #
  # @param old [RevTree, nil] the old version of the tree
  # @param new [RevTree, nil] the new version of the tree
  # @return [RevTree, nil] the resulting tree with status updates or `nil`
  def self.compare(old, new)
    return nil if old.nil? && new.nil?

    return handle_addition(new) if old.nil?
    return handle_removal(old) if new.nil?

    if old.rev != new.rev
      return handle_modification(old, new)
    else
      return handle_unmodified(old, new)
    end
  end

  # Handles the addition of a new node.
  #
  # @param new [RevTree] the new node
  # @return [RevTree] the node with the status set to `:added`
  def self.handle_addition(new)
    with_status = new.dup
    with_status.instance_variable_set(:@status, :added)
    with_status
  end

  # Handles the removal of an old node.
  #
  # @param old [RevTree] the old node
  # @return [RevTree] the node with the status set to `:removed`
  def self.handle_removal(old)
    with_status = old.dup
    with_status.instance_variable_set(:@status, :removed)
    with_status
  end

  # Handles the modification of a node.
  #
  # @param old [RevTree] the old node
  # @param new [RevTree] the new node
  # @return [RevTree] the node with the status set to `:modified`
  def self.handle_modification(old, new)
    if old.type == :folder && new.type == :folder
      compare_folders(old, new, :modified)
    else
      with_status = new.dup
      with_status.instance_variable_set(:@status, :modified)
      with_status
    end
  end

  # Compares two folder nodes and returns a merged node with status updates.
  #
  # @param old [RevTree] the old folder node
  # @param new [RevTree] the new folder node
  # @param status [Symbol] the status to apply (:modified or :unmodified)
  # @return [RevTree] the resulting folder node with status updates
  def self.compare_folders(old, new, status)
    combined_children = merge_children(old.children, new.children)
    with_status = new.dup
    merged = combined_children.map { |o, n| compare(o, n) }

    folder_status = merged.any? { |child| child.status == :modified } ? :modified : status

    with_status.instance_variable_set(:@children, merged)
    with_status.instance_variable_set(:@status, folder_status)
    with_status
  end

  # Handles the unmodified status of a node.
  #
  # @param old [RevTree] the old node
  # @param new [RevTree] the new node
  # @return [RevTree] the node with the status set to `:unmodified`
  def self.handle_unmodified(old, new)
    if old.type == :folder && new.type == :folder
      compare_folders(old, new, :unmodified)
    else
      with_status = new.dup
      with_status.instance_variable_set(:@status, :unmodified)
      with_status
    end
  end

  # Merges the children of two nodes.
  #
  # @param old_children [Array<RevTree>] the children of the old node
  # @param new_children [Array<RevTree>] the children of the new node
  # @return [Array<Array<RevTree, RevTree>>] an array of paired old and new children
  def self.merge_children(old_children, new_children)
    all_names = (old_children.map(&:name) + new_children.map(&:name)).uniq
    all_names.map do |name|
      old_child = old_children.find { |child| child.name == name }
      new_child = new_children.find { |child| child.name == name }
      [old_child, new_child]
    end
  end

  # Traverses the tree and executes a block for each file matching the provided status whitelist.
  #
  # @param node [RevTree] the current node being traversed
  # @param status_whitelist [Array<Symbol>] the list of statuses to match
  # @param root [Pathname] the root path
  # @param current_path [Pathname] the current path
  # @yield [node, full_path] the block to be executed for each matching file
  # @yieldparam node [RevTree] the current node being traversed
  # @yieldparam full_path [String] the full path of the current node
  # @return [void]
  def self.traverse_tree(node, status_whitelist, root, current_path, &block)
    full_path = if current_path
        File.join(current_path.to_s, node.name.to_s)
      else
        root
      end

    if node.type == :file && status_whitelist.include?(node.status)
      block.call(node, File.expand_path(current_path.to_s))
    end

    node.children.each do |child|
      traverse_tree(child, status_whitelist, root, full_path, &block)
    end
  end
end
