require 'spec_helper'

describe Zxcvbn::Matchers::Spatial do
  let(:matcher) { Zxcvbn::Matchers::Spatial.new(graphs) }
  let(:graphs)  { Zxcvbn::ADJACENCY_GRAPHS }

  describe '#matches' do

    it 'finds the correct of matches' do
      matches = matcher.matches('rtyikm') #using let here causes sort not to work. and without sorting the order of matches is random
      matches.count.should eq 3
      matches = matches.sort_by {|m| m.token}
      matches[0].token.should eq 'ikm'
      matches[0].graph.should eq 'qwerty'
      matches[1].token.should eq 'rty'
      matches[1].graph.should eq 'qwerty'
      matches[2].token.should eq 'yik'
      matches[2].graph.should eq 'dvorak'
    end
  end
end