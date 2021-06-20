local function cWrite(text)
    local w, h = term.getSize()
	local cX,cY = term.getCursorPos()
    term.setCursorPos(math.floor(w / 2 - text:len() / 2 + .5), cY)
    io.write(text)
end
crashScreen = function(...)
    local pass, err = ...
    if not pass and err then
        if err == nil then err = '( no error given )' end
        
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        
        term.setBackgroundColor(colors.red)
        paintutils.drawFilledBox(1,0,51,3)
        term.setCursorPos(1,2)
        cWrite('TURBINE CONTROL ERROR')
        
        term.setBackgroundColor(colors.black)
        printError('\n\n\n'..err..'\n')
    end
end

crashScreen(false,"Tubrine program does not yet exist.")
