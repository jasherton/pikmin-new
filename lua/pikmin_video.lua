VideoFrame = VideoFrame or nil

local function PikminVideoTest(ply, cmd, args)
	local w, h = surface.ScreenWidth(), surface.ScreenHeight()
	
	if VideoFrame then
		VideoFrame:Remove()
		VideoFrame = nil
	end
	
	if not args[1] then return end
	
	local browser = vgui.Create("DHTML")
	browser:Dock(FILL)
	browser:SetAllowLua(true)
	browser:AddFunction("console","destroy",function()
		VideoFrame:Remove()
		VideoFrame = nil
	end)
	browser:SetHTML([[
	
	<div style="height:100%; overflow:hidden">
	
	<div id="player"></div>
	
	<script>
	var tag = document.createElement('script');

	tag.src = "https://www.youtube.com/iframe_api";
	var firstScriptTag = document.getElementsByTagName('script')[0];
	firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
	
	var player;
	var ytcontrol;
	function onYouTubeIframeAPIReady() {
	player = new YT.Player("player", {
		width: "100%",
		height: "120%",
		videoId: "]]..args[1]..[[",
		events: {
		"onReady": onPlayerReady,
		"onStateChange": onPlayerStateChange,
		"onError": onPlayerError,
		}
	});
	player.g.style.marginTop = "-60px";
	player.g.setAttribute("allow","accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture");
	player.g.setAttribute("scrolling","no");
	player.g.setAttribute("allowfullscreen","");
	}
	function onPlayerReady(event) {
		event.target.playVideo();
		ytcontrol = event.target;
	}
	
	function onPlayerStateChange(event) {
		if (event.data == 0) {
			console.destroy();
		}
	}
	
	function onPlayerError(event) {
		console.destroy();
	}

	function changeVolume(vol) {
		ytcontrol.setVolume(vol);
	}
	</script>
	
	<div style="width: 100%;height: 100%;position: absolute;z-index: 1000;top: 0;left: 0;"></div>
	</div>
	
	]])
	
	--browser:SetHTML([[
	--<div style="height:100%; overflow:hidden">
	--<iframe style="width: 100%; height: 130%; margin-top: -60px"
	--src="https://www.youtube.com/embed/nxVGbcnXy28?autoplay=1&modestbranding=1&controls=0&disablekb=1&rel=0&autohide=0"
	--allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
	--frameborder="0" scrolling="no" allowfullscreen></iframe>
	--</div>
	--<div style="width: 100%;height: 100%;position: absolute;z-index: 1000;top: 0;left: 0;"></div>
	--]])
	
	browser:SetAlpha(0)
	browser:SetMouseInputEnabled(false)
	
	VideoFrame = browser
end
concommand.Add("pikmin_video", PikminVideoTest)

hook.Add("PreDrawHUD", "DrawPikminVideo", function()
	if VideoFrame then
		cam.Start2D()
		draw.NoTexture()
		surface.SetDrawColor(0,0,0,255)
		local w,h = surface.ScreenWidth(), surface.ScreenHeight()
		surface.DrawRect(0,0,w,h)
		local mat = VideoFrame:GetHTMLMaterial()
		if not mat then cam.End2D() return end
		surface.SetMaterial(mat)
		surface.SetDrawColor(255,255,255,255)
		surface.DrawTexturedRectUV(0,0,w,h,0,0.025,w/mat:Width(),h/mat:Height())
		cam.End2D()
	end
end)