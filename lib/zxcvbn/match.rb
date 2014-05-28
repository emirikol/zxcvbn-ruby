require 'ostruct'

module Zxcvbn
  class Match < OpenStruct
    def to_hash
      hash = @table.dup
      hash.keys.map(&:to_s).sort.each do |key|
        hash[key] = hash.delete(key.intern)
      end
      hash
    end
  end
end