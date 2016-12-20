###
  Debug Arcade Physics plugin v{!major!}.{!minor!}.{!maintenance!} ({!build!}) for Phaser
###

"use strict"

{abs, cos, max, sin} = Math
{freeze, seal} = Object
{Bullet, Circle, Line, PARTICLE, Plugin, Point, Rectangle, SPRITE} = Phaser
{sign} = Phaser.Math
{ARCADE} = Phaser.Physics

degreeToRadiansFactor = Math.PI / 180

Phaser.Plugin.DebugArcadePhysics = freeze class DebugArcadePhysics extends Phaser.Plugin

  # Constructor

  @addTo = (game) ->
    game.plugins.add this

  # Filters

  @exists = (obj) ->
    obj.exists

  @isAlive = (obj) ->
    obj.alive

  @isBullet = (obj) ->
    obj instanceof Bullet

  @isNotBullet = (obj) ->
    not obj instanceof Bullet

  @isNotParticle = (obj) ->
    obj.type isnt PARTICLE

  @isNotSprite = (obj) ->
    obj.type isnt SPRITE

  @isParticle = (obj) ->
    obj.type is PARTICLE

  @isSprite = (obj) ->
    obj.type is SPRITE

  @VERSION = "{!major!}.{!minor!}.{!maintenance!}.{!build!}"

  # Private

  TOO_BIG = 9999

  red    = "hsla(0  , 100%,  50%, 0.5)"
  coral  = "hsla(15 , 100%,  50%, 0.5)"
  orange = "hsla(30 , 100%,  50%, 0.5)"
  gold   = "hsla(45 , 100%,  50%, 0.5)"
  yellow = "hsla(60 , 100%,  50%, 0.5)"
  green  = "hsla(120, 100%,  50%, 0.5)"
  aqua   = "hsla(180, 100%,  50%, 0.5)"
  blue   = "hsla(210, 100%,  50%, 0.5)"
  indigo = "hsla(240, 100%,  50%, 0.5)"
  purple = "hsla(270, 100%,  50%, 0.5)"
  violet = "hsla(300, 100%,  50%, 0.5)"
  rose   = "hsla(330, 100%,  50%, 0.5)"
  white  = "hsla(0  ,   0%, 100%, 0.5)"
  gray   = "hsla(0  ,   0%,  50%, 0.5)"

  # Prototype

  colors: colors =
    acceleration: violet
    blocked:      coral
    body:         yellow
    bodyDisabled: gray
    center:       white
    drag:         orange
    maxVelocity:  green
    offset:       yellow
    rotation:     yellow
    speed:        blue
    touching:     red
    velocity:     aqua

  config: seal
    filter:             null
    lineWidth:          1
    on:                 yes
    renderAcceleration: yes
    renderBlocked:      yes
    renderBody:         yes
    renderBodyDisabled: yes
    renderCenter:       yes
    renderConfig:       no
    renderDrag:         yes
    renderMaxVelocity:  yes
    renderLegend:       yes
    renderOffset:       yes
    renderRotation:     yes
    renderSpeed:        yes
    renderTouching:     yes
    renderVelocity:     yes

  configKeys: freeze Object.keys this::config

  name: "Debug Arcade Physics Plugin"

  Object.defineProperty @prototype, "version",
    get: ->
      @constructor.VERSION

  # Hooks

  init: (settings) ->
    console.log "%s v%s", @name, @version
    @game.debug.arcade = @interface()
    @help()
    @configSet settings if settings
    return

  postRender: ->
    return unless @config.on
    @renderConfig() if @config.renderConfig
    @renderColors() if @config.renderLegend
    @renderAll()
    return

  # Helpers

  bodyColor: (body) ->
    {renderBlocked, renderBodyDisabled, renderTouching} = @config
    {blocked, enable, touching} = body
    colors[ if renderBodyDisabled and not enable        then "bodyDisabled"
    else    if renderTouching     and not touching.none then "touching"
    else    if renderBlocked      and (blocked.down     or
                                       blocked.up       or
                                       blocked.left     or
                                       blocked.right)   then "blocked"
    else                                                     "body"
    ]

  _calculateDrag = new Point

  calculateDrag: (body, out = _calculateDrag) ->
    {drag, velocity} = body
    {physicsElapsed} = @game.time
    vx = velocity.x
    vy = velocity.y
    dx = drag.x * -sign(vx)
    dy = drag.y * -sign(vy)
    out.x = if (abs(vx) - abs(dx * physicsElapsed)) > 0 then dx else 0
    out.y = if (abs(vy) - abs(dy * physicsElapsed)) > 0 then dy else 0
    out

  configSet: (settings) ->
    for name, val of settings
      if name of @config
        @config[name] = val
        console.log name, val
      else
        console.warn "No such setting '#{name}'. Use #{@configKeys.join ', '}."
    this

  geom: (obj, color, fill = no, lineWidth = @config.lineWidth) ->
    {debug}   = @game
    {context} = debug
    savedLineWidth = context.lineWidth
    context.lineWidth = lineWidth
    debug.geom obj, color, fill
    context.lineWidth = savedLineWidth
    this

  help: ->
    console.log "Use `game.debug.arcade`: #{Object.keys(@game.debug.arcade).join ', '}"
    this

  helpConfig: ->
    console.log "Use `game.debug.arcade.configSet()`: #{@configKeys.join ', '}"
    this

  hide: ->
    @visible = no
    this

  off: ->
    @config.on = no
    this

  on: ->
    @config.on = yes
    this

  placeLine: (line, start, end) ->
    @placeLineXY line, start.x, start.y, end.x, end.y

  placeLineXY: (line, startX, startY, endX, endY) ->
    line.setTo startX, startY, endX, endY

  placeRect: (rect, center, size) ->
    rect.resize(2 * size.x, 2 * size.y).centerOn(center.x, center.y)
    rect

  placeVector: (line, start, vector) ->
    @placeVectorXY line, start.x, start.y, vector.x, vector.y

  placeVectorXY: (line, startX, startY, vectorX, vectorY) ->
    line.setTo startX, startY, startX + vectorX, startY + vectorY

  renderAcceleration: (body) ->
    @renderVector body.acceleration, body, colors.acceleration
    this

  renderAll: ->
    @renderObj @game.world
    this

  renderCenter: (body) ->
    {x, y} = body.center
    {camera} = @game
    @game.debug.pixel ~~(x - camera.x), ~~(y - camera.y), colors.center
    this

  _circle = new Circle

  renderCircle: (radius, body, color) ->
    return this if radius < 1
    _circle.setTo body.center.x, body.center.y, 2 * radius
    @geom _circle, color
    this

  renderColors: (x = 10, y = x) ->
    {debug} = @game
    debug.start x, y
    for name, val of @colors
      debug.currentColor = val
      debug.line name
    debug.stop()
    this

  renderConfig: (x = 10, y = x) ->
    {debug} = @game
    debug.start x, y
    for name, val of @config
      debug.line "#{name}: #{val}"
    debug.stop()
    this

  renderDrag: (body) ->
    @renderVector @calculateDrag(body), body, colors.drag
    this

  renderMaxVelocity: (body) ->
    {maxVelocity} = body
    return this if maxVelocity.x > TOO_BIG or
                   maxVelocity.y > TOO_BIG
    @renderRect maxVelocity, body, colors.maxVelocity
    this

  renderObj: (obj) ->
    return this unless obj.exists

    {config} = this
    {filter} = config
    {body} = obj

    if obj.renderable      and
       body                and
       body.type is ARCADE and
       (body.enable or config.renderBodyDisabled)

      return this if filter and not filter(obj)

      @renderBody         body if config.renderBody
      @renderOffset       body if config.renderOffset
      @renderRotation     body if config.renderRotation
      @renderSpeed        body if config.renderSpeed
      @renderMaxVelocity  body if config.renderMaxVelocity
      @renderVelocity     body if config.renderVelocity
      @renderAcceleration body if config.renderAcceleration
      @renderDrag         body if config.renderDrag
      @renderCenter       body if config.renderCenter

    for child in obj.children
      @renderObj child
    this

  renderBody: (body) ->
    @game.debug.body body.sprite, @bodyColor(body), no
    this

  _line = new Line

  renderLine: (startX, startY, endX, endY, color, width) ->
    _line.setTo startX, startY, endX, endY
    @geom _line, color, no, width
    this

  _offset = new Line

  renderOffset: (body) ->
    @placeVectorXY _offset, body.position.x,
                            body.position.y,
                            -body.offset.x * body.sprite.scale.x,
                            -body.offset.y * body.sprite.scale.y
    @geom _offset, colors.offset, no
    this

  _rect = new Rectangle

  renderRect: (vector, body, color) ->
    return this if vector.isZero()
    @placeRect _rect, body.center, vector
    @geom _rect, color
    this

  _rotation = new Line

  renderRotation: (body) ->
    {halfHeight, halfWidth, rotation} = body
    {x, y} = body.center
    rotation *= degreeToRadiansFactor
    @renderVectorXY halfWidth  * cos(rotation),
                    halfHeight * sin(rotation),
                    body, colors.rotation
    this

  renderSpeed: (body) ->
    return this if body.speed < 1
    @renderCircle body.speed, body, colors.speed
    this

  renderVector: (vector, body, color) ->
    return this if vector.isZero()
    @renderVectorXY vector.x, vector.y, body, color
    this

  renderVectorXY: (vectorX, vectorY, body, color) ->
    return this if vectorX is 0 and vectorY is 0
    {x, y} = body.center
    @renderLine x, y, x + vectorX, y + vectorY, color
    this

  renderVelocity: (body) ->
    @renderVector body.velocity, body, colors.velocity
    this

  show: ->
    @visible = yes
    this

  toggle: ->
    @config.on = not @config.on
    this

  toggleVisible: ->
    @visible = not @visible
    this

  # Interface (as `game.debug.arcade`)

  interface: ->
    freeze
      acceleration: @renderAcceleration.bind this
      body:         @renderBody        .bind this
      center:       @renderCenter      .bind this
      circle:       @renderCircle      .bind this
      config:       @config
      configSet:    @configSet         .bind this
      drag:         @renderDrag        .bind this
      help:         @help              .bind this
      helpConfig:   @helpConfig        .bind this
      hide:         @hide              .bind this
      maxVelocity:  @renderMaxVelocity .bind this
      obj:          @renderObj         .bind this
      off:          @off               .bind this
      offset:       @renderOffset      .bind this
      on:           @on                .bind this
      rect:         @renderRect        .bind this
      rotation:     @renderRotation    .bind this
      show:         @show              .bind this
      speed:        @renderSpeed       .bind this
      vector:       @renderVector      .bind this
      vectorXY:     @renderVectorXY    .bind this
      velocity:     @renderVelocity    .bind this
      toggle:       @toggle            .bind this
