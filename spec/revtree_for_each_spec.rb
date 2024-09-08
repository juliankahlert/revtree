# spec/revtree_for_each_spec.rb
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

require 'spec_helper'
require 'revtree'

RSpec.describe RevTree do
  let(:file_structure) do
    {
      type: :folder,
      name: 'root',
      rev: 'rootrev',
      status: :modified,
      children: [
        {
          type: :file,
          name: 'file1.rb',
          rev: 'file1rev',
          status: :added,
          children: [],
        },
        {
          type: :file,
          name: 'file2.md',
          rev: 'file2rev',
          status: :removed,
          children: [],
        },
        {
          type: :folder,
          name: 'subfolder',
          rev: 'subfolderrev',
          status: :unmodified,
          children: [
            {
              type: :file,
              name: 'file3.rb',
              rev: 'file3rev',
              status: :unmodified,
              children: [],
            },
          ],
        },
      ],
    }
  end

  let(:revtree) { RevTree.from_h(file_structure) }

  describe '#for_each' do
    it 'calls the block for files with statuses in the whitelist' do
      statuses = [:added, :removed]
      results = []
      revtree.for_each(statuses) do |file, _full_path|
        results << { name: file.name, status: file.status }
      end

      expect(results).to contain_exactly(
        { name: 'file1.rb', status: :added },
        { name: 'file2.md', status: :removed }
      )
    end

    it 'does not call the block for files with statuses not in the whitelist' do
      statuses = [:added]
      results = []

      revtree.for_each(statuses) do |file, _full_path|
        results << { name: file.name, status: file.status }
      end

      expect(results).to contain_exactly(
        { name: 'file1.rb', status: :added }
      )
    end

    it 'handles an empty status whitelist' do
      statuses = []
      results = []

      revtree.for_each(statuses) do |file, _full_path|
        results << { name: file.name, status: file.status }
      end

      expect(results).to be_empty
    end
  end
end
