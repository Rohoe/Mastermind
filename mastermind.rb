module Mastermind
	class Color
		COLORS = [:red, :green, :blue, :white, :black, :yellow]

		def Color.from_string(str)
			to_return = COLORS.select {|c| c.to_s == str.downcase}
			if to_return.empty?
				puts "Invalid color!"
				raise ArgumentError
			else
				return to_return.first
			end
		end
	end

	class Peg
		attr_reader :color
		def initialize(color)
			@color=color
		end

		#returns new peg with random color
		def Peg.random(colors)
			return Peg.new(colors.sample)
		end
	end

	#Type can be human or AI
	class Player
		attr_accessor :name, :type, :score
		def initialize(name,type = :human)
			@name = name
			@type = type
			@score = 0
		end

		def is_AI?
			@type == :AI
		end
	end

	class AI < Player
		attr_accessor :name, :type, :score, :best_guess, :must_include
		def initialize(name, type = :AI)
			@name = name
			@type = type
			@score = 0
			@must_include=[]
			@best_guess = Array.new(4)
		end

		def flush_memory
			@must_include = []
			@best_guess = Array.new(4)
		end
	end


	#Contains code, attempts, and feedback
	class Board
		attr_accessor :code, :attempts, :responses, :guesses

		def initialize
			@code = []
			@attempts = []
			@responses = []
			@guesses = 1
		end

		def pick_colors
			begin
				colors = gets.chomp.downcase.split.map {|c| Color.from_string(c)}
				if !(colors.length == Game::CODE_LENGTH)
					puts "Wrong length!"
					pick_colors
				else
					colors
				end
			rescue
				puts "Invalid input!"
				pick_colors
			end
		end

		def make_code(player)
			attempt = []
			if player.is_AI?
				puts "#AI is thinking..."
				#Implement smarter guessing"
				attempt = player.best_guess.map {|peg|
					if peg.nil?
						unless player.must_include.empty?
							peg = Peg.new(player.must_include.shuffle!.pop)
						else
							peg = Peg.random(Color::COLORS)
						end
					else
						peg
					end
				}
				# Game::CODE_LENGTH.times do
				# 	attempt << Peg.random(Color::COLORS)
				# end
				# attempt = [Peg.new(:white), Peg.new(:white), Peg.new(:black), Peg.new(:black)]
				$stdout.flush
				sleep(1)
			else
				puts "Pick #{Game::CODE_LENGTH} colors!"
				puts "Colors: " + Color::COLORS.join(" ")
				colors = pick_colors
				colors.each {|c|
					attempt << Peg.new(c)
				}
			end
			return attempt
		end

		def make_attempt(player)
			code = make_code(player)
			attempts << code
			puts "Guess #{@guesses} of #{Game::GUESSES_ALLOWED}"
			@guesses += 1
			Game.print_pegs(code)
			puts "Response:"
			feedback = provide_feedback(code)
			#update best_guess if player is AI
			if player.is_AI?
				feedback.each_with_index {|peg, i|
					if peg.nil?
						next
					elsif peg.color == :white
						player.must_include << code[i].color
					elsif peg.color == :black
						player.best_guess[i] = Peg.new(code[i].color)
					end
				}
			end
			Game.print_pegs(feedback)
		end

		def exact_matches(code,attempt,color)
			matches = 0
			attempt.each_with_index {|peg, i|
				if color == peg.color && peg.color == code[i].color
					matches += 1
				end
			}
			return matches
		end

		#If there are duplicate colours in the guess, they cannot all be awarded a key peg unless they correspond
		#to the same number of duplicate colours in the hidden code. For example, if the hidden code is
		#white-white-black-black and the player guesses white-white-white-black, the codemaker will award two colored
		#key pegs for the two correct whites, nothing for the third white as there is not a third white in the code,
		#and a colored key peg for the black. No indication is given of the fact that the code also includes a second
		#black
		def provide_feedback(attempt)
			feedback = []
			attempt.each_with_index {|peg,i|
				if peg.color == @code[i].color
					feedback << Peg.new(:black)
				elsif @code.any? {|c_peg| c_peg.color == peg.color}
					num_c_pegs = @code.map{|c| c = c.color}.count(peg.color)
					matches = exact_matches(@code,attempt,peg.color)
					if num_c_pegs > matches
						feedback << Peg.new(:white)
					else
						feedback << nil
					end
				else
					feedback << nil
				end
			}
			@responses << feedback
			return feedback
		end

		def codes_equal(c1,c2)
			equal = true
			c1.each_with_index {|peg1, i|
				equal = equal && (peg1.color == c2[i].color)
			}
			return equal
		end

		def breaker_victory?
			@attempts.any? {|att| codes_equal(att,@code)}
		end

		def maker_victory?
			@guesses > Game::GUESSES_ALLOWED
		end

	end

	#Checks for victory, manages player turns
	class Game
		attr_accessor :board, :human, :ai, :code_breaker, :code_maker, :rounds
		CODE_LENGTH = 4
		GUESSES_ALLOWED = 12

		def initialize
			@board = Board.new()
			@ai = AI.new("Mastermind")
			main
		end

		def Game.print_pegs(pegs)
			pegs.each {|peg| if peg.nil?
								print "*MISS* "
							 else
							 	print "(#{peg.color}) "
							 end
					  }
			puts
		end

		def breaker_or_maker
			puts "Code breaker or maker? B or M"
			initial = gets.chomp.downcase
			if initial == "b"
				@code_breaker = @human
				@code_maker = @ai
			elsif initial == "m"
				@code_breaker = @ai
				@code_maker = @human
			else
				puts "Invalid input."
				breaker_or_maker
			end
		end

		def set_rounds
			puts "How many rounds?"
			input = gets.to_i
			if input == 0
				puts "Invalid input."
				set_rounds
			else
				@rounds = input
			end
		end

		def set_human
			puts "Welcome to Mastermind! What is your name?"
			name = gets.chomp
			@human = Player.new(name)
		end

		def game_victory?
			if @human.score > @rounds/2
				puts "Game over!"
				puts "#{@human.name} wins! #{@human.score}/#{@rounds} rounds"
				return true
			elsif @ai.score > @rounds/2
				puts "Game over!"
				puts "#{@ai.name} wins! #{@ai.score}/#{@rounds} rounds"
				return true
			elsif @human.score + @ai.score == rounds
				puts "Game over!"
				puts "Draw!"
				return true
			else
				return false
			end
		end

		def swap_players
			t = @code_maker
			@code_maker = @code_breaker
			@code_breaker = t
		end

		def print_score
			puts "Rounds: #{@rounds}"
			puts "#{@human.name}'s score: #{@human.score}"
			puts "#{@ai.name}'s score: #{@ai.score}"
		end

		def main
			set_human
			breaker_or_maker
			set_rounds
			running = true
			while running
				if game_victory?
					break
				else
					round_victory = false
					@board = Board.new()
					puts "Make a secret code!"
					@board.code = @board.make_code(@code_maker)
					while !round_victory
						if @board.breaker_victory?
							puts "Code breaker wins!"
							@code_breaker.score += 1
							print_score
							round_victory = true
							swap_players
						elsif @board.maker_victory?
							puts "Code maker wins!"
							@code_maker.score += 1
							print_score
							round_victory = true
							swap_players
						else
							puts "Make an attempt!"
							@board.make_attempt(code_breaker)
						end
					end
				end
			end
		end

	end

end