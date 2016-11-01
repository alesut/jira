require 'spec_helper'
require 'scenarios'

describe Scenarios::CreateRelease do
  describe '#run' do
    it 'should create release from filter' do

      Scenarios::CreateRelease.new.run
    end
  end
end