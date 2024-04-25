extends Node2D


var grid: Array = []
var next_tick_grid: Array = []

var width = 30
var height = 20
var margin_top = 35.0
var margin_left = 2.0

var cell_size = 25

var tick = 0
var fpsTick = 0

var runing = false

func _ready():
    var size = get_viewport_rect()
    width = ceil((size.size.x - margin_left) / cell_size)
    height = ceil((size.size.y - margin_top) / cell_size)
    for i in width:
        grid.append([])
        next_tick_grid.append([])
        for j in height:
            grid[i].append(0)
            next_tick_grid[i].append(0)

var pressed = false
func _input(event: InputEvent) -> void:
    if !(event is InputEventMouse):
        return

    if (event is InputEventMouseButton):
        if event.pressed:
            pressed = true
        if event.is_released():
            pressed = false

    var pos = event.position
    var x = floor((pos.x - margin_left)/ cell_size);
    var y = floor((pos.y - margin_top) / cell_size);
    if pressed && x >= 0 && x < width && y >= 0 && y < height:
        grid[x][y] = 1
        next_tick_grid[x][y] = 1
        queue_redraw()
        

func _process(delta: float) -> void:
    # queue_redraw()
    fpsTick += delta
    tick += delta
    if (tick >= 0.05):
        calculateGrid()
        queue_redraw()
        tick = 0
    
    if fpsTick >= 1:
        $lblFps.text = str(Engine.get_frames_per_second())

func calculateGrid():
    if !runing: return
    for x in len(grid):
        for y in len(grid[x]):
            grid[x][y] = next_tick_grid[x][y]
            var alive_nighbors = 0

            var minX = x-1 if x > 0 else x;
            var minY = y-1 if y > 0 else y;
            var maxX = x+1 if x < width-1 else x;
            var maxY = y+1 if y < height-1 else y;
            for nx in range(minX, maxX + 1):
                for ny in range(minY, maxY + 1):
                    alive_nighbors += grid[nx][ny]
            alive_nighbors -= grid[x][y]
            
            next_tick_grid[x][y] = applyRule(grid[x][y], alive_nighbors)

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
            return 1
        return 0
    else:
        if alive_neighbors == 3:
            return 1
    return is_alive



var colors = [Color.BLACK, Color.WHITE]
var default_font : Font = ThemeDB.fallback_font;
func _draw() -> void:
    for x in len(grid):
        for y in len(grid[x]):
            # prints(x, y, grid[x][y])
            draw_rect(Rect2((x * cell_size + margin_left), (y * cell_size + margin_top), cell_size, cell_size), colors[grid[x][y]], true)
            draw_rect(Rect2((x * cell_size + margin_left), (y * cell_size + margin_top), cell_size, cell_size), Color.WHITE, false)



func _on_check_box_toggled(toggled_on:bool) -> void:
    runing = toggled_on


func _on_button_pressed() -> void:
    for x in len(grid):
        for y in len(grid[x]):
            grid[x][y] = 0
            next_tick_grid[x][y] = 0