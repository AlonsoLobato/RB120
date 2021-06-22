require 'pry'

module Printable
  def clear_screen
    system('clear') || system('cls')
  end

  def paused_message(msg)
    puts msg
    sleep(2)
  end

  def prompt(msg)
    puts "⥤ " + msg
  end

  def blank_space
    puts ""
  end

  def game_instructions
    paused_message("➥ Scissors cut paper")
    paused_message("➥ Paper covers rock")
    paused_message("➥ Rock crushes lizard")
    paused_message("➥ Lizard poisons Spock")
    paused_message("➥ Spock smashes scissors")
    paused_message("➥ Scissors decapitate lizard")
    paused_message("➥ Lizard eats paper")
    paused_message("➥ Paper disproves Spock")
    paused_message("➥ Spock vaporises rock")
    paused_message("➥ Rock crushes scissors")
  end

  def print_game_instructions
    clear_screen
    paused_message("Hello #{human.name}, we'll explain the rules to follow.")
    puts Banner.new("GAME RULES")
    game_instructions
    blank_space
    paused_message("All the opponents in this game are randomly generated " \
                  "and are based on characters from films and books.")
    paused_message("Try to guess their strengths and wicknesses by " \
                  "their mottos, so you have more chances to win.")
  end

  def print_opponent_info
    clear_screen
    paused_message("Your opponent for this game will be #{computer.name}.")
    paused_message("#{computer.name}'s motto is: " \
                  "\"#{computer.personality.motto}\"")
    paused_message("The first to win #{RPSGame::WINNING_SCORE} "\
                   "games will be the grand winner.")
  end

  def print_moves
    puts "#{human.name} chose #{human.move}."
    puts "#{computer.name} chose #{computer.move}."
  end

  def print_round_winner
    if human.move > computer.move
      puts "#{human.name} won the round!"
    elsif computer.move > human.move
      puts "#{computer.name} won the round!"
    else
      puts "It's a tie!"
    end
  end

  def print_score
    puts "#{human.name} score is: #{human.score}"
    puts "#{computer.name} score is: #{computer.score}"
  end

  def print_round_summary
    print_moves
    blank_space
    print_round_winner
    blank_space
    update_score
    print_score
  end

  def print_final_winner
    if human.score == RPSGame::WINNING_SCORE
      blank_space
      puts "Congratulations #{human.name}, you have won this game!"
    elsif computer.score == RPSGame::WINNING_SCORE
      blank_space
      puts "Sorry, #{computer.name} has won this game."
    end
    reset_score
  end

  def print_history
    clear_screen
    blank_space
    history.each_with_index do |game, game_idx|
      winner = game.last.split[0, 2].join(" ")
      puts "Game #{game_idx + 1}: #{winner} the game."
      game.each_with_index do |round, round_idx|
        puts " ➥ Round #{round_idx + 1}: #{round}"
      end
      puts
    end
  end

  def print_goodbye_message
    puts "Thanks for playing with us today."
    puts "Good bye #{human.name}!"
  end
end

module Continuable
  include Printable

  def press_return_to_continue?
    blank_space
    puts "                   /press return key to continue/"
    true if gets.chomp == ' '
  end
end

module Askable
  include Printable

  def ask_user_name
    name = ""
    loop do
      prompt("Please enter your name")
      name = gets.chomp.capitalize
      break unless name.empty?
      puts "Sorry, you must enter a valid name."
    end
    self.name = name
  end

  def ask_user_choice
    choice = nil
    loop do
      clear_screen
      prompt("Please choose (r)ock, (p)aper, (s)cissors, (l)izard or spoc(k):")
      choice = gets.chomp.downcase
      break if Move::VALID_CHOICES.include?(choice)
      paused_message("Sorry, that's an invalid choice, try again")
    end
    self.move = move_choice(choice)
  end

  def play_again?
    blank_space
    prompt("Do you want to play again? (y/n)")
    answer = nil
    loop do
      answer = gets.chomp.downcase
      break if ['yes', 'no', 'y', 'n'].include?(answer)
      puts "Sorry, I didn't catch that"
    end
    ['yes', 'y'].include?(answer) ? true : false
  end
end

class Banner
  include Printable

  def initialize(message)
    @message = message
    @width = message.size + 5
  end

  def to_s
    clear_screen
    [top_line, empty_line, message_line, empty_line, bottom_line].join("\n")
  end

  private

  def top_line
    "┌#{'─' * @width}┐"
  end

  def empty_line
    "│#{' ' * @width}│"
  end

  def message_line
    "│#{@message.center(@width)}│"
  end

  def bottom_line
    "└#{'─' * @width}┘"
  end
