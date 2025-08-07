extends Node2D

var cols: int = 30
var rows: int = 20
var margin_top = 35.0
var margin_left = 2.0

var cell_size = 25

var tick: float = 0
var maxTickTime: float = 1
var fpsTick: float = 0

var runing: bool = false
@export var showDebug: bool = false

var sliderValue = 0

#var grids = [
    #[],
    #[]
#]

var gridCount: int = 0
var gridIndex: int = 0
#var currentGrid: Array[int] = []
#var nextGrid: Array[int] = []
var grids = [
    [],
    []
]

func _ready():
    _on_slider_speed_value_changed(%sliderSpeed.value)
    $debug.visible = showDebug

    setupGrid(cell_size)

func stepGridIndex() -> void:
   gridCount += 1
   gridIndex = gridCount % 2

func getCurrentGridValue(x: int, y: int) -> int:
   return grids[gridIndex][(x * rows) + y]
func setCurrentGridValue(x: int, y: int, value: int) -> void:
   grids[gridIndex][(x * rows) + y] = value

func getNextGridValue(x: int, y: int) -> int:
   var newGridIndex = (gridCount + 1) % 2
   return grids[newGridIndex][(x * rows) + y]
func setNextGridValue(x: int, y: int, value: int) -> void:
   var newGridIndex = (gridCount + 1) % 2
   grids[newGridIndex][(x * rows) + y] = value



func setupGrid(cellSize):
    if runing:
        return
    var size = get_viewport_rect()
    cols = int(ceil((size.size.x - margin_left) / cellSize))
    rows = int(ceil((size.size.y - margin_top) / cellSize))

    grids[0].resize(cols * rows)
    grids[1].resize(cols * rows)
    grids[0].fill(0)
    grids[1].fill(0)

var clickPressed = false
func _input(event: InputEvent) -> void:
    if event is InputEventMouse:
        handleMouseEvent(event)
    if event is InputEventKey:
        handleKeyEvent(event)


var clickCellValue = 1
func handleMouseEvent(event: InputEventMouse) -> void:
    if (event is InputEventMouseButton):
        if event.pressed:
            clickPressed = true
        if event.is_released():
            clickPressed = false
            clickCellValue = 1


        if event.button_index == MOUSE_BUTTON_RIGHT:
            clickCellValue = 0
        else:
            clickCellValue = 1

    var pos = event.position
    var x = int(floor((pos.x - margin_left) / cell_size));
    var y = int(floor((pos.y - margin_top) / cell_size));

    if showDebug:
       showDebugInfo(x, y)


    if (clickPressed && x >= 0 && x < cols && y >= 0 && y < rows):
        setCurrentGridValue(x, y, clickCellValue)
        setNextGridValue(x, y, clickCellValue)
        queue_redraw()

func handleKeyEvent(event: InputEventKey) -> void:
    if event.keycode == KEY_SHIFT:
        showDebug = event.is_pressed()
        $debug.visible = showDebug

func _process(delta: float) -> void:
    tick += delta

    if (tick >= maxTickTime):
        calculateGrid()
        queue_redraw()
        tick = 0

    fpsTick += delta
    if fpsTick >= 1:
        $lblFps.text = str(Engine.get_frames_per_second())

func calculateGrid(force: bool = false):
    if !runing && !force: return
    stepGridIndex()

    for i in range(cols * rows):

        var x = i % cols
        var y = i / cols

        var state = getCurrentGridValue(x, y)
        var alive_nighbors = calculateAliveNeigbors(x, y)

        setNextGridValue(x, y, applyRule(state, alive_nighbors))

func applyRule(is_alive: int, alive_neighbors: int) -> int:
    # https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
    # Any live cell with fewer than two live neighbors dies, as if by underpopulation.
    # Any live cell with two or three live neighbors lives on to the next generation.
    # Any live cell with more than three live neighbors dies, as if by overpopulation.
    # Any dead cell with exactly three live neighbors becomes a live cell, as if by reproduction.
    #
    if is_alive:
        if alive_neighbors < 2:
            return 0
        if alive_neighbors == 2 or alive_neighbors == 3:
            return is_alive
        return 0
    else:
        if alive_neighbors == 3:
            return 1
        else:
            return 0

func showDebugInfo(x, y):
    if !showDebug: return

    var current = getCurrentGridValue(x, y)
    var next = getNextGridValue(x, y)
    var aliveN = calculateAliveNeigbors(x, y)
    var calculatedNextState = applyRule(current, aliveN)

    var text = "Cur: %d - Next: %d -- Alive Neighbors: %d - Next State: %d" % [current, next, aliveN, calculatedNextState]

    %lblDebug.text = text

func calculateAliveNeigbors(x: int, y: int) -> int:
    var alive_nighbors = 0

    var minX = x - 1 if x > 0 else x;
    var minY = y - 1 if y > 0 else y;
    var maxX = x + 1 if x < cols - 1 else x;
    var maxY = y + 1 if y < rows - 1 else y;
    for nx in range(minX, maxX + 1):
        for ny in range(minY, maxY + 1):
            alive_nighbors += getCurrentGridValue(nx, ny)
    alive_nighbors -= getCurrentGridValue(x, y)

    return alive_nighbors

var colors = [Color.BLACK, Color.WHITE]
var default_font: Font = ThemeDB.fallback_font;
func _draw() -> void:
    for i in range(cols * rows):
        var x = i % cols
        var y = i / cols

        var value = getCurrentGridValue(x, y)

        draw_rect(Rect2((x * cell_size + margin_left), (y * cell_size + margin_top), cell_size, cell_size), colors[value], true)
        draw_rect(Rect2((x * cell_size + margin_left), (y * cell_size + margin_top), cell_size, cell_size), Color.WHITE, false)

func _on_button_toggled(toggled_on: bool) -> void:
    runing = toggled_on
    %txtCellSize.editable = !toggled_on
    %btnSet.disabled = toggled_on
    if runing:
        %btnStart.text = "Stop"
    else:
        %btnStart.text = "Start"

func _on_button_pressed() -> void:
    grids[0].fill(0)
    grids[1].fill(0)

func _on_slider_speed_value_changed(value: float) -> void:
    sliderValue = value
    maxTickTime = 1 - (sliderValue / 100)

func _on_btn_set_pressed() -> void:
    var size = int(%txtCellSize.text)
    if size <= 3:
        size = 25
        %txtCellSize.text = "25"
    cell_size = size
    setupGrid(size)


func _on_btn_next_step_pressed() -> void:
    calculateGrid(true)
