local RunService = game:GetService("RunService")
local Scheduler = require(game:GetService("ReplicatedStorage").Scheduler)

local ITERATIONS = 2000000
local CHUNK = 200

local function heavy(i: number)
	return math.sqrt(i) * math.sin(i)
end

local function measureBaseline()
	local frameTimes = {}
	local lastTime = os.clock()
	
	local startTime = os.clock()
	
	for i=1,ITERATIONS do
		heavy(i)
		
		local now = os.clock()
		local delta = now - lastTime
		if delta > 1/120 then
			table.insert(frameTimes, delta)
			lastTime = now
		end
	end
	
	local total = os.clock() - startTime
	return total, frameTimes
end

local function measureScheduler()
	local scheduler = Scheduler.new()
	local finished = false
	local frameTimes = {}
	local lastTime = os.clock()
	
	scheduler:Add(function()
		for i=1,ITERATIONS do
			heavy(i)
			if i % CHUNK == 0 then
				scheduler:Yield()
			end
		end
		finished = true
	end)
	
	local startTime = os.clock()
	
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		local nowTime = os.clock()
		table.insert(frameTimes, nowTime - lastTime)
		lastTime = nowTime
		
		scheduler:Step()
		
		if finished then
			connection:Disconnect()
		end
	end)
	
	repeat
		RunService.Heartbeat:Wait()
	until finished
	
	local totalTime = os.clock() - startTime
	return totalTime, frameTimes
end

local function summarize(frameTimes: {number})
	local sum = 0
	local maxF = 0
	local minF = math.huge
	
	for _,dt in ipairs(frameTimes) do
		sum += dt
		if dt > maxF then maxF = dt end
		if dt < minF then minF = dt end
	end
	
	local avg = sum/#frameTimes
	return avg, maxF, minF
end

print("waiting 5 seconds before start")
task.wait(5)
print(">>>> BENCHMARK START <<<<")

print("Running baseline...")
local baseTime, baseFrames = measureBaseline()
local baseAvg, baseMax, baseMin = summarize(baseFrames)
print(string.format("Baseline total time: %.3f s, frames: %d, avg: %.4f, max: %.4f, min: %.4f", baseTime, #baseFrames, baseAvg, baseMax, baseMin))

print("Running scheduler...")
local schedTime, schedFrames = measureScheduler()
local schedAvg, schedMax, schedMin = summarize(schedFrames)
print(string.format("Scheduler total time: %.3f s, frames: %d, avg: %.4f, max: %.4f, min: %.4f", schedTime, #schedFrames, schedAvg, schedMax, schedMin))

print(">>>> BENCHMARK END <<<<")
