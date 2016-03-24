WALK_TIMER = 300
TILE_SIZE = 16

class window.GameState
  remote_players: {}
  constructor: (websocket) ->
    @game = window.GameApp
    @websocket = websocket

  preload: ->
    @add.plugin(Phaser.Plugin.Tiled)
    @load.image('pad', 'gfx/pad.png');
    @load.spritesheet('chara0', 'gfx/chara0.gif', 32, 32);

    @cursors = @input.keyboard.createCursorKeys();
    @game.stage.smoothed = false;

    @cacheKey = Phaser.Plugin.Tiled.utils.cacheKey;
    @game.load.tiledmap( @cacheKey('worldmap', 'tiledmap'), 'gfx/map01.json', null, Phaser.Tilemap.TILED_JSON);
    @game.load.image(    @cacheKey('worldmap', 'tileset', 'map01'), 'gfx/map01.gif');

  setupFullscreen: ->
    @scale.scaleMode = Phaser.ScaleManager.SHOW_ALL;
    @scale.maxWidth = 1536;
    @scale.maxHeight = 2048;
    @scale.pageAlignHorizontally = true;
    @scale.pageAlignVertically = true;
    @scale.setScreenSize(true);

  create: ->
    @map = @add.tiledmap('worldmap');

    padImg = @game.add.sprite(220, 220, 'pad')
    padImg.fixedToCamera = true;
    @game.world.bringToTop padImg
    @player_name = 'Player' + Math.floor(Math.random()*1000)
    @setupFullscreen()
    @player_name = prompt("Please enter your name.", @player_name) || @player_name
    @player = @createPlayerGfx(@player_name, 96, 96)
    @game.camera.follow(@player)
    @websocket.send 'player_create',
      name: @player_name,
      x: @player.body.position.x,
      y: @player.body.position.y

    self = this
    update_remote_player = (attributes) ->
      self.update_remote_player(attributes)
    @websocket.on 'player_create', update_remote_player
    @websocket.on 'player_destroy', update_remote_player
    @websocket.on 'player_update', update_remote_player

  update_remote_player: (attributes) ->
    #jezeli nie jest mna
    if attributes.name && attributes.name != @player_name
      #jezeli juz istnieje jego grafika
      if @remote_players[attributes.name]
        player = @remote_players[attributes.name]
        if attributes['_destroy'] == true
          player.kill()
        else if @remote_players[attributes.name].x != attributes.x || @remote_players[attributes.name].y != attributes.y
          player.animations.play 'walk_' + attributes.direction
          @game.add.tween(player).to({
            x: attributes.x
            y: attributes.y
          }, WALK_TIMER, Phaser.Easing.Quadratic.InOut, true).onComplete.add((->
            player.animations.play 'idle_' + attributes.direction
          ), this)
        else
          player.animations.play 'idle_' + attributes.direction
      else if attributes['_destroy'] != true #jezeli nie istnieje jego grafika i nie zabijamy go
        @remote_players[attributes.name] = @createPlayerGfx(attributes.name, attributes.x, attributes.y)

  createPlayerGfx: (player_name, x_cord, y_cord) ->
    player = @game.add.sprite(96, 96, 'chara0')
    a = 0
    b = 3
    player.animations.add 'walk_down', [ 0 + a * 3, 1 + a * 3, 2 + a * 3 ], 6, true, true
    player.animations.add 'idle_down', [ 1 + a * 3 ], 1, false, true
    player.animations.add 'walk_left', [ 3 * b + a * 3, 1 + 3 * b + a * 3, 2 + 3 * b + a * 3 ], 6, true, true
    player.animations.add 'idle_left', [ 1 + 3 * b + a * 3 ], 1, false, true
    player.animations.add 'walk_right',[ 6 * b + a * 3, 6 * b + a * 3 + 1, 6 * b + a * 3 + 2 ], 6, true, true
    player.animations.add 'idle_right',[ 6 * b + a * 3 + 1 ], 1, false, true
    player.animations.add 'walk_up',   [ 9 * b + a * 3, 9 * b + a * 3 + 1, 9 * b + a * 3 + 2 ], 6, true, true
    player.animations.add 'idle_up',   [ 9 * b + a * 3 + 1 ], 1, false, true

    player.animations.play 'idle_down'
    @game.physics.arcade.enable player
    player.body.collideWorldBounds = true
    player.body.setSize 16, 16, 8, 16
    player.body.maxVelocity = new (Phaser.Point)(0, 0)
    player.isMoving = false
    playerText = @game.add.text(TILE_SIZE, 0, player_name,
      font: 'bold 10px sans-serif'
      fill: '#f1c40f'
      stroke: 'black'
      strokeThickness: 4)
    playerText.anchor.setTo 0.5, 0.5
    player.addChild playerText
    player.x = x_cord - 8
    player.y = y_cord - 16
    return player

  update: ->
    if !@player?.isMoving
      if @game.input.activePointer.isDown
        clickX = @game.input.activePointer.x - 270
        clickY = @game.input.activePointer.y - 270
        if clickX < 50 and clickY > -50
          if clickX > clickY
            if -clickX > clickY
              @movePlayer 0, -TILE_SIZE, 'up'
            else
              @movePlayer TILE_SIZE, 0, 'right'
          else
            if -clickX > clickY
              @movePlayer -TILE_SIZE, 0, 'left'
            else
              @movePlayer 0, TILE_SIZE, 'down'
      if @cursors.left.isDown
        @movePlayer -TILE_SIZE, 0, 'left'
      else if @cursors.right.isDown
        @movePlayer TILE_SIZE, 0, 'right'
      else if @cursors.up.isDown
        @movePlayer 0, -TILE_SIZE, 'up'
      else if @cursors.down.isDown
        @movePlayer 0, TILE_SIZE, 'down'

  movePlayer: (newX, newY, direction) ->
    return if @player.isMoving
    if @isTileWalkable(@player.body.position.x + newX, @player.body.position.y + newY)
      @websocket.send 'player_update',
        name: @player_name,
        x: @player.x + newX,
        y: @player.y + newY,
        direction: direction
      @player.isMoving = true
      @player.animations.play 'walk_' + direction
      @game.add.tween(@player).to({
        x: @player.x + newX
        y: @player.y + newY
      }, WALK_TIMER, Phaser.Easing.Quadratic.InOut, true).onComplete.add (->
        @player.isMoving = false
        @player.animations.play 'idle_' + direction
        return
      ), this
    else
      @player.animations.play 'idle_' + direction
      @websocket.send 'player_update',
        name: @player_name,
        x: @player.x,
        y: @player.y,
        direction: direction

  isTileWalkable: (cordX, cordY) ->
    tileX = cordX / 16
    tileY = cordY / 16
    groundTile = @map.getTile(tileX, tileY, @map.layers[0])
    sceneTile = @map.getTile(tileX, tileY, @map.layers[1])
    if groundTile
      if !sceneTile
        groundTile.properties.walkable == true
      else
        groundTile.properties.walkable == true && sceneTile.properties.walkable == true
    else
      false
