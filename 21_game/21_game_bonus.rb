module Terminal
  def clear_screen
    system 'clear'
  end

  def blank_space
    puts ""
  end

  def prompt(msg)
    puts "⥤ " + msg
  end

  def display_info(msg)
    blank_space
    puts "  ➥ " + msg
  end

  def press_return_to_continue?
    blank_space
    puts "                                    /press return key to continue/"
    true if gets.chomp == ' '
  end
end

module Instructions
  include Terminal

  def want_instructions?
    answer = nil
    valid_answers = ['yes', 'y', 'no', 'n']
    loop do
      prompt "Do you want to read the instructions before you play (y/n)?"
      answer = gets.chomp.downcase
      break if valid_answers.include?(answer)
      prompt "Sorry, I didn't catch that..."
    end
    ['yes', 'y'].include?(answer) ? true : false
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Layout/LineLength, Layout/TrailingWhitespace
  def display_instructions
    clear_screen
    puts "GAME RULES"
    puts "──────────"
    prompt "We'll play with a normal 52-card deck"
    blank_space
    prompt "The goal is to try to get as close to #{Hand::OPTIMAL_POINTS} points as possible, without going over"
    blank_space
    prompt "If you go over #{Hand::OPTIMAL_POINTS}, it's a 'bust' and you lose the game"
    press_return_to_continue?
    clear_screen

    puts "GAME RULES (continue...)"
    puts "────────────────────────"
    prompt "There are two players that are initially dealt 2 cards"
    blank_space
    prompt "You can see your two cards, but only one of your opponent's cards"
    press_return_to_continue?
    clear_screen

    puts "GAME RULES (continue...)"
    puts "────────────────────────"
    prompt "The card values are:"
    blank_space
    puts " --> The numbers '2' through '10' are worth their face value"
    blank_space
    puts " --> 'J', 'Q' and 'K' are worth 10 points each"
    blank_space
    puts " --> 'A' can be worth 1 or 11, depending on the sum of the other cards"
    puts "     (if that sum is > 21, 'A' will be worth 1; otherwise it'll be worth 11)"
    press_return_to_continue?
    clear_screen
    
    puts "GAME RULES (continue...)"
    puts "────────────────────────"
    prompt "Once you've seen your cards, you can ask for as many additional cards as you want by typing 'Hit'"
    blank_space
    prompt "Remember you want to get as close to #{Hand::OPTIMAL_POINTS} points as possible but without busting!"
    blank_space
    prompt "Once you are happy with the cards you have in hand, enter 'Stay'"
    blank_space
    prompt "Then is the computer's turn, who will play its hand as best as its AI allows it"
    press_return_to_continue?
    clear_screen

    puts "GAME RULES (continue...)"
    puts "────────────────────────"
    prompt "After both you and the computer have played, the cards are compared"
    blank_space
    prompt "Whoever got closest to #{Hand::OPTIMAL_POINTS} without busting wins the game"
    press_return_to_continue?
    clear_screen

    puts "GAME RULES (continue...)"
    puts "────────────────────────"
    prompt "Don't worry if you didn't get it all; we know this may be a bit overwhelming"
    blank_space
    prompt "It's easier if you play a few rounds"
    blank_space
    prompt "Ready? Let's play some rounds!"
    press_return_to_continue?
    clear_screen
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Layout/LineLength, Layout/TrailingWhitespace
end

class Banner
  include Terminal

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

class Card
  CARDS = [[*('2'..'10'), 'J', 'Q', 'K', 'A'], ['♣', '♦', '♥', '♠']]

  attr_accessor :number, :suit

  def initialize(number, suit)
    @number = number
    @suit = suit
  end
end

class Deck
  attr_accessor :cards

  def initialize
    @cards = []
    initialize_deck
  end

  def initialize_deck
    Card::CARDS[0].each do |number|
      Card::CARDS[1].each do |suit|
        @cards << Card.new(number, suit)
      end
    end

    @cards.shuffle!
  end

  def deal_cards
    cards.pop
  end
end

