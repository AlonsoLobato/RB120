module Terminal
  def clear
    system 'clear'
  end

  def paused_message(msg)
    puts msg
    sleep(2)
  end

  def blank_space
    puts ""
  end

  def prompt(msg)
    puts "⥤ " + msg
  end
end

class Banner
  include Terminal

  def initialize(message)
    @message = message
    @width = message.size + 5
  end

  def to_s
    clear
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

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]

  def initialize
    @squares = {}
    reset
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----|-----|-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----|-----|-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_squares
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_squares.empty?
  end

  def center_available?
    @squares[5].unmarked?
  end

  def square_threatened_by(marker)
    WINNING_LINES.each do |line|
      markers_in_line = @squares.values_at(*line).map(&:marker)
      if markers_in_line.count(Square::INITIAL_MARKER) == 1 && \
         markers_in_line.count(marker) == 2
        line.each do |square|
          return square if @squares[square].unmarked?
        end
      end
    end
    nil
  end

  def square_threatened_by?(marker)
    !!square_threatened_by(marker)
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def someone_won?
    !!winning_marker
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != 3
    markers.uniq.size == 1
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_reader :score
  attr_accessor :name, :marker

  def initialize
    @score = 0
    # player_name
  end

  def update_score
    @score += 1
  end

  def reset_score
    @score = 0
  end
end

class Human < Player
  include Terminal

  def initialize
    super
    player_name
    player_marker
  end

  def ask_user_name
    name = ""
    loop do
      prompt("Please enter your name.")
      name = gets.chomp.strip.capitalize
      break unless name.empty?
      puts "Sorry, you must enter a valid name."
    end
    self.name = name
  end

  def player_name
    ask_user_name
  end

  def ask_user_marker
    marker = ""
    loop do
      prompt("Please enter a marker of your choice.")
      marker = gets.chomp.capitalize
      break unless marker.empty? || marker.size > 1
      puts "Sorry, you must enter a single character as a marker"
    end
    self.marker = marker
  end

  def player_marker
    ask_user_marker
  end
end

class Computer < Player
  def initialize(other_marker, other_name)
    super()
    player_name(other_name)
    player_marker(other_marker)
  end

  def player_name(other_name)
    self.name = if other_name == 'Computer'
                  'Machine'
                else
                  'Computer'
                end
  end

  def player_marker(other_marker)
    self.marker = if other_marker == 'O'
                    'X'
                  else
                    'O'
                  end
  end
end

class TTTGame
  include Terminal

  POINTS_TO_WIN = 3
  VALID_TURNS = { 1 => 'Me', 2 => 'My opponent', 3 => "I don't mind" }

  attr_reader :board, :human, :computer

  puts Banner.new('WELCOME TO TIC TAC TOE GAME')

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new(human.marker, human.name)
    # @current_marker
  end

  def play
    clear
    display_welcome_message
    loop do
      main_game
      break unless play_again?
      reset
    end
    display_goodbye_message
  end

  private

  def main_game
    until final_winner?
      first_to_play
      round
      update_general_score
      display_winning_info
      reset
    end
    display_final_winner
    reset_scores
  end

  def round
    loop do
      clear_screen_and_display_board
      both_players_moves
      break if round_winner? || board.full?
    end
  end

  def both_players_moves
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def display_winning_info
    paused_message(display_round_winner)
    paused_message(display_general_score)
  end

  def display_welcome_message
    puts "Welcome #{human.name}."
    blank_space
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe. Goodbye!"
  end

  def display_board
    puts "Your marker is: #{human.marker}    #{computer.name}'s " \
         "marker is: #{computer.marker}"
    blank_space
    board.draw
    blank_space
  end

  def display_round_winner
    clear_screen_and_display_board

    if human_won?
      puts "Congratulations! You won this round"
    elsif computer_won?
      puts "Sorry, #{computer.name} won this round"
    else
      puts "This round is a tie!"
    end
  end

  def display_empty_squares
    joinor(board.unmarked_squares)
  end

  def display_general_score
    puts "Your score is: #{human.score}"
    puts "#{computer.name}'s score is: #{computer.score}"
  end

  def display_final_winner
    if human.score == POINTS_TO_WIN
      puts "Well done #{human.name}! You've won #{POINTS_TO_WIN} rounds, " \
           "so you are the game winner"
    elsif computer.score == POINTS_TO_WIN
      puts "#{computer.name} has won #{POINTS_TO_WIN} rounds, " \
           "so you've lost this game. Good luck next time!"
    end
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def ask_user_for_turns
    answer = nil
    prompt("Who do you want to play first?")
    loop do
      VALID_TURNS.each { |k, v| puts "#{k}. #{v}    " }
      answer = gets.chomp
      answer = answer.to_i if answer.to_i.to_s == answer
      break if VALID_TURNS.key?(answer)
      puts "Sorry, that's not a valid option"
    end
    answer == 3 ? VALID_TURNS.values[0..1].sample : VALID_TURNS[answer]
  end

  def first_to_play
    @current_marker = if ask_user_for_turns == VALID_TURNS[1]
                        human.marker
                      else
                        computer.marker
                      end
  end

  def human_turn?
    @current_marker == human.marker
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = computer.marker
    else
      computer_moves
      @current_marker = human.marker
    end
  end

  def joinor(squares)
    if squares.size > 2
      squares[0...-1].join(', ').to_s + " or " + squares.last.to_s
    elsif squares.size == 2
      squares.join(' or ').to_s
    else
      squares.join('').to_s
    end
  end

  def human_moves
    prompt("It's your turn, please choose a square: " \
         "#{display_empty_squares}")
    square = nil
    loop do
      square = gets.chomp
      square = square.to_i if square.to_i.to_s == square
      break if board.unmarked_squares.include?(square)
      puts "Invalid choice, please try again"
    end

    board[square] = human.marker
  end

  def computer_moves
    computer_moves = computer.marker
    if find_computer_best_move == :attack_move
      mark_strategic_square(computer.marker, computer_moves)
    elsif find_computer_best_move == :defense_move
      mark_strategic_square(human.marker, computer_moves)
    elsif board.center_available?
      mark_center_square(computer_moves)
    else
      mark_random_square(computer_moves)
    end
  end

  def find_computer_best_move
    if board.square_threatened_by?(computer.marker)
      :attack_move
    elsif board.square_threatened_by?(human.marker)
      :defense_move
    end
  end

  def mark_strategic_square(input_marker, marker)
    board[board.square_threatened_by(input_marker)] = marker
  end

  def mark_center_square(marker)
    board[5] = marker
  end

  def mark_random_square(marker)
    board[board.unmarked_squares.sample] = marker
  end

  def human_won?
    board.winning_marker == human.marker
  end

  def computer_won?
    board.winning_marker == computer.marker
  end

  def round_winner?
    human_won? || computer_won?
  end

  def update_general_score
    if human_won?
      human.update_score
    elsif computer_won?
      computer.update_score
    end
  end

  def reset_scores
    human.reset_score
    computer.reset_score
  end

  def final_winner?
    human.score == POINTS_TO_WIN || computer.score == POINTS_TO_WIN
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

  def reset
    board.reset
    clear
  end
end

game = TTTGame.new
game.play
