extends Node3D

# This script acts as a state machine, thus using an enum
enum GameState {
	GAME_WAITING,
	GAME_COUNTDOWN,
	GAME,
	PLAYER_DOWN,
	GAME_OVER,
	PAUSED
}
@export var player1: Node3D
@export var player2: Node3D
@export var debugLabel: Label
var currentState: GameState
var resumeState: GameState
var player1Down: bool
var player2Down: bool

# Debug values for us, these will be set through events occuring before or during the game
var startGame: bool = false
var paused: bool = false

# Variables specific to player timers and game over condition
var player1Timer: float
var player2Timer: float
var player1Outs: int = 0
var player2Outs: int = 0
var lastPlayerDown: int = 0
var player1Win: bool = false

# Other variables
var gameCountdownTimer: float = 3.0
const basePlayerTimer: float = 15.0
const minPlayerTimer: float = 6.0
const playerTimeReduction: float = 3.0
var lastPhysicsState: bool

# Initial value setup
func _ready() -> void:
	currentState = GameState.GAME_WAITING
	print('Controls\n3 >> Start game\n4 >> Pause game')
	debugLabel.text = 'Controls\n3 >> Start game\n4 >> Pause game'
	PhysicsServer3D.set_active(false)
	return

# On every frame, runs global function, then function specific to current state
func _process(delta: float) -> void:
	_globalLoop()
	match currentState:
		GameState.GAME_WAITING:
			_gameWaiting()
		GameState.GAME_COUNTDOWN:
			_gameCountdown(delta)
		GameState.GAME:
			_game()
		GameState.PLAYER_DOWN:
			_playerDown(delta)
		GameState.GAME_OVER:
			_gameOver()
		GameState.PAUSED:
			_paused()
	return

# Logic to be called every single frame, despite game state
# Used for button input (for debugging) and handling pausing
func _globalLoop() -> void:
	# Inputs for debugging
	if Input.is_action_just_pressed("DebugPlayer1Down"):
		player1Down = !player1Down
	if Input.is_action_just_pressed("DebugPlayer2Down"):
		player2Down = !player2Down
	if Input.is_action_just_pressed("DebugStart"):
		startGame = !startGame
	if Input.is_action_just_pressed("DebugPause"):
		paused = !paused
	# Logic to always run
	player1Down = player1.splitPlayers
	player2Down = player2.splitPlayers
	if paused && currentState != GameState.PAUSED:
		resumeState = currentState
		currentState = GameState.PAUSED
		lastPhysicsState = PhysicsServer3D.space_is_active(get_world_3d().space)
		PhysicsServer3D.set_active(false)
	return

# Logic while waiting for the game to begin
func _gameWaiting() -> void:
	if startGame:
		startGame = false
		currentState = GameState.GAME_COUNTDOWN
	return

# Logic for the timer before the game begins proper
func _gameCountdown(delta: float) -> void:
	gameCountdownTimer -= delta
	if gameCountdownTimer <= 0.0:
		gameCountdownTimer = 0.0
		currentState = GameState.GAME
		print('Game started!')
		debugLabel.text = 'Game started!'
		lastPhysicsState = true
		PhysicsServer3D.set_active(true)
		return
	print('Game Countdown: ' + str(snappedf(gameCountdownTimer, 0.1)))
	debugLabel.text = 'Game Countdown: ' + str(snappedf(gameCountdownTimer, 0.1))
	return

# Core game logic
func _game() -> void:
	if player1Down || player2Down:
		player1Timer = _getPlayerTimer(player1Outs)
		player2Timer = _getPlayerTimer(player2Outs)
		currentState = GameState.PLAYER_DOWN
		return
	print('Main game state! P1 outs: ' + str(player1Outs) + ' || P2 outs: ' + str(player2Outs))
	debugLabel.text = 'Main game state! P1 outs: ' + str(player1Outs) + ' || P2 outs: ' + str(player2Outs)
	return

# Logic for when at least 1 player is split
func _playerDown(delta: float) -> void:
	# If both players are split, do nothing and reset the timers
	if player1Down && player2Down:
		player1Timer = _getPlayerTimer(player1Outs)
		player2Timer = _getPlayerTimer(player2Outs)
		lastPlayerDown = 0
		print('Both players down!')
		debugLabel.text = 'Both players down!'
		return
	# Player 1 timer
	if player1Down:
		player1Timer -= delta
		lastPlayerDown = 1
		# End game if timer runs out
		if player1Timer <= 0.0:
			player1Timer = 0.0
			player1Win = false
			currentState = GameState.GAME_OVER
			return
		print('Player 1 timer: ' + str(snappedf(player1Timer, 0.1)) + ' (Outs: ' + str(player1Outs) + ')')
		debugLabel.text = 'Player 1 timer: ' + str(snappedf(player1Timer, 0.1)) + ' (Outs: ' + str(player1Outs) + ')'
		return
	# Player 2 timer
	if player2Down:
		player2Timer -= delta
		lastPlayerDown = 2
		# End game if timer runs out
		if player2Timer <= 0.0:
			player2Timer = 0.0
			player1Win = true
			currentState = GameState.GAME_OVER
			return
		print('Player 2 timer: ' + str(snappedf(player2Timer, 0.1)) + ' (Outs: ' + str(player2Outs) + ')')
		debugLabel.text = 'Player 2 timer: ' + str(snappedf(player2Timer, 0.1)) + ' (Outs: ' + str(player2Outs) + ')'
		return
	# Nobody is down, add out to last player to reconnect. If both players reconnect on the same frame, no outs are added. Then resume game
	if lastPlayerDown == 1:
		player1Outs += 1
	elif lastPlayerDown == 2:
		player2Outs += 1
	currentState = GameState.GAME
	return

# Logic for the game being over
func _gameOver() -> void:
	print('Game over! Player ' + ('ONE' if player1Win else 'TWO') + ' wins!')
	debugLabel.text = 'Game over! Player ' + ('ONE' if player1Win else 'TWO') + ' wins!'
	PhysicsServer3D.set_active(false)
	return

# Logic when the game is paused (waits until unpaused to resume)
func _paused() -> void:
	if !paused:
		currentState = resumeState
		PhysicsServer3D.set_active(lastPhysicsState)
		return
	print('Game paused')
	debugLabel.text = 'Game paused'
	return

# Shortcut to get total timer for player
func _getPlayerTimer(outs: float):
	return clamp(basePlayerTimer - outs * playerTimeReduction, minPlayerTimer, basePlayerTimer)