module Hand
  OPTIMAL_POINTS = 21

  def cards_corrected_value
    corrected_sum = cards_total_value
    cards.select { |card| card.number == "A" }.count.times do
      corrected_sum -= 10 if corrected_sum > OPTIMAL_POINTS
    end
    corrected_sum
  end

  def busted?
    cards_corrected_value > OPTIMAL_POINTS
  end

  def add_card(new_card)
    cards << new_card
  end

  def display_num_and_suit(hand)
    cards_in_hand = []
    hand.each do |card|
      cards_in_hand << card.number + card.suit
    end
    cards_in_hand[0...-1].join(', ') + ' and ' + cards_in_hand.last
  end

  private

  # rubocop:disable Metrics/MethodLength
  def cards_total_value
    card_values = cards.map(&:number)
    sum_of_values = 0
    card_values.each do |number|
      sum_of_values += if number == 'A'
                         11
                       elsif ['1', 'J', 'Q', 'K'].include?(number)
                         10
                       else
                         number.to_i
                       end
    end
    sum_of_values
  end
  # rubocop:enable Metrics/MethodLength
end

class Player
  include Hand, Terminal

  attr_accessor :name, :cards

  def initialize
    @cards = []
  end

  # rubocop:disable Layout/LineLength
  def display_busted_msg(other_name)
    blank_space
    puts Banner.new("#{name.upcase} BUSTED — #{other_name.name.upcase} WINS THIS ROUND")
  end
  # rubocop:enable Layout/LineLength
end

class User < Player
  def initialize
    super
    user_name
  end

  private

  def ask_user_name
    name = ""
    loop do
      blank_space
      prompt "Please enter your name."
      name = gets.chomp.strip.capitalize
      break unless name.empty?
      puts "Sorry, you must enter a valid name."
    end
    self.name = name
  end

  def user_name
    ask_user_name
  end

  public

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def display_cards
    fcs = cards[0].suit                 # fcs stands for 1st card suit
    scs = cards[1].suit                 # scs stands for 2n card suit
    fcv = cards[0].number.center(8)     # fcv stands for 1st card number
    scv = cards[1].number.center(8)     # scv stands for 2nd card number

    display_info "These are the cards in your initial hand:"
    puts " ┌────────────┐ ┌────────────┐"
    puts " │ #{fcs}        #{fcs} │ │ #{scs}        #{scs} │"
    puts " │ ┌────────┐ │ │ ┌────────┐ │"
    puts " │ │        │ │ │ │        │ │"
    puts " │ │        │ │ │ │        │ │"
    puts " │ │#{fcv}│ │ │ │#{scv}│ │"
    puts " │ │        │ │ │ │        │ │"
    puts " │ │        │ │ │ │        │ │"
    puts " │ └────────┘ │ │ └────────┘ │"
    puts " │ #{fcs}        #{fcs} │ │ #{scs}        #{scs} │"
    puts " └────────────┘ └────────────┘"
    puts "     (#{cards_corrected_value} points in total)"
    blank_space
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def display_extra_card
    cs = cards.last.suit                 # fcs stands for card suit
    cv = cards.last.number.center(8)     # fcv stands for card number

    clear_screen
    display_info "This is your new card:"
    puts " ┌────────────┐"
    puts " │ #{cs}        #{cs} │ "
    puts " │ ┌────────┐ │"
    puts " │ │        │ │"
    puts " │ │        │ │"
    puts " │ │#{cv}│ │ "
    puts " │ │        │ │"
    puts " │ │        │ │"
    puts " │ └────────┘ │"
    puts " │ #{cs}        #{cs} │ "
    puts " └────────────┘"
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def stay?
    answer = nil
    valid_answers = ['hit', 'stay', 'h', 's']
    loop do
      blank_space
      prompt "Please enter '(H)it' if you want another " \
             "card or '(S)tay' if you don't"
      answer = gets.chomp.downcase
      break if valid_answers.include?(answer)
      puts "Sorry, that's not a valid answer"
    end

    ['stay', 's'].include?(answer)
  end
  # rubocop:enable Metrics/MethodLength
end

