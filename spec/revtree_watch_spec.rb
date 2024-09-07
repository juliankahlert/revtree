# spec/revtree_watch_spec.rb

# spec/revtree_spec.rb

require 'revtree'
require 'rspec'

RSpec.describe RevTree do
  let(:path) { './spec/.test_dir' }
  let(:whitelist) { ['*.rb'] }
  let(:tree) { RevTree.new(path, whitelist) }
  let(:interval) { 0 }

  before do
    File.delete(File.join(path, 'test.rb')) if File.exist?(File.join(path, 'test.rb'))
    Dir.rmdir(path) if Dir.exist?(path) && Dir.empty?(path)
    Dir.mkdir(path) unless Dir.exist?(path)
  end

  after do
    File.delete(File.join(path, 'test.rb')) if File.exist?(File.join(path, 'test.rb'))
    Dir.rmdir(path) if Dir.empty?(path)
  end

  describe '#watch' do
    it 'calls the block with the correct parameters when a file is modified' do
      initial_tree = RevTree.new(path, whitelist)

      dummy_file = File.join(path, 'test.rb')
      File.write(dummy_file, 'puts "Hello"')

      allow_any_instance_of(RevTree).to receive(:loop).and_yield

      block_called = false

      initial_tree.with_interval(interval).watch([:added]) do |file, full_path|
        block_called = true
        expect(file.name).to eq('test.rb')
        expect(full_path).to eq(File.expand_path(path))
      end

      expect(block_called).to be true
    end
  end
end