end

class Move
  VALID_CHOICES = %w(r p s l k)

  attr_accessor :value, :beats

  def >(other_move)
    beats.include?(other_move.value)
  end

  def to_s
    @value
  end
end

class Rock < Move
  def initialize
    @value = 'rock'
    @beats = ['scissors', 'lizard']
  end
end

class Paper < Move
  def initialize
    @value = 'paper'
    @beats = ['rock', 'spock']
  end
end

class Scisors < Move
  def initialize
    @value = 'scissors'
    @beats = ['paper', 'lizard']
  end
end

class Lizard < Move
  def initialize
    @value = 'lizard'
    @beats = ['paper', 'spock']
  end
end

class Spock < Move
  def initialize
    @value = 'spock'
    @beats = ['rock', 'scissors']
  end
end

class Player
  attr_accessor :move, :name, :score

  def initialize
    set_name
    @score = 0
  end

  def move_choice(choice)
    case choice
    when 'r' then Rock.new
    when 'p' then Paper.new
    when 's' then Scisors.new
    when 'l' then Lizard.new
    when 'k' then Spock.new
    end
  end

  def add_a_point
    @score += 1
  end

  def reset_score
    @score = 0
  end
end

class Human < Player
  include Printable, Askable

  def set_name
    ask_user_name
  end

  def choose
    ask_user_choice
  end
end

class Computer < Player
  attr_reader :personality

  def initialize
    @personality = [Edd.new, Airiam.new, MechanicalHound.new, Diana.new].sample
    super
  end

  def set_name
    self.name = personality.name
  end

  def choose
    self.move = move_choice(personality.values.sample)
  end
end

class Edd
  attr_reader :name, :values, :motto

  def initialize
    @name = "Edd"
    @values = Move::VALID_CHOICES + ([Move::VALID_CHOICES[2]] * 5)
    @motto = "An uncommonly gentle gothic man"
  end
end

class Airiam
  attr_reader :name, :values, :motto

  def initialize
    @name = "Airiam"
    @values = Move::VALID_CHOICES + ([Move::VALID_CHOICES[4]] * 5)
    @motto = "A Starfleet science officer who lived during the mid-23rd century"
  end
end

class MechanicalHound
  attr_reader :name, :values, :motto

  def initialize
    @name = "Mechanical Hound"
    @values = [Move::VALID_CHOICES[2]] + [Move::VALID_CHOICES[3]]
    @motto = "An eight-legged robotic hound in the search for fireman Montag"
  end
end

class Diana
  attr_reader :name, :values, :motto

  def initialize
    @name = "Diana"
    @values = Move::VALID_CHOICES + ([Move::VALID_CHOICES[3]] * 5)
    @motto = "Commander of the mothership Los Angeles"
  end
end

class RPSGame
  include Printable, Continuable, Askable

  WINNING_SCORE = 5

  attr_accessor :human, :computer, :history

  puts Banner.new('WELCOME TO THE ROCK PAPER SCISSORS LIZARD SPOCK GAME')

  def initialize
    @human = Human.new
    @computer = Computer.new
    @history = []
  end

  def player_choices
    human.choose
    computer.choose
  end

  def player_won?
    human.move > computer.move
  end

  def computer_won?
    computer.move > human.move
  end

  def update_score
    if player_won?
      human.add_a_point
    elsif computer_won?
      computer.add_a_point
    end
  end

  def reset_score
    human.reset_score
    computer.reset_score
  end

  def round_result
    if player_won?
      "#{human.name} won (#{human.move} vs #{computer.move})"
    elsif computer_won?
      "#{computer.name} won (#{computer.move} vs #{human.move})"
    else
      "It was a tie (both chose #{human.move})"
    end
  end

  def update_history
    history.last << round_result
  end

  def grand_winner?
    if human.score == WINNING_SCORE || computer.score == WINNING_SCORE
      true
    else
      false
    end
  end

  def round
    loop do
      @history << []
      until grand_winner?
        player_choices
        print_round_summary
        press_return_to_continue? unless grand_winner?
        update_history; end
      print_final_winner
      break unless play_again?
    end
  end

  def game
    print_opponent_info
    press_return_to_continue?
    round
    print_history
    print_goodbye_message
    blank_space
  end

  def play
    print_game_instructions
    press_return_to_continue?
    game
  end
end

RPSGame.new.play
