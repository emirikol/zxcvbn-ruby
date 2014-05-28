module Zxcvbn
  class Scorer
    include Entropy
    include CrackTime

    def minimum_entropy_match_sequence(password, matches)
      bruteforce_cardinality = bruteforce_cardinality(password) # e.g. 26 for lowercase
      up_to_k = []      # minimum entropy up to k.
      backpointers = [] # for the optimal sequence of matches up to k, holds the final match (match.j == k). null means the sequence ends w/ a brute-force character.
      (0...password.length).each do |k|
        # starting scenario to try and beat: adding a brute-force character to the minimum entropy sequence at k-1.
        previous_k_entropy = k == 0 ? 0 : up_to_k[k-1]
        up_to_k[k] = previous_k_entropy + lg(bruteforce_cardinality)
        backpointers[k] = nil
        matches.each do |match|
          next unless match.j == k
          i, j = match.i, match.j
          # see if best entropy up to i-1 + entropy of this match is less than the current minimum at j.
          previous_i_entropy = i > 0 ? up_to_k[i-1] : 0
          candidate_entropy = previous_i_entropy + calc_entropy(match)
          if up_to_k[j] && candidate_entropy < up_to_k[j]
            up_to_k[j] = candidate_entropy
            backpointers[j] = match
          end
        end
      end
      # walk backwards and decode the best sequence
      match_sequence = []
      k = password.length - 1
      while k >= 0
        match = backpointers[k]
        if match
          match_sequence.push match
          k = match.i - 1
        else
          k -= 1
        end
      end
      match_sequence.reverse!

      # fill in the blanks between pattern matches with bruteforce "matches"
      # that way the match sequence fully covers the password: match1.j == match2.i - 1 for every adjacent match1, match2.
      make_bruteforce_match = lambda do |i, j|
        Match.new(
          :pattern => 'bruteforce',
          :i => i,
          :j => j,
          :token => password[i..j],
          :entropy => lg(bruteforce_cardinality ** (j - i + 1)),
          :cardinality => bruteforce_cardinality
        )
      end

      k = 0
      match_sequence_copy = []
      match_sequence.each do |match|
        i, j = match.i, match.j
        if i - k > 0
          debugger if i == 0
          match_sequence_copy << make_bruteforce_match.call(k, i - 1)
        end
        k = j + 1
        match_sequence_copy.push match
      end
      if k < password.length
        match_sequence_copy.push make_bruteforce_match.call(k, password.length - 1)
      end
      match_sequence = match_sequence_copy

      min_entropy = up_to_k[password.length - 1] || 0  # or 0 corner case is for an empty password ''
      crack_time = entropy_to_crack_time(min_entropy)

      # final result object
      Score.new(
        :password => password,
        :entropy => round(min_entropy,3),
        :match_sequence => match_sequence,
        :crack_time => round(crack_time,3),
        :crack_time_display => display_time(crack_time),
        :score => crack_time_to_score(crack_time)
      )
    end

    private
    def round(num, digits)
      if RUBY_VERSION.to_f < 1.9
        (num * 10**digits).round.to_f / 10**digits
      else
        num.round(digits)
      end
    end
  end
end