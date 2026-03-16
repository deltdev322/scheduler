# Roblox Coroutine Scheduler
A lightweight frame-budget coroutine scheduler for Roblox.
This module allows you to run large workloads across multiple frames without freezing the game by enforcing a strict execution time budget per frame.

--------------------------------------------------------------------------------

# The scheduler is designed for CPU-heavy systems such as:
1. procedural generation
2. large data processing
3. AI systems
4. ECS systems
5. pathfinding batches
6. chunk streaming

--------------------------------------------------------------------------------

# Why use this?
Running large loops in a single frame can cause frame drops or server stalls.
Example of a problematic pattern:
```lua
for i = 1, 100000 do
    heavyWork()
end
```

This module spreads the work across frames:
```lua
scheduler:Add(function()
    for i = 1, 100000 do
        heavyWork()
        scheduler:Yield()
    end
end)
```

It uses ~85% of the frame duration and leaves headroom for the rest of the game.

--------------------------------------------------------------------------------

# Ring queue: O(1) vs O(n)
When removing the first element, Luau must shift every element in the array, this means every element is moved in memory.
For large queues this becomes expensive.
{A, B, C, D} -> {B, C, D} (after table.remove())

This scheduler uses a ring queue instead. Instead of shifting memory, it tracks two indices: head and tail.
{A, B, C, D} -> {nil, B, C, D}; head = 2; tail = 4

--------------------------------------------------------------------------------

# Benchmark
A simple benchmark was run comparing:
baseline execution (single-frame workload)
scheduler execution (frame-budgeted tasks)

Executing:
```lua
local function heavy(i)
	return math.sqrt(i) * math.sin(i)
end
```

# Baseline (no scheduler)
```
Total time: 0.180 s
Frames used: 21
Average frame time: 0.0083 s
Max frame time: 0.0083 s
```
All work is executed in large chunks, causing long frame spikes.

# With Scheduler
```
Total time: 0.256 s
Frames used: 61
Average frame time: 0.0041 s
Max frame time: 0.0065 s
Min frame time: 0.0001 s
```
Work is distributed across frames using the scheduler's adaptive frame budget.

# That means:
1. 50% lower average frame time
2. Heavy tasks are spread across 3x more frames, preventing sudden spikes.
3. Instead of blocking frames with large bursts of work, the scheduler maintains a consistent execution budget.

--------------------------------------------------------------------------------

# Example
Chunk generation example:
```lua
local scheduler = Scheduler.new()

scheduler:Add(function()
    for x = 1, 100 do
        for y = 1, 100 do
            generateTile(x, y)
            scheduler:Yield()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    scheduler:Step()
end)
```
