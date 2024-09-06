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

class RevTree
  attr_reader :children, :type, :name, :rev, :status

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

  def calculate_file_rev
    Digest::MD5.file(@path).hexdigest
  end

  def calculate_directory_rev
    Digest::MD5.hexdigest(@children.map(&:rev).join)
  end

  def print_tree(indent = 0)
    status_str = @status ? " (status: #{@status})" : ''
    puts "#{'  ' * indent}#{@type == :folder ? '[Folder]' : '[File]'} #{@name} (rev: #{@rev})#{status_str}"
    @children.each { |child| child.print_tree(indent + 1) }
  end

  # Serialize the RevTree object to JSON
  def to_h
    {
      type: @type,
      name: @name,
      rev: @rev,
      status: @status,
      children: @children.map(&:to_h),
    }
  end

  def to_json(*_args)
    JSON.pretty_generate(self.to_h)
  end

  def self.from_h(h)
    new_tree(h[:name], h[:type].to_sym, h[:rev], h[:children], h[:status])
  end

  def self.from_json(json_str)
    data = JSON.parse(json_str, symbolize_names: true)
    file_tree = from_h(data)

    file_tree
  end

  def for_each(status_whitelist, &block)
    return unless block_given?

    RevTree.traverse_tree(self, status_whitelist, @path, &block)
  end

  private

  def init_dir
    @type = :folder
    @children = @path.children
      .select { |c| include_in_tree?(c) }
      .map { |c| RevTree.new(c, @whitelist) }
    @rev = calculate_directory_rev
  end

  def init_file
    @type = :file
    @children = []
    @rev = calculate_file_rev
  end

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

  def include_in_tree?(path)
    return false if path.directory? && path.basename.to_s.start_with?('.')

    return true if path.directory?
    return true if @whitelist.empty?

    @whitelist.any? { |p| File.fnmatch?(p, path.basename.to_s) }
  end

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

  def self.handle_addition(new)
    with_status = new.dup
    with_status.instance_variable_set(:@status, :added)
    with_status
  end

  def self.handle_removal(old)
    with_status = old.dup
    with_status.instance_variable_set(:@status, :removed)
    with_status
  end

  def self.handle_modification(old, new)
    if old.type == :folder && new.type == :folder
      compare_folders(old, new, :modified)
    else
      with_status = new.dup
      with_status.instance_variable_set(:@status, :modified)
      with_status
    end
  end

  def self.compare_folders(old, new, status)
    combined_children = merge_children(old.children, new.children)
    with_status = new.dup
    merged = combined_children.map { |o, n| compare(o, n) }

    folder_status = merged.any? { |child| child.status == :modified } ? :modified : status

    with_status.instance_variable_set(:@children, merged)
    with_status.instance_variable_set(:@status, folder_status)
    with_status
  end

  def self.handle_unmodified(old, new)
    if old.type == :folder && new.type == :folder
      compare_folders(old, new, :unmodified)
    else
      with_status = new.dup
      with_status.instance_variable_set(:@status, :unmodified)
      with_status
    end
  end

  def self.merge_children(old_children, new_children)
    all_names = (old_children.map(&:name) + new_children.map(&:name)).uniq
    all_names.map do |name|
      old_child = old_children.find { |child| child.name == name }
      new_child = new_children.find { |child| child.name == name }
      [old_child, new_child]
    end
  end

  def self.traverse_tree(node, status_whitelist, current_path, &block)
    if node.type == :file && status_whitelist.include?(node.status)
      block.call(node, File.expand_path(current_path.to_s))
    end

    full_path = File.join(current_path.to_s, node.name.to_s)

    node.children.each do |child|
      traverse_tree(child, status_whitelist, full_path, &block)
    end
  end
end
