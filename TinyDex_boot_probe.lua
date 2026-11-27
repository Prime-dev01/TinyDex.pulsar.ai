--[[ TinyDex boot probe — run this in Delta/Xeno to find where the load dies.
Each stage prints to the executor console. The last line you see = where it stops. ]]

print("[PROBE 1] executor running, script started")

if not game:IsLoaded() then
  print("[PROBE 2] game not loaded yet — waiting for Loaded signal...")
  game.Loaded:Wait()
end
print("[PROBE 3] game loaded")

local plr = game:GetService("Players").LocalPlayer
if not plr then
  print("[PROBE 4] waiting for LocalPlayer...")
  repeat task.wait(0.1) plr = game:GetService("Players").LocalPlayer until plr
end
print("[PROBE 5] LocalPlayer OK: " .. plr.Name)

print("[PROBE 6] gethui = " .. tostring(type(gethui)) .. " | request = " ..
  tostring(type(request)) .. " | loadstring = " .. tostring(type(loadstring)))

local playerGui = plr:FindFirstChildOfClass("PlayerGui")
print("[PROBE 7] PlayerGui = " .. tostring(playerGui))

local gui = Instance.new("ScreenGui")
gui.Name = "TinyDexProbe"
gui.ResetOnSpawn = false
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 320, 0, 60)
label.Position = UDim2.new(0, 20, 0, 20)
label.BackgroundColor3 = Color3.fromRGB(20, 17, 36)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Text = "TinyDex probe alive"
label.Parent = gui

local ok = pcall(function() gui.Parent = playerGui end)
print("[PROBE 8] parented to PlayerGui: " .. tostring(ok) .. " (should show a small purple box top-left)")

if type(gethui) == "function" then
  local ok2 = pcall(function() gui.Parent = gethui() end)
  print("[PROBE 9] parented to gethui: " .. tostring(ok2))
end
local ok3 = pcall(function() gui.Parent = game:GetService("CoreGui") end)
print("[PROBE 10] parented to CoreGui: " .. tostring(ok3))

print("[PROBE 11] all stages done — TinyDex boot path is fine; executor/UI env is the problem")
