extends Node2D

var width = 30
var height = 20
var margin_top = 35.0
var margin_left = 2.0

var cell_size = 25

var tick: float = 0
var maxTickTime: float = 1
var fpsTick: float = 0

var runing: bool = false
var showDebug: bool = false

var sliderValue = 0

var grids = [
    [],
    []
]

var gridCount: int = 0
var gridIndex: int = 0
var nextGridIndex: int = 1

func _ready():
    sliderValue = %sliderSpeed.value
    maxTickTime = 1 - (sliderValue / 100)
    $debug.visible = showDebug
    
    setupGrid(cell_size)

func setupGrid(cellSize):
    if runing:
        return
    var size = get_viewport_rect()
    width = ceil((size.size.x - margin_left) / cellSize)
    height = ceil((size.size.y - margin_top) / cellSize)

    grids[gridIndex] = []
    grids[nextGridIndex] = []
    var grid = grids[gridIndex]
    var next_tick_grid = grids[nextGridIndex]
    for i in width:
        grid.append([])
        next_tick_grid.append([])
        for j in height:
            grid[i].append(0)
            next_tick_grid[i].append(0)

var clickPressed = false
func _input(event: InputEvent) -> void:
    if event is InputEventMouse:
        handleMouseEvent(event)
    if event is InputEventKey:
        handleKeyEvent(event)
    

func handleMouseEvent(event: InputEventMouse) -> void:
    if (event is InputEventMouseButton):
        if event.pressed:
            clickPressed = true
        if event.is_released():
            clickPressed = false

    var pos = event.position
    var x = floor((pos.x - margin_left) / cell_size);
    var y = floor((pos.y - margin_top) / cell_size);

    showDebugInfo(x, y)

    var grid = grids[gridIndex]
    var next_tick_grid = grids[nextGridIndex]

    if (clickPressed&&x >= 0&&x < width&&y >= 0&&y < height):
        grid[x][y] = 1
        next_tick_grid[x][y] = 1
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
    gridCount += 1
    gridIndex = gridCount % 2
    nextGridIndex = (gridCount + 1) % 2
    
    var next_tick_grid = grids[nextGridIndex]
    var grid = grids[gridIndex]
    
    for x in width:
        for y in height:
            var state = grid[x][y]
            var alive_nighbors = calculateAliveNeigbors(x, y)
            
            next_tick_grid[x][y] = applyRule(state, alive_nighbors)

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
    var grid = grids[gridIndex]
    var next_tick_grid = grids[nextGridIndex]

    var current = grid[x][y]
    var next = next_tick_grid[x][y]
    var aliveN = calculateAliveNeigbors(x, y)
    var calculatedNextState = applyRule(current, aliveN)

    var text = "Cur: %d - Next: %d -- Alive Neighbors: %d - Next State: %d" % [current, next, aliveN, calculatedNextState]

    %lblDebug.text = text

func calculateAliveNeigbors(x: int, y: int) -> int:
    var grid = grids[gridIndex]
    var alive_nighbors = 0

    var minX = x - 1 if x > 0 else x;
    var minY = y - 1 if y > 0 else y;
    var maxX = x + 1 if x < width - 1 else x;
    var maxY = y + 1 if y < height - 1 else y;
    for nx in range(minX, maxX + 1):
        for ny in range(minY, maxY + 1):
            alive_nighbors += grid[nx][ny]
    alive_nighbors -= grid[x][y]

    return alive_nighbors

var colors = [Color.BLACK, Color.WHITE]
var default_font: Font = ThemeDB.fallback_font;
func _draw() -> void:
    var grid = grids[gridIndex]
    for x in width:
        for y in height:
            # prints(x, y, grid[x][y])
            draw_rect(Rect2((x * cell_size + margin_left), (y * cell_size + margin_top), cell_size, cell_size), colors[grid[x][y]], true)
            draw_rect(Rect2((x * cell_size + margin_left), (y * cell_size + margin_top), cell_size, cell_size), Color.WHITE, false)

func _on_button_toggled(toggled_on: bool) -> void:
    runing = toggled_on
    if runing:
        %btnStart.text = "Stop"
    else:
        %btnStart.text = "Start"

func _on_button_pressed() -> void:
    var grid = grids[gridIndex]
    var next_tick_grid = grids[nextGridIndex]
    for x in width:
        for y in height:
            grid[x][y] = 0
            next_tick_grid[x][y] = 0

func _on_slider_speed_value_changed(value: float) -> void:
    sliderValue = value
    maxTickTime = 1 - (sliderValue / 100)

func _on_btn_set_pressed() -> void:
    var size = int( %txtCellSize.text)
    if size <= 3:
        size = 25
        %txtCellSize.text = "25"
    cell_size = size
    setupGrid(size)


func _on_btn_next_step_pressed() -> void:
    calculateGrid(true)
