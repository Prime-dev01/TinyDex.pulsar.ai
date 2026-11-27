--[[
	PRIMEz SafeSpy — crash-safe passive environment logger (PRIMEz Studios)
	Part of the TinyDex tool suite. Loads standalone or from the TinyDex Tools tab.

	DESIGN RULES (why this never crashes the client):
	  • LISTENS ONLY. No hookfunction / hookmetamethod / __namecall hooks.
	  • No getgc() heap walks, no getconnections(), no executor internals.
	  • UI parents to PlayerGui only (SafeBoot rule) — never CoreGui/gethui.
	  • Every external callback wrapped in pcall, every buffer capped.

	WHAT IT LOGS (all via normal Roblox APIs):
	  remote     — RemoteEvent.OnClientEvent traffic (incoming, with arguments)
	  log        — LogService output (game scripts' print/warn/error)
	  instance   — DescendantAdded/Removed stream (spawns, anti-cheat, backdoors)
	  click      — ClickDetector.MouseClick / ProximityPrompt.Triggered

	PULSAR / terminal integration:
	  _G.PRIMEZ_SAFESPY.query(kind, n) -> table of recent entries
	  _G.PRIMEZ_SAFESPY.entries        -> the full ring buffer
	  e.g. run:  print(table.concat(_G.PRIMEZ_SAFESPY.query("remote", 10), "\n"))
]]

local RUN_ID = tostring(os.clock())
local MAX_ENTRIES = 300
local MAX_REMOTE_WATCH = 150

local Players          = game:GetService("Players")
local LogService       = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
if not plr then
	while not plr do
		plr = Players.LocalPlayer
		if not plr then task.wait(0.2) end
	end
end

-- ── SafeBoot container: PlayerGui only, destroy an old instance first ──────
local playerGui = plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui", 10)
if not playerGui then
	warn("[SafeSpy] no PlayerGui — cannot start")
	return
end
pcall(function()
	for _, existing in ipairs(playerGui:GetChildren()) do
		if existing.Name == "PRIMEz_SafeSpy" then existing:Destroy() end
	end
end)

-- ── Ring buffer + state ────────────────────────────────────────────────────
local entries  = {}   -- { kind = "remote"|"log"|"instance"|"click", text = str, at = os.time() }
local enabled  = true
local filter   = "ALL"  -- ALL | remote | log | instance | click
local watchers = 0
local stats    = { remote = 0, log = 0, instance = 0, click = 0 }

local function push(kind, text)
	if not enabled then return end
	stats[kind] = (stats[kind] or 0) + 1
	entries[#entries + 1] = { kind = kind, text = tostring(text), at = os.time() }
	if #entries > MAX_ENTRIES then table.remove(entries, 1) end
end

local function safeConnect(signal, fn)
	local ok, conn = pcall(function() return signal:Connect(fn) end)
	if ok and conn then return conn end
	return nil
end

local function argText(...)
	local parts = {}
	for i = 1, luaSelect("#", ...) do
		local v = tostring(luaSelect(i, ...))
		if #v > 120 then v = v:sub(1, 120) .. "…" end
		parts[#parts + 1] = v
	end
	return table.concat(parts, ", ")
end

-- ── UI ─────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "PRIMEz_SafeSpy"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = playerGui

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 480, 0, 340)
win.Position = UDim2.new(0.5, -240, 0.5, -170)
win.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local winStroke = Instance.new("UIStroke", win)
winStroke.Color = Color3.fromRGB(72, 48, 125)
winStroke.Thickness = 1.5

-- drag (title bar)
do
	local dragging, dragStart, startPos = false, nil, nil
	local title = Instance.new("Frame")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(20, 19, 34)
	title.BorderSizePixel = 0
	title.Parent = win
	Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)
	local ttl = Instance.new("TextLabel")
	ttl.Size = UDim2.new(1, -150, 1, 0)
	ttl.Position = UDim2.fromOffset(10, 0)
	ttl.BackgroundTransparency = 1
	ttl.Font = Enum.Font.GothamBold
	ttl.TextSize = 12
	ttl.TextXAlignment = Enum.TextXAlignment.Left
	ttl.TextColor3 = Color3.fromRGB(160, 83, 255)
	ttl.Text = "◆ PRIMEz SafeSpy — passive env logger"
	ttl.Parent = title
	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = win.Position
		end
	end)
	title.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local feed = Instance.new("ScrollingFrame")
