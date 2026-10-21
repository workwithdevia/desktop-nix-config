-- "Subtitler (lite) mod.lua" -- VLC Extension

-- Global variables:
subtitles_uri = nil -- "file:///D:/films/subtitles.srt"
output_dialogbox = false -- true or false
output_osd = true
osd_position = "top" -- "top-left", "top-right", "left", ...
-- UTF-8 charset is autodetected!
charset = "Windows-1250" -- nil or "UTF-8", "ISO-8859-2", ...
filename_extension = "srt" -- "eng.srt", "srt-vlc", ...
execute_commands = true -- true/false; [SKIP], [MUTE]

html1 = "<div align=\"center\" style=\"background-color:white;\"><a style=\"font-family:Verdana;font-size:36px;font-weight:bold;color:black;background-color:white;\">"
welcome = "Subtitler (lite) mod"
html2 = "</a></div>"

function descriptor()
	return {
		title = "Subtitler (lite) mod",
		version = "1.3",
		author = "lubozle",
		url = "https://addons.videolan.org/p/1154027/",
--		shortdesc = "Subtitles displayer", -- Commented out to show title instead of shortdesc in VLC menu.
		description = [[Subtitles displayer

>>> Subtitler (lite) mod <<< is VLC extension that displays subtitles on the screen in a playing video and/or in a dialog box. Now you can watch your film with 2 different subtitles. It can also SKIP unwanted scenes (intro, credits, commercials, unimportant scenes, ...) or MUTE selected scenes.
]], -- Then the first row of the text block in description is used as a short description.
		capabilities = {}
	}
end
function activate()
	create_dialog()
end
function deactivate()
end
function close()
		vlc.deactivate()
end
function meta_changed()
	return false
end

function create_dialog()
	dlg = vlc.dialog("Subtitler (lite) mod")
	if vlc.input.item() and Load_subtitles() then
		dlg:add_button("Refresh",input_events_handler, 1, 1, 1, 1)
		if vlc.object.vout()==nil then
			output_osd=false
			output_dialogbox = true
		end
		if output_dialogbox==true then 
			dialogbox_label(html1 .. #subtitles .. html2)
		end
		if output_osd==true  then
			channel1 = vlc.osd.channel_register()
		end
	else
		w1 = dlg:add_label(html1..welcome..html2.."<ol><li>Play a media first.</li><li>Activate this extension. You will see<br />a number of loaded subtitles<br />or just the [Refresh] button.</li><li>Keep the Enter key pressed down<br />or use some \"keypresser\".</li></ol>", 1, 1, 1, 1)
	end
end

function dialogbox_label(label_text)
	if w1 then dlg:del_widget(w1) end
	w1 = dlg:add_label(label_text, 1, 1, 1, 1)
	dlg:update()
end

function Load_subtitles()
	if subtitles_uri==nil then subtitles_uri=media_path(filename_extension) end
-- read file
	local s = vlc.stream(subtitles_uri)
	if s==nil then return false end
	data = s:read(500000)
	data = string.gsub( data, "\r", "")
	-- UTF-8 BOM detection
	if string.char(0xEF,0xBB,0xBF)==string.sub(data,1,3) then charset=nil end
-- parse data
	subtitles={}
	srt_pattern = "(%d%d):(%d%d):(%d%d),(%d%d%d) %-%-> (%d%d):(%d%d):(%d%d),(%d%d%d).-\n(.-)\n\n"
	for h1, m1, s1, ms1, h2, m2, s2, ms2, text in string.gmatch(data, srt_pattern) do
		if text=="" then text=" " end
		if charset~=nil then text=vlc.strings.from_charset(charset, text) end
		table.insert(subtitles,{format_time(h1, m1, s1, ms1), format_time(h2, m2, s2, ms2), text})
	end
	if #subtitles~=0 then return true else return false end
end
function format_time(h,m,s,ms) -- time to seconds
	return (tonumber(h)*3600+tonumber(m)*60+tonumber(s)+tonumber("."..ms))*1000000 -- VLC 3 microseconds fix
end
function media_path(extension)
	local media_uri = vlc.input.item():uri()
	media_uri = string.gsub(media_uri, "^(.*)%..-$","%1") .. "." .. extension
	vlc.msg.info(media_uri)
	return media_uri
end

-- SUBTITLING CORE:
subtitle=nil
function input_events_handler(var, old, new, data)
	local input = vlc.object.input()
	local actual_time = vlc.var.get(input, "time")
	
	if subtitle==nil then
		for i,v in pairs(subtitles) do
			if actual_time>=v[1] and actual_time<=v[2] then
--vlc.msg.info(actual_time.." << subtitle on")		
				subtitle=v
				--dlg:set_title(i.."/"..#subtitles.." Subtitler (lite)")
				--dlg:update()

				if execute_commands==true then
					command, text = string.match(subtitle[3], "^(%[.-%])(.*)$")
					if command=="[SKIP]" then
						--subtitle[3] = text
						vlc.var.set(input, "time", subtitle[2])
					elseif command=="[MUTE]" then
						mute_volume = vlc.volume.get()
						vlc.volume.set(0)
						--subtitle[3] = text
					end
				end

				if output_dialogbox==true then
					dialogbox_subtitle=string.gsub(subtitle[3],"\n","<br />")
					w1:set_text(html1..dialogbox_subtitle..html2)
					dlg:update()
--vlc.msg.info(dialogbox_subtitle)
				end
					--
				if output_osd==true then
					vlc.osd.message(subtitle[3],channel1,osd_position,5000000)
				end
				break
			end
		end
	else
		if actual_time<subtitle[1] or actual_time>subtitle[2] then
--vlc.msg.info(actual_time.." << subtitle off")
			subtitle=nil

			if mute_volume~=nil then 
				vlc.volume.set(mute_volume)
				mute_volume = nil
			end
	
			if output_dialogbox==true then
				--w1:set_text("")
				dialogbox_label("")
			end
			if output_osd==true then
				vlc.osd.message("",channel1)
			end
		else
			if output_osd==true then
				vlc.osd.message(subtitle[3],channel1,osd_position,5000000) -- OSD subtitle refresh
			end
		end
	end
end
