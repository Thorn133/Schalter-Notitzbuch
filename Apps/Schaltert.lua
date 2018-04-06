--------------------------------------------------------------------------------
local model, config, pages, rows, columns, fonts, frames, texts, formID, timeB4, timeB5
local windows = 2
local fontOptions = {"Mini", "Normal", "Bold", "Maxi"}
local fontConstants = {FONT_MINI, FONT_NORMAL, FONT_BOLD, FONT_MAXI}
local frameForms = {}
local defaultText = ""
local folder = "Apps/Modelle/"
local extension = ".txt"
local version = "1.2"
local debugmem =0
local mem = 0

--------------------------------------------------------------------------------
local function showPage(window)
	local r,g,b   = lcd.getBgColor()
	local startX  = 0
	local startY  = 1
	local offset  = 0
	local border  = 2
	local font    = fontConstants[fonts[window]]
	local height  = lcd.getTextHeight(font, "|") + border*2
	local rows    = rows[window]
	local columns = columns[window]
	local texts   = texts[window]
	
	if (r+g+b)/3 > 128 then
	    r,g,b = 0,0,0
	else
	    r,g,b = 255,255,255
	end
	
	lcd.setColor(r,g,b)
	
	for j=1, columns do
		local width = 0
		
		for i=1, rows do
			local currentWidth = lcd.getTextWidth(font, texts[i][j]) + border*2
			if (width < currentWidth) then
				width = currentWidth
			end
		end 
		
		if (j > 1) then
			local x = startX+offset
			if (frames[window]) then
				lcd.drawLine(x, startY, x, startY+height*rows)
			end
		end		
		
		for i=1, rows do
			lcd.drawText(startX+offset+border, startY+height*(i-1)+border, texts[i][j], font)
		end
		
		offset = offset + width
	end
	
	for i=1, rows do
		if (i > 1) then
			local y = startY+height*(i-1)
			if (frames[window]) then
				lcd.drawLine(startX, y, startX+offset, y)
			end
		end
	end
	
	if (frames[window]) then
		lcd.drawRectangle(startX, startY, offset+1, height*rows+1)
	end
end

---------------------------------------------------------------------------------
local function showPage1()
	return showPage(1)
end

---------------------------------------------------------------------------------
local function showPage2()
	return showPage(2)
end

---------------------------------------------------------------------------------
local function setupForm1()
	for w=1, windows do		
		form.addRow(1)
		form.addLabel({label = "Fenster "..w, font=FONT_BOLD})
		
		form.addRow(2)
		form.addLabel({label = "Zeilen", width=200})
		form.addIntbox(rows[w], 1, 10, 2, 0, 1, function(value)
			if (rows[w] < value) then
				for i=rows[w]+1, value do
					texts[w][i] = {}
					for j=1, columns[w] do
						texts[w][i][j] = defaultText
						system.pSave("text."..w.."."..i.."."..j, defaultText)
					end
				end
			else
				for i=value+1, rows[w] do
					texts[w][i] = nil
					for j=1, columns[w] do
						system.pSave("text."..w.."."..i.."."..j, nil)
					end
				end
			end
		
			rows[w] = value
			system.pSave("row."..w, value)
		end)
		
		form.addRow(2)
		form.addLabel({label = "Spalten", width=200})
		form.addIntbox(columns[w], 1, 10, 2, 0, 1, function(value)
			if (columns[w] < value) then
				for i=1, rows[w] do
					for j=columns[w]+1, value do
						texts[w][i][j] = defaultText
						system.pSave("text."..w.."."..i.."."..j, defaultText)
					end
				end
			else
				for i=1, rows[w] do
					for j=value+1, columns[w] do
						texts[w][i][j] = nil
						system.pSave("text."..w.."."..i.."."..j, nil)
					end
				end
			end

			columns[w] = value
			system.pSave("column."..w, value)
		end)
		
		form.addRow(2)
		form.addLabel({label = "Schriftart", width=200})
		form.addSelectbox(fontOptions, fonts[w], false, function(value)
			fonts[w] = value
			system.pSave("font."..w, value)
		end)
		
		form.addRow(2)
		form.addLabel({label = "Umrandung", width=275})
		frameForms[w] = form.addCheckbox(frames[w], function(value)
			 frames[w] = not value
			 system.pSave("frame."..w, not value and 1 or 0)
			 form.setValue(frameForms[w], not value) 
		end)
		
		form.addSpacer(1, 7)
	end
	
	form.addRow(1)
	form.addLabel({label = "Speichern / Laden", font=FONT_BOLD})
	
	form.addRow(2)
  form.addLabel({label = "Name", width=200})
	form.addTextbox(config, 63, function(value)
		config = value
		system.pSave("config", value)
		form.setButton(4, "S", config:len() > 0 and ENABLED or DISABLED)
		form.setButton(5, "L", config:len() > 0 and ENABLED or DISABLED)
	end)
	
	form.addRow(1)
	form.addLabel({label="Powered by Thorn - v."..version, font=FONT_MINI, alignRight=true})