feed.Size = UDim2.new(1, -12, 1, -66)
feed.Position = UDim2.fromOffset(6, 34)
feed.BackgroundTransparency = 1
feed.BorderSizePixel = 0
feed.ScrollBarThickness = 4
feed.CanvasSize = UDim2.new(0, 0, 0, 0)
feed.Parent = win
local feedLayout = Instance.new("UIListLayout", feed)
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.Padding = UDim.new(0, 2)
feedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	feed.CanvasSize = UDim2.new(0, 0, 0, feedLayout.AbsoluteContentSize.Y + 6)
end)

local KIND_COLOR = {
	remote   = Color3.fromRGB(77, 224, 143),
	log      = Color3.fromRGB(120, 180, 255),
	instance = Color3.fromRGB(255, 200, 100),
	click    = Color3.fromRGB(200, 120, 255),
}

local function visible(e)
	return filter == "ALL" or e.kind == filter
end

local function renderEntry(e)
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -6, 0, 14)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.Code
	row.TextSize = 10
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextTruncate = Enum.TextTruncate.AtEnd
	row.TextColor3 = KIND_COLOR[e.kind] or Color3.fromRGB(200, 200, 210)
	row.Text = "[" .. string.sub(e.kind, 1, 3):upper() .. "] " .. e.text
	row.LayoutOrder = #feed:GetChildren()
	row.Parent = feed
	row.Visible = visible(e)
	return row
end

local function refreshFeed()
	for _, child in ipairs(feed:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end
	for i, e in ipairs(entries) do
		if i > #entries - 120 then -- render the newest 120 only
			renderEntry(e)
		end
	end
	feed.CanvasPosition = Vector2.new(0, feedLayout.AbsoluteContentSize.Y)
end

-- ── buttons ────────────────────────────────────────────────────────────────
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -12, 0, 24)
btnRow.Position = UDim2.new(0, 6, 1, -28)
btnRow.BackgroundTransparency = 1
btnRow.Parent = win
local btnLayout = Instance.new("UIListLayout", btnRow)
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 5)

local function makeBtn(text, accent)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 74, 1, 0)
	b.BackgroundColor3 = accent and Color3.fromRGB(83, 43, 139) or Color3.fromRGB(28, 24, 43)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 9
	b.TextColor3 = Color3.fromRGB(235, 232, 248)
	b.Text = text
	b.Parent = btnRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local pauseBtn = makeBtn("⏸ PAUSE", false)
pauseBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	pauseBtn.Text = enabled and "⏸ PAUSE" or "▶ RESUME"
end)

local clearBtn = makeBtn("CLEAR", false)
clearBtn.MouseButton1Click:Connect(function()
	entries = {}
	refreshFeed()
end)

