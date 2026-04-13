-- ╔══════════════════════════════════════════════════════════════╗
-- ║          DESTROYER HUB — STEAL A BRAINROT                   ║
-- ║    Instant Steal | TP Base | Anti Hit | DeSync | Invisible  ║
-- ║              Delta Mobile Compatible v2.0                   ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Github'dan çekmek için:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/SENIN_KULLANICI/REPO/main/DestroyerHub.lua"))()

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace       = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local HRP  = Char:WaitForChild("HumanoidRootPart")
local Hum  = Char:WaitForChild("Humanoid")

LP.CharacterAdded:Connect(function(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
end)

-- ══════════════════════════════════════════════════════════════
--                        AYARLAR
-- ══════════════════════════════════════════════════════════════
local Settings = {
    InstantSteal    = false,
    TPBase          = false,
    AntiHit         = false,
    DeSync          = false,
    InvisibleSteal  = false,
    AutoFarm        = false,
    StealRange      = 40,
    FarmDelay       = 0.08,
}

local TotalStolen = 0

-- ══════════════════════════════════════════════════════════════
--                    YARDIMCI FONKSİYONLAR
-- ══════════════════════════════════════════════════════════════

local function SafeTP(pos)
    if not HRP then return end
    HRP.CFrame = CFrame.new(pos)
end

local function GetBase()
    -- SpawnLocation (kendi takım rengi)
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("SpawnLocation") then
            if v.TeamColor == LP.TeamColor then
                return v.Position + Vector3.new(0, 6, 0)
            end
        end
    end
    -- "Base" isimli part
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower():find("base") and v:IsA("BasePart") then
            return v.Position + Vector3.new(0, 6, 0)
        end
    end
    return HRP and HRP.Position or Vector3.new(0,5,0)
end

local function IsBrainrotObj(obj)
    local n = obj.Name:lower()
    return n:find("brainrot") or n:find("brain") or
           n:find("steal") or n:find("drop") or
           n:find("item") or n:find("collect") or
           n:find("orb") or n:find("gem") or
           n:find("loot") or n:find("pickup")
end

local function TouchObj(obj)
    pcall(function()
        firetouchinterest(HRP, obj, 0)
        task.wait(0.02)
        firetouchinterest(HRP, obj, 1)
    end)
end

local function FireRemotes()
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("steal") or n:find("collect") or n:find("grab") or n:find("pick") then
                pcall(function() v:FireServer() end)
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════
--                       STEAL FONKSİYONU
-- ══════════════════════════════════════════════════════════════

local function DoSteal()
    if not HRP then return 0 end
    local count = 0
    local basePos = GetBase()
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if not Settings.InstantSteal and not Settings.AutoFarm then break end
        
        local pos
        if obj:IsA("BasePart") and IsBrainrotObj(obj) then
            pos = obj.Position
        elseif obj:IsA("Model") and IsBrainrotObj(obj) and obj.PrimaryPart then
            pos = obj.PrimaryPart.Position
        end
        
        if pos then
            local dist = (HRP.Position - pos).Magnitude
            if dist <= Settings.StealRange then
                SafeTP(pos + Vector3.new(0, 3, 0))
                TouchObj(obj)
                FireRemotes()
                count += 1
                task.wait(0.03)
                
                if Settings.TPBase then
                    SafeTP(basePos)
                    task.wait(0.05)
                end
            end
        end
    end
    
    TotalStolen += count
    return count
end

-- ══════════════════════════════════════════════════════════════
--                     ANTI HIT (Noclip)
-- ══════════════════════════════════════════════════════════════
local AntiHitConn
local function EnableAntiHit()
    AntiHitConn = RunService.Stepped:Connect(function()
        if not Settings.AntiHit then return end
        if not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
end

local function DisableAntiHit()
    if AntiHitConn then AntiHitConn:Disconnect() end
    if Char then
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════
--                       DESYNC
-- ══════════════════════════════════════════════════════════════
local DeSyncPart
local function EnableDeSync()
    -- Fake part sunucudan ayrı pozisyon gösterir
    DeSyncPart = Instance.new("Part")
    DeSyncPart.Size = Vector3.new(1,1,1)
    DeSyncPart.Transparency = 1
    DeSyncPart.CanCollide = false
    DeSyncPart.Anchored = false
    DeSyncPart.Parent = Workspace
    
    if HRP then
        DeSyncPart.CFrame = HRP.CFrame
    end
    
    -- Network owner'ı al (Delta'da çalışır)
    pcall(function()
        HRP:SetNetworkOwner(nil)
    end)
end

local function DisableDeSync()
    if DeSyncPart then DeSyncPart:Destroy() end
    pcall(function()
        HRP:SetNetworkOwner(LP)
    end)
end

-- ══════════════════════════════════════════════════════════════
--                    INVISIBLE STEAL
-- ══════════════════════════════════════════════════════════════
local function SetInvisible(state)
    if not Char then return end
    for _, v in pairs(Char:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") then
            v.Transparency = state and 1 or 0
        end
    end
end

-- ══════════════════════════════════════════════════════════════
--                         GUI
-- ══════════════════════════════════════════════════════════════

-- Eski GUI temizle
local function CleanOldGui()
    local targets = {gethui and gethui(), pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui"), LP:FindFirstChild("PlayerGui")}
    for _, t in pairs(targets) do
        if t then
            local old = t:FindFirstChild("DestroyerHub")
            if old then old:Destroy() end
        end
    end
end
CleanOldGui()

local SG = Instance.new("ScreenGui")
SG.Name = "DestroyerHub"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 999

if gethui then
    SG.Parent = gethui()
else
    local ok = pcall(function() SG.Parent = game:GetService("CoreGui") end)
    if not ok then SG.Parent = LP:WaitForChild("PlayerGui") end
end

-- ── Renkler ──
local C = {
    bg      = Color3.fromRGB(8, 8, 14),
    panel   = Color3.fromRGB(14, 14, 22),
    border  = Color3.fromRGB(230, 180, 0),
    accent  = Color3.fromRGB(220, 160, 0),
    text    = Color3.fromRGB(255, 255, 255),
    sub     = Color3.fromRGB(180, 180, 200),
    on      = Color3.fromRGB(255, 200, 0),
    off     = Color3.fromRGB(60, 60, 80),
    red     = Color3.fromRGB(255, 60, 80),
    green   = Color3.fromRGB(60, 255, 130),
    dark    = Color3.fromRGB(20, 20, 32),
}

-- ── Ana Çerçeve ──
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 290, 0, 480)
Main.Position = UDim2.new(0.5, -145, 0.5, -240)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local ms = Instance.new("UIStroke", Main)
ms.Color = C.border
ms.Thickness = 2

-- ── Başlık ──
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 56)
Header.BackgroundColor3 = C.dark
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

-- Alt kenarları düzelt
local HFix = Instance.new("Frame")
HFix.Size = UDim2.new(1, 0, 0.5, 0)
HFix.Position = UDim2.new(0, 0, 0.5, 0)
HFix.BackgroundColor3 = C.dark
HFix.BorderSizePixel = 0
HFix.Parent = Header

local HeaderGrad = Instance.new("UIGradient")
HeaderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 22, 5)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 15, 3)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 22, 5)),
})
HeaderGrad.Rotation = 0
HeaderGrad.Parent = Header

