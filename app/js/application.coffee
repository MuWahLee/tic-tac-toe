"use strict"

@ticTacToe = angular.module 'TicTacToe', ["firebase"]

ticTacToe.constant 'WIN_PATTERNS',
  [
    [0,1,2]
    [3,4,5]
    [6,7,8]
    [0,3,6]
    [1,4,7]
    [2,5,8]
    [0,4,8]
    [2,4,6]
  ]

class BoardCtrl
  constructor: (@$scope, @WIN_PATTERNS, @$firebase) ->
    @resetBoard()
    @player = 'x'
    @$scope.mark = @mark
    @$scope.startGame = @startGame
    @$scope.gameOn = false
    @$scope.currentPlayer = @player
    @dbRef = new Firebase "https://tictactoemwl.firebaseio.com/games/"
    @queueRef = new Firebase "https://tictactoemwl.firebaseio.com/queue"

  uniqueId: (length = 8) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  # reviewQueue: (queue) =>
  #   if queue
  #     @player = 2
  #     console.log queue
  #     null
  #   else
  #     @player = 1
  #     console.log @id
  #     @id

  # @firebaseError: (error, committed, snapshot) ->
  #   console.log "error:", error
  #   console.log "committed:", committed
  #   console.log "snapshot:", snapshot

  createGame: (gameId) =>
    @db = @$firebase @dbRef.child (gameId)
    @resetBoard()
    # @unbind() if @unbind
    # @queue = @$firebase @queueRef.child ('id')
    # @queueRef.transaction(@reviewQueue, @firebaseError)
    # log
    @db.$bind( @$scope, 'cells' ).then (unbind) =>
      @unbind = unbind
      @$scope.gameOn = true

    # @playersRef = @$firebase @dbRef.child ('players')
    # @playersRef.$set @$scope.currentPlayer
    # @playersRef.$bind( @$scope, 'currentPlayer')
    

  startGame: =>
    @resetBoard()
    @playerId = @uniqueId()

    @queueRef.transaction (gameId) =>
      if gameId == null
        @gameId = @uniqueId()
      else
        @gameId = gameId
        null
    , (error, committed, snapshot) =>
      if committed and not error
        gameId = snapshot.val()
        if gameId
          console.log "Creating game #{gameId}"
          @createGame(gameId)
          console.log "I am player:", @player
        else
          console.log "Joining game #{@gameId}"
          @createGame(@gameId)
          @player = 'o'
          console.log "I am player:", @player
    
  getPatterns: =>
    @patternsToTest = @WIN_PATTERNS.filter -> true

  getRow: (pattern) =>
    c = @$scope.cells
    c0 = c[pattern[0]] || pattern[0]
    c1 = c[pattern[1]] || pattern[1]
    c2 = c[pattern[2]] || pattern[2]
    "#{c0}#{c1}#{c2}"

  someoneWon: (row) ->
    'xxx' == row || 'ooo' == row

  resetBoard: =>
    @$scope.theWinnerIs = false
    @$scope.cats = false
    @$scope.cells = {}
    @winningCells = @$scope.winningCells = {}
    @$scope.currentPlayer = @player
    @getPatterns()

  numberOfMoves: =>
    Object.keys(@$scope.cells).length

  movesRemaining: (player) =>
    totalMoves = 9 - @numberOfMoves()

    if player == 'x'
      Math.ceil(totalMoves / 2)
    else if player == 'o'
      Math.floor(totalMoves / 2)
    else
      totalMoves

  isMyTurn: (player, options) =>
    options ||= whoMovedLast: false
    moves = @numberOfMoves() - (if options.whoMovedLast then 1 else 0)
    turn = if moves % 2 == 0 then 'x' else 'o'
    player == turn

  isMixedRow: (row) ->
    !!row.match(/o+\d?x+|x+\d?o+/i)

  hasOneX: (row) ->
    !!row.match(/x\d\d|\dx\d|\d\dx/i)

  hasTwoXs: (row) ->
    !!row.match(/xx\d|x\dx|\dxx/i)

  hasOneO: (row) ->
    !!row.match(/o\d\d|\do\d|\d\do/i)

  hasTwoOs: (row) ->
    !!row.match(/oo\d|o\do|\doo/i)

  isEmptyRow: (row) ->
    !!row.match(/\d\d\d/i)

  gameUnwinnable: =>
    @patternsToTest.length < 1

  announceWinner: (winningPattern) =>
    winner = @$scope.cells[winningPattern[0]]
    for k, v of @$scope.cells
      @winningCells[k] = if parseInt(k) in winningPattern then 'win'
      else 'unwin'
    @$scope.theWinnerIs = winner
    @$scope.gameOn = false
    
  announceTie: =>
    @$scope.cats = true
    @$scope.gameOn = false

  rowStillWinnable: (row) =>
    not (@isMixedRow(row) or
    (@hasOneX(row) and @movesRemaining('x') < 2) or
    (@hasTwoXs(row) and @movesRemaining('x') < 1) or
    (@hasOneO(row) and @movesRemaining('o') < 2) or
    (@hasTwoOs(row) and @movesRemaining('o') < 1) or
    (@isEmptyRow(row) and @movesRemaining() < 5))

  parseBoard: =>
    winningPattern = false
    console.log "x remaining moves: ", @movesRemaining('x')
    console.log "o remaining moves: ", @movesRemaining('o')
    console.log "Number of moves: ", @numberOfMoves()
    console.log "$scope.cells: ", @$scope.cells
    @patternsToTest = @patternsToTest.filter (pattern) =>
      row = @getRow(pattern)
      winningPattern ||= pattern if @someoneWon(row)
      @rowStillWinnable(row)
    if winningPattern
      @announceWinner(winningPattern)
    else if @gameUnwinnable()
      @announceTie()

  mark: (@$event) =>
    cell = @$event.target.dataset.index
    if @$scope.gameOn && !@$scope.cells[cell] && @isMyTurn(@player)
      console.log @$scope
      console.log "$scope.cells before assigning value: ", @$scope.cells
      @$scope.cells[cell] = @player
      console.log "after assigning value: ", @$scope.cells
      @parseBoard()
      @$scope.currentPlayer = @player

BoardCtrl.$inject = ["$scope", "WIN_PATTERNS", "$firebase"]
ticTacToe.controller "BoardCtrl", BoardCtrl