end

---------------------------------------------------------------------------------
local function setupFormTable(window)
	local rows = rows[window]
	local columns = columns[window]
	local texts = texts[window]

	for i=1, rows do
		if (i > 1) then
			form.addSpacer(1, 7)
		end
		
		form.addRow(1)
		form.addLabel({label = "Zeile "..i, font=FONT_BOLD})
		local row = texts[i]
	
		for j=1, columns do
			form.addRow(2)
			form.addLabel({label = "Spalte "..j, width=200})
			form.addTextbox(row[j], 63, function(value)				
				row[j] = value
				system.pSave("text."..window.."."..i.."."..j, value)
			end)
		end
	end
end

---------------------------------------------------------------------------------
local function setupForm2()
	setupFormTable(1)
end

---------------------------------------------------------------------------------
local function setupForm3()
	setupFormTable(2)
end

---------------------------------------------------------------------------------
local function setupForm(id)
	formID = id
	
	if (formID == 1) then
		setupForm1()
	elseif (formID == 2) then
		setupForm2()
	elseif (formID == 3) then
		setupForm3()
	end
	
	form.setButton(1, "O", formID == 1 and HIGHLIGHTED or ENABLED)
	form.setButton(2, "1", formID == 2 and HIGHLIGHTED or ENABLED)
	form.setButton(3, "2", formID == 3 and HIGHLIGHTED or ENABLED)
	
	if (formID == 1) then
		form.setButton(4, "S", timeB4 and HIGHLIGHTED or config:len() > 0 and ENABLED or DISABLED)
	  form.setButton(5, "L", timeB5 and HIGHLIGHTED or config:len() > 0 and ENABLED or DISABLED)
	else
		form.setButton(4, ":up",   timeB4 and HIGHLIGHTED or ENABLED)
		form.setButton(5, ":down", timeB5 and HIGHLIGHTED or ENABLED)
	end
end

---------------------------------------------------------------------------------
local function toBytes(text)
	local result = ""
	local sign, id
	for i=1, text:len() do
		sign = text:sub(i, i)
		id   = sign:byte()
		if (id < 32 or id > 126) then
			sign = "["..id.."]"
		end
		result = result..sign
	end
	return result
end

---------------------------------------------------------------------------------
local function toString(bytes)
	local result = ""
	local offset = 0
	local limit  = bytes:len()
	local index, sign
	for i=1, limit do
		index = i + offset
		if (index > limit) then
			break
		end
		
		sign = bytes:sub(index, index)
		if (sign == "[") then
			sign   = bytes:sub(index):match("%[(%d+)%]")
			offset = offset + sign:len() + 1
			sign   = string.char(tonumber(sign))
		end
		result = result..sign
	end
	return result
end

