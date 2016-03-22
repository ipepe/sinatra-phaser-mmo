WALK_TIMER = 400
TILE_SIZE = 16
window.GameState = class GameState
  constructor: ->
    @game = window.GameApp

  preload: ->
    @add.plugin(Phaser.Plugin.Tiled)
    @load.image('pad', 'gfx/pad.png');
    @load.spritesheet('chara0', 'gfx/chara0.gif', 32, 32);

    @cursors = @input.keyboard.createCursorKeys();
    @game.stage.smoothed = false;
    #import map
    @cacheKey = Phaser.Plugin.Tiled.utils.cacheKey;
    @game.load.tiledmap( @cacheKey('worldmap', 'tiledmap'), 'gfx/map01.json', null, Phaser.Tilemap.TILED_JSON);
    @game.load.image(    @cacheKey('worldmap', 'tileset', 'map01'), 'gfx/map01.gif');

  setupFullscreen: ->
    @scale.scaleMode = Phaser.ScaleManager.SHOW_ALL;
    @scale.maxWidth = 1536;
    @scale.maxHeight = 2048;
    @scale.pageAlignHorizontally = true;
    @scale.pageAlignVertically = true;
    @scale.refresh()

  create: ->
    @map = @add.tiledmap('worldmap');

    padImg = @game.add.sprite(220, 220, 'pad')
    padImg.fixedToCamera = true;
    @game.world.bringToTop padImg
    @setupFullscreen()
    @player = @createPlayerGfx('developer', 'chara0', 96, 96)
    @game.camera.follow(@player)

  createPlayerGfx: (playerNameObj, gfxName, xCord, yCord) ->
    @player = @game.add.sprite(24, 16, gfxName)
    a = 0
    b = 3
    @player.animations.add 'walk_down', [ 0 + a * 3, 1 + a * 3, 2 + a * 3 ], 6, true, true
    @player.animations.add 'idle_down', [ 1 + a * 3 ], 1, false, true
    @player.animations.add 'walk_left', [ 3 * b + a * 3, 1 + 3 * b + a * 3, 2 + 3 * b + a * 3 ], 6, true, true
    @player.animations.add 'idle_left', [ 1 + 3 * b + a * 3 ], 1, false, true
    @player.animations.add 'walk_right',[ 6 * b + a * 3, 6 * b + a * 3 + 1, 6 * b + a * 3 + 2 ], 6, true, true
    @player.animations.add 'idle_right',[ 6 * b + a * 3 + 1 ], 1, false, true
    @player.animations.add 'walk_up',   [ 9 * b + a * 3, 9 * b + a * 3 + 1, 9 * b + a * 3 + 2 ], 6, true, true
    @player.animations.add 'idle_up',   [ 9 * b + a * 3 + 1 ], 1, false, true

    @player.animations.play 'idle_down'
    @game.physics.arcade.enable @player
    @player.body.collideWorldBounds = true
    @player.body.setSize 16, 16, 8, 16
    @player.body.maxVelocity = new (Phaser.Point)(0, 0)
    @player.isMoving = false
    playerText = @game.add.text(TILE_SIZE, 0, playerNameObj,
      font: 'bold 10px sans-serif'
      fill: '#f1c40f'
      stroke: 'black'
      strokeThickness: 4)
    playerText.anchor.setTo 0.5, 0.5
    @player.addChild playerText
    @player.x = xCord - 8
    @player.y = yCord - 16
    return @player

  update: ->
    if !@player.isMoving
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
      #informServer(player.body.position.x + newX, player.body.position.y + newY, direction);
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
      #informServer(-1,-1,direction);
      @player.animations.play 'idle_' + direction

  isTileWalkable: (cordX, cordY) ->
    tileX = cordX / 16
    tileY = cordY / 16
    console.log @map.getTile(tileX, tileY, @map.layers[0])
    groundTile = @map.getTile(tileX, tileY, @map.layers[0])
    sceneTile = @map.getTile(tileX, tileY, @map.layers[1])
    if groundTile
      if !sceneTile
        groundTile.properties.walkable == true
      else
        groundTile.properties.walkable == true && sceneTile.properties.walkable == true
    else
      false
