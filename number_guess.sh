#!/bin/bash

# Configuración de conexión a la base de datos
PSQL="psql --username=freecodecamp --dbname=postgres -t --no-align -c"

# Verificar si la base de datos 'number_guess' existe, si no, crearla
DB_EXIST=$($PSQL "SELECT 1 FROM pg_database WHERE datname = 'number_guess'")
if [[ -z $DB_EXIST ]]; then
  $PSQL "CREATE DATABASE number_guess"
  echo "Base de datos 'number_guess' creada."
fi

# Cambiar la conexión para usar la base de datos 'number_guess'
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Crear la tabla 'users' si no existe
$PSQL "CREATE TABLE IF NOT EXISTS users(
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(22) UNIQUE NOT NULL
);"

# Crear la tabla 'games' si no existe
$PSQL "CREATE TABLE IF NOT EXISTS games(
  game_id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(user_id),
  number INT NOT NULL,
  tries INT NOT NULL
);"

# Número secreto aleatorio entre 1 y 1000
NUMBER=$(( RANDOM % 1000 + 1 ))

# Pedir nombre de usuario
echo -e "Enter your username:"
read USER_NAME

# Verificar si el usuario existe en la base de datos
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME'")
if [[ -z $USER_ID ]]; then
  echo "Welcome, $USER_NAME! It looks like this is your first time here."
  NEW_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USER_NAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME'")
else
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID")
  BEST_GAME=$($PSQL "SELECT MIN(tries) FROM games WHERE user_id = $USER_ID")
  echo "Welcome back, $USER_NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Función para obtener la conjetura del usuario
GET_NUMBER() {
  if [[ $1 ]]; then
    echo "That is not an integer, guess again: "
  fi
  read USER_GUESS
}

# Validar que la entrada sea un número
ENSURE_NUMBER() {
  GET_NUMBER
  until [[ $USER_GUESS =~ ^[0-9]+$ ]]; do
    GET_NUMBER again
  done
}

echo "Guess the secret number between 1 and 1000:"
ENSURE_NUMBER

# Bucle principal del juego
TRIES=1
until [[ $USER_GUESS -eq $NUMBER ]]; do
  ((TRIES++))
  if [[ $USER_GUESS -gt $NUMBER ]]; then
    echo "It's lower than that, guess again:"
    ENSURE_NUMBER
  else
    echo "It's higher than that, guess again:"
    ENSURE_NUMBER
  fi
done
# Registrar el resultado del juego
ADD_USER_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number, tries) VALUES($USER_ID, $NUMBER, $TRIES)")
echo "You guessed it in $TRIES tries. The secret number was $NUMBER. Nice job!"