---------------------------------------------------------------------------------
local function saveConfig()
	if (config:len() > 0) then
		local file = io.open(folder..config..extension, "w+")
		if (file) then
			local row = ""
			local column = ""
			local font = ""
			local frame = ""
			local text = ""
			local space = " "
			local line = "\n"
			
			for w=1, windows do
				if (w > 1) then
					row    = row..space
					column = column..space
					font   = font..space
					frame  = frame..space
					text   = text..space
				end
			
				row    = row..rows[w]
				column = column..columns[w]
				font   = font..fonts[w]
				frame  = frame..(frames[w] and 1 or 0)
				
				for i=1, rows[w] do
					if (i > 1) then
						text = text..space
					end
					for j=1, columns[w] do
						if (j > 1) then
							text = text..space
						end
						text = text.."\""..toBytes(texts[w][i][j]).."\""
					end
				end
			end	
					
			io.write(file, row..line)
			io.write(file, column..line)
			io.write(file, text..line)
			io.write(file, font..line)
			io.write(file, frame..line)
			io.close(file)
			
			config = ""		
			system.pSave("config", config)
			
			saved = system.getTimeCounter()
		end
	end
end

---------------------------------------------------------------------------------
local function loadConfig()
	if (config:len() > 0) then		
		local file = io.open(folder..config..extension, "r")
		if (file) then
			local row = {}
			local column = {}
			local font = {}
			local frame = {}
			local text = {}
			local count = 0
			local line, index
			
			repeat
				line = io.readline(file, true)
				if (not line) then
					break
				end
				
				count = count + 1
				index = 0
				
				if (count == 1) then
					for value in line:gmatch("%d+") do
						index = index + 1
						row[index] = tonumber(value)
					end
				elseif (count == 2) then
					for value in line:gmatch("%d+") do
						index = index + 1
						column[index] = tonumber(value)
					end
				elseif (count == 3) then
					index = index + 1
					local i,j = 1,1
					for value in line:gmatch("\"([^\"]*)\"") do
						if (not text[index]) then
							text[index] = {}
						end
						
						if (not text[index][i]) then
							text[index][i] = {}
						end
						
						text[index][i][j] = toString(value)
						
						j = j + 1
						if (j > column[index]) then
							j = 1
							i = i + 1
							
							if (i > row[index]) then
								i = 1
								index = index + 1
							end
						end
					end
					index = index - 1
				elseif (count == 4) then	
					for value in line:gmatch("%d+") do
						index = index + 1
						font[index] = tonumber(value)
						
						if (font[index] == 5) then
							font[index] = 4
						end
					end
				elseif (count == 5) then	
					for value in line:gmatch("%d+") do
						index = index + 1
						frame[index] = tonumber(value) == 1 and true or false
					end
				end
				
				if (index ~= windows) then
					io.close(file)
					return
				end
			until (count >= 5)
			
			if (count < 1) then
				for w=1, windows do
					row[w] = 2
				end
			end
			
			if (count < 2) then
				for w=1, windows do
					column[w] = 2
				end
			end
			
			if (count < 3) then
				for w=1, windows do
					text[w] = {}
					for i=1, row[w] do
						text[w][i] = {}
						for j=1, column[w] do
							text[w][i][j] = defaultText
						end
					end
				end
			end
			
			if (count < 4) then
				for w=1, windows do
					font[w] = 1
				end
			end
			
			if (count < 5) then
				for w=1, windows do
					frame[w] = true
				end
			end
			
			for w=1, windows do
				system.pSave("row."..w, row[w])
				system.pSave("column."..w, column[w])
				system.pSave("font."..w, font[w])
				system.pSave("frame."..w, frame[w] and 1 or 0)
				
				for i=1, row[w] do
					for j=1, column[w] do
						system.pSave("text."..w.."."..i.."."..j, text[w][i][j])
					end
				end
			end

			rows = row
			columns = column
			fonts = font
			frames = frame
			texts = text
			
			config = ""			
			system.pSave("config", config)
		
			io.close(file)
			loaded = system.getTimeCounter()
		end
	end
end

