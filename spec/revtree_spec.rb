# spec/revtree_spec.rb
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

require 'rspec'
require_relative '../lib/revtree'

RSpec.describe RevTree do
  let(:old_tree_json) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "unmodified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file2.txt",
            "rev": "revfile2",
            "status": "unmodified",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  let(:new_tree_json_added) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "unmodified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file2.txt",
            "rev": "revfile2",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file3.txt",
            "rev": "revfile3new",
            "status": "unmodified",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  let(:new_tree_json_removed) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "unmodified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1",
            "status": "unmodified",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  let(:new_tree_json_modified) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "unmodified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1new",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file2.txt",
            "rev": "revfile2",
            "status": "unmodified",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  let(:new_tree_json_unmodified) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "unmodified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file2.txt",
            "rev": "revfile2",
            "status": "unmodified",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  let(:expected_tree_json_added) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "unmodified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file2.txt",
            "rev": "revfile2",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file3.txt",
            "rev": "revfile3new",
            "status": "added",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  let(:expected_tree_json_removed) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "unmodified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file2.txt",
            "rev": "revfile2",
            "status": "removed",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  let(:expected_tree_json_modified) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "modified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1new",
            "status": "modified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file2.txt",
            "rev": "revfile2",
            "status": "unmodified",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  let(:expected_tree_json_unmodified) do
    <<~JSON
      {
        "type": "folder",
        "name": "root",
        "rev": "abcd1234",
        "status": "unmodified",
        "children": [
          {
            "type": "file",
            "name": "file1.txt",
            "rev": "revfile1",
            "status": "unmodified",
            "children": [

            ]
          },
          {
            "type": "file",
            "name": "file2.txt",
            "rev": "revfile2",
            "status": "unmodified",
            "children": [

            ]
          }
        ]
      }
    JSON
  end

  def ck(new_tree_json, expected_tree_json)
    old_tree = RevTree.from_json(old_tree_json)
    new_tree = RevTree.from_json(new_tree_json)
    result_tree = RevTree.compare(old_tree, new_tree)
    result_json = result_tree.to_json
    expect(result_json).to eq(expected_tree_json.strip)
  end

  it 'marks added files correctly' do
    ck(new_tree_json_added, expected_tree_json_added)
  end

  it 'marks removed files correctly' do
    ck(new_tree_json_removed, expected_tree_json_removed)
  end

  it 'marks modified files correctly' do
    ck(new_tree_json_modified, expected_tree_json_modified)
  end

  it 'marks unmodified files correctly' do
    ck(new_tree_json_unmodified, expected_tree_json_unmodified)
  end
end