class Dealer < Player
  DEALER_MAX_RISK = 17

  def initialize(other_name)
    super()
    dealer_name(other_name)
  end

  private

  def dealer_name(other_name)
    self.name = if other_name == 'Dealer'
                  'Boss'
                else
                  'Dealer'
                end
  end

  public

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def display_cards
    cs = cards[0].suit                 # fcs stands for card suit
    cv = cards[0].number.center(8)     # fcv stands for card number

    display_info "And this is the one card you can see " \
                 "of #{name}'s initial hand:"
    puts " ┌────────────┐ ┌────────────┐"
    puts " │ #{cs}        #{cs} │ │            │"
    puts " │ ┌────────┐ │ │   ╔═══╗    │"
    puts " │ │        │ │ │   ║╔═╗║    │"
    puts " │ │        │ │ │   ╚╝╔╝║    │"
    puts " │ │#{cv}│ │ │     ║╔╝    │"
    puts " │ │        │ │ │     ╔╗     │"
    puts " │ │        │ │ │     ╚╝     │"
    puts " │ └────────┘ │ │            │"
    puts " │ #{cs}        #{cs} │ │            │"
    puts " └────────────┘ └────────────┘"
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def stay?
    cards_corrected_value >= DEALER_MAX_RISK
  end
end

class Game
  include Terminal, Instructions

  attr_accessor :deck, :user, :dealer

  puts Banner.new("WELCOME TO TWENTY-ONE GAME")

  def initialize
    @deck = Deck.new
    @user = User.new
    @dealer = Dealer.new(user.name)
  end

  def play
    clear_screen
    display_welcome_message
    display_instructions if want_instructions?
    loop do
      game
      break unless play_again?
      reset
      display_play_again_message
    end
    display_goodbye_message
  end

  private

  def display_welcome_message
    puts "Welcome #{user.name}."
    blank_space
  end

  def game
    deal_initial_cards
    show_initial_cards
    turns
    show_result
  end

  def deal_initial_cards
    2.times do
      user.add_card(deck.deal_cards)
      dealer.add_card(deck.deal_cards)
    end
  end

  def show_initial_cards
    user.display_cards
    dealer.display_cards
  end

  def turns
    user_turn
    if user.busted?
      user.display_busted_msg(dealer)
    else
      dealer_turn
    end
    dealer.display_busted_msg(user) if dealer.busted?
  end

  def user_turn
    loop do
      break if user.busted? || user.stay?
      user.add_card(deck.deal_cards)
      user.display_extra_card
      display_current_hand
    end
  end

  def dealer_turn
    loop do
      break if dealer.busted? || dealer.stay?
      dealer.add_card(deck.deal_cards)
    end
  end

  def display_current_hand
    display_info "Your current cards are: " \
                 "#{user.display_num_and_suit(user.cards)}, " \
                 "which sum up #{user.cards_corrected_value} points"
  end

  def detect_round_winner
    user_points = user.cards_corrected_value
    dealer_points = dealer.cards_corrected_value

    return unless !user.busted? && !dealer.busted?
    if user_points > dealer_points
      :user
    elsif dealer_points > user_points
      :dealer
    else
      :tie
    end
  end

  def display_round_winner
    if detect_round_winner == :user
      puts Banner.new("#{user.name.upcase} WON THIS ROUND!")
    elsif detect_round_winner == :dealer
      puts Banner.new("#{dealer.name.upcase} WON THIS ROUND!")
    elsif detect_round_winner == :tie
      puts Banner.new("IT'S A TIE!")
    end
  end

  def display_round_summary
    display_info "#{user.name}'s cards in this round were " \
                 "#{user.display_num_and_suit(user.cards)} " \
                 "(#{user.cards_corrected_value} points)"
    display_info "#{dealer.name}'s cards in this round were " \
                 "#{dealer.display_num_and_suit(dealer.cards)} " \
                 "(#{dealer.cards_corrected_value} points)"
  end

  def show_result
    display_round_winner
    display_round_summary
  end

  def play_again?
    blank_space
    prompt "Do you want to play again? (y/n)"
    answer = nil
    loop do
      answer = gets.chomp.downcase
      break if ['yes', 'no', 'y', 'n'].include?(answer)
      puts "Sorry, I didn't catch that"
    end
    ['yes', 'y'].include?(answer) ? true : false
  end

  def display_play_again_message
    puts "Let's play again!"
  end

  def reset
    clear_screen
    self.deck = Deck.new
    user.cards = []
    dealer.cards = []
  end

  def display_goodbye_message
    blank_space
    puts "Thanks for playing Twenty-One #{user.name}. Goodbye!"
    blank_space
  end
end

Game.new.play
