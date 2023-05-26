# frozen_string_literal: true

require 'rspec'

require_relative '../builtin_patch'

RSpec.describe 'BuiltinPatch' do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  describe Hash do
    context '#invert_without_loss' do
      it 'called with `use_set` as default (i.e. `false`)' do
        h = { a: :x, b: :y, c: :x }
        act = h.invert_without_loss
        exp = { x: %i[a c], y: %i[b] }
        expect(act.keys).to match_array(exp.keys)
        act.each { |k, v| expect(v).to match_array(exp[k]) }
      end

      it 'called with `use_set` as `true`' do
        h = { a: :x, b: :y, c: :x }
        act = h.invert_without_loss(use_set: true)
        exp = { x: Set.new(%i[a c]), y: Set.new(%i[b]) }
        expect(act).to eql(exp)
      end
    end
  end

  # context 'when condition' do
  #   it 'succeeds' do
  #     pending 'Not implemented'
  #   end
  # end
end