-- Sarı sol çizgi
local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(0, 4, 0.7, 0)
AccentLine.Position = UDim2.new(0, 12, 0.15, 0)
AccentLine.BackgroundColor3 = C.border
AccentLine.BorderSizePixel = 0
AccentLine.Parent = Header
Instance.new("UICorner", AccentLine).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 24, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DESTROYER HUB"
Title.TextColor3 = C.border
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -80, 0, 14)
SubTitle.Position = UDim2.new(0, 24, 0.62, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Steal a Brainrot • v2.0"
SubTitle.TextColor3 = C.sub
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

-- Kapat
local CloseB = Instance.new("TextButton")
CloseB.Size = UDim2.new(0, 28, 0, 28)
CloseB.Position = UDim2.new(1, -38, 0.5, -14)
CloseB.BackgroundColor3 = C.red
CloseB.Text = "✕"
CloseB.TextColor3 = Color3.new(1,1,1)
CloseB.Font = Enum.Font.GothamBold
CloseB.TextSize = 13
CloseB.BorderSizePixel = 0
CloseB.Parent = Header
Instance.new("UICorner", CloseB).CornerRadius = UDim.new(0, 7)
CloseB.MouseButton1Click:Connect(function() SG:Destroy() end)

-- Minimize
local MinB = Instance.new("TextButton")
MinB.Size = UDim2.new(0, 28, 0, 28)
MinB.Position = UDim2.new(1, -70, 0.5, -14)
MinB.BackgroundColor3 = C.accent
MinB.Text = "—"
MinB.TextColor3 = Color3.new(0,0,0)
MinB.Font = Enum.Font.GothamBold
MinB.TextSize = 13
MinB.BorderSizePixel = 0
MinB.Parent = Header
Instance.new("UICorner", MinB).CornerRadius = UDim.new(0, 7)

local minimized = false
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, 0, 1, -56)
ContentFrame.Position = UDim2.new(0, 0, 0, 56)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = Main

