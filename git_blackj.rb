require 'io/console'

module Printable
  def prompt(message)
    puts "=> #{message}"
  end

  def display_welcome
    prompt('Welcome to Blackjack!')
  end

  def clear_screen
    press_key
    system 'clear'
  end

  def press_key
    prompt("Press any key to continue.")
    $stdin.getch
  end

  def display_rules
    puts("The rules are simple. The Player and the Dealer will be dealt two \n
    cards from a shuffled deck.. Only one of the cards from the Dealer's hand \n
    will be visible to the player at this time. The goal is for the Player's \n
    hand to reach a total of 21 in value without going over. If the Player's \n
    total goes above 21, the Player will bust and the Dealer wins. The player \n
    can choose to either 'Hit' (receive an additional card from the deck) or \n
    stay (end his turn) before reaching 21. The Dealer will then go through \n
    their turn, either choosing to hit or stay accordingly. At the end of the\n
    Dealer's turn, both the Player's and Dealer's hands will be revealed and \n
    the totals compared. The owner of the hand with the highest total will be \n
    the winner. If both hands are the same total, the result will be a tie and\n
    there will be no winner.")
  end

  def need_help?
    prompt("Do you need an explanation of the rules? (y/n)")
    answer = ''
    loop do
      answer = gets.chomp.downcase
      break if ['y', 'n'].include?(answer)
      prompt('Please enter either y or n.')
    end
    display_rules if answer == 'y'
    prompt('Have fun!!')
    clear_screen
  end

  def set_name
    n = ''
    loop do
      prompt('Please enter your name:')
      n = gets.chomp
      break unless n.empty?

      prompt('Name cannot be empty.')
    end
    n
  end

  def show_initial_hand(other_player)
    prompt("#{name} was dealt:")
    cards.each { |card| prompt(card.to_s) }
    prompt("#{other_player.name} was dealt:")
    prompt(other_player.cards.first.to_s)
    prompt("And an unknown card.")
    clear_screen
  end

  def show_full_hand
    prompt("#{name}'s hand is:")
    cards.each { |card| prompt(card.to_s) }
    prompt("#{name}'s total is:")
    prompt("#{total}.")
  end

  def hit_or_stay?(deck)
    answer = ''
    loop do
      show_full_hand
      prompt("Would you like to 1.) Hit, or 2.) Stay?")
      answer = gets.chomp.to_i
      case answer
      when 1
        cards << deck.deal_one
        prompt("A new card, #{cards.last}, was added to #{name}'s hand.")
        clear_screen
      when 2
        prompt("#{name}'s chosen to stay.")
        clear_screen
        break
      end
      break if busted?
    end
    return prompt("Seems like a bust. Too bad for #{name}...") if busted?
    prompt("#{name}'s turn has ended. It is the Dealer's turn.")
  end

  def show_winner(other_player, bet)
    if total > other_player.total && no_bust(other_player)
      win_bet(bet)
      prompt("#{name} wins!")
    elsif other_player.total > total && no_bust(other_player)
      lose_bet(bet)
      prompt("#{other_player.name} wins!")
    elsif total == other_player.total && no_bust(other_player)
      prompt("Both hands are the same value. It's a tie!")
    end
  end

  def show_busted?(other_player, bet)
    if busted?
      prompt("#{name} busted! #{other_player.name} wins!")
      lose_bet(bet)
    elsif other_player.busted?
      prompt("#{other_player.name} busted! #{name} wins!")
      win_bet(bet)
    end
  end

  def win_bet(bet)
    self.pot += bet
    prompt("Your pot is now: $#{pot}")
  end

  def lose_bet(bet)
    self.pot -= bet
    prompt("Your pot is now: $#{pot}")
  end

  def play_again?
    sleep(2)
    clear_screen
    prompt("Would you like to play another game? (y/n)")
    answer = ''
    loop do
      answer = gets.chomp.downcase
      break if ['y', 'n'].include?(answer)
      prompt("Invalid choice. Please answer y or n.")
    end
    if answer == 'y'
      clear_screen
      prompt("A new deck is being shuffled...")
      sleep(1)
      return true
    end
    false
  end

  def place_bet
    bet = ''
    loop do
      prompt("#{name}'s funds are: $#{pot}.")
      prompt("Please place your bet:")
      bet = gets.chomp.to_i
      break unless bet > pot || bet.zero?
      prompt("Invalid bet, please provide a valid amount.")
    end
    bet
  end

end

module Calculations
  def total
    total = 0
    cards.each do |card|
      total += card.face.to_i unless card.ace? || card.jack_queen_king?
      total += 11 if card.ace?
      total += 10 if card.jack_queen_king?
    end
    cards.select(&:ace?).count.times do
      total <= 21 ? break : total -= 10
    end
    total
  end

  def busted?
    total > Participant::MAX_TOTAL
  end

end

class Participant
  include Calculations
  include Printable
  attr_accessor :cards, :name, :pot

  MAX_TOTAL = 21
  MIN_TOTAL = 17
  INITIAL_FUNDS = 1_000

  def initialize
    @cards = Array.new
    @name = set_name
    @pot = INITIAL_FUNDS
  end

  def no_bust(other_player)
    !busted? && !other_player.busted?
  end

end

class Dealer < Participant
  def set_name
    'Dealer'
  end

  def hit_or_stay?(deck)
    loop do
      if total > MIN_TOTAL && !busted?
        prompt("#{name} stays!")
        break
      elsif busted?
        prompt("It's a bust for #{name}!")
        break
      else
        prompt("#{name} hits!")
        cards << deck.deal_one
      end
    end
  end
end

class Deck
  attr_accessor :deck

  def initialize
    @deck = []
    Card::SUIT_VALUE.each do |face|
      Card::FACE_VALUE.each do |suit|
        @deck << Card.new(face, suit)
      end
    end
    @deck.shuffle!
  end

  def deal_one
    deck.pop
  end
end

class Card
  attr_accessor :face, :suit

  FACE_VALUE = (2..10).to_a.map(&:to_s) + ['Jack', 'Queen', 'King', 'Ace']
  SUIT_VALUE = ['Hearts', 'Diamonds', 'Spades', 'Clubs']

  def initialize(suit, face)
    @face = face
    @suit = suit
  end

  def ace?
    face == 'Ace'
  end

  def jack_queen_king?
    face == 'Jack' || face == 'Queen' || face == 'King'
  end

  def to_s
    "The #{face} of #{suit}"
  end
end

class Blackjack
  include Printable
  include Calculations

  attr_accessor :deck, :dealer, :player

  def initialize
    @player = Participant.new
    @dealer = Dealer.new
    @deck = Deck.new
  end

  def starting_hand
    2.times do
      player.cards << deck.deal_one
      dealer.cards << deck.deal_one
    end
  end

  def reset_game
    @deck = Deck.new
    player.cards = Array.new
    dealer.cards = Array.new
  end

  def show_both_hands
    player.show_full_hand
    dealer.show_full_hand
  end

  def start
    display_welcome
    clear_screen
    need_help?
    loop do
      starting_hand
      bet = player.place_bet
      player.show_initial_hand(dealer)
      player.hit_or_stay?(deck)
      dealer.hit_or_stay?(deck) unless player.busted?
      show_both_hands
      player.show_busted?(dealer, bet) || player.show_winner(dealer, bet)
      play_again? ? reset_game : break
    end
    prompt("You walk away with $#{player.pot}.")
    prompt("Thank you for playing! Goodbye!")
  end
end

Blackjack.new.start
