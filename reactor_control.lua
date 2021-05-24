
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
        
        term.setBackgroundColor(colors.blue)
        paintutils.drawFilledBox(1,0,51,3)
        term.setCursorPos(1,2)
        cWrite('Something went wrong!')
        
        term.setBackgroundColor(colors.black)
        printError('\n\n\n'..err..'\n')
    end
end

crashScreen(false,"This program is still under development. If you wish to preview the program, please use the indev branch. \n\nDO NOT USE INDEV VERSIONS ON A REACTOR THAT YOU DO NOT WISH TO LOOSE; SERIOUS DAMAGES MAY OCCUR FROM FAULTY INDEV COMMITS.")