MinB.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentFrame.Visible = not minimized
    Main.Size = minimized and UDim2.new(0, 290, 0, 56) or UDim2.new(0, 290, 0, 480)
    MinB.Text = minimized and "+" or "—"
end)

-- ── Scroll ──
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -10)
Scroll.Position = UDim2.new(0, 0, 0, 5)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = C.border
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = ContentFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = Scroll

local ListPad = Instance.new("UIPadding")
ListPad.PaddingLeft = UDim.new(0, 10)
ListPad.PaddingRight = UDim.new(0, 10)
ListPad.PaddingTop = UDim.new(0, 6)
ListPad.Parent = Scroll

-- ── Section başlığı ──
local function MakeSection(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. text
    lbl.TextColor3 = C.border
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = Scroll
    return lbl
end

-- ── Toggle ──
local function MakeToggle(cfg)
    -- cfg: {label, icon, desc, key, order, callback}
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 52)
    row.BackgroundColor3 = C.panel
    row.BorderSizePixel = 0
    row.LayoutOrder = cfg.order
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local rs = Instance.new("UIStroke", row)
    rs.Color = Color3.fromRGB(35, 35, 50)
    rs.Thickness = 1

    -- İkon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 36, 0, 36)
    icon.Position = UDim2.new(0, 8, 0.5, -18)
    icon.BackgroundColor3 = C.dark
    icon.Text = cfg.icon
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.BorderSizePixel = 0
    icon.Parent = row
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)

    -- Label
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.55, 0, 0, 20)
    lbl.Position = UDim2.new(0, 52, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = cfg.label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(0.55, 0, 0, 14)
    desc.Position = UDim2.new(0, 52, 0, 28)
    desc.BackgroundTransparency = 1
    desc.Text = cfg.desc
    desc.TextColor3 = C.sub
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 10
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = row

    -- Toggle switch
    local state = Settings[cfg.key] or false

    local togBg = Instance.new("Frame")
    togBg.Size = UDim2.new(0, 48, 0, 26)
    togBg.Position = UDim2.new(1, -58, 0.5, -13)
    togBg.BackgroundColor3 = state and C.on or C.off
    togBg.BorderSizePixel = 0
    togBg.Parent = row
    Instance.new("UICorner", togBg).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 20, 0, 20)
    circle.Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    circle.BackgroundColor3 = Color3.new(1,1,1)
    circle.BorderSizePixel = 0
    circle.Parent = togBg
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    -- Status dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 6, 0.5, -3)
    dot.BackgroundColor3 = state and C.green or C.off
    dot.BorderSizePixel = 0
    dot.Parent = togBg
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        state = not state
        Settings[cfg.key] = state
        local tw = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
        TweenService:Create(togBg, tw, {BackgroundColor3 = state and C.on or C.off}):Play()
        TweenService:Create(circle, tw, {
            Position = state and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
        }):Play()
        TweenService:Create(dot, tw, {BackgroundColor3 = state and C.green or C.off}):Play()
        if cfg.callback then cfg.callback(state) end
    end)

    return row
