--[[ ══════════════════════════════════════════════════════════════════════════
  TinyDex v23 Standalone — PRIMEz Studios SCRIPTS CLIENT  •  NO AI  •  SMOOTH UI 2 EDITION
  NEW GUI: SmoothUI 2 — terminal-style boot, 3 themes (Midnight/Carbon/Ocean),
  floating draggable P toggle. SafeBoot: PlayerGui-only UI, no boot HTTP.
  PULSAR AGENT edition: real tool-calling agent loop + executing Luau terminal.

  WHAT'S NEW IN v23 (vs v22)
  • AGENT LOOP: the server may return tool_calls; TinyDex executes them live
    (analyze_game, inspect, search_game, list_children, read_property,
    get_selection, get_logs, run_luau, save_draft, set_property,
    create_instance, destroy_instance) and posts results back — up to 8
    steps per turn. PULSAR can now ACT, not just chat.
  • TERMINAL: the CONSOLE tab executes Luau (`run`, `run <code>`) when the
    runtime provides loadstring (executor clients). Studio stays read-only.
  • FULL GAME ANALYSIS: the analyze_game tool produces a structured report of
    the whole DataModel — services, players, characters, remotes, replicated
    content, camera, lighting, workspace.
  • SCRIPT CARDS + AUTO-RUN: PULSAR replies with ```lua blocks that become
    RUN / COPY cards. With AUTO-RUN ON, generated scripts execute through the
    terminal automatically; execution output and errors are fed back to the
    agent so it can fix its own code.
  • FIXES v22 BUG: raw tool_calls JSON leaking into the chat is now parsed
    and executed (or cleanly reported) instead of being displayed as text.

  WHAT'S NEW IN v23.1 (PERF PATCH)
  • No boot-time full-game index build — it froze big games (laggy movement,
    crashes). The index now builds lazily via SYNC DATA or deep analyze_game.
  • Index builder is capped (4000 instances / 2s CPU budget), yields every 10
    instances, and caps per-instance child lists — labeled CAPPED when partial.
  • MAX_STEPS 40 → 8 (the documented limit). A turn can no longer spiral into
    dozens of chained model requests.
  • Tool results are clipped to 6k chars in agent history — requests stay
    small and fast instead of dragging megabytes through every step.
  • search_game and the analyze_game remote scan cap their work per service
    and yield mid-scan.

  WHAT'S NEW IN v23.2 (FLOATING TOGGLE)
  • A round PRIMEz "P" button (black bg, white P, purple stroke) is pinned
    at the BOTTOM-LEFT of the screen and always stays there.
  • Tap it to hide the TinyDex window, tap again to show it. PULSAR, the
    agent loop, tools and the terminal keep working while hidden.
  • Showing the window snaps it fully back on screen — it can never be
    stuck outside the viewport or impossible to grab.
  • The X button still removes TinyDex completely, including the P button.

  WHAT'S NEW IN v23.3 (DRAGGABLE P BUTTON)
  • The P button can now be DRAGGED anywhere on screen — any side, any
    corner — so it never has to sit on top of the game's mobile controls.
  • Drag = move the button; quick tap = toggle the window (same as before).
  • The button is live-clamped while dragging: it always stays fully
    visible on screen and can never get lost off-screen.
  • v23.3.1 FIX: tapping P to show the window no longer drifts it into a
    corner. The window re-centers ONLY if part of it is off-screen; a
    valid position is never rewritten.
  • v23.3.2 FIX: P taps now use the Activated event. On mobile, InputEnded
    could miss the button when the finger lifted slightly off it — P then
    looked dead and the drag state could stick, making the button follow
    the next touch. Drag state is now cleaned up globally and a finished
    drag suppresses the tap for 0.35s, so drags never toggle the window.

  WHAT'S NEW IN v23.4 (AUTO-FINISH + WEB RESEARCH)
  • NO MORE "SAY CONTINUE": the agent budget is 8 → 24 steps per turn, so
    PULSAR keeps working until the task is actually DONE (research →
    analyze → build → execute → verify), not stopped mid-task.
  • WEB RESEARCH: new web_search tool — PULSAR searches the internet
    (DuckDuckGo, client-side via executor HTTP, no backend change) for
    the game's current scripts, features, updates and meta.
  • v23.4.1 FIX: failed AI requests no longer kill the whole turn — each
    step retries up to 3 times (waits in between), and the HTTP timeout
    is 90s instead of 45s so Render cold starts stop eating requests.
    Invented tool names now get told the real tool list so the agent
    self-corrects on the next step.
  • v23.4.2 SPEED: the goal is a delivered script in under 5 minutes.
    New SPEED RULES in the agent brain — finish in 8 steps or fewer, at
    most ONE web search, summary analysis only, no narration between
    steps. Status bar shows a live step + elapsed-time counter, and
    history is trimmed tighter (28 messages) so requests stay fast.
  • v23.4.3 FIX: status bar now has a live heartbeat (refreshes every
    second, even mid-request — before, it froze at "STEP 1/24 · 0:00"
    during long model waits and PULSAR looked dead). Messages typed
    while PULSAR is working are QUEUED and auto-sent when the task
    finishes instead of being silently swallowed. The agent brain is
    forbidden from announcing a script without including the full code
    in the same reply. AGENT DONE shows the total turn time.
  • v23.4.4 FOCUS: PULSAR is a SCRIPT BUILDER, judged only by whether
    the delivered script actually RUNS. New WORKING SCRIPT STANDARD in
    the brain (a script "works" only after run_luau returns EXEC OK,
    fix up to 3 attempts, final report states SCRIPT RUNNING ✓/✗ plus
    how to stop it) and anti-random rules (no tutorials, no "here are
    ideas", no off-topic chatter when a script was requested).
    Mechanical guarantee: after the final reply, the delivered script's
    largest lua block is auto-executed and reported EXEC OK / FAILED —
    a broken script can never be passed off as working.
  • GAME DETECTION: the game's real name is auto-detected (place info)
    and sent to PULSAR with EVERY request; new get_game_info tool.
  • SCRIPT WORKFLOW: for game-script requests PULSAR now follows:
    identify the game → web_search its known features/scripts → analyze
    the live game → build → execute. It knows the common script types
    (auto-steal, autofarm/auto-collect, auto-buy, ESP, movement,
    teleport, anti-AFK, GUI hubs, remote tools, lag tools).


  ── BACKEND CONTRACT — POST {PRIMEZ}/api/ai/chat ─────────────────────────
  request body:
    {
      agent   = true,
      step    = <int>,
      tools   = { { name, description, parameters }, ... },  -- from TOOL_SCHEMAS
      context = "<product knowledge + live client context>",
      messages = {
        { role = "user",      content = "..." },
        { role = "assistant", content = "..." },
        { role = "tool", tool_call_id = "...", name = "...", arguments = <args table>, content = "<result>" },
      },
    }
  response body, one of:
    { success = true, done = false, tool_calls = { { id, name, args } } }
    { success = true, done = true,  reply = "final answer text" }
    { success = false, error = "..." }
  • Legacy { success = true, reply = "..." } responses are treated as done.
  • Server must NEVER place raw tool_calls JSON inside `reply`.
  • role="tool" entries in `messages` are tool results from the previous step.
═════════════════════════════════════════════════════════════════════════════ ]]

-- ── WHAT'S NEW IN v23.6 (SMOOTH UI + THEMES) ──────────────────────────────
-- • Terminal-style boot: a mini console types its own boot log ([BOOT],
--   [ OK ], [SYNC]...) with a blinking caret while the bar fills, ambient
--   glow + particles breathe, and the finished window springs in. Tap
--   anywhere to skip straight to the reveal.
-- • 3 THEMES — Midnight, Carbon, Ocean: pick one on the splash screen and it
--   applies live across the whole interface; the choice is saved for the
--   next launch (Midnight is the default).
-- • Cleaned chrome: decorative glyphs removed from buttons (PICK, COPY
--   SHOWN, RUN, COPY, AUTO-RUN, EXEC are plain text now). Features unchanged.


-- DELTA-style boot: executors inject before the client finishes loading.
if not game:IsLoaded() then game.Loaded:Wait() end
local PlayersService = game:GetService("Players")
local plr = PlayersService.LocalPlayer
while not plr do
  task.wait(0.1)
  plr = PlayersService.LocalPlayer
end
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local TweenService = game:GetService("TweenService")
local luaSelect = select
local PRIMEZ = "https://primez-guard.vercel.app/"

local gui = Instance.new("ScreenGui")
gui.Name = "TinyDex"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Enabled = true
local playerGui = plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui", 10)
local playerGui = plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui", 10)
-- SafeBoot: PlayerGui-only UI container. gethui()/CoreGui are never touched:
-- those calls crash clients whose executor is stale after a Roblox update.
pcall(function()
  for _, existing in ipairs(playerGui and playerGui:GetChildren() or {}) do
    if existing.Name == "TinyDex" then existing:Destroy() end
  end
end)
if not gui.Parent and playerGui then
  pcall(function() gui.Parent = playerGui end)
end
if not gui.Parent then
  error("TinyDex v23: no UI container available (PlayerGui unavailable)")
end

local C = {
  bg = Color3.fromRGB(12, 12, 20), row = Color3.fromRGB(17, 17, 29), panel = Color3.fromRGB(20, 19, 34),
  txt = Color3.fromRGB(235, 232, 248), dim = Color3.fromRGB(151, 145, 177),
  hot = Color3.fromRGB(160, 83, 255), hot2 = Color3.fromRGB(105, 48, 210),
  good = Color3.fromRGB(77, 224, 143), bad = Color3.fromRGB(255, 103, 128),
  line = Color3.fromRGB(72, 48, 125),
}
-- ── v23.6-SMOOTH UI: THEME SYSTEM ──────────────────────────────────────────
-- 3 presets (Midnight / Carbon / Ocean). The active theme paints the shared
-- C palette before anything builds, is switchable live from the boot splash
-- via a full-interface re-tint, and is remembered for the next launch.
local function tint(a, b, t)
  return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
local THEMES = {
  Midnight = {
    bg = Color3.fromRGB(12, 12, 20), row = Color3.fromRGB(17, 17, 29),
    panel = Color3.fromRGB(20, 19, 34), txt = Color3.fromRGB(235, 232, 248),
    dim = Color3.fromRGB(151, 145, 177), hot = Color3.fromRGB(160, 83, 255),
    hot2 = Color3.fromRGB(105, 48, 210), good = Color3.fromRGB(77, 224, 143),
    bad = Color3.fromRGB(255, 103, 128), line = Color3.fromRGB(72, 48, 125),
    btnBg = Color3.fromRGB(39, 27, 65), btnHov = Color3.fromRGB(72, 43, 112),
  },
  Carbon = {
    bg = Color3.fromRGB(10, 10, 12), row = Color3.fromRGB(15, 15, 17),
    panel = Color3.fromRGB(19, 19, 22), txt = Color3.fromRGB(238, 238, 241),
    dim = Color3.fromRGB(146, 146, 154), hot = Color3.fromRGB(88, 158, 255),
    hot2 = Color3.fromRGB(28, 102, 204), good = Color3.fromRGB(77, 224, 143),
    bad = Color3.fromRGB(255, 103, 128), line = Color3.fromRGB(66, 66, 76),
    btnBg = Color3.fromRGB(35, 35, 40), btnHov = Color3.fromRGB(54, 54, 62),
  },
  Ocean = {
    bg = Color3.fromRGB(8, 17, 21), row = Color3.fromRGB(12, 24, 29),
    panel = Color3.fromRGB(15, 31, 37), txt = Color3.fromRGB(224, 242, 240),
    dim = Color3.fromRGB(130, 164, 163), hot = Color3.fromRGB(0, 208, 178),
    hot2 = Color3.fromRGB(0, 133, 116), good = Color3.fromRGB(77, 224, 143),
    bad = Color3.fromRGB(255, 103, 128), line = Color3.fromRGB(33, 88, 84),
    btnBg = Color3.fromRGB(15, 45, 47), btnHov = Color3.fromRGB(24, 64, 66),
  },
}
local THEME_ORDER = { "Midnight", "Carbon", "Ocean" }
local THEME_FILE = "primez_tinydex_theme.txt"
local ACTIVE_THEME = "Midnight"
pcall(function()
  if type(readfile) == "function" and type(isfile) == "function" and isfile(THEME_FILE) then
    local saved = (readfile(THEME_FILE) or ""):gsub("%s+", "")
    if THEMES[saved] then ACTIVE_THEME = saved end
  end
end)
local function saveTheme(n)
  if type(writefile) == "function" then pcall(writefile, THEME_FILE, n) end
end
do -- paint the shared palette with the saved theme before anything builds
  for k, v in pairs(THEMES[ACTIVE_THEME]) do C[k] = v end
end


local FULL = UDim2.new(0, 900, 0, 540)
local MINI = UDim2.new(0, 900, 0, 58)

-- ═══════════════════════════════════════════════════════════════════════════
-- v23.6-SMOOTH UI: terminal-style boot sequence (presentation layer only)
-- A mini console types its own boot log with a blinking caret while the bar
-- fills and the ambient layers breathe; then it dissolves and reveals the
-- finished window with entrance animations. NO feature logic is changed
-- anywhere below — the window and the P button are simply created hidden and
-- revealed when loading ends. Tap anywhere to skip the cosmetic layer.
-- ═══════════════════════════════════════════════════════════════════════════
local BOOTUI = { t0 = os.clock(), done = false, revealed = false, reveal = nil }
do
  local splashGui = Instance.new("ScreenGui")
  splashGui.Name = "TinyDexBootSplash"
  splashGui.ResetOnSpawn = false
  splashGui.IgnoreGuiInset = true
  splashGui.DisplayOrder = 9999999
  pcall(function() splashGui.Parent = hiddenUi or playerGui or gui end)
  pcall(function()
    gui.Destroying:Connect(function() splashGui:Destroy() end)
  end)

  local overlay = Instance.new("Frame")
  overlay.Name = "Overlay"
  overlay.Size = UDim2.fromScale(1, 1)
  overlay.BackgroundColor3 = Color3.fromRGB(8, 7, 14)
  overlay.BorderSizePixel = 0
  overlay.BackgroundTransparency = 1
  overlay.Parent = splashGui
  local ovGrad = Instance.new("UIGradient", overlay)
  ovGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 11, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 7, 14)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 9, 24)),
  })
  ovGrad.Rotation = 35
  -- the backdrop gradient sways slowly so the room never feels frozen
  task.spawn(function()
    while splashGui.Parent do
      local a = TweenService:Create(ovGrad, TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = 65})
      a:Play() a.Completed:Wait()
      if not splashGui.Parent then break end
      local b = TweenService:Create(ovGrad, TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = 35})
      b:Play() b.Completed:Wait()
    end
  end)

  -- ambient glow blobs behind the stage (breathing, very low alpha)
  local glowA = Instance.new("Frame")
  glowA.Name = "GlowA"
  glowA.AnchorPoint = Vector2.new(0.5, 0.5)
  glowA.Position = UDim2.new(0.5, 0, 0.47, -20)
  glowA.Size = UDim2.fromOffset(460, 460)
  glowA.BackgroundColor3 = C.hot
  glowA.BackgroundTransparency = 1
  glowA.BorderSizePixel = 0
  glowA.Parent = overlay
  Instance.new("UICorner", glowA).CornerRadius = UDim.new(1, 0)
  local glowB = Instance.new("Frame")
  glowB.Name = "GlowB"
  glowB.AnchorPoint = Vector2.new(0.5, 0.5)
  glowB.Position = UDim2.new(0.5, 150, 0.47, 130)
  glowB.Size = UDim2.fromOffset(300, 300)
  glowB.BackgroundColor3 = C.hot2
  glowB.BackgroundTransparency = 1
  glowB.BorderSizePixel = 0
  glowB.Parent = overlay
  Instance.new("UICorner", glowB).CornerRadius = UDim.new(1, 0)

  local stage = Instance.new("Frame")
  stage.Name = "Stage"
  stage.AnchorPoint = Vector2.new(0.5, 0.5)
  stage.Position = UDim2.fromScale(0.5, 0.47)
  stage.Size = UDim2.fromOffset(320, 252)
  stage.BackgroundTransparency = 1
  stage.Parent = overlay
  local stageScale = Instance.new("UIScale", stage)
  stageScale.Scale = 0.86

  local logo = Instance.new("TextLabel")
  logo.Name = "Logo"
  logo.AnchorPoint = Vector2.new(0.5, 0)
  logo.Position = UDim2.new(0.5, 0, 0, 14)
  logo.Size = UDim2.fromOffset(320, 52)
  logo.BackgroundTransparency = 1
  logo.Font = Enum.Font.GothamBold
  logo.TextSize = 40
  logo.TextColor3 = C.txt
  logo.Text = "◆  TinyDex"
  logo.TextTransparency = 1
  logo.Parent = stage
  local logoGlow = Instance.new("UIStroke", logo)
  logoGlow.Color = C.hot
  logoGlow.Thickness = 1.2
  logoGlow.Transparency = 1
  local logoScale = Instance.new("UIScale", logo)
  logoScale.Scale = 0.7
  -- shimmer: a soft highlight sweeps across the letters on a loop
  local logoGrad = Instance.new("UIGradient", logo)
  logoGrad.Color = ColorSequence.new(
    Color3.fromRGB(186, 182, 208), Color3.fromRGB(255, 255, 255), Color3.fromRGB(186, 182, 208))
  logoGrad.Offset = Vector2.new(-1, 0)
  task.spawn(function()
    while splashGui.Parent do
      local tw = TweenService:Create(logoGrad, TweenInfo.new(1.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Offset = Vector2.new(1, 0)})
      tw:Play() tw.Completed:Wait()
      if not splashGui.Parent then break end
      logoGrad.Offset = Vector2.new(-1, 0)
    end
  end)

  local sub = Instance.new("TextLabel")
  sub.Name = "Subtitle"
  sub.AnchorPoint = Vector2.new(0.5, 0)
  sub.Position = UDim2.new(0.5, 0, 0, 70)
  sub.Size = UDim2.fromOffset(320, 16)
  sub.BackgroundTransparency = 1
  sub.Font = Enum.Font.Gotham
  sub.TextSize = 11
  sub.TextColor3 = Color3.fromRGB(177, 145, 235)
  sub.Text = "PRIMEz STUDIOS  •  PULSAR AGENT EDITION"
  sub.TextTransparency = 1
  sub.Parent = stage

  -- ── the terminal card ────────────────────────────────────────────────────
  local term = Instance.new("Frame")
  term.Name = "Term"
  term.AnchorPoint = Vector2.new(0.5, 0)
  term.Position = UDim2.new(0.5, 0, 0, 92)
  term.Size = UDim2.fromOffset(300, 128)
  term.BackgroundColor3 = Color3.fromRGB(9, 9, 16)
  term.BackgroundTransparency = 0.18
  term.BorderSizePixel = 0
  term.ClipsDescendants = true
  term.Parent = stage
  Instance.new("UICorner", term).CornerRadius = UDim.new(0, 10)
  local termScale = Instance.new("UIScale", term)
  termScale.Scale = 0.92
  local termStroke = Instance.new("UIStroke", term)
  termStroke.Color = Color3.fromRGB(255, 255, 255)
  termStroke.Thickness = 1
  termStroke.Transparency = 1

  -- traffic dots + window title, like a real terminal emulator
  local traffic = {}
  local tcols = {
    Color3.fromRGB(255, 95, 86), Color3.fromRGB(255, 189, 46), Color3.fromRGB(52, 214, 108),
  }
  for i = 1, 3 do
    local d = Instance.new("Frame")
    d.Name = "TDot" .. i
    d.Position = UDim2.new(0, 10 + (i - 1) * 14, 0, 6)
    d.Size = UDim2.fromOffset(8, 8)
    d.BackgroundColor3 = tcols[i]
    d.BackgroundTransparency = 1
    d.BorderSizePixel = 0
    d.Parent = term
    Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
    traffic[i] = d
  end
  local termTitle = Instance.new("TextLabel")
  termTitle.Name = "TermTitle"
  termTitle.Position = UDim2.new(0, 0, 0, 3)
  termTitle.Size = UDim2.new(1, 0, 0, 14)
  termTitle.BackgroundTransparency = 1
  termTitle.Font = Enum.Font.Code
  termTitle.TextSize = 10
  termTitle.TextColor3 = C.dim
  termTitle.Text = "tinydex: ~/boot"
  termTitle.TextTransparency = 1
  termTitle.Parent = term
  local divider = Instance.new("Frame")
  divider.Name = "Divider"
  divider.Position = UDim2.new(0, 0, 0, 20)
  divider.Size = UDim2.new(1, 0, 0, 1)
  divider.BackgroundColor3 = C.dim
  divider.BackgroundTransparency = 1
  divider.BorderSizePixel = 0
  divider.Parent = term

  -- six log lines typed one by one; the tag is colored via RichText
  local GREEN = Color3.fromRGB(108, 228, 152)
  local function hexOf(c)
    return string.format("#%02X%02X%02X",
      math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
  end
  local LOG = {
    { "BOOT", C.hot,  "booting TinyDex core..." },
    { " OK ", GREEN,  "modules loaded (32)" },
    { " OK ", GREEN,  "themes: Midnight / Carbon / Ocean" },
    { "SYNC", C.hot2, "PRIMEz network link established" },
    { " AI ", C.txt,  "PULSAR agent standing by" },
    { "DONE", GREEN,  "welcome to TinyDex." },
  }
  local logLines = {}
  for i, e in ipairs(LOG) do
    local ln = Instance.new("TextLabel")
    ln.Name = "Log" .. i
    ln.Position = UDim2.new(0, 14, 0, 26 + (i - 1) * 15)
    ln.Size = UDim2.new(1, -28, 0, 13)
    ln.BackgroundTransparency = 1
    ln.Font = Enum.Font.Code
    ln.TextSize = 10
    ln.TextXAlignment = Enum.TextXAlignment.Left
    ln.RichText = true
    ln.TextColor3 = C.dim
    ln.Text = ""
    ln.TextTransparency = 1
    ln.Parent = term
    logLines[i] = ln
  end
  -- blinking block caret that rides the active line
  local caret = Instance.new("Frame")
  caret.Name = "Caret"
  caret.Position = UDim2.new(0, 14, 0, 27)
  caret.Size = UDim2.fromOffset(7, 12)
  caret.BackgroundColor3 = C.hot
  caret.BackgroundTransparency = 0.15
  caret.BorderSizePixel = 0
  caret.Visible = false
  caret.Parent = term
  Instance.new("UICorner", caret).CornerRadius = UDim.new(0, 2)
  task.spawn(function()
    while splashGui.Parent do
      caret.Visible = not caret.Visible
      task.wait(0.42)
    end
  end)

  local barBg = Instance.new("Frame")
  barBg.Name = "BarBg"
  barBg.AnchorPoint = Vector2.new(0.5, 0)
  barBg.Position = UDim2.new(0.5, 0, 0, 230)
  barBg.Size = UDim2.fromOffset(280, 6)
  barBg.BackgroundColor3 = C.row
  barBg.BorderSizePixel = 0
  barBg.Parent = stage
  barBg.ClipsDescendants = true
  Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
  -- moving shine streak riding along the track
  local shine = Instance.new("Frame")
  shine.Name = "Shine"
  shine.AnchorPoint = Vector2.new(0, 0.5)
  shine.Position = UDim2.new(0, -40, 0.5, 0)
  shine.Size = UDim2.new(0, 34, 1, 0)
  shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
  shine.BackgroundTransparency = 0.35
  shine.BorderSizePixel = 0
  shine.Parent = barBg
  local shineGrad = Instance.new("UIGradient", shine)
  shineGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
  shineGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 1),
  })
  task.spawn(function()
    while splashGui.Parent do
      shine.Position = UDim2.new(0, -40, 0.5, 0)
      local tw = TweenService:Create(shine, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.new(1, 6, 0.5, 0)})
      tw:Play() tw.Completed:Wait()
      if not splashGui.Parent then break end
      task.wait(0.55)
    end
  end)
  local barFill = Instance.new("Frame")
  barFill.Name = "BarFill"
  barFill.Size = UDim2.new(0, 0, 1, 0)
  barFill.BackgroundColor3 = C.hot
  barFill.BorderSizePixel = 0
  barFill.Parent = barBg
  Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
  local fillGrad = Instance.new("UIGradient", barFill)
  fillGrad.Color = ColorSequence.new(C.hot2, C.hot)
  fillGrad.Rotation = 0

  -- live percentage beside the bar
  local pct = Instance.new("TextLabel")
  pct.Name = "Pct"
  pct.Position = UDim2.new(0.5, 148, 0, 227)
  pct.Size = UDim2.fromOffset(46, 14)
  pct.BackgroundTransparency = 1
  pct.Font = Enum.Font.Code
  pct.TextSize = 12
  pct.TextColor3 = C.dim
  pct.TextXAlignment = Enum.TextXAlignment.Left
  pct.Text = "0%"
  pct.TextTransparency = 1
  pct.Parent = stage

  local verTag = Instance.new("TextLabel")
  verTag.Name = "Version"
  verTag.AnchorPoint = Vector2.new(0.5, 1)
  verTag.Position = UDim2.new(0.5, 0, 1, -18)
  verTag.Size = UDim2.fromOffset(320, 14)
  verTag.BackgroundTransparency = 1
  verTag.Font = Enum.Font.Gotham
  verTag.TextSize = 10
  verTag.TextColor3 = C.dim
  verTag.Text = "TINYDEX v23.6  •  SMOOTH UI"
  verTag.TextTransparency = 1
  verTag.Parent = overlay

  -- theme picker: Midnight / Carbon / Ocean — tap to apply live, choice is
  -- saved for the next launch. Quiet row under the stage.
  local chipRow = Instance.new("Frame")
  chipRow.Name = "ThemePicker"
  chipRow.AnchorPoint = Vector2.new(0.5, 1)
  chipRow.Position = UDim2.new(0.5, 0, 1, -46)
  chipRow.Size = UDim2.fromOffset(340, 18)
  chipRow.BackgroundTransparency = 1
  chipRow.Parent = overlay
  local chipLayout = Instance.new("UIListLayout", chipRow)
  chipLayout.FillDirection = Enum.FillDirection.Horizontal
  chipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
  chipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
  chipLayout.Padding = UDim.new(0, 20)
  local chips = {}
  local function selectTheme(name)
    ACTIVE_THEME = name
    saveTheme(name)
    for nm, chip in pairs(chips) do
      chip.label.TextColor3 = (nm == name) and THEMES[nm].hot or C.dim
    end
    if BOOTUI.applyTheme then pcall(BOOTUI.applyTheme, name) end
  end
  BOOTUI.selectTheme = selectTheme
  for _, name in ipairs(THEME_ORDER) do
    local chip = Instance.new("TextButton")
    chip.Name = "Theme_" .. name
    chip.BackgroundTransparency = 1
    chip.AutoButtonColor = false
    chip.Size = UDim2.fromOffset(86, 18)
    chip.Text = ""
    chip.Parent = chipRow
    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(0, 10, 0.5, 0)
    dot.Size = UDim2.fromOffset(7, 7)
    dot.BackgroundColor3 = THEMES[name].hot
    dot.BackgroundTransparency = 1
    dot.BorderSizePixel = 0
    dot.Parent = chip
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 22, 0, 0)
    label.Size = UDim2.new(1, -22, 1, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTransparency = 1
    label.TextColor3 = (name == ACTIVE_THEME) and THEMES[name].hot or C.dim
    label.Text = name
    label.Parent = chip
    chips[name] = { label = label, dot = dot }
    chip.MouseButton1Click:Connect(function() selectTheme(name) end)
  end
  task.delay(0.8, function() -- chips drift in so the splash reads calm
    if not chipRow.Parent then return end
    for _, chip in pairs(chips) do
      TweenService:Create(chip.label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.1}):Play()
      TweenService:Create(chip.dot, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
    end
  end)

  local function fade(obj, props, dur, delay)
    local tw = TweenService:Create(obj, TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay or 0), props)
    tw:Play()
    return tw
  end

  -- tap anywhere to skip the cosmetic layer (the window still animates in)
  local skipRequested = false
  overlay.InputBegan:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1
      or io.UserInputType == Enum.UserInputType.Touch then
      skipRequested = true
    end
  end)
  local skipHint = Instance.new("TextLabel")
  skipHint.Name = "SkipHint"
  skipHint.AnchorPoint = Vector2.new(1, 1)
  skipHint.Position = UDim2.new(1, -16, 1, -16)
  skipHint.Size = UDim2.fromOffset(110, 14)
  skipHint.BackgroundTransparency = 1
  skipHint.Font = Enum.Font.Gotham
  skipHint.TextSize = 10
  skipHint.TextColor3 = C.dim
  skipHint.TextTransparency = 1
  skipHint.TextXAlignment = Enum.TextXAlignment.Right
  skipHint.Text = "tap to skip"
  skipHint.Parent = overlay

  -- ambient particle drift around the stage
  local rng = Random.new()
  task.spawn(function()
    while splashGui.Parent do
      task.wait(0.22)
      if not splashGui.Parent then break end
      local p = Instance.new("Frame")
      p.Size = UDim2.fromOffset(rng:NextInteger(3, 6), rng:NextInteger(3, 6))
      p.Position = UDim2.new(0.5, rng:NextInteger(-190, 190), 0.47, rng:NextInteger(-160, 210))
      p.BackgroundColor3 = (rng:NextNumber() < 0.7) and C.hot or C.txt
      p.BackgroundTransparency = 0.55
      p.BorderSizePixel = 0
      p.Parent = overlay
      Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
      local drift = TweenService:Create(p, TweenInfo.new(rng:NextNumber(2.1, 3.2), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, p.Position.X.Offset + rng:NextInteger(-50, 50), 0.47, p.Position.Y.Offset - rng:NextInteger(60, 110)),
        BackgroundTransparency = 1,
      })
      drift:Play()
      drift.Completed:Once(function() p:Destroy() end)
    end
  end)

  -- the big glow blob breathes on a slow cycle
  task.spawn(function()
    while splashGui.Parent do
      local t1 = TweenService:Create(glowA, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.9})
      t1:Play() t1.Completed:Wait()
      if not splashGui.Parent then break end
      local t2 = TweenService:Create(glowA, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.96})
      t2:Play() t2.Completed:Wait()
    end
  end)

  -- entrance choreography
  fade(overlay, {BackgroundTransparency = 0}, 0.3)
  fade(logo, {TextTransparency = 0}, 0.4, 0.12)
  fade(logoGlow, {Transparency = 0.7}, 0.4, 0.12)
  TweenService:Create(logoScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
  fade(sub, {TextTransparency = 0.15}, 0.4, 0.35)
  TweenService:Create(termScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
  fade(termStroke, {Transparency = 0.88}, 0.45, 0.5)
  for i, d in ipairs(traffic) do
    fade(d, {BackgroundTransparency = 0}, 0.25, 0.55 + i * 0.07)
  end
  fade(termTitle, {TextTransparency = 0.35}, 0.4, 0.6)
  fade(divider, {BackgroundTransparency = 0.85}, 0.4, 0.6)
  fade(barBg, {BackgroundTransparency = 0}, 0.3, 0.7)
  fade(pct, {TextTransparency = 0.5}, 0.3, 0.75)
  fade(glowA, {BackgroundTransparency = 0.93}, 0.8, 0.2)
  fade(glowB, {BackgroundTransparency = 0.94}, 0.8, 0.35)
  fade(verTag, {TextTransparency = 0.35}, 0.4, 0.9)
  task.delay(1.4, function()
    if skipHint.Parent then fade(skipHint, {TextTransparency = 0.45}, 0.5) end
  end)

  -- breathing glow on the logo for as long as the splash is alive
  task.spawn(function()
    while splashGui.Parent do
      local a = TweenService:Create(logoGlow, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.4})
      a:Play() a.Completed:Wait()
      if not splashGui.Parent then break end
      local b = TweenService:Create(logoGlow, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.7})
      b:Play() b.Completed:Wait()
    end
  end)

  -- boot choreography: the console types while the bar fills; when both
  -- lanes meet, the final line lands and the splash hands over.
  task.spawn(function()
    pcall(function()
      local barDone, logDone = false, false
      -- lane 1: stepped bar fills (skip-aware)
      task.spawn(function()
        local steps = {
          { 0.18, 0.5 }, { 0.44, 0.7 }, { 0.68, 0.8 }, { 0.86, 0.6 }, { 1.00, 0.5 },
        }
        for _, s in ipairs(steps) do
          local tw = TweenService:Create(barFill, TweenInfo.new(s[2], Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(s[1], 0, 1, 0)})
          tw:Play()
          while tw.PlaybackState == Enum.PlaybackState.Playing and not skipRequested do task.wait(0.03) end
          if not splashGui.Parent or skipRequested then break end
        end
        if skipRequested then barFill.Size = UDim2.new(1, 0, 1, 0) end
        barDone = true
      end)
      -- lane 2: the live percentage rides the bar width
      task.spawn(function()
        while splashGui.Parent do
          pct.Text = math.floor(barFill.Size.X.Scale * 100 + 0.5) .. "%"
          task.wait(0.05)
        end
      end)
      -- lane 3: typed boot log (lines 1-5; line 6 lands at the meet point)
      task.spawn(function()
        for i, e in ipairs(LOG) do
          if i >= 6 then break end
          if not skipRequested then
            local markup = '<font color="' .. hexOf(e[2]) .. '">[' .. e[1] .. ']</font> '
            local ln = logLines[i]
            local baseY = 26 + (i - 1) * 15
            ln.Position = UDim2.new(0, 14, 0, baseY + 6)
            fade(ln, {TextTransparency = 0.55}, 0.16)
            TweenService:Create(ln, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 14, 0, baseY)}):Play()
            caret.Position = UDim2.new(0, 14, 0, baseY + 1)
            task.wait(0.16)
            for c = 1, #e[3] do
              if not splashGui.Parent or skipRequested then break end
              ln.Text = markup .. string.sub(e[3], 1, c)
              caret.Position = UDim2.new(0, 14 + (7 + c) * 6, 0, baseY + 1)
              task.wait(0.014)
            end
            fade(ln, {TextTransparency = 0.15}, 0.2)
            task.wait(0.22)
          end
          if not splashGui.Parent then return end
        end
        logDone = true
      end)
      -- meet point: both lanes finished (or the user tapped to skip)
      while not (logDone and barDone) and not skipRequested and splashGui.Parent do
        task.wait(0.04)
      end
      if not splashGui.Parent then return end
      if skipRequested then -- stamp the whole log at once
        for i, e in ipairs(LOG) do
          local ln = logLines[i]
          ln.Text = '<font color="' .. hexOf(e[2]) .. '">[' .. e[1] .. ']</font> ' .. e[3]
          ln.TextTransparency = 0.15
          ln.Position = UDim2.new(0, 14, 0, 26 + (i - 1) * 15)
        end
      end
      -- final line: typed with the caret, or stamped instantly on skip
      local e6 = LOG[6]
      local markup6 = '<font color="' .. hexOf(e6[2]) .. '">[' .. e6[1] .. ']</font> '
      local ln6 = logLines[6]
      if skipRequested then
        ln6.Text = markup6 .. e6[3]
        ln6.TextTransparency = 0.15
        caret.Position = UDim2.new(0, 14 + (7 + #e6[3]) * 6, 0, 101 + 1)
        caret.Visible = true
      else
        ln6.Position = UDim2.new(0, 14, 0, 107)
        fade(ln6, {TextTransparency = 0.55}, 0.16)
        TweenService:Create(ln6, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 14, 0, 101)}):Play()
        caret.Position = UDim2.new(0, 14, 0, 102)
        caret.Visible = true
        task.wait(0.16)
        for c = 1, #e6[3] do
          if not splashGui.Parent then return end
          ln6.Text = markup6 .. string.sub(e6[3], 1, c)
          caret.Position = UDim2.new(0, 14 + (7 + c) * 6, 0, 102)
          task.wait(0.014)
        end
        fade(ln6, {TextTransparency = 0.15}, 0.2)
      end
      -- hold the full console until the script reports ready (7s safety cap)
      while not BOOTUI.done and os.clock() - BOOTUI.t0 < 7 and not skipRequested do
        task.wait(0.05)
      end
      task.wait(skipRequested and 0.55 or 0.45)
    end)
    -- dissolve the splash
    pcall(function()
      TweenService:Create(stageScale, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1.06}):Play()
      fade(overlay, {BackgroundTransparency = 1}, 0.45)
      fade(logo, {TextTransparency = 1}, 0.3)
      fade(logoGlow, {Transparency = 1}, 0.3)
      fade(sub, {TextTransparency = 1}, 0.3)
      fade(termStroke, {Transparency = 1}, 0.3)
      fade(termTitle, {TextTransparency = 1}, 0.25)
      fade(divider, {BackgroundTransparency = 1}, 0.25)
      for _, d in ipairs(traffic) do fade(d, {BackgroundTransparency = 1}, 0.25) end
      for _, ln in ipairs(logLines) do fade(ln, {TextTransparency = 1}, 0.25) end
      fade(caret, {BackgroundTransparency = 1}, 0.2)
      fade(barBg, {BackgroundTransparency = 1}, 0.3)
      fade(barFill, {BackgroundTransparency = 1}, 0.3)
      fade(shine, {BackgroundTransparency = 1}, 0.25)
      fade(pct, {TextTransparency = 1}, 0.3)
      fade(verTag, {TextTransparency = 1}, 0.3)
      fade(skipHint, {TextTransparency = 1}, 0.2)
      fade(glowA, {BackgroundTransparency = 1}, 0.45)
      fade(glowB, {BackgroundTransparency = 1}, 0.45)
      for _, chip in pairs(chips) do
        fade(chip.label, {TextTransparency = 1}, 0.25)
        fade(chip.dot, {BackgroundTransparency = 1}, 0.25)
      end
    end)
    task.wait(0.45)
    splashGui:Destroy()
    -- reveal the finished window with an entrance animation
    if BOOTUI.reveal then
      pcall(BOOTUI.reveal)
    elseif BOOTUI.win then
      BOOTUI.revealed = true
      BOOTUI.win.Visible = true
      if BOOTUI.pBtn then BOOTUI.pBtn.Visible = true end
    end
  end)

  -- watchdog: no matter what happens to the cosmetic layer above, TinyDex
  -- can never stay hidden forever — plain reveal after 8.5s worst case.
  task.delay(8.5, function()
    if splashGui.Parent then splashGui:Destroy() end
    if BOOTUI.win and not BOOTUI.revealed then
      BOOTUI.revealed = true
      BOOTUI.win.Visible = true
      if BOOTUI.pBtn then BOOTUI.pBtn.Visible = true end
    end
  end)
end


local win = Instance.new("Frame")
win.Name = "PRIMEzTinyDexWindow"
win.Size = FULL
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.Position = UDim2.fromScale(0.5, 0.5)
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 13)
win.Visible = false -- v23.6-SMOOTH UI: born hidden, revealed by the boot splash
local outerStroke = Instance.new("UIStroke", win)
outerStroke.Color = C.line
outerStroke.Thickness = 1.5
outerStroke.Transparency = 0.08
local winGradient = Instance.new("UIGradient", win)
winGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, tint(C.bg, C.hot, 0.10)), ColorSequenceKeypoint.new(0.55, C.bg), ColorSequenceKeypoint.new(1, tint(C.bg, C.hot, 0.05))})
winGradient.Rotation = 25
local winScale = Instance.new("UIScale")
winScale.Name = "ResponsiveScale"
winScale.Parent = win
local function updateScale()
  local camera = workspace.CurrentCamera
  if not camera then return end
  local v = camera.ViewportSize
  winScale.Scale = math.clamp(math.min((v.X * 0.96) / 900, (v.Y * 0.92) / 540), 0.42, 1.12)
end
updateScale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end

local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.Size = UDim2.new(1,0,0,36)
bar.BackgroundColor3 = Color3.fromRGB(16, 13, 29)
bar.BorderSizePixel = 0
bar.Parent = win
local barGrad = Instance.new("UIGradient", bar)
barGrad.Color = ColorSequence.new(tint(C.bg, C.hot, 0.22), tint(C.bg, C.hot, 0.05))
barGrad.Rotation = 0
local barLine = Instance.new("Frame")
barLine.Size = UDim2.new(1, -24, 0, 1)
barLine.Position = UDim2.new(0, 12, 1, -1)
barLine.BackgroundColor3 = C.line
barLine.BackgroundTransparency = 0.25
barLine.BorderSizePixel = 0
barLine.Parent = bar
local brand = Instance.new("TextLabel")
brand.Name = "Brand"
brand.Size = UDim2.new(0, 270, 1, 0)
brand.Position = UDim2.fromOffset(15, 0)
brand.BackgroundTransparency = 1
brand.Font = Enum.Font.GothamBold
brand.TextSize = 17
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.TextColor3 = C.txt
brand.Text = "◆  TinyDex  "
brand.Parent = bar
local brandSub = Instance.new("TextLabel")
brandSub.Size = UDim2.new(0, 180, 0, 14)
brandSub.Position = UDim2.fromOffset(111, 18)
brandSub.BackgroundTransparency = 1
brandSub.Font = Enum.Font.Gotham
brandSub.TextSize = 9
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.TextColor3 = Color3.fromRGB(177, 145, 235)
brandSub.Text = "by PRIMEz Studios  •  v23.4"
brandSub.Parent = bar

-- manual drag on the title bar only
do
  local dragging, ds, ws
  bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
      dragging, ds, ws = true, i.Position, win.Position
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
      local d = i.Position - ds
      win.Position = UDim2.new(ws.X.Scale, ws.X.Offset + d.X, ws.Y.Scale, ws.Y.Offset + d.Y)
    end
  end)
  UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
  end)
end

local function tbtn(text, w, xo, col)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(0, w, 0, 25)
  b.Position = UDim2.new(1, xo, 0, 5)
  b.BackgroundColor3 = C.btnBg
  b.BorderSizePixel = 0
  b.Font = Enum.Font.GothamSemibold
  b.TextSize = 10
  b.Text = text
  b.TextColor3 = col or Color3.fromRGB(210,210,220)
  b.Parent = bar
  Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
  local st = Instance.new("UIStroke", b)
  st.Color = C.line
  st.Transparency = 0.25
  b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.14), {BackgroundColor3 = C.btnHov}):Play() end)
  b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = C.btnBg}):Play() end)
  return b
end
local diagBtn = tbtn("HELP", 48, -166, C.dim)
local pickBtn = tbtn("PICK", 74, -112, C.hot)
local copyShown = tbtn("COPY SHOWN", 116, -236)
local xb = Instance.new("TextButton")
xb.Size = UDim2.new(0, 30, 0, 28)
xb.Position = UDim2.new(1, -36, 0, 4)
xb.BackgroundColor3 = Color3.fromRGB(72, 27, 52)
xb.BackgroundTransparency = 0.1
xb.BorderSizePixel = 0
xb.Font = Enum.Font.GothamBold
xb.TextSize = 15
xb.TextColor3 = C.bad
xb.Text = "x"
xb.Parent = bar
Instance.new("UICorner", xb).CornerRadius = UDim.new(0, 7)
xb.MouseButton1Click:Connect(function() gui:Destroy() end)

-- v23.2: floating PRIMEz toggle button, pinned bottom-left. Tap to hide the
-- TinyDex window, tap again to show it. PULSAR, the agent loop, tools and
-- the terminal keep running while the window is hidden. The X button is
-- still the only way to remove TinyDex completely (it takes the P button
-- with it).
-- v23.3: the P button is also DRAGGABLE — press and slide it anywhere on
-- screen (any side, any corner) so it never has to sit on top of the game's
-- mobile controls. Drag = move, quick tap = toggle.
local pBtn = Instance.new("TextButton")
pBtn.Name = "PRIMEzToggle"
pBtn.Size = UDim2.new(0, 40, 0, 40)
pBtn.AnchorPoint = Vector2.new(0, 0)
pBtn.Position = UDim2.new(0, 10, 1, -52)
pBtn.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
pBtn.BorderSizePixel = 0
pBtn.Font = Enum.Font.GothamBold
pBtn.TextSize = 21
pBtn.Text = "P"
pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pBtn.AutoButtonColor = false
pBtn.Parent = gui
Instance.new("UICorner", pBtn).CornerRadius = UDim.new(1, 0)
local pStroke = Instance.new("UIStroke", pBtn)
pStroke.Color = C.hot
pStroke.Thickness = 1.5
pStroke.Transparency = 0.12

-- v23.6-SMOOTH UI: register the finished window with the boot splash and
-- arm its entrance animation (elastic scale-in + stroke glow fade-in, and a
-- pop-in for the P button). The show/hide toggle below is untouched.
pBtn.Visible = false
BOOTUI.win = win
BOOTUI.pBtn = pBtn
BOOTUI.reveal = function()
  if BOOTUI.revealed then return end
  BOOTUI.revealed = true
  win.Visible = true
  local finalScale = winScale.Scale
  winScale.Scale = finalScale * 0.7
  TweenService:Create(winScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = finalScale}):Play()
  outerStroke.Transparency = 1
  TweenService:Create(outerStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.08}):Play()
  local pScale = Instance.new("UIScale")
  pScale.Parent = pBtn
  pScale.Scale = 0
  task.delay(0.18, function()
    pBtn.Visible = true
    TweenService:Create(pScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
  end)
end

-- v23.6-SMOOTH UI: live theme re-tint. Walks the finished interface and
-- swaps every colour that comes from the C palette (plus the derived window
-- gradient tints), so switching themes needs no reload. C is updated in
-- place, so anything created afterwards matches too. Colours are matched by
-- RGB value, not object identity, so shared palette values resolve correctly.
local function rgbkey(c)
  return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
BOOTUI.applyTheme = function(name)
  local th = THEMES[name]
  if not th then return end
  local map = {}
  for k, v in pairs(C) do map[rgbkey(v)] = th[k] end
  for _, f in ipairs({ 0.10, 0.05, 0.22 }) do
    map[rgbkey(tint(C.bg, C.hot, f))] = tint(th.bg, th.hot, f)
  end
  local function swap(c) return map[rgbkey(c)] end
  local function walk(o)
    for _, d in ipairs(o:GetChildren()) do
      pcall(function()
        if d:IsA("GuiObject") then
          local s = swap(d.BackgroundColor3)
          if s then d.BackgroundColor3 = s end
        end
        if d:IsA("TextLabel") or d:IsA("TextButton") then
          local s = swap(d.TextColor3)
          if s then d.TextColor3 = s end
        end
        if d:IsA("UIStroke") then
          local s = swap(d.Color)
          if s then d.Color = s end
        end
        if d:IsA("UIGradient") then
          local kps, changed = {}, false
          for _, kp in ipairs(d.Color.Keypoints) do
            local s = swap(kp.Value)
            if s then changed = true end
            kps[#kps + 1] = ColorSequenceKeypoint.new(kp.Time, s or kp.Value)
          end
          if changed then d.Color = ColorSequence.new(kps) end
        end
      end)
      walk(d)
    end
  end
  walk(gui)
  for k, v in pairs(th) do C[k] = v end
end

-- v23.3: drag the P button anywhere on screen; a quick tap toggles the
-- window. The button is live-clamped so it always stays fully visible.
local pDragging, pDragStart, pBtnStart, pMoved = false, nil, nil, false
pBtn.InputBegan:Connect(function(i)
  if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
    pDragging, pMoved = true, false
    pDragStart, pBtnStart = i.Position, pBtn.Position
  end
end)
UIS.InputChanged:Connect(function(i)
  if pDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
    local d = i.Position - pDragStart
    if not pMoved and (math.abs(d.X) > 8 or math.abs(d.Y) > 8) then pMoved = true end
    if pMoved then
      pBtn.Position = UDim2.new(pBtnStart.X.Scale, pBtnStart.X.Offset + d.X, pBtnStart.Y.Scale, pBtnStart.Y.Offset + d.Y)
      -- live clamp: keep the button fully on screen while dragging
      local cam = workspace.CurrentCamera
      local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
      local pos, size = pBtn.AbsolutePosition, pBtn.AbsoluteSize
      local nx = math.clamp(pos.X, 2, math.max(2, vp.X - size.X - 2))
      local ny = math.clamp(pos.Y, 2, math.max(2, vp.Y - size.Y - 2))
      if nx ~= pos.X or ny ~= pos.Y then
        pBtn.Position = UDim2.new(0, nx, 0, ny)
        pBtnStart, pDragStart = pBtn.Position, i.Position
      end
    end
  end
end)
-- v23.3.2 FIX: InputEnded on a small button is unreliable on mobile — if the
-- finger lifts slightly off the button it never fires, so P looked dead and
-- pDragging stayed stuck (the button then followed the next touch). Taps
-- now use the Activated event (fires reliably on release over the button,
-- never fires on a drag-away), and a GLOBAL InputEnded clears drag state and
-- suppresses the tap for 0.35s after any drag so a drag that ends on the
-- button can't accidentally toggle the window.
local pSuppressTapUntil = 0
UIS.InputEnded:Connect(function(i)
  if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
    if pDragging then
      pDragging = false
      if pMoved then
        pMoved = false
        pSuppressTapUntil = time() + 0.35
      end
    end
  end
end)
pBtn.Activated:Connect(function()
  if time() < pSuppressTapUntil then return end
  win.Visible = not win.Visible
  if win.Visible then
    -- v23.3.1 FIX: the old snap code read the window position before the
    -- layout refreshed and wrote offsets that ignored the window's center
    -- anchor — every show drifted the window until it landed in a corner
    -- where its title bar (the only drag handle) was unreachable. Now:
    -- wait one frame for fresh layout, and re-center the window ONLY if
    -- any part of it is off-screen. On-screen positions are untouched.
    task.wait()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local pos, size = win.AbsolutePosition, win.AbsoluteSize
    local offScreen = pos.X < -12 or pos.Y < -12
      or (pos.X + size.X) > (vp.X + 12) or (pos.Y + size.Y) > (vp.Y + 12)
    if offScreen then
      win.Position = UDim2.fromScale(0.5, 0.5)
    end
  end
end)

local readout = Instance.new("TextLabel")
readout.Size = UDim2.new(1, -26, 0, 14)
readout.Position = UDim2.new(0, 13, 0, 39)
readout.BackgroundTransparency = 1
readout.Font = Enum.Font.Code
readout.TextSize = 11
readout.TextXAlignment = Enum.TextXAlignment.Left
readout.TextTruncate = Enum.TextTruncate.AtEnd
readout.TextColor3 = C.hot
readout.Text = ""
readout.Parent = win

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.52, -10, 0, 14)
status.Position = UDim2.new(0, 13, 1, -19)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = C.good
status.Parent = win

local footer = Instance.new("TextLabel")
footer.Name = "PRIMEzFooter"
footer.Size = UDim2.new(1, -22, 0, 14)
footer.Position = UDim2.new(0, 11, 1, -17)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.Gotham
footer.TextSize = 9
footer.TextXAlignment = Enum.TextXAlignment.Right
footer.TextColor3 = Color3.fromRGB(133, 112, 170)
footer.Text = "PRIMEz Studios   •   Shared Inspection Index   •   v22.0 (No Limits)"
footer.Parent = win
local function flash(t, c)
  status.Text = tostring(t)
  status.TextColor3 = c or C.good
  task.delay(3, function() if status.Text == tostring(t) then status.Text = "" end end)
end
local function safe(label, fn, ...)
  local ok, e = pcall(fn, ...)
  if not ok then
    flash(label .. " ERR: " .. tostring(e), C.bad)
    warn("[TinyDex] " .. label .. ": " .. tostring(e))
  end
  return ok
end

-- Standard-Luau export surface: users can select and copy text manually.
local function showTextExport(title, payload)
  local overlay = Instance.new("Frame")
  overlay.Name = "TinyDexExport"
  overlay.Size = UDim2.fromScale(1, 1)
  overlay.BackgroundColor3 = Color3.new(0, 0, 0)
  overlay.BackgroundTransparency = 0.3
  overlay.ZIndex = 100
  overlay.Parent = gui

  local panel = Instance.new("Frame")
  panel.Size = UDim2.new(0.82, 0, 0.78, 0)
  panel.Position = UDim2.fromScale(0.09, 0.11)
  panel.BackgroundColor3 = C.panel
  panel.BorderSizePixel = 0
  panel.ZIndex = 101
  panel.Parent = overlay
  Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6)

  local heading = Instance.new("TextLabel")
  heading.Size = UDim2.new(1, -80, 0, 28)
  heading.Position = UDim2.fromOffset(8, 4)
  heading.BackgroundTransparency = 1
  heading.Font = Enum.Font.GothamBold
  heading.TextSize = 12
  heading.TextXAlignment = Enum.TextXAlignment.Left
  heading.TextColor3 = C.txt
  heading.Text = title .. " — select text, then copy"
  heading.ZIndex = 102
  heading.Parent = panel

  local close = Instance.new("TextButton")
  close.Size = UDim2.fromOffset(28, 24)
  close.Position = UDim2.new(1, -34, 0, 5)
  close.BackgroundColor3 = C.row
  close.TextColor3 = C.bad
  close.Font = Enum.Font.Code
  close.Text = "X"
  close.ZIndex = 102
  close.Parent = panel
  close.MouseButton1Click:Connect(function() overlay:Destroy() end)

  local body = Instance.new("TextBox")
  body.Size = UDim2.new(1, -16, 1, -44)
  body.Position = UDim2.fromOffset(8, 36)
  body.BackgroundColor3 = C.row
  body.BorderSizePixel = 0
  body.ClearTextOnFocus = false
  body.MultiLine = true
  body.TextEditable = true
  body.TextWrapped = false
  body.TextXAlignment = Enum.TextXAlignment.Left
  body.TextYAlignment = Enum.TextYAlignment.Top
  body.Font = Enum.Font.Code
  body.TextSize = 11
  body.TextColor3 = C.txt
  body.Text = payload
  body.ZIndex = 102
  body.Parent = panel
  body:CaptureFocus()
  body.CursorPosition = 1
  body.SelectionStart = #body.Text + 1
end

local search = Instance.new("TextBox")
search.Size = UDim2.new(0, 340, 0, 27)
search.Position = UDim2.new(0, 10, 0, 59)
search.BackgroundColor3 = C.row
search.BorderSizePixel = 0
search.Font = Enum.Font.Gotham
search.TextSize = 11
search.Text = ""
search.PlaceholderText = "search name / class"
search.TextColor3 = C.txt
search.PlaceholderColor3 = C.dim
search.ClearTextOnFocus = false
search.TextXAlignment = Enum.TextXAlignment.Left
search.Parent = win
Instance.new("UIPadding", search).PaddingLeft = UDim.new(0, 5)
Instance.new("UICorner", search).CornerRadius = UDim.new(0, 7)
local searchStroke = Instance.new("UIStroke", search)
searchStroke.Color = C.line
searchStroke.Transparency = 0.4

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(0, 340, 1, -120)
list.Position = UDim2.new(0, 10, 0, 92)
list.BackgroundColor3 = C.row
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new(0,0,0,0)
list.Parent = win
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 9)
local listStroke = Instance.new("UIStroke", list)
listStroke.Color = C.line
listStroke.Transparency = 0.48
Instance.new("UIListLayout", list).SortOrder = Enum.SortOrder.LayoutOrder

local right = Instance.new("Frame")
right.Size = UDim2.new(1, -370, 1, -70)
right.Position = UDim2.new(0, 360, 0, 40)
right.BackgroundColor3 = C.panel
right.BorderSizePixel = 0
right.Parent = win
Instance.new("UICorner", right).CornerRadius = UDim.new(0, 10)
local rightStroke = Instance.new("UIStroke", right)
rightStroke.Color = C.line
rightStroke.Transparency = 0.42

local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -16, 0, 28)
tabRow.Position = UDim2.new(0, 8, 0, 7)
tabRow.BackgroundTransparency = 1
tabRow.Parent = right
local tl = Instance.new("UIListLayout")
tl.FillDirection = Enum.FillDirection.Horizontal
tl.Padding = UDim.new(0, 6)
tl.Parent = tabRow

local pageArea = Instance.new("Frame")
pageArea.Size = UDim2.new(1, -16, 1, -47)
pageArea.Position = UDim2.new(0, 8, 0, 43)
pageArea.BackgroundTransparency = 1
pageArea.Parent = right

local pages, tabBtns = {}, {}
local function gotoTab(n)
  for k, p in pairs(pages) do p.Visible = (k == n) end
  for k, b in pairs(tabBtns) do
    b.TextColor3 = (k == n) and Color3.fromRGB(255, 250, 255) or C.dim
    local target = (k == n) and Color3.fromRGB(83, 43, 139) or Color3.fromRGB(28, 24, 43)
    TweenService:Create(b, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = target}):Play()
  end
  if n == "3D" then safe("view", buildView, selected) end
end
for _, n in ipairs({ "Props", "3D", "Code", "Term", "Hub" }) do
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(0, 92, 0, 26)
  b.BackgroundColor3 = Color3.fromRGB(28, 24, 43)
  b.BorderSizePixel = 0
  b.Font = Enum.Font.GothamSemibold
  b.TextSize = 10
  b.Text = ({Props = "INSPECT", ["3D"] = "PREVIEW", Code = "WORKSPACE", Term = "CONSOLE", Hub = "PRIMEZ_"})[n]
  b.TextColor3 = C.dim
  b.Parent = tabRow
  Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
  local tabStroke = Instance.new("UIStroke", b)
  tabStroke.Color = C.line
  tabStroke.Transparency = 0.55
  b.MouseButton1Click:Connect(function() gotoTab(n) end)
  tabBtns[n] = b
  local p = Instance.new("Frame")
  p.Size = UDim2.new(1,0,1,0)
  p.BackgroundTransparency = 1
  p.Visible = false
  p.Parent = pageArea
  pages[n] = p
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PRIMEZ_ TAB — official PRIMEz hub: website + community Discord.
-- ═══════════════════════════════════════════════════════════════════════════
do
  local nTabs = 0
  for _ in pairs(tabBtns) do nTabs += 1 end
  local tabW = math.floor((514 - (nTabs - 1) * 6) / nTabs)
  for _, b in pairs(tabBtns) do
    b.Size = UDim2.new(0, tabW, 0, 26)
    b.TextSize = 9
  end

  local hub = pages["Hub"]
  local SITE_URL = "https://primez-guard.vercel.app/"
  local DISCORD_URL = "https://discord.gg/u3pZxDF3c"
  PRIMEZ_DISCORD_URL = DISCORD_URL -- global: read by the terminal 'agent' hint

  local hero = Instance.new("Frame")
  hero.Size = UDim2.new(1, -24, 0, 108)
  hero.Position = UDim2.new(0, 12, 0, 10)
  hero.BackgroundColor3 = Color3.fromRGB(30, 20, 52)
  hero.BorderSizePixel = 0
  hero.Parent = hub
  Instance.new("UICorner", hero).CornerRadius = UDim.new(0, 12)
  local heroG = Instance.new("UIGradient")
  heroG.Color = ColorSequence.new(Color3.fromRGB(124, 58, 237), Color3.fromRGB(34, 211, 238))
  heroG.Rotation = 15
  heroG.Parent = hero

  local hTitle = Instance.new("TextLabel")
  hTitle.Size = UDim2.new(1, -32, 0, 40)
  hTitle.Position = UDim2.new(0, 16, 0, 12)
  hTitle.BackgroundTransparency = 1
  hTitle.Font = Enum.Font.GothamBlack
  hTitle.TextSize = 32
  hTitle.TextXAlignment = Enum.TextXAlignment.Left
  hTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
  hTitle.Text = "PRIMEz ▸ HUB"
  hTitle.Parent = hero

  local hSub = Instance.new("TextLabel")
  hSub.Size = UDim2.new(1, -32, 0, 16)
  hSub.Position = UDim2.new(0, 17, 0, 54)
  hSub.BackgroundTransparency = 1
  hSub.Font = Enum.Font.GothamBold
  hSub.TextSize = 11
  hSub.TextXAlignment = Enum.TextXAlignment.Left
  hSub.TextColor3 = Color3.fromRGB(233, 226, 255)
  hSub.Text = "STUDIOS  •  TINYDEX  •  OFFICIAL LINKS"
  hSub.Parent = hero

  local hTag = Instance.new("TextLabel")
  hTag.Size = UDim2.new(1, -32, 0, 16)
  hTag.Position = UDim2.new(0, 17, 0, 78)
  hTag.BackgroundTransparency = 1
  hTag.Font = Enum.Font.Gotham
  hTag.TextSize = 11
  hTag.TextXAlignment = Enum.TextXAlignment.Left
  hTag.TextColor3 = Color3.fromRGB(255, 255, 255)
  hTag.TextTransparency = 0.35
  hTag.Text = "Everything PRIMEz in one place — official site and community Discord below."
  hTag.Parent = hero

  local function copyToClipboard(txt)
    local ok = pcall(function() setclipboard(txt) end)
    if not ok then ok = pcall(function() toclipboard(txt) end) end
    return ok
  end

  local function linkCard(y, accent, titleTxt, descTxt, url)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -24, 0, 84)
    card.Position = UDim2.new(0, 12, 0, y)
    card.BackgroundColor3 = C.panel
    card.BorderSizePixel = 0
    card.Parent = hub
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = C.line
    cardStroke.Transparency = 0.45
    cardStroke.Parent = card

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -16)
    bar.Position = UDim2.new(0, 10, 0, 8)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    bar.Parent = card
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, -140, 0, 18)
    t1.Position = UDim2.new(0, 26, 0, 10)
    t1.BackgroundTransparency = 1
    t1.Font = Enum.Font.GothamBold
    t1.TextSize = 13
    t1.TextXAlignment = Enum.TextXAlignment.Left
    t1.TextColor3 = accent
    t1.Text = titleTxt
    t1.Parent = card

    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, -140, 0, 16)
    t2.Position = UDim2.new(0, 26, 0, 30)
    t2.BackgroundTransparency = 1
    t2.Font = Enum.Font.Gotham
    t2.TextSize = 11
    t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.TextColor3 = C.dim
    t2.Text = descTxt
    t2.Parent = card

    local urlBox = Instance.new("TextBox")
    urlBox.Size = UDim2.new(1, -150, 0, 18)
    urlBox.Position = UDim2.new(0, 26, 0, 54)
    urlBox.BackgroundTransparency = 1
    urlBox.Font = Enum.Font.Code
    urlBox.TextSize = 11
    urlBox.TextXAlignment = Enum.TextXAlignment.Left
    urlBox.TextColor3 = C.txt
    urlBox.Text = url
    urlBox.ClearTextOnFocus = false
    urlBox.Parent = card

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 104, 0, 30)
    copyBtn.Position = UDim2.new(1, -118, 1, -42)
    copyBtn.BackgroundColor3 = accent
    copyBtn.BorderSizePixel = 0
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 11
    copyBtn.TextColor3 = Color3.fromRGB(16, 12, 28)
    copyBtn.Text = "COPY LINK"
    copyBtn.Parent = card
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)
    copyBtn.MouseButton1Click:Connect(function()
      local ok = copyToClipboard(url)
      copyBtn.Text = ok and "COPIED ✔" or "SELECT + COPY"
      task.delay(1.4, function() copyBtn.Text = "COPY LINK" end)
    end)
  end

  linkCard(130, Color3.fromRGB(34, 211, 238), "PRIMEz WEBSITE",
    "Official PRIMEz site — releases, access and the PRIMEz hub.", SITE_URL)
  linkCard(226, Color3.fromRGB(88, 101, 242), "PRIMEz DISCORD",
    "Community server — support, previews and announcements.", DISCORD_URL)

  local foot = Instance.new("TextLabel")
  foot.Size = UDim2.new(1, -24, 0, 16)
  foot.Position = UDim2.new(0, 12, 1, -28)
  foot.BackgroundTransparency = 1
  foot.Font = Enum.Font.Gotham
  foot.TextSize = 10
  foot.TextColor3 = C.dim
  foot.Text = "PRIMEz Studios  •  primez-guard.vercel.app"
  foot.Parent = hub
end

-- Lua Workspace: edit and review snippets. This client intentionally does not
-- compile/execute arbitrary text; use Roblox Studio's Script Editor for execution
-- in projects you own or are authorized to develop.
local codePage = pages["Code"]
local codeHeader = Instance.new("Frame")
codeHeader.Size = UDim2.new(1, 0, 0, 32)
codeHeader.BackgroundTransparency = 1
codeHeader.Parent = codePage
local codeTitle = Instance.new("TextLabel")
codeTitle.Size = UDim2.new(0.45, 0, 1, 0)
codeTitle.BackgroundTransparency = 1
codeTitle.Font = Enum.Font.GothamBold
codeTitle.TextSize = 12
codeTitle.TextXAlignment = Enum.TextXAlignment.Left
codeTitle.TextColor3 = C.txt
codeTitle.Text = "Lua Workspace  ·  Draft Editor"
codeTitle.Parent = codeHeader
local function editorButton(label, width, offset)
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(width, 25)
  b.Position = UDim2.new(1, offset, 0, 3)
  b.BackgroundColor3 = Color3.fromRGB(48, 29, 79)
  b.BorderSizePixel = 0
  b.Font = Enum.Font.GothamSemibold
  b.TextSize = 10
  b.TextColor3 = C.txt
  b.Text = label
  b.Parent = codeHeader
  Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
  return b
end
local validateDraft = editorButton("CHECK", 62, -68)
local clearDraft = editorButton("CLEAR", 58, -132)
local editor = Instance.new("TextBox")
editor.Name = "LuaDraftEditor"
editor.Size = UDim2.new(1, 0, 1, -68)
editor.Position = UDim2.fromOffset(0, 36)
editor.BackgroundColor3 = Color3.fromRGB(12, 11, 20)
editor.BorderSizePixel = 0
editor.Font = Enum.Font.Code
editor.TextSize = 12
editor.TextColor3 = Color3.fromRGB(220, 213, 240)
editor.PlaceholderColor3 = C.dim
editor.PlaceholderText = "-- Write or paste a Luau draft here\\n-- Use CHECK for a basic delimiter review."
editor.Text = "-- PRIMEz TinyDex Lua Workspace\\n-- Draft and review Luau here.\\n-- For execution, use Roblox Studio in an experience you own.\\n"
editor.ClearTextOnFocus = false
editor.MultiLine = true
editor.TextWrapped = false
editor.TextXAlignment = Enum.TextXAlignment.Left
editor.TextYAlignment = Enum.TextYAlignment.Top
editor.Parent = codePage
Instance.new("UICorner", editor).CornerRadius = UDim.new(0, 8)
local editorStroke = Instance.new("UIStroke", editor)
editorStroke.Color = C.line
editorStroke.Transparency = 0.35
local editorPad = Instance.new("UIPadding", editor)
editorPad.PaddingTop = UDim.new(0, 9)
editorPad.PaddingLeft = UDim.new(0, 10)
editorPad.PaddingRight = UDim.new(0, 8)
local editorNote = Instance.new("TextLabel")
editorNote.Size = UDim2.new(1, 0, 0, 22)
editorNote.Position = UDim2.new(0, 0, 1, -24)
editorNote.BackgroundTransparency = 1
editorNote.Font = Enum.Font.Gotham
editorNote.TextSize = 9
editorNote.TextXAlignment = Enum.TextXAlignment.Left
editorNote.TextColor3 = C.dim
editorNote.Text = "DRAFT MODE  •  Run with CONSOLE `run` or let PULSAR auto-run it"
editorNote.Parent = codePage
local function checkDraft()
  local source = editor.Text or ""
  local stack, pairsMap = {}, { [")"] = "(", ["]"] = "[", ["}"] = "{" }
  local quote, escaped, lineComment, blockComment = nil, false, false, false
  local i = 1
  while i <= #source do
    local ch, nx = source:sub(i,i), source:sub(i+1,i+1)
    if lineComment then
      if ch == "\n" then lineComment = false end
    elseif blockComment then
      if ch == "]" and nx == "]" then blockComment = false; i = i + 1 end
    elseif quote then
      if escaped then escaped = false
      elseif ch == "\\" then escaped = true
      elseif ch == quote then quote = nil end
    elseif ch == "-" and nx == "-" then
      if source:sub(i+2,i+3) == "[[" then blockComment = true; i = i + 3 else lineComment = true; i = i + 1 end
    elseif ch == "'" or ch == '"' or ch == "`" then quote = ch
    elseif ch == "(" or ch == "[" or ch == "{" then table.insert(stack, ch)
    elseif pairsMap[ch] then
      if stack[#stack] ~= pairsMap[ch] then
        editorNote.Text = "CHECK FAILED  •  Unexpected " .. ch .. " near character " .. i
        editorNote.TextColor3 = C.bad
        return
      end
      table.remove(stack)
    end
    i = i + 1
  end
  if quote then editorNote.Text = "CHECK WARNING  •  Unclosed string literal"
  elseif blockComment then editorNote.Text = "CHECK WARNING  •  Unclosed block comment"
  elseif #stack > 0 then editorNote.Text = "CHECK WARNING  •  Unclosed delimiter " .. stack[#stack]
  else editorNote.Text = "BASIC CHECK PASSED  •  Delimiters balanced; not a full Luau compile" end
  editorNote.TextColor3 = (quote or blockComment or #stack > 0) and C.bad or C.good
end
validateDraft.MouseButton1Click:Connect(checkDraft)
clearDraft.MouseButton1Click:Connect(function()
  editor.Text = ""
  editorNote.Text = "Draft cleared."
  editorNote.TextColor3 = C.dim
end)

local selected, expanded, vis = nil, {}, {}
local propList, vp -- forward declarations used by diagnostics
local selBox = Instance.new("SelectionBox")
selBox.LineThickness = 0.03
selBox.Color3 = Color3.fromRGB(0, 170, 255)
selBox.Visible = false
selBox.Parent = workspace

local function pathOf(i)
  local ok, p = pcall(function() return i:GetFullName() end)
  return ok and p or "?"
end

-- Roblox Instances are userdata-like objects: `next(instance)` does not
-- enumerate their properties. Probe a safe, broad list and keep readable ones.
local PROPERTY_CANDIDATES = {
  "Name", "ClassName", "Parent", "Archivable", "AbsolutePosition", "AbsoluteSize",
  "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency",
  "BorderColor3", "BorderSizePixel", "CanvasPosition", "CanvasSize", "ClipsDescendants",
  "Color", "CFrame", "CastShadow", "CanCollide", "CanQuery", "CanTouch", "Transparency",
  "BrickColor", "Material", "Reflectance", "Size", "Position", "Orientation", "PivotOffset",
  "Shape", "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface",
  "BackSurface", "AssemblyLinearVelocity", "AssemblyAngularVelocity", "Mass",
  "Massless", "Anchored", "Velocity", "RotVelocity", "CollisionGroup",
  "Text", "TextColor3", "TextTransparency", "TextSize", "TextScaled", "TextWrapped",
  "TextXAlignment", "TextYAlignment", "Font", "FontFace", "RichText", "PlaceholderText",
  "Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize",
  "Visible", "Enabled", "Active", "Selectable", "Modal", "DisplayOrder", "ResetOnSpawn",
  "ZIndex", "LayoutOrder", "Rotation", "ScaleType", "SliceCenter", "TileSize",
  "Value", "MaxValue", "MinValue", "Disabled", "Looped", "Playing", "TimePosition",
  "PlaybackSpeed", "Volume", "SoundId", "AnimationId", "WalkSpeed", "JumpPower",
  "JumpHeight", "HipHeight", "Health", "MaxHealth", "Team", "Neutral", "UserId",
  "AccountAge", "DisplayName", "RigType", "PrimaryPart", "WorldPivot", "ModelStreamingMode",
  "CurrentCamera", "FieldOfView", "CameraType", "CameraSubject", "Focus", "Ambient",
  "LightColor", "LightDirection", "Brightness", "ClockTime", "GeographicLatitude",
  "FogColor", "FogEnd", "FogStart", "GlobalShadows", "OutdoorAmbient", "TimeOfDay",
  "PlaybackState", "SoundGroup", "EmitterSize", "RollOffMaxDistance", "RollOffMinDistance",
  "Rate", "Lifetime", "Speed", "SpreadAngle", "Enabled", "Texture", "TextureID",
  "MeshId", "TextureID", "Animation", "PrimaryAxis", "SecondaryAxis", "Target",
  "TargetFilter", "CurrentDistance", "Enabled", "Style", "Color3", "TextButton",
}
local READ_ONLY_PROPERTIES = {
  ClassName = true, Parent = true, AbsolutePosition = true, AbsoluteSize = true,
  AssemblyLinearVelocity = true, AssemblyAngularVelocity = true, Mass = true,
  PlaybackState = true, UserId = true, AccountAge = true, DisplayName = true,
  CurrentDistance = true,
}
local function readableProperties(inst)
  local names, seen = {}, {}
  local function addName(name)
    if type(name) ~= "string" or seen[name] then return end
    seen[name] = true
    local ok = pcall(function() return inst[name] end)
    if ok then names[#names + 1] = name end
  end

  -- Standard Roblox Luau does not expose universal property enumeration.
  -- Use the curated, readable property list below; no executor APIs are probed.
  -- Standard Roblox fallback: enumerate a broad, safe list of common
  -- properties. No property is assigned during copying.
  for _, name in ipairs(PROPERTY_CANDIDATES) do addName(name) end
  table.sort(names)
  return names
end

local function valueToText(value)
  local kind = typeof(value)
  if kind == "Instance" then return pathOf(value) end
  if kind == "string" then return string.format("%q", value) end
  if kind == "table" then
    local ok, encoded = pcall(function() return HttpService:JSONEncode(value) end)
    if ok then return encoded end
  end
  return tostring(value)
end


local inspectionIndexDirty, inspectionIndexEpoch = true, 0
local inspectionIndexCache = "Inspection index has not been built yet."
local inspectionIndexRevision, inspectionIndexCount = 0, 0
local inspectionIndexTruncated = false
local indexInfo

local function markInspectionIndexDirty()
  inspectionIndexEpoch += 1
  inspectionIndexDirty = true
  if indexInfo then indexInfo.Text = "INDEX OUTDATED · refresh pending" end
end

local KNOWN_SERVICES = {
  "Workspace", "Players", "Lighting", "ReplicatedFirst", "ReplicatedStorage",
  "StarterGui", "StarterPack", "StarterPlayer", "SoundService", "Chat",
  "TextChatService", "LocalizationService", "JointsService", "MaterialService",
  "ServerScriptService", "ServerStorage", "HttpService",
}

local function resolveTarget(name)
  if not name or name == "" then return nil end
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  local ok, s = pcall(function() return game:GetService(name) end)
  if ok and s then return s end
  for _, sName in ipairs(KNOWN_SERVICES) do
    if sName:lower() == name:lower() then
      local sOk, res = pcall(function() return game:GetService(sName) end)
      if sOk and res then return res end
    end
  end
  local found
  pcall(function()
    found = game:FindFirstChild(name, true)
  end)
  return found
end

local PULSAR_INDEX_PROPERTIES = {
  "Value", "Text", "Visible", "Enabled", "Active", "Anchored", "CanCollide",
  "Transparency", "Position", "Size", "WalkSpeed", "JumpPower", "JumpHeight",
  "Health", "MaxHealth", "DisplayName", "Team", "Material", "Color",
  "BackgroundColor3", "Image", "SoundId", "AnimationId", "PlaybackSpeed",
}
local function indexValue(inst, propertyName)
  local ok, value = pcall(function() return inst[propertyName] end)
  if not ok then return nil end
  local kind = typeof(value)
  if kind ~= "string" and kind ~= "number" and kind ~= "boolean"
    and kind ~= "EnumItem" and kind ~= "Vector2" and kind ~= "Vector3"
    and kind ~= "CFrame" and kind ~= "Color3" and kind ~= "UDim"
    and kind ~= "UDim2" and kind ~= "BrickColor" and kind ~= "Instance" then
    return nil
  end
  local rendered = valueToText(value)
  if #rendered > 120 then rendered = rendered:sub(1, 117) .. "..." end
  return propertyName .. "=" .. rendered
end

local function rebuildInspectionIndex()
  if not inspectionIndexDirty then return inspectionIndexCache end
  local buildEpoch = inspectionIndexEpoch
  local lines = {
    "SCOPE: Full client-accessible Roblox DataModel descendants (NO LIMITS).",
    "STATUS: Complete, unconstrained live hierarchy snapshot.",
  }
  local stack, seen, seenRoots = {}, {}, {}

  -- Discover all accessible root services (StarterPlayer, ServerStorage, Workspace, etc.)
  for _, sName in ipairs(KNOWN_SERVICES) do
    pcall(function()
      local s = game:GetService(sName)
      if s and s ~= gui and not seenRoots[s] then
        seenRoots[s] = true
        stack[#stack + 1] = s
      end
    end)
  end

  local roots = {}
  pcall(function() roots = game:GetChildren() end)
  for i = #roots, 1, -1 do
    local r = roots[i]
    if r and r ~= gui and not seenRoots[r] then
      seenRoots[r] = true
      stack[#stack + 1] = r
    end
  end

  -- PERF: hard caps + CPU budget so big games can't freeze the client or
  -- balloon memory (v23.1). Index is built lazily, never at boot.
  local INDEX_MAX_INSTANCES = 4000
  local INDEX_CPU_BUDGET = 2.0
  local buildStartClock = os.clock()
  local count = 0
  local stoppedWhy = nil
  while #stack > 0 do
    local inst = table.remove(stack)
    if inst and inst ~= gui and not seen[inst] then
      seen[inst] = true
      local childOk, children = pcall(function() return inst:GetChildren() end)
      if not childOk or type(children) ~= "table" then children = {} end

      local entry = {
        ("ITEM %d | %s | %s | children=%d"):format(
          count + 1, tostring(inst.ClassName), tostring(inst.Name), #children
        ),
        "PATH: " .. tostring(pathOf(inst)),
      }

      local propParts = {}
      for _, propertyName in ipairs(PULSAR_INDEX_PROPERTIES) do
        local rendered = indexValue(inst, propertyName)
        if rendered then
          propParts[#propParts + 1] = rendered
        end
      end
      if #propParts > 0 then entry[#entry + 1] = "PROPERTIES: " .. table.concat(propParts, " | ") end

      local attrOk, attrs = pcall(function() return inst:GetAttributes() end)
      if attrOk and type(attrs) == "table" then
        local keys = {}
        for key in pairs(attrs) do keys[#keys + 1] = tostring(key) end
        table.sort(keys)
        local attrParts = {}
        for i = 1, #keys do
          local key = keys[i]
          local valueOk, value = pcall(function() return inst:GetAttribute(key) end)
          if valueOk then
            local rendered = valueToText(value)
            attrParts[#attrParts + 1] = key .. "=" .. rendered
          end
        end
        if #attrParts > 0 then entry[#entry + 1] = "ATTRIBUTES: " .. table.concat(attrParts, " | ") end
      end

      local childParts = {}
      for i = 1, math.min(#children, 12) do
        local child = children[i]
        childParts[#childParts + 1] = tostring(child.Name) .. "<" .. tostring(child.ClassName) .. ">"
      end
      if #children > 12 then childParts[#childParts + 1] = ("…(+%d more)"):format(#children - 12) end
      if #childParts > 0 then entry[#entry + 1] = "DIRECT CHILDREN: " .. table.concat(childParts, ", ") end

      lines[#lines + 1] = table.concat(entry, "\n")
      count += 1

      for i = #children, 1, -1 do
        if children[i] ~= gui and not seen[children[i]] then
          stack[#stack + 1] = children[i]
        end
      end

      if count % 10 == 0 then task.wait() end
      if count >= INDEX_MAX_INSTANCES then stoppedWhy = "instance cap reached" break end
      if os.clock() - buildStartClock > INDEX_CPU_BUDGET then stoppedWhy = "cpu budget reached" break end
    end
  end

  inspectionIndexCount = count
  inspectionIndexTruncated = stoppedWhy ~= nil
  inspectionIndexRevision += 1
  inspectionIndexCache = table.concat(lines, "\n")
    .. ("\nINDEX SUMMARY: %d instances indexed; revision %d; %s"):format(
      count, inspectionIndexRevision,
      stoppedWhy and ("PARTIAL — stopped: " .. stoppedWhy .. ". Use search_game/inspect for anything not listed.") or "complete index."
    )
  inspectionIndexDirty = inspectionIndexEpoch ~= buildEpoch
  if indexInfo then
    indexInfo.Text = ("INDEX %d · REV %d · %s"):format(
      inspectionIndexCount, inspectionIndexRevision, stoppedWhy and "CAPPED" or "FULL"
    )
    indexInfo.TextColor3 = inspectionIndexDirty and C.dim or C.good
  end
  return inspectionIndexCache
end

game.DescendantAdded:Connect(function(inst)
  if inst ~= gui and not inst:IsDescendantOf(gui) then markInspectionIndexDirty() end
end)
game.DescendantRemoving:Connect(function(inst)
  if inst ~= gui and not inst:IsDescendantOf(gui) then markInspectionIndexDirty() end
end)
local function dump(inst, out)
  if not inst or not inst.Parent and inst ~= game then return end
  out[#out+1] = "=================================================="
  out[#out+1] = "PATH: " .. pathOf(inst)
  out[#out+1] = "CLASS: " .. inst.ClassName
  out[#out+1] = "NAME: " .. inst.Name
  out[#out+1] = "-- PROPERTIES"
  local names = readableProperties(inst)
  for _, k in ipairs(names) do
    local ok, v = pcall(function() return inst[k] end)
    if ok then out[#out+1] = k .. " = " .. valueToText(v) end
  end

  local oka, at = pcall(function() return inst:GetAttributes() end)
  if oka and at then
    out[#out+1] = "-- ATTRIBUTES"
    local keys = {}
    for k in pairs(at) do keys[#keys + 1] = k end
    table.sort(keys)
    if #keys == 0 then out[#out+1] = "(none)" end
    for _, k in ipairs(keys) do out[#out+1] = k .. " = " .. valueToText(at[k]) end
  end

  local okTags, tags = pcall(function()
    return game:GetService("CollectionService"):GetTags(inst)
  end)
  if okTags then
    table.sort(tags)
    out[#out+1] = "-- TAGS"
    out[#out+1] = #tags > 0 and table.concat(tags, ", ") or "(none)"
  end
  out[#out+1] = ""
end

local copying = false
local function copy(insts, note)
  if copying then return flash("copy already running", C.bad) end
  copying = true
  task.spawn(function()
    -- Export each supplied Explorer row AND every descendant beneath it.
    -- Keep a running size counter (rather than rescanning the output on each
    -- object) and yield periodically so large trees do not monopolize a frame.
    local MAX_CHARS = 250000
    local out = {
      "Tiny Dex — RECURSIVE TREE EXPORT",
      "Roots supplied by Explorer: " .. tostring(#insts),
      "Every reachable descendant is traversed recursively; duplicate instances are emitted once.",
      "Each object includes its path, class, name, readable properties, attributes, and CollectionService tags where available.",
      "Property limitation: standard Roblox Luau has no universal property-enumeration API; a curated built-in property list is used.",
      "Export safety limit: approximately 250,000 characters. If reached, the export reports truncation instead of freezing the client.",
      "",
    }
    local size = 0
    for _, line in ipairs(out) do size = size + #line + 1 end
    local stack, seen = {}, {}
    -- Reverse insertion preserves the Explorer's usual forward order in DFS.
    for i = #insts, 1, -1 do
      if insts[i] then stack[#stack + 1] = insts[i] end
    end
    local count, stopped, failed = 0, false, 0
    while #stack > 0 do
      local inst = table.remove(stack)
      if inst and not seen[inst] then
        seen[inst] = true
        local objectOut = {}
        local ok = pcall(dump, inst, objectOut)
        if ok then
          local chunk = table.concat(objectOut, "\n") .. "\n"
          if size + #chunk > MAX_CHARS then
            out[#out + 1] = "[TRUNCATED SAFELY] Clipboard size limit reached. Collapse/filter the Explorer and copy smaller subtrees to export the remainder."
            stopped = true
            break
          end
          for _, line in ipairs(objectOut) do out[#out + 1] = line end
          size = size + #chunk
          count = count + 1
        else
          failed = failed + 1
          out[#out + 1] = "[ERROR] Could not dump an object at " .. pathOf(inst)
        end

        -- Add every child regardless of whether its Explorer row is expanded.
        local children = {}
        pcall(function()
          for _, child in ipairs(inst:GetChildren()) do
            children[#children + 1] = child
          end
        end)
        for i = #children, 1, -1 do
          if not seen[children[i]] then stack[#stack + 1] = children[i] end
        end

        if count % 2 == 0 then task.wait() end
      end
    end
    if failed > 0 then out[#out + 1] = "Objects that could not be fully read: " .. tostring(failed) end
    local payload = table.concat(out, "\n")
    copying = false
    showTextExport(note or "Tree export", payload)
    flash("export ready · " .. count .. " objects · " .. #payload .. " chars" .. (stopped and " · safely truncated" or ""), C.good)
  end)
end

local refreshProps, buildView, render
local function selectInst(i)
  selected = i
  safe("selbox", function()
    selBox.Adornee = i
    selBox.Visible = i ~= nil and i:IsA("BasePart")
  end)
  safe("props", refreshProps)
  if pages["3D"] and pages["3D"].Visible then
    safe("view", buildView, i)
  end
end

function render()
  markInspectionIndexDirty()
  for _, c in ipairs(list:GetChildren()) do
    if c:IsA("TextButton") then c:Destroy() end
  end
  vis = {}
  local q = search.Text:lower()
  local matchBelowCache = {}

  local function matches(inst)
    return q == ""
      or inst.Name:lower():find(q, 1, true) ~= nil
      or inst.ClassName:lower():find(q, 1, true) ~= nil
  end

  local function getChildren(inst)
    local kids = {}
    local ok = pcall(function()
      for _, child in ipairs(inst:GetChildren()) do
        kids[#kids + 1] = child
      end
    end)
    if not ok then return {} end
    table.sort(kids, function(a, b)
      local an, bn = a.Name:lower(), b.Name:lower()
      if an == bn then return a.ClassName < b.ClassName end
      return an < bn
    end)
    return kids
  end

  local function hasMatchBelow(inst)
    if matchBelowCache[inst] ~= nil then
      return matchBelowCache[inst]
    end
    local found = false
    for _, child in ipairs(getChildren(inst)) do
      if matches(child) or hasMatchBelow(child) then
        found = true
        break
      end
    end
    matchBelowCache[inst] = found
    return found
  end

  local function makeLine(parent, x, y, h, w)
    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    line.BackgroundColor3 = C.good
    line.BackgroundTransparency = 0.08
    line.Position = UDim2.fromOffset(x, y)
    line.Size = UDim2.fromOffset(w or 1, h)
    line.Parent = parent
    return line
  end

  -- Each visible row is a node in a real tree. Ancestor guide lines are
  -- repeated down the rows while that ancestor has following siblings.
  local function walk(parentInst, depth, ancestorContinues)
    local sourceKids = getChildren(parentInst)
    local shownKids = {}
    for _, child in ipairs(sourceKids) do
      if q == "" or matches(child) or hasMatchBelow(child) then
        shownKids[#shownKids + 1] = child
      end
    end

    for index, child in ipairs(shownKids) do
      local isLast = index == #shownKids
      local childKids = getChildren(child)
      local childCount = #childKids
      local hasChildren = childCount > 0
      local isOpen = expanded[child] == true or q ~= ""
      local rowHeight = 21

      vis[#vis + 1] = child
      local row = Instance.new("TextButton")
      row.Name = "TreeRow_" .. child.Name
      row.Size = UDim2.new(1, 0, 0, rowHeight)
      row.BackgroundTransparency = (selected == child) and 0 or 1
      row.BackgroundColor3 = Color3.fromRGB(66, 39, 112)
      row.AutoButtonColor = false
      row.Text = ""
      row.Parent = list

      -- Carry vertical guides from open parent branches through this row.
      for level, continues in ipairs(ancestorContinues) do
        if continues then
          makeLine(row, (level - 1) * 14 + 6, 0, rowHeight, 1)
        end
      end

      local branchX = depth * 14 + 6
      makeLine(row, branchX, 0, 9, 1)
      makeLine(row, branchX, 8, 1, 9)
      if not isLast then
        makeLine(row, branchX, 9, 9, 1)
      end

      local arrow = Instance.new("TextButton")
      arrow.Size = UDim2.fromOffset(13, 16)
      arrow.Position = UDim2.fromOffset(depth * 14 + 14, 1)
      arrow.BackgroundTransparency = 1
      arrow.Font = Enum.Font.Code
      arrow.TextSize = 12
      arrow.TextColor3 = hasChildren and C.hot or C.dim
      arrow.Text = hasChildren and (isOpen and "v" or ">") or " "
      arrow.AutoButtonColor = false
      arrow.Parent = row
      if hasChildren then
        arrow.MouseButton1Click:Connect(function()
          expanded[child] = not expanded[child]
          render()
        end)
      end

      local icon = Instance.new("TextLabel")
      icon.Size = UDim2.fromOffset(14, 16)
      icon.Position = UDim2.fromOffset(depth * 14 + 28, 1)
      icon.BackgroundTransparency = 1
      icon.Font = Enum.Font.Code
      icon.TextSize = 11
      icon.TextColor3 = hasChildren and C.hot or C.dim
      icon.Text = hasChildren and (isOpen and "▾" or "▸") or "·"
      icon.Parent = row

      local name = Instance.new("TextLabel")
      name.Size = UDim2.new(1, -(depth * 14 + 46), 1, 0)
      name.Position = UDim2.fromOffset(depth * 14 + 44, 0)
      name.BackgroundTransparency = 1
      name.Font = Enum.Font.Code
      name.TextSize = 11
      name.TextXAlignment = Enum.TextXAlignment.Left
      name.TextTruncate = Enum.TextTruncate.AtEnd
      name.TextColor3 = (selected == child) and Color3.new(1, 1, 1) or C.txt
      local countText = hasChildren
        and ("  (" .. tostring(childCount) .. (childCount == 1 and " item)" or " items)"))
        or ""
      name.Text = child.Name .. countText .. "  [" .. child.ClassName .. "]"
      if q ~= "" and not matches(child) then
        name.TextColor3 = C.dim
      end
      name.Parent = row

      local lastClick = 0
      row.MouseButton1Click:Connect(function()
        local now = os.clock()
        if now - lastClick < 0.30 and hasChildren then
          expanded[child] = not expanded[child]
          render()
          lastClick = 0
          return
        end
        lastClick = now
        selectInst(child)
      end)
      row.MouseButton2Click:Connect(function()
        showTextExport("Instance path", pathOf(child))
      end)

      if hasChildren and isOpen then
        local nextAncestors = {}
        for level, continues in ipairs(ancestorContinues) do
          nextAncestors[level] = continues
        end
        -- Keep a green guide running down every expanded folder branch.
        nextAncestors[#nextAncestors + 1] = true
        walk(child, depth + 1, nextAncestors)
      end
    end
  end

  walk(game, 0, {})
  flash(#vis .. " shown", C.dim)
end
search:GetPropertyChangedSignal("Text"):Connect(function() safe("render", render) end)

local function revealNode(inst)
  local chain = {}
  local p = inst
  while p and p ~= game do chain[#chain+1] = p; p = p.Parent end
  for _, n in ipairs(chain) do expanded[n] = true end
  render()
  for i, c in ipairs(vis) do
    if c == inst then list.CanvasPosition = Vector2.new(0, math.max(0, i * 21 - 60)); break end
  end
end

-- World picker: supports mouse and touch through one raycast path.
local mouse = plr:GetMouse()
local GuiService = game:GetService("GuiService")
local pickOn, pickCon, pickInputCon
local function setCollapsed(v)
  win.Size = v and MINI or FULL
  search.Visible = not v
  list.Visible = not v
  right.Visible = not v
  status.Visible = not v
  footer.Visible = not v
end
local function hover(t)
  if not t then readout.Text = ""; return end
  selBox.Adornee = t:IsA("BasePart") and t or nil
  selBox.Visible = t:IsA("BasePart")
  readout.Text = t.ClassName .. " · " .. pathOf(t)
    .. (t:IsA("BasePart") and ("  @ " .. tostring(t.Position)) or "")
end
local function stopPick()
  pickOn = false
  pickBtn.BackgroundColor3 = C.btnBg
  if pickCon then pickCon:Disconnect(); pickCon = nil end
  if pickInputCon then pickInputCon:Disconnect(); pickInputCon = nil end
  setCollapsed(false)
  readout.Text = ""
  selBox.Adornee = selected and selected:IsA("BasePart") and selected or nil
  selBox.Visible = selected ~= nil and selected:IsA("BasePart")
end
local function promotePick(hit)
  -- Selecting a part inside a model previews the complete model when possible.
  local node = hit
  local parent = hit.Parent
  while parent and parent ~= workspace do
    if parent:IsA("Model") then node = parent; break end
    parent = parent.Parent
  end
  return node
end
local function pickAt(screenPos, isTouch)
  if not pickOn then return end
  local cam = workspace.CurrentCamera
  if not cam then return end
  local pos = screenPos
  local inset = GuiService:GetGuiInset()
  pos = Vector2.new(pos.X - inset.X, pos.Y - inset.Y)
  local ray = cam:ViewportPointToRay(pos.X, pos.Y)
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  local excluded = {}
  if plr.Character then excluded[#excluded + 1] = plr.Character end
  params.FilterDescendantsInstances = excluded
  params.IgnoreWater = false
  local hit = workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
  if not hit or not hit.Instance then return end
  local object = promotePick(hit.Instance)
  hover(object)
  selectInst(object)
  revealNode(object)
  -- Switch to the preview tab so the picked object's 3D view is ready on exit.
  gotoTab("3D")
  -- Keep PICK active for repeated picks; user can tap PICK again to exit.
  if isTouch then flash("picked " .. object.Name, C.good) end
end
local function startPick()
  pickOn = true
  pickBtn.BackgroundColor3 = C.hot
  setCollapsed(true)
  pickCon = UIS.InputBegan:Connect(function(input, processed)
    if not pickOn or processed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
      pickAt(input.Position, true)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
      pickAt(UIS:GetMouseLocation(), false)
    end
  end)
end
pickBtn.MouseButton1Click:Connect(function()
  if pickOn then stopPick() else startPick() end
end)

copyShown.MouseButton1Click:Connect(function()
  -- Copy every Explorer row plus every descendant beneath those rows,
  -- including children hidden by collapsed folders/tree branches.
  if #vis == 0 then return flash("nothing shown", Color3.fromRGB(230,180,110)) end
  copy(vis, "COPY TREE complete")
end)

local function runDiagnostics()
  local rows, props, vpKids, camOk = #vis, 0, 0, false
  pcall(function() for _, c in ipairs(propList:GetChildren()) do if c:IsA("TextButton") then props = props + 1 end end end)
  pcall(function() vpKids = #vp:GetChildren() end)
  pcall(function() camOk = vp.CurrentCamera ~= nil end)
  local sel = selected and (selected.ClassName .. " " .. pathOf(selected)) or "none"
  local msg = ("rows=%d props=%d sel=%s vpKids=%d cam=%s mouse=%s")
    :format(rows, props, sel, vpKids, tostring(camOk), tostring(mouse ~= nil))
  flash(msg, C.dim)
  print("[TinyDex DIAG] " .. msg)
end

-- props
local propsPage = pages["Props"]
local pSearch = Instance.new("TextBox")
pSearch.Size = UDim2.new(1, 0, 0, 18)
pSearch.BackgroundColor3 = Color3.fromRGB(28,28,34)
pSearch.BorderSizePixel = 0
pSearch.Font = Enum.Font.Code
pSearch.TextSize = 11
pSearch.Text = ""
pSearch.PlaceholderText = "filter"
pSearch.TextColor3 = C.txt
pSearch.PlaceholderColor3 = C.dim
pSearch.ClearTextOnFocus = false
pSearch.TextXAlignment = Enum.TextXAlignment.Left
pSearch.Parent = propsPage
Instance.new("UIPadding", pSearch).PaddingLeft = UDim.new(0, 5)

propList = Instance.new("ScrollingFrame")
propList.Size = UDim2.new(1, 0, 1, -22)
propList.Position = UDim2.new(0, 0, 0, 22)
propList.BackgroundColor3 = C.row
propList.BorderSizePixel = 0
propList.ScrollBarThickness = 5
propList.AutomaticCanvasSize = Enum.AutomaticSize.Y
propList.CanvasSize = UDim2.new(0,0,0,0)
propList.Parent = propsPage
Instance.new("UIListLayout", propList).SortOrder = Enum.SortOrder.LayoutOrder

local function textEditable(t)
  return t ~= "bool" and t ~= "Enum" and t ~= "BrickColor" and t ~= "Instance"
end
local propConnections = {}
local function setProp(prop, val)
  local target = prop.target
  if prop.ro or not target then return end
  local ok, err = pcall(function()
    if prop.attr then target:SetAttribute(prop.name, val) else target[prop.name] = val end
  end)
  flash(ok and ("set " .. prop.name) or ("failed " .. prop.name .. ": " .. tostring(err)), ok and C.good or C.bad)
end
local function modal(w, text, done)
  local m = Instance.new("TextBox")
  m.Size = UDim2.new(0, w, 0, 22)
  m.Position = UDim2.new(0.5, -w/2, 0.5, -11)
  m.BackgroundColor3 = Color3.fromRGB(34,34,42)
  m.BorderSizePixel = 0
  m.Font = Enum.Font.Code
  m.TextSize = 11
  m.Text = text or ""
  m.TextColor3 = Color3.fromRGB(225,225,235)
  m.ClearTextOnFocus = false
  m.ZIndex = 70
  m.Parent = gui
  Instance.new("UICorner", m).CornerRadius = UDim.new(0, 4)
  m:CaptureFocus()
  m.FocusLost:Connect(function(enter)
    if enter then pcall(done, m.Text) end
    m:Destroy()
  end)
end
local function enumPick(enum, done)
  local m = Instance.new("ScrollingFrame")
  m.Size = UDim2.new(0, 220, 0, 240)
  m.Position = UDim2.new(0.5, -110, 0.5, -120)
  m.BackgroundColor3 = Color3.fromRGB(34,34,42)
  m.BorderSizePixel = 0
  m.ScrollBarThickness = 5
  m.ZIndex = 70
  m.Parent = gui
  Instance.new("UICorner", m).CornerRadius = UDim.new(0, 5)
  Instance.new("UIListLayout", m).SortOrder = Enum.SortOrder.LayoutOrder
  for _, item in ipairs(enum:GetEnumItems()) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 17)
    b.BackgroundTransparency = 1
    b.AutoButtonColor = false
    b.Font = Enum.Font.Code
    b.TextSize = 11
    b.Text = "  " .. item.Name
    b.TextColor3 = C.txt
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = m
    b.MouseButton1Click:Connect(function() pcall(done, item); m:Destroy() end)
  end
end

function refreshProps()
  for _, connection in ipairs(propConnections) do
    pcall(function() connection:Disconnect() end)
  end
  table.clear(propConnections)
  for _, c in ipairs(propList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
  if not selected then
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 26)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.Text = "select something"
    l.TextColor3 = C.dim
    l.Parent = propList
    return
  end
  local q = pSearch.Text:lower()
  local target = selected
  local names = readableProperties(target)

  local function addRow(name, value, isAttr)
    local t = typeof(value)
    if t == "RBXScriptSignal" or t == "function" then return end
    local prop = { name = name, attr = isAttr, target = target }
    -- Never probe writability by assigning the current value: setters can
    -- fire events or have side effects. Attempt the real edit only on request.
    prop.ro = (not isAttr and READ_ONLY_PROPERTIES[name] == true) or t == "Instance"

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 17)
    row.BackgroundTransparency = 1
    row.AutoButtonColor = false
    row.Text = ""
    row.Parent = propList

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(0.45, 0, 1, 0)
    nl.BackgroundTransparency = 1
    nl.Font = Enum.Font.Code
    nl.TextSize = 11
    nl.Text = (isAttr and "@" or "") .. name
    nl.TextColor3 = prop.ro and C.dim or Color3.fromRGB(140,180,255)
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.TextTruncate = Enum.TextTruncate.AtEnd
    nl.Parent = row

    local vf = Instance.new("Frame")
    vf.Size = UDim2.new(0.55, 0, 1, 0)
    vf.Position = UDim2.new(0.45, 0, 0, 0)
    vf.BackgroundTransparency = 1
    vf.Parent = row

    if t == "boolean" then
      local cb = Instance.new("TextButton")
      cb.Size = UDim2.new(0, 16, 0, 16)
      cb.BackgroundTransparency = 1
      cb.Font = Enum.Font.Code
      cb.TextSize = 13
      cb.Text = value and "☑" or "☐"
      cb.TextColor3 = prop.ro and C.dim or C.txt
      cb.Parent = vf
      cb.MouseButton1Click:Connect(function()
        if prop.ro then return end
        value = not value
        cb.Text = value and "☑" or "☐"
        setProp(prop, value)
      end)
    elseif t == "Color3" then
      local sw = Instance.new("TextButton")
      sw.Size = UDim2.new(0, 46, 0, 14)
      sw.BackgroundColor3 = value
      sw.BorderSizePixel = 0
      sw.Text = ""
      sw.Parent = vf
      Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 2)
      local l = Instance.new("TextLabel")
      l.Size = UDim2.new(1, -50, 1, 0)
      l.Position = UDim2.new(0, 50, 0, 0)
      l.BackgroundTransparency = 1
      l.Font = Enum.Font.Code
      l.TextSize = 11
      l.TextColor3 = prop.ro and C.dim or C.txt
      l.TextXAlignment = Enum.TextXAlignment.Left
      l.Text = string.format("%d,%d,%d", math.floor(value.R*255 + 0.5), math.floor(value.G*255 + 0.5), math.floor(value.B*255 + 0.5))
      l.Parent = vf
      sw.MouseButton1Click:Connect(function()
        if prop.ro then return end
        modal(200, tostring(value), function(txt)
          local r, g, b = txt:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
          if r and g and b then
            local v = Color3.fromRGB(
              math.clamp(tonumber(r), 0, 255),
              math.clamp(tonumber(g), 0, 255),
              math.clamp(tonumber(b), 0, 255)
            )
            sw.BackgroundColor3 = v
            setProp(prop, v)
          else
            flash("enter RGB as 120,140,255", C.bad)
          end
        end)
      end)
    elseif t == "EnumItem" then
      local b = Instance.new("TextButton")
      b.Size = UDim2.new(1, 0, 1, 0)
      b.BackgroundTransparency = 1
      b.Font = Enum.Font.Code
      b.TextSize = 11
      b.Text = value.Name
      b.TextColor3 = prop.ro and C.dim or C.txt
      b.TextXAlignment = Enum.TextXAlignment.Left
      b.Parent = vf
      b.MouseButton1Click:Connect(function()
        if prop.ro then return end
        enumPick(value.EnumType, function(item) b.Text = item.Name; setProp(prop, item) end)
      end)
    else
      local l = Instance.new("TextLabel")
      l.Size = UDim2.new(1, 0, 1, 0)
      l.BackgroundTransparency = 1
      l.Font = Enum.Font.Code
      l.TextSize = 11
      l.Text = (typeof(value) == "Instance") and pathOf(value) or tostring(value)
      l.TextColor3 = prop.ro and C.dim or C.txt
      l.TextXAlignment = Enum.TextXAlignment.Left
      l.TextTruncate = Enum.TextTruncate.AtEnd
      l.Parent = vf
      if textEditable(t) and not prop.ro then
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 1, 0)
        b.BackgroundTransparency = 1
        b.Text = ""
        b.Parent = vf
        b.MouseButton1Click:Connect(function()
          modal(240, tostring(value), function(txt)
            local ok, v = pcall(function()
              if t == "number" then
                local n = tonumber(txt)
                assert(n ~= nil, "enter a valid number")
                return n
              elseif t == "string" then
                return txt
              elseif t == "Vector3" then
                local x, y, z = txt:match("^%s*([^,]+),%s*([^,]+),%s*([^,]+)%s*$")
                assert(x and y and z, "use x,y,z")
                return Vector3.new(assert(tonumber(x)), assert(tonumber(y)), assert(tonumber(z)))
              elseif t == "Vector2" then
                local x, y = txt:match("^%s*([^,]+),%s*([^,]+)%s*$")
                assert(x and y, "use x,y")
                return Vector2.new(assert(tonumber(x)), assert(tonumber(y)))
              else
                error("editing this value type is not supported")
              end
            end)
            if ok then
              setProp(prop, v)
              l.Text = tostring(v)
            else
              flash(tostring(v), C.bad)
            end
          end)
        end)
      end
      if not isAttr then
        pcall(function()
          local connection = target:GetPropertyChangedSignal(name):Connect(function()
            local ok, nv = pcall(function() return target[name] end)
            if ok then l.Text = (typeof(nv) == "Instance") and pathOf(nv) or tostring(nv) end
          end)
          propConnections[#propConnections + 1] = connection
        end)
      end
    end
    if isAttr then
      row.MouseButton2Click:Connect(function()
        pcall(function() target:SetAttribute(name, nil) end)
        refreshProps()
      end)
    end
  end

  for _, k in ipairs(names) do
    if q == "" or k:lower():find(q, 1, true) then
      local ok, v = pcall(function() return selected[k] end)
      if ok then addRow(k, v, false) end
    end
  end
  local oka, at = pcall(function() return selected:GetAttributes() end)
  if oka and at then
    for k, v in next, at do
      if q == "" or k:lower():find(q, 1, true) then addRow(k, v, true) end
    end
  end
end
pSearch:GetPropertyChangedSignal("Text"):Connect(function() safe("props", refreshProps) end)

-- 3D preview: lightweight part-only clone, bounded model size, lazy rendering.
local viewPage = pages["3D"]
vp = Instance.new("ViewportFrame")
vp.Size = UDim2.new(1, 0, 1, -14)
vp.BackgroundColor3 = Color3.fromRGB(12, 13, 23)
vp.BorderSizePixel = 0
vp.Ambient = Color3.fromRGB(140,140,150)
vp.LightColor = Color3.new(1,1,1)
vp.LightDirection = Vector3.new(-0.5, -0.8, -0.6)
vp.Parent = viewPage
Instance.new("UICorner", vp).CornerRadius = UDim.new(0, 9)
local vpStroke = Instance.new("UIStroke", vp)
vpStroke.Color = C.line
vpStroke.Transparency = 0.45

diagBtn.MouseButton1Click:Connect(runDiagnostics)

local pathLbl = Instance.new("TextLabel")
pathLbl.Size = UDim2.new(1, 0, 0, 14)
pathLbl.Position = UDim2.new(0, 0, 1, 0)
pathLbl.BackgroundTransparency = 1
pathLbl.Font = Enum.Font.Code
pathLbl.TextSize = 10
pathLbl.TextTransparency = 0.15
pathLbl.TextXAlignment = Enum.TextXAlignment.Left
pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
pathLbl.Text = "Choose a Part or Model"
pathLbl.Parent = viewPage

local rotationX, rotationY, distance = 0.25, 0.6, 10
local dragging, hovering, zoomMul = false, false, 2
local lastpos = Vector2.zero
local vcam, vmodel
local previewCenter = Vector3.zero
local previewSize = Vector3.new(4, 4, 4)
local previewPartCount = 0
local MAX_PREVIEW_PARTS = 120

local function stopView()
  vcam = nil
  vmodel = nil
  vp.CurrentCamera = nil
  for _, child in ipairs(vp:GetChildren()) do child:Destroy() end
end

local function stripUnsafeChildren(root)
  for _, child in ipairs(root:GetDescendants()) do
    if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript")
      or child:IsA("Constraint") or child:IsA("JointInstance") then
      pcall(function() child:Destroy() end)
    end
  end
end

function buildView(item)
  stopView()
  rotationX, rotationY = 0.25, 0.6
  if not item then
    pathLbl.Text = "Choose a Part or Model"
    return
  end
  if not (item:IsA("BasePart") or item:IsA("Model")) then
    pathLbl.Text = "No 3D preview for " .. item.ClassName
    return
  end

  local sourceParts = {}
  if item:IsA("BasePart") then
    sourceParts[1] = item
  else
    for _, child in ipairs(item:GetDescendants()) do
      if child:IsA("BasePart") then
        sourceParts[#sourceParts + 1] = child
        if #sourceParts >= MAX_PREVIEW_PARTS then break end
      end
    end
  end
  if #sourceParts == 0 then
    pathLbl.Text = "No BaseParts found in this object"
    return
  end

  local boundsOK, boundsCF, boundsSize = pcall(function()
    if item:IsA("Model") then return item:GetBoundingBox() end
    return item.CFrame, item.Size
  end)
  if boundsOK then
    previewCenter = boundsCF.Position
    previewSize = boundsSize
  else
    previewCenter = sourceParts[1].Position
    previewSize = sourceParts[1].Size
  end

  vmodel = Instance.new("Model")
  vmodel.Name = "TinyDexPreview"
  vmodel.Parent = vp
  local firstPart
  for _, source in ipairs(sourceParts) do
    local ok, clone = pcall(function() return source:Clone() end)
    if ok and clone and clone:IsA("BasePart") then
      stripUnsafeChildren(clone)
      clone.Anchored = true
      clone.CanCollide = false
      clone.CanTouch = false
      clone.CanQuery = false
      clone.CFrame = CFrame.new(-previewCenter) * source.CFrame
      clone.Parent = vmodel
      firstPart = firstPart or clone
      previewPartCount += 1
    end
  end
  if not firstPart then
    stopView()
    pathLbl.Text = "Preview unavailable (object cannot be cloned)"
    return
  end
  vmodel.PrimaryPart = firstPart
  local maxAxis = math.max(previewSize.X, previewSize.Y, previewSize.Z)
  distance = math.max(4, maxAxis * 1.8)
  vcam = Instance.new("Camera")
  vcam.FieldOfView = 55
  vcam.Parent = vp
  vp.CurrentCamera = vcam
  local suffix = (#sourceParts >= MAX_PREVIEW_PARTS) and (" · capped at " .. MAX_PREVIEW_PARTS .. " parts") or (" · " .. #sourceParts .. " parts")
  pathLbl.Text = "3D: " .. pathOf(item) .. suffix
end

vp.InputBegan:Connect(function(i)
  if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
    dragging = true
    lastpos = Vector2.new(i.Position.X, i.Position.Y)
  end
end)
vp.InputEnded:Connect(function(i)
  if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
    dragging = false
  end
end)
vp.MouseEnter:Connect(function() hovering = true end)
vp.MouseLeave:Connect(function() hovering = false; dragging = false end)
vp.InputChanged:Connect(function(i)
  if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
    local p = Vector2.new(i.Position.X, i.Position.Y)
    local d = p - lastpos
    lastpos = p
    rotationY = rotationY - d.X * 0.012
    rotationX = math.clamp(rotationX - d.Y * 0.012, -math.pi/2 + 0.1, math.pi/2 - 0.1)
  end
  if i.UserInputType == Enum.UserInputType.MouseWheel and hovering then
    distance = math.clamp(distance - i.Position.Z * zoomMul, 1, math.max(6, math.max(previewSize.X, previewSize.Y, previewSize.Z) * 8))
  end
end)

-- Throttle camera work and pause completely when the 3D tab is hidden.
local renderAccumulator = 0
RunService.RenderStepped:Connect(function(dt)
  if not viewPage.Visible or not vcam or not vmodel or not vmodel.Parent then return end
  renderAccumulator += dt
  if renderAccumulator < (1 / 30) then return end
  local step = renderAccumulator
  renderAccumulator = 0
  rotationY = rotationY + 0.18 * step
  local center = Vector3.zero
  local cf = CFrame.new(center) * CFrame.Angles(0, rotationY, 0)
    * CFrame.Angles(rotationX, 0, 0) * CFrame.new(0, 0, distance)
  vcam.CFrame = CFrame.lookAt(cf.Position, center)
end)

-- Local utility console: intentionally does not compile or execute user-provided code.
local termPage = pages["Term"]
local termOut = Instance.new("ScrollingFrame")
termOut.Size = UDim2.new(1, 0, 1, -26)
termOut.BackgroundColor3 = C.row
termOut.BorderSizePixel = 0
termOut.ScrollBarThickness = 5
termOut.AutomaticCanvasSize = Enum.AutomaticSize.Y
termOut.CanvasSize = UDim2.new(0,0,0,0)
termOut.Parent = termPage
Instance.new("UIListLayout", termOut).SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", termOut).PaddingTop = UDim.new(0, 2)

local function out(msg, col)
  local l = Instance.new("TextLabel")
  l.Size = UDim2.new(1, 0, 0, 14)
  l.BackgroundTransparency = 1
  l.Font = Enum.Font.Code
  l.TextSize = 11
  l.Text = os.date("%H:%M:%S") .. "   " .. tostring(msg)
  l.TextColor3 = col or Color3.fromRGB(171,171,171)
  l.TextXAlignment = Enum.TextXAlignment.Left
  l.TextTruncate = Enum.TextTruncate.AtEnd
  l.Parent = termOut
  termOut.CanvasPosition = Vector2.new(0, 9e9)
end
LogService.MessageOut:Connect(function(msg, t)
  local col = Color3.fromRGB(204,204,204)
  if t == Enum.MessageType.MessageWarning then col = Color3.fromRGB(255,142,60)
  elseif t == Enum.MessageType.MessageError then col = Color3.fromRGB(255,68,68) end
  pcall(out, msg, col)
end)

local termLine = Instance.new("Frame")
termLine.Size = UDim2.new(1, 0, 0, 22)
termLine.Position = UDim2.new(0, 0, 1, -22)
termLine.BackgroundColor3 = Color3.fromRGB(37,37,37)
termLine.BorderSizePixel = 0
termLine.Parent = termPage
local termIn = Instance.new("TextBox")
termIn.Size = UDim2.new(1, 0, 1, 0)
termIn.BackgroundTransparency = 1
termIn.Font = Enum.Font.Code
termIn.TextSize = 11
termIn.Text = ""
termIn.PlaceholderText = "Run a command"
termIn.PlaceholderColor3 = C.dim
termIn.TextColor3 = Color3.fromRGB(211,211,211)
termIn.ClearTextOnFocus = false
termIn.TextXAlignment = Enum.TextXAlignment.Left
termIn.Parent = termLine
Instance.new("UIPadding", termIn).PaddingLeft = UDim.new(0, 6)


-- ══════════════════════════════════════════════════════════════════════
-- TERMINAL EXECUTION CORE (v23)
-- Shared by the CONSOLE tab (`run` command) and the PULSAR agent
-- (run_luau tool / auto-run). Execution requires loadstring, which only
-- executor runtimes provide. Studio stays read-only and reports that.
-- ══════════════════════════════════════════════════════════════════════
local EXEC_AVAILABLE = (function()
  if type(loadstring) == "function" then return true end
  local g = (type(getgenv) == "function") and getgenv() or nil
  return g ~= nil and type(g.loadstring) == "function"
end)()

local Terminal = {}
Terminal.runs = 0

-- Crash guard: detect chunks that would freeze the client before running them.
function Terminal.unsafeReason(code)
  local scrubbed = code:gsub("%-%-%[%b[]%]", " ")
  scrubbed = scrubbed:gsub("%-%-[^\n]*", " ")
  scrubbed = scrubbed:gsub("%[%b[]%]", " ")
  scrubbed = scrubbed:gsub('"[^"\n]*"', ' "" '):gsub("'[^\'\n]*'", " '' ")
  local yieldKw = scrubbed:find("task%.wait") or scrubbed:find("task%.defer")
    or scrubbed:find(":%s*Wait%s*%(") or scrubbed:find("[^%w_%.]wait%s*%(")
    or scrubbed:find("WaitForChild") or scrubbed:find("Heartbeat")
    or scrubbed:find("RenderStepped") or scrubbed:find("Stepped")
  if yieldKw then return nil end
  if scrubbed:find("while%s+true%s*do") or scrubbed:find("while%s+1%s*do") then
    return "`while true do` loop with no task.wait() inside -- it spins without yielding and freezes the client"
  end
  if (scrubbed:find("^repeat[^%w_]") or scrubbed:find("[^%w_]repeat[^%w_]")) and scrubbed:find("until%s+false") then
    return "`repeat ... until false` loop with no task.wait() inside -- it spins without yielding and freezes the client"
  end
  return nil
end

function Terminal.exec(code, label)
  local result = { ok = false, output = "", duration = 0 }
  if type(code) ~= "string" or code:match("^%s*$") then
    result.output = "nothing to run: empty code"
    return result
  end
  if not EXEC_AVAILABLE then
    result.output = "Luau execution unavailable: this runtime has no loadstring. "
      .. "Run TinyDex from an executor client, or copy the script into Roblox Studio."
    out(result.output, C.bad)
    return result
  end

  -- Capture print/warn output so tool results can be returned to the agent.
  local captured = {}
  local oldPrint, oldWarn = print, warn
  local shimOk = pcall(function()
    print = function(...)
      local parts = {}
      for i = 1, luaSelect("#", ...) do parts[#parts + 1] = tostring(luaSelect(i, ...)) end
      captured[#captured + 1] = table.concat(parts, "  ")
    end
    warn = function(...)
      local parts = { "[warn]" }
      for i = 1, luaSelect("#", ...) do parts[#parts + 1] = tostring(luaSelect(i, ...)) end
      captured[#captured + 1] = table.concat(parts, "  ")
    end
  end)
  local function restore()
    if shimOk then
      pcall(function() print = oldPrint end)
      pcall(function() warn = oldWarn end)
    end
  end

  Terminal.runs += 1
  local tag = tostring(label or "run") .. " #" .. Terminal.runs
  out("▶ EXEC " .. tag .. " (" .. #code .. " chars)", Color3.fromRGB(190, 145, 255))
  local startedAt = os.clock()
  local chunk, compileErr
  local compileOk = pcall(function()
    chunk, compileErr = loadstring(code, "=PRIMEz_" .. tag:gsub("%W+", "_"))
  end)
  if not compileOk or type(chunk) ~= "function" then
    restore()
    result.output = "compile error: " .. tostring(compileErr)
    out("✖ " .. result.output, C.bad)
    return result
  end
  local unsafeWhy = Terminal.unsafeReason and Terminal.unsafeReason(code)
  if unsafeWhy then
    restore()
    result.output = "blocked (crash guard): " .. unsafeWhy
      .. ". Fix: put task.wait() inside the loop, or ask PULSAR to rewrite it with a yield."
    out("✖ " .. result.output, C.bad)
    return result
  end
  local runOk, runErr = pcall(chunk)
  restore()
  result.duration = math.floor((os.clock() - startedAt) * 1000 + 0.5)
  local tail = table.concat(captured, "\n")
  if #tail > 6000 then tail = tail:sub(1, 6000) .. "\n... output truncated" end
  if runOk then
    result.ok = true
    result.output = (tail ~= "" and tail or "(no output)")
    out("✔ done in " .. result.duration .. " ms", C.good)
    for _, line in ipairs(captured) do out("   " .. line) end
  else
    result.output = "runtime error: " .. tostring(runErr) .. (tail ~= "" and ("\n" .. tail) or "")
    out("✖ " .. tostring(runErr), C.bad)
    for _, line in ipairs(captured) do out("   " .. line) end
  end
  return result
end

function Terminal.execDraft(label)
  local source = editor.Text or ""
  if source:match("^%s*$") then
    out("Draft is empty. Write code in the WORKSPACE tab first.", C.bad)
    return { ok = false, output = "draft empty", duration = 0 }
  end
  return Terminal.exec(source, label or "draft")
end

Terminal.available = EXEC_AVAILABLE
termIn.PlaceholderText = "help | run | refresh | selected | children | count | clear | agent"
termIn.FocusLost:Connect(function(enter)
  local txt = termIn.Text
  if not enter or txt == "" then return end
  termIn.Text = ""
  local raw = txt:match("^%s*(.-)%s*$")
  local command = raw:lower()
  out("> " .. raw, Color3.fromRGB(120,120,135))
  if command == "help" then
    out("Commands: help, run, exec, refresh, selected, path, children, count, clear, status, agent")
    out("run            — execute the WORKSPACE draft in this terminal")
    out("run <luau>     — execute one line of Luau code, e.g.  run print(workspace.Name)")
    out("status         — runtime capabilities (executor / execution / PRIMEz route)")
    out("agent          — PULSAR AI lives in the full version (PRIMEZ_ tab has links)")
    if not Terminal.available then
      out("Execution is OFF in this runtime (no loadstring): Studio-safe diagnostics only.", C.dim)
    end
  elseif command == "run" or command == "exec" then
    Terminal.execDraft("console")
  elseif command:sub(1, 4) == "run " or command:sub(1, 5) == "exec " then
    local code = raw:sub(command:sub(1, 4) == "run " and 5 or 6)
    Terminal.exec(code, "console-line")
  elseif command == "status" then
    out("TinyDex v23 runtime status")
    out("  execution (loadstring): " .. (Terminal.available and "AVAILABLE" or "unavailable (read-only mode)"), Terminal.available and C.good or C.bad)
    local hasHttp = (type(request) == "function") or (type(http_request) == "function") or (syn and type(syn.request) == "function")
    out("  executor HTTP: " .. (hasHttp and "AVAILABLE" or "unavailable"), hasHttp and C.good or C.bad)
    out("  PRIMEz route: " .. PRIMEZ)
    out("  terminal runs this session: " .. Terminal.runs)
  elseif command == "refresh" then
    safe("render", render)
    safe("props", refreshProps)
    out("Explorer and properties refreshed.", C.good)
  elseif command == "selected" or command == "path" then
    out(selected and (selected.ClassName .. "  " .. pathOf(selected)) or "Nothing selected.")
  elseif command == "children" then
    if not selected then out("Select an instance first.", C.bad) else
      local kids = selected:GetChildren()
      out("Children: " .. #kids)
      for i = 1, math.min(#kids, 40) do out(kids[i].Name .. "  <" .. kids[i].ClassName .. ">") end
      if #kids > 40 then out("Output limited to first 40 children.", C.dim) end
    end
  elseif command == "count" then
    local total, stack = 0, { game }
    while #stack > 0 and total < 5000 do
      local obj = table.remove(stack)
      total += 1
      local ok, kids = pcall(function() return obj:GetChildren() end)
      if ok then for _, child in ipairs(kids) do stack[#stack+1] = child end end
    end
    out("Visible DataModel descendants counted: " .. total .. (total >= 5000 and " (limit reached)" or ""), C.good)
  elseif command == "agent" then
    out("PULSAR AI is not in this standalone build. Join the PRIMEz Discord to get the full PULSAR AI version: " .. tostring(PRIMEZ_DISCORD_URL), C.dim)
  elseif command == "clear" then
    for _, child in ipairs(termOut:GetChildren()) do
      if child:IsA("TextLabel") then child:Destroy() end
    end
  else
    out("Unknown command. Type help.", C.bad)
  end
end)

gotoTab("Props")
safe("props", refreshProps)
safe("render", render)
safe("view", buildView, nil)
flash("ready", C.dim)
-- v23.6-SMOOTH UI: everything built — let the splash hand over to the reveal
BOOTUI.done = true












