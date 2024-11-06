#!/bin/bash

# Connect to PostgreSQL and number_guess database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number between 1 and 1000
TARGET=$((RANDOM % 1000 + 1))

# Prompt the user for their username
echo "Enter your username:"
read USERNAME

# Ensure the username is 22 characters or less
if [[ ${#USERNAME} -gt 22 ]]; then
  echo "Username must be 22 characters or less."
  exit 1
fi

# Check if the user exists in the database and retrieve game stats if they do
USER_INFO=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
if [[ -z $USER_INFO ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Retrieve the total number of games played and the best game score
  USER_ID=$USER_INFO
  GAME_STATS=$($PSQL "SELECT COUNT(game_id), MIN(guesses) FROM games WHERE user_id=$USER_ID")
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$GAME_STATS"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
GUESSES=0

while true; do
  read GUESS

  # Check if input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment guess counter
  ((GUESSES++))

  # Compare the guess to the target number
  if (( GUESS < TARGET )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > TARGET )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESSES tries. The secret number was $TARGET. Nice job!"
    # Record the game in the database
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $GUESSES)")
    break
  fi
done