end

-- ── Büyük Buton ──
local function MakeButton(cfg)
    -- cfg: {label, icon, color, order, callback}
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.BackgroundColor3 = cfg.color or C.accent
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.LayoutOrder = cfg.order
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180,140,0)/Color3.new(1,1,1))
    })
    -- simple approach
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.4),
    })
    grad.Rotation = 90
    grad.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = cfg.icon .. "  " .. cfg.label
    lbl.TextColor3 = Color3.fromRGB(10, 10, 10)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.Parent = btn

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(180, 130, 0)
        }):Play()
        task.wait(0.12)
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = cfg.color or C.accent
        }):Play()
        if cfg.callback then cfg.callback() end
    end)

    return btn
end

-- ── Status Bar ──
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -20, 0, 32)
StatusBar.BackgroundColor3 = C.dark
StatusBar.BorderSizePixel = 0
StatusBar.LayoutOrder = 99
StatusBar.Parent = Scroll
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 8)

local StatusTxt = Instance.new("TextLabel")
StatusTxt.Size = UDim2.new(0.6, 0, 1, 0)
StatusTxt.BackgroundTransparency = 1
StatusTxt.Text = "⚡ Hazır"
StatusTxt.TextColor3 = C.green
StatusTxt.Font = Enum.Font.Gotham
StatusTxt.TextSize = 11
StatusTxt.TextXAlignment = Enum.TextXAlignment.Left
StatusTxt.Position = UDim2.new(0, 10, 0, 0)
StatusTxt.Parent = StatusBar

local CountTxt = Instance.new("TextLabel")
CountTxt.Size = UDim2.new(0.4, -10, 1, 0)
CountTxt.Position = UDim2.new(0.6, 0, 0, 0)
CountTxt.BackgroundTransparency = 1
CountTxt.Text = "🎯 0 çalındı"
CountTxt.TextColor3 = C.border
CountTxt.Font = Enum.Font.GothamBold
CountTxt.TextSize = 11
CountTxt.TextXAlignment = Enum.TextXAlignment.Right
CountTxt.Parent = StatusBar

local function SetStatus(msg, color)
    StatusTxt.Text = msg
    StatusTxt.TextColor3 = color or C.green
end

local function UpdateCount()
    CountTxt.Text = "🎯 " .. TotalStolen .. " çalındı"
end

-- ══════════════════════════════════════════════════════════════
--                      GUI İÇERİK
-- ══════════════════════════════════════════════════════════════

MakeSection("⚔️  STEAL", 1)

MakeToggle({
    label = "INSTANT STEAL",
    icon  = "⚡",
    desc  = "Yakındaki brainrotları anında çalar",
    key   = "InstantSteal",
    order = 2,
    callback = function(v)
        SetStatus(v and "⚡ Instant Steal aktif" or "⚡ Hazır", v and C.on or C.green)
    end
})

MakeToggle({
    label = "INVISIBLE STEAL",
    icon  = "👻",
    desc  = "Görünmez ol, sessizce çal",
    key   = "InvisibleSteal",
    order = 3,
    callback = function(v)
        SetInvisible(v)
        SetStatus(v and "👻 Görünmez mod açık" or "⚡ Hazır", v and C.border or C.green)
    end
})

MakeToggle({
    label = "TP BASE",
    icon  = "🏠",
    desc  = "Çalınca base'e otomatik ışın",
    key   = "TPBase",
    order = 4,
    callback = function(v)
        SetStatus(v and "🏠 TP Base aktif" or "⚡ Hazır", v and C.on or C.green)
    end
})

MakeSection("🛡️  KORUMA", 5)

MakeToggle({
    label = "ANTI HIT",
    icon  = "🛡️",
    desc  = "Hasar almayı engeller (noclip)",
    key   = "AntiHit",
    order = 6,
    callback = function(v)
        if v then EnableAntiHit() else DisableAntiHit() end
        SetStatus(v and "🛡️ Anti Hit açık" or "⚡ Hazır", v and C.green or C.green)
    end
})