---------------------------------------------------------------------------------
local function getFocusedEntry(window)
	local line    = form.getFocusedRow()
	local rows    = rows[window]
	local columns = columns[window]
	local row     = math.ceil(line / (columns + 2))
	local column  = line % (columns + 2) - 1
	
	return row, column
end

---------------------------------------------------------------------------------
local function setFocusedEntry(window, row, column)
	local columns = columns[window]	
	local line    = (row - 1) * (columns + 2) + (column > 0 and column + 1 or 0)

	form.setFocusedRow(line)
end

---------------------------------------------------------------------------------
local function getNextIndex(size, index, back)
	return (back and index - 2 or index) % size + 1
end

---------------------------------------------------------------------------------
local function moveLine(window, back)
	local row, column = getFocusedEntry(window)
	local rows        = rows[window]
	local columns     = columns[window]
	local texts       = texts[window]
	local index
	
	if (column < 1) then
		index = getNextIndex(rows, row, back)
		texts[index], texts[row] = texts[row], texts[index]
		setFocusedEntry(window, index, column)
	else
		index = getNextIndex(columns, column, back)	
		for i=1, rows do
			texts[i][index], texts[i][column] = texts[i][column], texts[i][index]
		end
		setFocusedEntry(window, row, index)
	end
end

---------------------------------------------------------------------------------
local function keyForm(key)
	if (key == KEY_1 and formID ~= 1) then
		form.reinit(1)
	elseif (key == KEY_2 and formID ~= 2) then
		form.reinit(2)
	elseif (key == KEY_3 and formID ~= 3) then
		form.reinit(3)
	elseif (key == KEY_4) then
		if (formID == 1) then
			saveConfig()
		else
			moveLine(formID - 1, true)
		end
		
		form.reinit(formID)
	elseif (key == KEY_5) then
		form.preventDefault()
		
		if (formID == 1) then
			loadConfig()
		else
			moveLine(formID - 1)
		end
		
		form.reinit(formID)
	end
end

---------------------------------------------------------------------------------
local function loop()
	if (timeB4 or timeB5) then
		local time  = system.getTimeCounter()
		local limit = 1000
		if (timeB4 and time - timeB4 > limit) then
			timeB4 = nil
			form.setButton(4, formID == 1 and "S" or ":up", formID ~= 1 and ENABLED or config:len() > 0 and ENABLED or DISABLED)
		end
		
		if (timeB5 and time - timeB5 > limit) then
			timeB5 = nil
			form.setButton(5, formID == 1 and "L" or ":down", formID ~= 1 and ENABLED or config:len() > 0 and ENABLED or DISABLED)
		end
	end
	debugmem = math.modf(collectgarbage('count'))
	if (mem < debugmem) then
		mem = debugmem
		print("max Storage: "..debugmem.."K")
	end
end

---------------------------------------------------------------------------------
local function init()
	pages = {showPage1, showPage2}
	model = system.getProperty("Model") or ""	
	config = system.pLoad("config", "")	
	rows = {}
	columns = {}
	fonts = {}
	frames = {}
	texts = {}
	
	for w=1, windows do	
		local r = system.pLoad("row."..w, 2)
		local c = system.pLoad("column."..w, 2)
		
		local win = {}
		for i=1, r do
			local row = {}
			for j=1, c do
					row[j] = system.pLoad("text."..w.."."..i.."."..j, defaultText)
			end
			win[i] = row
		end
		texts[w] = win
		rows[w] = r
		columns[w] = c
		fonts[w] = system.pLoad("font."..w, 1)
		frames[w] = system.pLoad("frame."..w, 1) == 1 and true or false
	end
	
	system.registerForm(1, MENU_APPS, "Schalterbelegung", setupForm, keyForm)
	for w=1, windows do
		system.registerTelemetry(w, "Schalterbelegung "..w.." - "..model, 4, pages[w])   -- full size Window
	end
end
--------------------------------------------------------------------------------

return {init=init, loop=loop, author="Thorn", version=version, name="Schalter"}