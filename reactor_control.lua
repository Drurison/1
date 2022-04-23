local progInfo = {
	path = shell.getRunningProgram(),
	extension = shell.getRunningProgram():match("[^%.]*$"),
	name = string.sub(shell.getRunningProgram(),1,#shell.getRunningProgram()-#shell.getRunningProgram():match("[^%.]*$")-1),
	appName = 'ACI Fission Reactor Control',
	version = {
        string = '1.1.0a5',
	    date = 'April 23, 2022',
        build = 67
    },
	files = {
		config = string.sub(shell.getRunningProgram(),1,#shell.getRunningProgram()-#shell.getRunningProgram():match("[^%.]*$")-1)..'.cfg',
		os_settings = '/.settings',
	},
}

progInfo.help = {
    display = function()
        term.setCursorPos(1,1) term.clear()
        local w, h = term.getSize()
        local helpScreen = window.create(term.current(),1,1,w,h-1)
        local sw, sh = helpScreen.getSize()
        local lines = {
            {colors.yellow,progInfo.appName},
            "v"..progInfo.version.string.." build "..progInfo.version.build.." ("..progInfo.version.date..")",
            "",
            {colors.lightBlue,"Switches:"},
            " /dev   - Activates dev functions",
            " /debug - Triggers debugging keybinds",
            " /verbose - Triggers additional debug messages",
            " /voxtest - Opens the VOX test menu",
            " /test - Triggers temporary tests (if any)",
            "",
        -- "|                                                    |"
            {colors.lightBlue,"Changelong v1.1.0:"},
            " + Added reactor disconnect alarm state and message",
            "   (no longer a program stop-error).",
            " + Added alarm state for reactor damage.",
            " * Rewrote/rearranged core code to mitigate input",
            "   lag.",
            " * Updated VOX system to use a remote VOX system.",
            {colors.lightBlue,"Changelong v1.0.3:"},
            " * Changed reactor type string for Advanced",
            "   Peripherals 0.7r (peripheral proxy was removed)",
            {colors.lightBlue,"Changelong v1.0.2:"},
            " * Moved env.clear() below reactor data collection.",
            "   in an attempt to reduce potential flickering.",
            {colors.lightBlue,"Changelong v1.0.1:"},
            " + Added scrollable help screen",
            " + Added VOX sebtece for manual activation when",
            "   master alarm is active",
            " * Now checks statuses before hitting activate",
            " * Updated VOX lines (new pack version required)",
            " * Terminal now clears when exiting program",
            " * Activation is not blocked from terminal when an ",
            "   alarm is raised.",
            "",
            {colors.lightBlue,"Debugging hotkeys:"},
            " F9 - Triggers crash screen",
        }
        local scroll = 1
        local scrollMax = #lines-sh+1
        if #lines <= sh then scrollMax = 1 end
        while true do
            scroll = math.clamp(1,scrollMax,scroll)
            term.setCursorPos(1,h)

            term.setTextColor(colors.yellow)
            term.write("Use ")
            if scroll == 1 then term.setTextColor(colors.gray) end
            term.write("/\\")
            term.setTextColor(colors.yellow)
            if scroll == scrollMax then term.setTextColor(colors.gray) end
            term.write(" \\/")
            term.setTextColor(colors.yellow)
            term.write(" to scroll or press ENTER to quit.")

            helpScreen.setCursorPos(1,1)
            helpScreen.setTextColor(colors.white)
            helpScreen.clear()
            for i=scroll, sh+scroll do
                helpScreen.setTextColor(colors.white)
                if lines[i] == nil then break end
                if type(lines[i]) == "table" then
                    helpScreen.setTextColor(lines[i][1])
                    helpScreen.write(lines[i][2])
                else
                    helpScreen.write(lines[i])
                end
                local x,y = helpScreen.getCursorPos()
                helpScreen.setCursorPos(1,y+1)
            end
            helpScreen.setCursorPos(1,h)
            helpScreen.write(scroll..","..sh+scroll)
            local event, key = os.pullEvent("key")
            if key == keys.up then
                scroll = scroll-1
                term.setCursorPos(1,h)
            elseif key == keys.down then
                scroll = scroll+1
                term.setCursorPos(1,h)
            elseif key == keys.enter or key == keys.numPadEnter then break end
        end
        term.clear()
        error()
    end,
}
--[[ Program User Config
local program_settings, save_settings, load_settings
do
    local program_settings_default = {
        vox = {
            default_voice = "voice_legacy",
            modem_channel = 39934,
        },
        reactor_ID = nil,
        startup_scramActive,
        alarm_coolantMin = 10000,
        alarm_integrityMin = 100,
    }
    local function deepCopy(tab)
        --printError("-Function start")
        local a = {}
        for k, v in pairs(tab) do
            if type(v) == "table" then
                --print("Key: "..k.." = ".."( table )")
                a[k]=deepCopy(v)
            else
                --print("Key: "..k.." = "..tostring(v))
                a[k]=v
            end
        end
        --printError("--Function return")
        return a
    end
    local function verify(target,reference)
        if type(target) ~= "table" then return error("argument #1: expected table, got '"..type(target).."' instead!") end
        if type(reference) ~= "table" then return error("argument #2: expected reference table, got '"..type(reference).."' instead!") end
        local return_boolean = false
        for key,value in pairs(reference) do
            if target[key] == nil then
                printError("Key: "..key.." missing! Default: "..tostring(value))
                target[key] = reference[key]
                return_boolean = true
            elseif type(target[key]) == "table" then
                return_boolean = verify(target[key],reference[key]) or return_boolean
            end
        end
        return return_boolean
    end
    function save_settings()
        print("Writing local config file...")
        local file = fs.open(program_info.files.config,"w")
        file.write(textutils.serialise(program_settings_default))
        file.close()
    end
    function load_settings(forceDefault)
        if fs.exists(program_info.files.config) and not forceDefault then
            local file = fs.open(program_info.files.config,"r")
            program_settings = textutils.unserialise(file.readAll())
            file.close()
            local err = verify(program_settings,program_settings_default)
            if err then printError("Config file is incomplete") save_settings() end
        else
            program_settings = deepCopy(program_settings_default)
            save_settings()
        end
    end
end
--]]
function math.clamp(vMin,vMax,x)
	return math.max(math.min(x,vMax),vMin)
end
local function keepWidth(text,width)
    local outputString = ""
    for i=1, #width-#text do
        outputString = outputString.." "
    end
    return outputString
end
local function cWrite(text)
    local w, h = term.getSize()
	local cX,cY = term.getCursorPos()
    term.setCursorPos(math.floor(w / 2 - text:len() / 2 + .5), cY)
    io.write(text)
end

args = {
    commandLine = {...},
    scanCommandLine = function()
        for i=1, #args.commandLine do
            if string.lower(args.commandLine[i]) == "/dev" then args.dev = true end
            if string.lower(args.commandLine[i]) == "/debug" then args.debug = true end
            if string.lower(args.commandLine[i]) == "/help" then args.help = true end
            if string.lower(args.commandLine[i]) == "/?" then args.help = true end
            if string.lower(args.commandLine[i]) == "--help" then args.help = true end
            if string.lower(args.commandLine[i]) == "-h" then args.help = true end
            if string.lower(args.commandLine[i]) == "/voxtest" then args.voxTest = true end
            if string.lower(args.commandLine[i]) == "/test" then args.test = true end
            if string.lower(args.commandLine[i]) == "/verbose" then args.verbose = true end
            if string.lower(args.commandLine[i]) == "--verbose" then args.verbose = true end
            --dev.verbose(i, type(args.commandLine[i]), args.commandLine[i])
        end
        --sleep(1)
    end,
}
args.scanCommandLine()
if args.help then progInfo.help.display() end
dev = {
    print = function(...)
        if args.dev then
            print(...)
        end
    end,
    verbose = function(...)
        if args.verbose then
            print(...)
        end
    end,
    write = function(...)
        if args.dev then
            write(...)
        end
    end,
    sleep = function(...)
        if args.dev then
            sleep(...)
        end
    end,
    pos = function(x,y)
        if args.dev then
            term.setCursorPos(x,y)
        end
    end,
}
w, h = term.getSize()
function sPos(x, y, relative, r2)
	if relative then
		x1, y1 = term.getCursorPos()
		if not r2 then x = x1 + x end --Allows excluding X from relative
		y = y1 + y
	end
	return term.setCursorPos(x, y)
end
--	Progress bar (Requires 'sPos()')
function barMeter(x, y, width, items, completed, text, text2, barColor, backgroundColor, terminal)
    if not terminal then terminal = term.current() end
	--local percent = math.max(math.min(items / completed * 100,100),0)
	local percent = math.clamp(0,100,items / completed * 100)
	local oldTColor = terminal.getTextColor()
	local oldBColor = terminal.getBackgroundColor()
	local text2 = text2 or ""

    local current_terminal = term.current()
    term.redirect(terminal)
    
	sPos(x, y-1) if text ~= nil then paintutils.drawLine(x,y-1,x+width-1,y-1) sPos(x, y-1) write(text) sPos(x+width-#text2,y-1) write(text2) end
	terminal.setBackgroundColor(backgroundColor)
	paintutils.drawLine(x,y,width+x-1,y)
	terminal.setBackgroundColor(barColor)
	if percent/100*width-1 > 0 --[[and width >= x]] then
		paintutils.drawLine(x,y,percent/100*width+x-1,y)
	end
    terminal.setBackgroundColor(oldBColor)
    terminal.setTextColor(oldTColor)
	term.redirect(current_terminal)
end

gui = {
    windows = {},
    rootTerminal = term.current(),
    item = 1,
    pos = {1,1},
    mode = "basic",
    newLine = function(env)
        local x,y = env.getCursorPos()
        return env.setCursorPos(1,y+1)
    end,
    basic = {
        config = {
            colors = {
                selected = colors.black,
                selectedHighlight = colors.lightBlue,
                selectedHighlightDisabled = colors.lightGray,
                enabled = colors.white,
                enabledHighlight = colors.gray,
                disabled = colors.lightGray,
                disabledHighlight = colors.gray,
            },
            windows = {
                menuPos = {1,1,10,h},
                monitorPos = {11,1,w-10,h},
            },
        },
        draw = function(env)
            env.setCursorPos(1,1)
            env.setBackgroundColor(colors.gray)
            env.clear()
            for i=1, #gui.menus.main do
                if gui.item == i and gui.menus.main[i].enabled then
                    env.setTextColor(gui.basic.config.colors.selected)
                    env.setBackgroundColor(gui.basic.config.colors.selectedHighlight)
                elseif gui.item == i and not gui.menus.main[i].enabled then
                    env.setTextColor(gui.basic.config.colors.selected)
                    env.setBackgroundColor(gui.basic.config.colors.selectedHighlightDisabled)
                elseif gui.menus.main[i].enabled then
                    env.setTextColor(gui.basic.config.colors.enabled)
                    env.setBackgroundColor(gui.basic.config.colors.enabledHighlight)
                else
                    env.setTextColor(gui.basic.config.colors.disabled)
                    env.setBackgroundColor(gui.basic.config.colors.disabledHighlight)
                end
                env.clearLine()
                env.write(gui.menus.main[i].name.."\n")
                gui.newLine(env)
            end
            return
        end,
    },
    menus = {
        main = {
            {
                name = "Activate",
                enabled = true,
                run = function()
                    equipment.reactor.activate()
                    --vox.queue(vox_sequences.reactorActivated)
                    for i=1, #gui.menus.main do
                        if gui.menus.main[i].name == "Activate" then
                            gui.menus.main[i].enabled = false
                        elseif gui.menus.main[i].name == "Scram" then
                            gui.menus.main[i].enabled = true
                            --gui.item = i
                        end
                    end
                    dev.write("Activated!") dev.sleep(0.25)
                end,
            },
            {
                name = "Scram",
                enabled = false,
                run = function()
                    equipment.reactor.scram()
                    --vox.queue(vox_sequences.reactorDeactivated)
                    for i=1, #gui.menus.main do
                        if gui.menus.main[i].name == "Activate" then
                            gui.menus.main[i].enabled = true
                            --gui.item = i
                        elseif gui.menus.main[i].name == "Scram" then
                            gui.menus.main[i].enabled = false
                        end
                    end
                    dev.write("Deactivated!") dev.sleep(0.25)
                end,
            },
            {
                name = "Reset",
                enabled = false,
                run = function()
                    vox.playlist = {}
                    for i=1, #gui.menus.main do
                        if gui.menus.main[i].name == "Activate" then
                            gui.menus.main[i].enabled = true
                        elseif gui.menus.main[i].name == "Scram" then
                            gui.menus.main[i].enabled = false
                        elseif gui.menus.main[i].name == "Reset" then
                            gui.menus.main[i].enabled = false
                        end
                    end
                    systemMonitor.alarms.master = false
                    systemMonitor.alarms.masterAlarmed = false
                    systemMonitor.alarms.disconnected = false
                    systemMonitor.vars.forceCheck = true
                end,
            },
            {
                name = "Config",
                enabled = false,
                run = function()
                    
                end,
            },
            {
                name = "Exit",
                enabled = true,
                run = function()
                    if equipment.reactor.getStatus() then
                        printError('REACTOR IS ACTIVE; SCRAMMING...')
                        equipment.reactor.scram()
                    end
                    dev.write("Rainbow Dash is best pegasus!") dev.sleep(0.25)
                    quit()
                end,
            },
        },
    },
}
--3,1
systemMonitor = {
    vars = {
        forceCheck = true,
        isActive = false,
        isTempCritical = false,
        isDamaged = false,
        isNoFuel = true,
        isNoCoolant= false,
        isLowCoolant= false,
        isWasteFull = false,
        isSteamFull = false,
        warnFlash = false,
    },
    data = {},
    warnConfig = {
        setup = function()
            if peripheral.isPresent(peripheral.getName(equipment.reactor)) then
                systemMonitor.warnConfig.wasteFullOffset = equipment.reactor.getWasteCapacity() - systemMonitor.warnConfig.wasteFullOffset
                systemMonitor.warnConfig.steamFullOffset = equipment.reactor.getHeatedCoolantCapacity() - systemMonitor.warnConfig.steamFullOffset
            end
        end,
        wasteFullOffset = 500,
        steamFullOffset = 500,
        tempLimit = 1000,
        coolantMin = 10000,
        fuelMin = 1,
        integrityWarn = 100,
    },
    alarms = {
        master = false,
        masterAlarmed = false,
        radiation = false,
        radiation_CoolDown = 0,
        disconnected = false
    },
    thread_main = function()
        if args.voxTest then return end
        os.queueEvent("r.system_screen")
        while true do
            while not peripheral.isPresent(peripheral.getName(equipment.reactor)) or systemMonitor.alarms.disconnected do
                if not systemMonitor.alarms.disconnected then
                    for i=1, #gui.menus.main do
                        if gui.menus.main[i].name == "Activate" then
                            gui.menus.main[i].enabled = false
                        elseif gui.menus.main[i].name == "Scram" then
                            gui.menus.main[i].enabled = false
                        elseif gui.menus.main[i].name == "Reset" then
                            gui.menus.main[i].enabled = true
                        end
                    end
                end
                systemMonitor.alarms.master = true
                systemMonitor.alarms.disconnected = true
                term.redirect(gui.windows.monitor)
                gui.windows.monitor.clear()
                disconnect_warn_state = not disconnect_warn_state
                if disconnect_warn_state then 
                    term.setTextColor(colors.red)
                else
                    term.setTextColor(colors.white)
                end
                term.setCursorPos(1,4)
                cWrite(">>> !!! WARNING !!! <<<")
                term.setCursorPos(1,6)
                cWrite("Reactor diconnected from network!")
                term.setCursorPos(1,7)
                cWrite("Check reactor status immediately.")
                sleep(0.25)
                if peripheral.isPresent(peripheral.getName(equipment.reactor)) then equipment.reactor.scram() end
                term.redirect(gui.rootTerminal)
                --error("WARNING: Reactor diconnected from network!\n\nCheck reactor status immediately.",0)
            end
            pcall(function()
                systemMonitor.data.status = equipment.reactor.getStatus()

                systemMonitor.data.fuel = equipment.reactor.getFuel()
                systemMonitor.data.fuel_cap = equipment.reactor.getFuelCapacity()
                systemMonitor.data.fuel_percent = systemMonitor.data.fuel/systemMonitor.data.fuel_cap
                systemMonitor.data.waste = equipment.reactor.getWaste()
                systemMonitor.data.waste_cap = equipment.reactor.getWasteCapacity()
                systemMonitor.data.waste_percent = systemMonitor.data.waste/systemMonitor.data.waste_cap

                systemMonitor.data.coolant = equipment.reactor.getCoolant()
                systemMonitor.data.coolant = systemMonitor.data.coolant.amount
                systemMonitor.data.coolant_cap = equipment.reactor.getCoolantCapacity()
                systemMonitor.data.coolant_percent = systemMonitor.data.coolant/systemMonitor.data.coolant_cap
                systemMonitor.data.steam = equipment.reactor.getHeatedCoolant()
                systemMonitor.data.steam = systemMonitor.data.steam.amount
                systemMonitor.data.steam_cap = equipment.reactor.getHeatedCoolantCapacity()
                systemMonitor.data.steam_percent = systemMonitor.data.steam/systemMonitor.data.steam_cap
                systemMonitor.data.temp = equipment.reactor.getTemperature() -- Kelvin

                systemMonitor.data.damage = equipment.reactor.getDamagePercent()
            end)

            local env = gui.windows.monitor
            --sleep(1) os.queueEvent("system_interrupt")
            local w,h = env.getSize()
            local disconnect_warn_state = false

            local status = equipment.reactor.getStatus()

            local fuel = systemMonitor.data.fuel or -1
            local fuel_cap = systemMonitor.data.fuel_cap or -1
            local fuel_percent = systemMonitor.data.fuel_percent or -1
            local waste = systemMonitor.data.waste or -1
            local waste_cap = systemMonitor.data.waste_cap or -1
            local waste_percent = systemMonitor.data.waste_percent or -1

            local coolant = systemMonitor.data.coolant or -1
            local coolant_cap = systemMonitor.data.coolant_cap or -1
            local coolant_percent = systemMonitor.data.coolant_percent or -1
            local steam = systemMonitor.data.steam or -1
            local steam_cap = systemMonitor.data.steam_cap or -1
            local steam_percent = systemMonitor.data.steam_percent or -1
            local temp = systemMonitor.data.temp or -1 -- Kelvin

            local damage = systemMonitor.data.damage or -1
            
            if systemMonitor.alarms.master then
                
                if systemMonitor.data.status then
                    equipment.reactor.scram()
                    vox.queue(vox_sequences.manualIllAdvised)
                end
            end
            --error("Program under heavy rewrite...",0)

            --os.queueEvent("r.system_screen")
            --sleep(0.05)

        if systemMonitor.alarms.master and not systemMonitor.alarms.masterAlarmed then
            for i=1, #gui.menus.main do
                if gui.menus.main[i].name == "Activate" then
                    gui.menus.main[i].enabled = false
                elseif gui.menus.main[i].name == "Scram" then
                    gui.menus.main[i].enabled = false
                elseif gui.menus.main[i].name == "Reset" then
                    gui.menus.main[i].enabled = true
                end
            end 
        elseif not systemMonitor.alarms.masterAlarmed then
            if systemMonitor.vars.isActive and not status then
                for i=1, #gui.menus.main do
                    if gui.menus.main[i].name == "Activate" then
                        gui.menus.main[i].enabled = true
                    elseif gui.menus.main[i].name == "Scram" then
                        gui.menus.main[i].enabled = false
                    end
                end
                --os.queueEvent("system_interrupt")
                vox.queue(vox_sequences.reactorDeactivated)
                systemMonitor.vars.isActive = false
            elseif not systemMonitor.vars.isActive and status then
                for i=1, #gui.menus.main do
                    if gui.menus.main[i].name == "Activate" then
                        gui.menus.main[i].enabled = false
                    elseif gui.menus.main[i].name == "Scram" then
                        gui.menus.main[i].enabled = true
                        --gui.item = i
                    end
                end
                --os.queueEvent("system_interrupt")
                vox.queue(vox_sequences.reactorActivated)
                systemMonitor.vars.isActive = true
            end
        end
        if not systemMonitor.alarms.master then
            if systemMonitor.vars.isDamaged and math.floor(100-damage) >= systemMonitor.warnConfig.integrityWarn then
                systemMonitor.vars.isDamaged = false
            elseif math.floor(100-damage) < systemMonitor.warnConfig.integrityWarn and (status or systemMonitor.vars.forceCheck) then
                systemMonitor.vars.isDamaged = true
                --vox.queue(vox_sequences.damaged) dev.pos(11,1) dev.write('VOX damaged')
            end

            if systemMonitor.vars.isNoFuel and fuel > 0 then
                systemMonitor.vars.isNoFuel = false
            elseif fuel == 0 and (status or systemMonitor.vars.forceCheck) then
                systemMonitor.vars.isNoFuel = true
                vox.queue(vox_sequences.noFuel) dev.pos(11,1) dev.write('VOX noFuel')
            end

            if systemMonitor.vars.isNoCoolant and coolant > 0 then
                systemMonitor.vars.isNoCoolant = false
            elseif coolant == 0 and (status or systemMonitor.vars.forceCheck) then
                systemMonitor.vars.isNoCoolant = true
                vox.queue(vox_sequences.noCoolant) dev.pos(11,1) dev.write('VOX noCoolant')
            end

            if systemMonitor.vars.isLowCoolant and coolant > 0 then
                systemMonitor.vars.isLowCoolant = false
            elseif coolant < systemMonitor.warnConfig.coolantMin and (status or systemMonitor.vars.forceCheck) then
                systemMonitor.vars.isLowCoolant = true
                vox.queue(vox_sequences.noCoolant) dev.pos(11,1) dev.write('VOX noCoolant')
            end

            if systemMonitor.vars.isSteamFull and steam < steam_cap-500 then
                systemMonitor.vars.isSteamFull = false
            elseif steam >= steam_cap-500 and (status or systemMonitor.vars.forceCheck) then
                systemMonitor.vars.isSteamFull = true
                vox.queue(vox_sequences.overflowSteam) dev.pos(11,1) dev.write('VOX overflowSteam')
            end

            if systemMonitor.vars.isWasteFull and waste < waste_cap-500 then
                systemMonitor.vars.isWasteFull = false
            elseif waste >= waste_cap-500 and (status or systemMonitor.vars.forceCheck) then
                systemMonitor.vars.isWasteFull = true
                vox.queue(vox_sequences.overflowWaste) dev.pos(11,1) dev.write('VOX overflowWaste')
            end

            if systemMonitor.vars.isTempCritical and temp < 1000 then
                systemMonitor.vars.isTempCritical = false
            elseif temp >= 1000 and (status or systemMonitor.vars.forceCheck) then
                systemMonitor.vars.isTempCritical = true
                vox.queue(vox_sequences.highTemp) dev.pos(11,1) dev.write('VOX highTemp')
            end
        end

        if waste == waste_cap then
            systemMonitor.alarms.radiation = true
        end
        if systemMonitor.alarms.radiation and systemMonitor.alarms.radiation_CoolDown == 0 then
            intercom.playSound("aci.vox.voice_legacy.bizwarn")
            systemMonitor.alarms.radiation_CoolDown = 5
        elseif systemMonitor.alarms.radiation_CoolDown > 0 then
            systemMonitor.alarms.radiation_CoolDown = systemMonitor.alarms.radiation_CoolDown - 1
        end

        if status and (coolant == 0 or fuel == 0 or temp >= 1000 or steam >= steam_cap-500 or waste >= waste_cap-500 or math.floor(100-damage) < systemMonitor.warnConfig.integrityWarn) then
            equipment.reactor.scram()
        end
        if not systemMonitor.alarms.master and (coolant == 0 or fuel == 0 or temp >= 1000 or steam >= steam_cap-500 or waste >= waste_cap-500 or math.floor(100-damage) < systemMonitor.warnConfig.integrityWarn) then
            systemMonitor.alarms.master = true
        end
        --  600 K moderate
        -- 1000 K high
        -- 1200 K critical
        if systemMonitor.vars.forceCheck then systemMonitor.vars.forceCheck = false end
        --sleep(0.75)
        end
    end,
    thread_input = function()
        while true do
            local event = {os.pullEvent()}
            if event[1] == "key" then
                if event[1] == "key" then key_raw = event[2] end
                if key_raw then
                    if key_raw == keys.f9 and args.debug then error("Error screen test message") end
                    if key_raw == keys.down then
                        if gui.item+1 > #gui.menus.main then
                            gui.item = 1
                        else
                            gui.item = gui.item + 1
                        end
                    elseif key_raw == keys.up then
                        if gui.item-1 < 1 then
                            gui.item = #gui.menus.main
                        else
                            gui.item = gui.item - 1
                        end
                    elseif (key_raw == keys.enter or key_raw == keys.numPadEnter) and gui.menus.main[gui.item].enabled then
                        gui.menus.main[gui.item].run()
                    end
                end
                gui.basic.draw(gui.windows.menu)

                --sleep(0.1)
                key_raw = nil
                
            
            else-- event[1] == "r.system_screen" then
                --systemMonitor.draw_monitor(gui.windows.monitor)
               gui.basic.draw(gui.windows.menu)
            end
            if args.dev then 
                term.setCursorPos(1,h)
                term.clearLine() for i=1, #event do dev.write(tostring(event[i])..',') end
                if args.dev then
                    if event[1] == "mouse_click" then term.setCursorPos(event[3],event[4]) printError("X") end
                    if event[1] == "mouse_drag" then term.setCursorPos(event[3],event[4]) printError("X") end
                    if event[1] == "mouse_up" then term.setCursorPos(event[3],event[4]) printError("X") end
                end
            end
        end
    end,
    thread_monitor = function()
        gui.windows.menu = window.create(gui.rootTerminal,table.unpack(gui.basic.config.windows.menuPos))
        gui.windows.monitor = window.create(gui.rootTerminal,table.unpack(gui.basic.config.windows.monitorPos))
        gui.basic.draw(gui.windows.menu)
        if args.voxTest then return end
        while true do
            sleep(0.75)
            if not systemMonitor.alarms.disconnected then
                local env = gui.windows.monitor
                --sleep(1) os.queueEvent("system_interrupt")
                local w,h = env.getSize()
                local disconnect_warn_state = false

                local status = equipment.reactor.getStatus()

                local fuel = systemMonitor.data.fuel or -1
                local fuel_cap = systemMonitor.data.fuel_cap or -1
                local fuel_percent = systemMonitor.data.fuel_percent or -1
                local waste = systemMonitor.data.waste or -1
                local waste_cap = systemMonitor.data.waste_cap or -1
                local waste_percent = systemMonitor.data.waste_percent or -1

                local coolant = systemMonitor.data.coolant or -1
                local coolant_cap = systemMonitor.data.coolant_cap or -1
                local coolant_percent = systemMonitor.data.coolant_percent or -1
                local steam = systemMonitor.data.steam or -1
                local steam_cap = systemMonitor.data.steam_cap or -1
                local steam_percent = systemMonitor.data.steam_percent or -1
                local temp = systemMonitor.data.temp or -1 -- Kelvin

                local damage = systemMonitor.data.damage or -1

                env.clear()
                env.setCursorPos(2,2)

                if status then
                    env.setTextColor(colors.green)
                    env.write("Reactor Online") 
                else
                    env.setTextColor(colors.red)
                    env.write("Reactor Offline")
                end
                if systemMonitor.alarms.master then
                    if systemMonitor.vars.warnFlash then
                        env.setTextColor(colors.white)
                        env.setBackgroundColor(colors.black)
                    else
                        env.setTextColor(colors.white)
                        env.setBackgroundColor(colors.red)
                    end
                    env.setCursorPos(1,1)
                    env.clearLine()
                    term.redirect(env)
                    cWrite("!! ===>> ALARM <<=== !!")
                    term.redirect(gui.rootTerminal)
                    env.setBackgroundColor(colors.black)
                end
                env.setCursorPos(2,5)
                env.setTextColor(colors.white)
                --env.write("Temp: "..math.floor(temp).."K")
                if systemMonitor.vars.isTempCritical and systemMonitor.vars.warnFlash then
                    env.setTextColor(colors.red)
                    barMeter(2,6,w/2-2,temp,1000,"Temp: ",math.floor(temp).."K",colors.red,colors.gray,env)
                else
                    env.setTextColor(colors.white)
                    barMeter(2,6,w/2-2,temp,1000,"Temp: ",math.floor(temp).."K",colors.lightBlue,colors.gray,env)
                end
                if (systemMonitor.vars.isNoCoolant or systemMonitor.vars.isLowCoolant) and systemMonitor.vars.warnFlash then
                    env.setTextColor(colors.red)
                    barMeter(w/2+1,6,w/2-1,coolant,coolant_cap,"Coolant: ",math.floor(coolant).."mB",colors.red,colors.gray,env)
                else
                    env.setTextColor(colors.white)
                    barMeter(w/2+1,6,w/2-1,coolant,coolant_cap,"Coolant: ",math.floor(coolant).."mB",colors.lightBlue,colors.gray,env)
                end
                if systemMonitor.vars.isSteamFull and systemMonitor.vars.warnFlash then
                    env.setTextColor(colors.red)
                    barMeter(2,9,w/2-2,steam,steam_cap,"Steam: ",math.floor(steam).."mB",colors.red,colors.gray,env)
                else
                    env.setTextColor(colors.white)
                    barMeter(2,9,w/2-2,steam,steam_cap,"Steam: ",math.floor(steam).."mB",colors.lightBlue,colors.gray,env)
                end
                if systemMonitor.vars.isDamaged and systemMonitor.vars.warnFlash then
                    env.setTextColor(colors.red)
                    barMeter(w/2+1,9,w/2-1,100-damage,100,"Integrity: ",math.floor(100-damage).."%",colors.red,colors.gray,env)
                else
                    env.setTextColor(colors.white)
                    barMeter(w/2+1,9,w/2-1,100-damage,100,"Integrity: ",math.floor(100-damage).."%",colors.lightBlue,colors.gray,env)
                end
                if systemMonitor.vars.isNoFuel and systemMonitor.vars.warnFlash then
                    env.setTextColor(colors.red)
                    barMeter(2,12,w/2-2,fuel,fuel_cap,"Fuel: ",math.floor(fuel).."mB",colors.red,colors.gray,env)
                else
                    env.setTextColor(colors.white)
                    barMeter(2,12,w/2-2,fuel,fuel_cap,"Fuel: ",math.floor(fuel).."mB",colors.lightBlue,colors.gray,env)
                end
                if systemMonitor.vars.isWasteFull and systemMonitor.vars.warnFlash then
                    env.setTextColor(colors.red)
                    barMeter(w/2+1,12,w/2-1,waste,waste_cap,"Waste: ",math.floor(waste).."mB",colors.red,colors.gray,env)
                    else
                    env.setTextColor(colors.white)
                    barMeter(w/2+1,12,w/2-1,waste,waste_cap,"Waste: ",math.floor(waste).."mB",colors.lightBlue,colors.gray,env)
                end
                --[[local radiation = systemMonitor.getRad()
                env.setCursorPos(2,h)
                if radiation[1] then
                    env.setTextColor(colors.red)
                else
                    env.setTextColor(colors.green)
                end
                env.write("Radiation: "..(radiation[2]))]]
            end
            systemMonitor.vars.warnFlash = not systemMonitor.vars.warnFlash
        end
    end,
    draw_monitor = function(env)
    end,
}

listen = {
    fallbackTerminate = function()
        while true do
            local event = os.pullEvent("terminate")
            if event == "terminate" then
                if equipment.reactor then
                    equipment.reactor.scram()
                end
                error("Program terminated!",0)
            end
        end
    end,
}

equipment = {
    reactor = peripheral.find("fissionReactor"),
    radiationSensors = {},
    findReactor = function()
        local ap = peripheral.find("fissionReactor")
        local mk = peripheral.find("fissionReactorLogicAdapter")
        equipment.reactor = ap or mk
        return (ap or mk) and true or false, ap and "legacy" or mk and "mek" or "none"
    end,
    findSensors = function()
        local attached = peripheral.getNames()
        for i=1, #attached do
            if peripheral.getType(attached[i]) == "environmentDetector" then
                table.insert(equipment.radiationSensors,peripheral.wrap(attached[i]))
            end
        end
        if #equipment.radiationSensors > 0 then return true else radiationSensors = nil end
    end,
}
equipment.findSensors()
intercom = {
	list = {},
	findAll = function()
		local connectedPeripherals = peripheral.getNames()
        intercom.list = {}
		for i=1, #connectedPeripherals do
			if peripheral.getType(connectedPeripherals[i]) == "speaker" then
				table.insert(intercom.list,connectedPeripherals[i])
			end
		end
	end,
	playSound = function(soundName,vol,pitch)
        intercom.findAll()
		for i=1, #intercom.list do
			local device = peripheral.wrap(intercom.list[i])
			device.playSound(soundName,vol,pitch)
		end
	end,
}
intercom.findAll()
vox = {
    generate_message = function(input_string,voice_name,seperator)
        local word_table={}
        for str in string.gmatch(input_string, "([^"..(seperator or " ").."]+)") do
                table.insert(word_table, str)
        end

        --if type(t) ~= "table" then error("expected table, got '"..type(input).."' instead") end

        local message = {}
        
        for i=1, #word_table do
            message[i] = {}
            local word = word_table[i]
            local trailChar = string.sub(word,#word,#word)
            if trailChar == "." or trailChar == "!" or trailChar == "?" then
                message[i].pause = "1"
                word = string.sub(word,1,#word-1)
            elseif trailChar == "," or trailChar == ";" or trailChar == ":" then
                message[i].pause = "0.25"
                word = string.sub(word,1,#word-1)
            end
            message[i].word = word
        end
        --return message
        local request = { message = "VOX_REQUEST", }
        request.playlist = message
        if voice_name and #voice_name>0 then request.voice = voice_name end
        return request
    end,
    send_message = function(vox_message)
        local channel = --[[program_settings.vox.modem_channel or]] 39934
        local modem = peripheral.find("modem")
        modem.transmit(channel,channel,request)
    end,
}

startup = {
    
    start = function()
        term.setCursorBlink(true)
        print(progInfo.appName .. "\n"..progInfo.version.string, "build "..progInfo.version.build, "("..progInfo.version.date..")\n")
        sleep(1)
        local pass,result = equipment.findReactor()
        if equipment.reactor then
            print("Found: "..peripheral.getName(equipment.reactor))
            if result == "mek" then
                crashScreen(false,"ERROR: This program is outdated, and will not work with Mekanism's peripheral API.\n\nPlease update to a newer version.")
                equipment.reactor.scram()
                return
            end
        else
            crashScreen(false,"Couldn't find a reactor. Check connected cables and ensure the modem on the reactor is activated, then try again.")
            return
        end
        if equipment.radiationSensors then
            print("Found: "..#equipment.radiationSensors.." radiation sensors")
        end
        if equipment.reactor.getStatus() and not args.voxTest then
            equipment.reactor.scram()
            printError("REACTOR IS ACTIVE; SCRAMMING...")
            sleep(1)
        end
        print("Starting GUI...")
        sleep(0.5)
        term.setCursorBlink(false)
        
        local pass, err = pcall(startup.run)
        crashScreen(pass, err)
        if equipment.reactor.getStatus() then
            equipment.reactor.scram()
            printError("\nREACTOR IS ACTIVE; SCRAMMING...")
            sleep(1)
            --quit()
        end
    end,
    run = function()
        if multishell then
            local process_id = multishell.getCurrent()
            multishell.setTitle(process_id,"Reactor Control")
        end
        parallel.waitForAll(listen.fallbackTerminate,systemMonitor.thread_main,systemMonitor.thread_input,systemMonitor.thread_monitor)
    end,
}
local __termOrig = term.current()
crashScreen = function(...)
    term.redirect(__termOrig)
    local pass, err = ...
    if not pass and err then
        if err == nil then err = '( no error given )' end
        
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        
        term.setBackgroundColor(colors.red)
        paintutils.drawFilledBox(1,0,51,3)
        term.setCursorPos(1,2)
        cWrite('Reactor Control encoutnered a critical error!')
        
        term.setBackgroundColor(colors.black)
        printError('\n\n\n'..err..'\n')
    end
end
quit = function()
    if gui.rootTerminal then term.redirect(gui.rootTerminal) end
    term.setCursorPos(1,1)
    term.clear()
    error()
end

function vox.queue(message)
    --if not vox_sequences[message_name] then return error("Vox message '"..message_name.."' does not exist.") end
    local request = vox.generate_message(message)
    vox.send_message(request)
end
vox_sequences = {
	["reactorActivated"] = "deeuu: Fission reactor, activated.",
    ["reactorDeactivated"] = "deeuu: Fission reactor, deactivated.",
    ["overflowWaste"] = "bizwarn bizwarn: Warning: Waste overflow!",
    ["overflowSteam"] = "bizwarn bizwarn: Warning: Steam overflow!",
    ["noFuel"] = "buzwarn buzwarn: Warning: Fissil fuel depleted.",
    ["noCoolant"] = "bizwarn bizwarn: Warning: Insufficient reactor coolant!",
    ["highTemp"] = "bizwarn bizwarn: Warning: Reactor temperature critical!",
    ["manualIllAdvised"] = "deeuu: Warning: Reactor activation is ill advised. Please check control terminal.",
}

if args.voxTest then
    local menuEntries = {
        {
            name = "-- VOX TEST MODE --",
            enabled = true,
            run = function()
                intercom.playSound("aci.vox.voice_legacy.doop")
            end,
        },
        {
            name = "test vox reactorActivated",
            enabled = true,
            run = function()
                vox.queue(vox_sequences.reactorActivated)
            end,
        },
        {
            name = "test vox reactorDeactivated",
            enabled = true,
            run = function()
                vox.queue(vox_sequences.reactorDeactivated)
            end,
        },
        {
            name = "test vox overflowWaste",
            enabled = true,
            run = function()
                vox.queue(vox_sequences.overflowWaste)
            end,
        },
        {
            name = "test vox overflowSteam",
            enabled = true,
            run = function()
                vox.queue(vox_sequences.overflowSteam)
            end,
        },
        {
            name = "test vox noFuel",
            enabled = true,
            run = function()
                vox.queue(vox_sequences.noFuel)
            end,
        },
        {
            name = "test vox noCoolant",
            enabled = true,
            run = function()
                vox.queue(vox_sequences.noCoolant)
            end,
        },
        {
            name = "test vox highTemp",
            enabled = true,
            run = function()
                vox.queue(vox_sequences.highTemp)
            end,
        },
        {
            name = "test vox manualIllAdvised",
            enabled = true,
            run = function()
                vox.queue(vox_sequences.manualIllAdvised)
            end,
        },
        {
            name = "clear queue",
            enabled = true,
            run = function()
                vox.playlist = {}
            end,
        },
        {
            name = "Play sound...",
            enabled = true,
            run = function()
                write('Enter sound name> ')
                intercom.playSound(read())
            end,
        },
        {
            name = "Exit",
            enabled = true,
            run = function()
                if equipment.reactor.getStatus() then
                    printError('REACTOR IS ACTIVE; SCRAMMING...')
                    equipment.reactor.scram()
                end
                dev.write("Rainbow Dash is best pegasus!") dev.sleep(0.25)
                error()
            end,
        },
    }
    gui.basic.config.windows.menuPos = {1,1,30,h}
    gui.menus.main = menuEntries
    sleep(1)
end
term.clear()
term.setCursorPos(1,1)
startup.start()