MakeToggle({
    label = "DESYNC",
    icon  = "🌀",
    desc  = "Sunucudan kopar, görünmez hareket",
    key   = "DeSync",
    order = 7,
    callback = function(v)
        if v then EnableDeSync() else DisableDeSync() end
        SetStatus(v and "🌀 DeSync açık" or "⚡ Hazır", v and C.border or C.green)
    end
})

MakeSection("🤖  OTO FARM", 8)

MakeToggle({
    label = "AUTO FARM",
    icon  = "🤖",
    desc  = "Otomatik sürekli brainrot topla",
    key   = "AutoFarm",
    order = 9,
    callback = function(v)
        SetStatus(v and "🤖 Auto Farm çalışıyor..." or "⚡ Hazır", v and C.on or C.green)
    end
})

MakeSection("🎯  AKSIYONLAR", 10)

MakeButton({
    label = "HEMEN ÇAL + BASE TP",
    icon  = "⚡",
    color = C.border,
    order = 11,
    callback = function()
        SetStatus("⚡ Çalıyor...", C.on)
        task.spawn(function()
            local n = DoSteal()
            UpdateCount()
            if Settings.TPBase then
                SafeTP(GetBase())
                SetStatus("🏠 Base'e ışınlandı! +" .. n, C.green)
            else
                SetStatus("✅ +" .. n .. " çalındı!", C.green)
            end
            task.wait(2)
            SetStatus("⚡ Hazır", C.green)
        end)
    end
})

MakeButton({
    label = "SADECE BASE'E TP",
    icon  = "🏠",
    color = Color3.fromRGB(40, 180, 100),
    order = 12,
    callback = function()
        SafeTP(GetBase())
        SetStatus("🏠 Base'e ışınlandı!", C.green)
        task.wait(2)
        SetStatus("⚡ Hazır", C.green)
    end
})

-- Status Bar sona
local sb2 = Instance.new("Frame")
sb2.Size = UDim2.new(1, 0, 0, 8)
sb2.BackgroundTransparency = 1
sb2.LayoutOrder = 98
sb2.Parent = Scroll

-- ══════════════════════════════════════════════════════════════
--                   SÜRÜKLEME (MOBİL)
-- ══════════════════════════════════════════════════════════════
local dragging, dragStart, frameStart = false, nil, nil

Header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or
       i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = i.Position
        frameStart= Main.Position
    end
end)

Header.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or
       i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if not dragging then return end
    if i.UserInputType == Enum.UserInputType.Touch or
       i.UserInputType == Enum.UserInputType.MouseMove then
        local d = i.Position - dragStart
        Main.Position = UDim2.new(
            frameStart.X.Scale, frameStart.X.Offset + d.X,
            frameStart.Y.Scale, frameStart.Y.Offset + d.Y
        )
    end
end)

-- ══════════════════════════════════════════════════════════════
--                    ANA DÖNGÜ
-- ══════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not Settings.AutoFarm and not Settings.InstantSteal then return end
    if not HRP then return end

    for _, obj in pairs(Workspace:GetDescendants()) do
        local pos
        if obj:IsA("BasePart") and IsBrainrotObj(obj) then
            pos = obj.Position
        elseif obj:IsA("Model") and IsBrainrotObj(obj) and obj.PrimaryPart then
            pos = obj.PrimaryPart.Position
        end

        if pos then
            local dist = (HRP.Position - pos).Magnitude
            if dist <= Settings.StealRange then
                SafeTP(pos + Vector3.new(0, 3, 0))
                TouchObj(obj)
                TotalStolen += 1
                UpdateCount()
                task.wait(Settings.FarmDelay)
                if Settings.TPBase then
                    SafeTP(GetBase())
                    task.wait(0.05)
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
print("✅ [Destroyer Hub] Yüklendi!")
print("🎯 Instant Steal | TP Base | Anti Hit | DeSync | Invisible")
-- ══════════════════════════════════════════════════════════════
