--[[
	Simple Reactor Tuner
	(c) 2023 Peekofwar
	v1.0
]]

local reactor = "fissionReactorLogicAdapter_2"
local old_burnrate
local r
local data = {
	coolant = 0,
	coolant_max = 0,
	coolant_lasttick = 0,
	coolant_rate = 0,
	burn_set = 0,
	burn = 0,
}
local display_exit = false

local function render()
	while true do
		term.setCursorPos(1,1) term.clear()
		if display_exit then
			print("")
			print("Are you sure you wish to exit?")
			print("                    [Y]es [N]o")
		else
			if not peripheral.isPresent(reactor) then
				printError("REACTOR DISCONNECTED")
			else
				print("Reactor burn rate: "..data.burn.."/"..data.burn_set)
				print("Coolant: "..data.coolant.."/"..data.coolant_max)
				print("Coolant rate: "..data.coolant_rate)
				local w,h=term.getSize()
				term.setCursorPos(1,h-4)
				print("Page Up/Down +/- 0.5")
				print("Up/Down Arrow +/- 0.01")
				print("[Home] Reset to original rate of "..old_burnrate)
				print("[Enter] Exit prompt")
			end
		end
		sleep(0.05)
	end
end
local function run()
	while true do
		if peripheral.isPresent(reactor) then
			local coolant = r.getCoolant().amount
			data.coolant_rate = coolant - data.coolant
			data.coolant = coolant
			data.coolant_max = r.getCoolantCapacity()
			data.burn_set = r.getBurnRate()
			data.burn = r.getActualBurnRate()
			data.burn_max = r.getMaxBurnRate()
		end
		sleep(0.05)
	end
end
local function input()
	while true do
		local event={os.pullEvent()}
		if display_exit then
			if event[1]=="key" then
				if event[2]==keys.y then
					term.clear()
					print("Program closed. Final burn rate is "..data.burn_set)
					return true
				elseif event[2]==keys.n then
					display_exit = false
				end
			end
		else
			if event[1]=="key" then
				local burnrate = r.getBurnRate()
				if event[2]==keys.down then
					r.setBurnRate(math.max(burnrate-0.01,0))
				elseif event[2]==keys.pageDown then
					r.setBurnRate(math.max(burnrate-0.5,0))
				elseif event[2]==keys.up then
					r.setBurnRate(math.min(burnrate+0.01,data.burn_max))
				elseif event[2]==keys.pageUp then
					r.setBurnRate(math.min(burnrate+0.5,data.burn_max))
				elseif event[2]==keys.home then
					r.setBurnRate(old_burnrate)
				elseif event[2]==keys.enter then
					display_exit = true
				end
			end
		end
	end
end

local pass, err = pcall(function()
	r=peripheral.wrap(reactor)
	if not peripheral.isPresent(reactor) then
		error("Reactor not found.",0)
	end
	old_burnrate = r.getBurnRate()
	
	print("Set burn rate: "..old_burnrate)
	sleep(1)
	parallel.waitForAny(input,run,render)
end)
if not pass then
	local pass2,err2 = pcall(function()
		r=peripheral.wrap(reactor)
		r.setBurnRate(old_burnrate)
	end)
	if pass2 then
		printError("Burn rate revertted to "..old_burnrate)
	elseif not old_burnrate then
		printError("Unable to save burn rate.")
	else
		printError("Unable to restore original burn rate of "..old_burnrate)
	end
	print("")
	error(err,0)
end