local copyBtn = makeBtn("COPY LOG", true)
copyBtn.MouseButton1Click:Connect(function()
	local lines = {}
	for _, e in ipairs(entries) do
		if visible(e) then lines[#lines + 1] = "[" .. e.kind .. "] " .. e.text end
	end
	local blob = table.concat(lines, "\n")
	local ok = pcall(function() setclipboard(blob) end)
	if not ok then ok = pcall(function() toclipboard(blob) end) end
	copyBtn.Text = ok and "COPIED ✔" or (#lines .. " rows")
	task.delay(1.4, function() copyBtn.Text = "COPY LOG" end)
end)

local hideBtn = makeBtn("HIDE", false)
hideBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

-- filter chips
local chipsRow = Instance.new("Frame")
chipsRow.Size = UDim2.new(1, -12, 0, 20)
chipsRow.Position = UDim2.new(0, 6, 1, -50)
chipsRow.BackgroundTransparency = 1
chipsRow.Parent = win
local chipsLayout = Instance.new("UIListLayout", chipsRow)
chipsLayout.FillDirection = Enum.FillDirection.Horizontal
chipsLayout.Padding = UDim.new(0, 5)
for _, kind in ipairs({ "ALL", "remote", "log", "instance", "click" }) do
	local chip = Instance.new("TextButton")
	chip.Size = UDim2.new(0, 62, 1, 0)
	chip.BackgroundColor3 = Color3.fromRGB(28, 24, 43)
	chip.BorderSizePixel = 0
	chip.Font = Enum.Font.Gotham
	chip.TextSize = 9
	chip.TextColor3 = Color3.fromRGB(151, 145, 177)
	chip.Text = kind:upper()
	chip.Parent = chipsRow
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 6)
	chip.MouseButton1Click:Connect(function()
		filter = kind
		for _, child in ipairs(feed:GetChildren()) do
			if child:IsA("TextLabel") then child:Destroy() end
		end
		for i, e in ipairs(entries) do
			if i > #entries - 120 then renderEntry(e) end
		end
	end)
end

-- ── collectors (all passive) ───────────────────────────────────────────────
local function watchRemote(r)
	if watchers >= MAX_REMOTE_WATCH then return end
	if not r:IsA("RemoteEvent") then return end
	watchers += 1
	local path = r:GetFullName()
	safeConnect(r.OnClientEvent, function(...)
		local args = argText(...)
		pcall(function() push("remote", path .. "  ←  " .. args) end)
	end)
end

pcall(function()
	for _, d in ipairs(game:GetDescendants()) do
		pcall(function() watchRemote(d) end)
	end
end)

safeConnect(game.DescendantAdded, function(d)
	pcall(function()
		if d:IsA("RemoteEvent") then
			watchRemote(d)
			push("instance", "RemoteEvent appeared: " .. d:GetFullName())
		elseif d:IsA("ClickDetector") then
			local path = d:GetFullName()
			safeConnect(d.MouseClick, function(who)
				pcall(function() push("click", path .. "  ←  " .. tostring(who)) end)
			end)
		elseif d:IsA("ProximityPrompt") then
			local path = d:GetFullName()
			safeConnect(d.Triggered, function(who)
				pcall(function() push("click", path .. "  ←  " .. tostring(who)) end)
			end)
		end
	end)
end)

safeConnect(game.DescendantRemoving, function(d)
	pcall(function()
		local cls = d.ClassName
		if cls == "Script" or cls == "LocalScript" or cls == "ModuleScript" or d:IsA("RemoteEvent") then
			push("instance", cls .. " removed: " .. d:GetFullName())
		end
	end)
end)

safeConnect(LogService.MessageOut, function(msg, msgType)
	pcall(function()
		local tag = tostring(msgType)
		push("log", tag .. "  " .. tostring(msg))
	end)
end)

pcall(function()
	local hist = LogService:GetLogHistory()
	local from = math.max(1, #hist - 25)
	for i = from, #hist do
		local h = hist[i]
		push("log", tostring(h.messageType) .. "  " .. tostring(h.message))
	end
end)

-- ── PULSAR / terminal API ──────────────────────────────────────────────────
local spyAPI = {
	version = "1.0",
	entries = entries,
	stats = stats,
	query = function(kind, n)
		n = n or 20
		local out = {}
		for i = #entries, 1, -1 do
			local e = entries[i]
			if (not kind or kind == "ALL" or e.kind == kind) then
				table.insert(out, "[" .. e.kind .. "] " .. e.text)
				if #out >= n then break end
			end
		end
		return out
	end,
}
-- export everywhere it can live: executor shared env, _G, plain global
pcall(function() if type(getgenv) == "function" then getgenv().PRIMEZ_SAFESPY = spyAPI end end)
pcall(function() _G.PRIMEZ_SAFESPY = spyAPI end)
PRIMEZ_SAFESPY = spyAPI

push("log", "SafeSpy active — passive listeners only (crash-safe). Copy log or ask PULSAR: _G.PRIMEZ_SAFESPY.query(\"remote\", 10)")
refreshFeed()

-- respawn safety: re-parent on character respawn is unnecessary (ResetOnSpawn=false)
print("[PRIMEz SafeSpy] loaded — passive environment logger running")
