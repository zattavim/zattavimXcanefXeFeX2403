-- ==========================================
-- ROBLOX SQUID GAME X - DEDEKTİF V3.6.2 (FIX)
-- Font Fix + Tam Kelime Filtresi + Hitbox & Tekne Düzeltmesi
-- ==========================================
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local genv = (typeof(getgenv) == "function" and getgenv()) or _G

if typeof(genv.DetectiveCleanup) == "function" then
    pcall(genv.DetectiveCleanup)
end

local function getService(serviceName)
    local service = game:GetService(serviceName)
    if typeof(cloneref) == "function" then
        local ok, cloned = pcall(cloneref, service)
        if ok and cloned then
            return cloned
        end
    end
    return service
end

local Players = getService("Players")
local Workspace = getService("Workspace")
local TweenService = getService("TweenService")
local RunService = getService("RunService")
local UserInputService = getService("UserInputService")
local VirtualUser = getService("VirtualUser")
local CoreGui = getService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ==========================================
-- AYARLAR, FİLTRELER VE BÖLGE TANIMLARI
-- ==========================================
genv.AutoDetective = false

local CONFIG = {
    EvidenceNames = {
        "evidence", "clue", "kanit", "kanıt", "document", "dossier",
        "notebook", "file", "briefcase", "binder", "casefile", "secret",
        "files", "documents", "redfolder", "bluefolder", "intel", "recorder",
        "tape", "usb", "flashdrive", "harddrive", "phone", "laptop", "diary",
        "keycard", "accesscard", "blueprint", "ledger", "letter", "note",
        "report", "vial", "sample", "syringe", "badge", "idcard", "paper",
        "folder", "photo", "photograph", "cassette", "disk", "microfilm"
    },
    EvidencePromptKeywords = {
        "evidence", "clue", "kanıt", "kanit", "document", "file", "dossier",
        "collect evidence", "pick up evidence", "take evidence", "investigate",
        "kanıtı al", "kanıt topla", "incele"
    },
    PromptBlacklist = {
        "door", "kapı", "sit", "otur", "bed", "sleep", "uyu", "locker", "dolap",
        "hide", "saklan", "shop", "market", "buy", "satın", "equip", "armor",
        "armour", "vest", "helmet", "mask", "uniform", "suit", "guard", "boat",
        "tekne", "escape", "deliver", "submit", "deposit", "deposite", "revive",
        "carry", "taşı", "vote", "elevator", "lift", "cook", "pişir", "fry",
        "boil", "chop", "cut", "serve", "eat", "ye", "drink", "iç", "wash",
        "yıka", "burn", "yak", "incinerate", "bury", "göm", "drive",
        "passenger", "seat", "steer", "pilot"
    },
    NonEvidencePropBlacklist = {
        "coffin", "tabut", "casket", "body", "corpse", "dead", "ceset", "beden",
        "skeleton", "skull", "kafatası", "iskelet", "incinerator", "furnace",
        "crematorium", "ash", "urn", "beef", "potato", "patates", "meat", "et",
        "cooking", "stove", "ocak", "oven", "fırın", "pot", "tencere", "pan",
        "tava", "knife", "bıçak", "food", "yemek", "soup", "çorba", "stew",
        "meal", "plate", "tabak", "bowl", "kase", "fridge", "freezer",
        "buzdolabı", "sink", "lavabo", "ingredient", "malzeme", "chef", "aşçı",
        "kitchenware", "cup", "mug", "glass", "bardak", "spoon", "fork",
        "kaşık", "çatal", "bread", "ekmek", "water", "su", "cuttingboard",
        "chair", "sandalye", "trash", "garbage", "çöp"
    },
    RoomZoneKeywords = {
        "guard", "kitchen", "cafeteria", "dining", "cctv", "camera", "security",
        "coffinroom", "coffin_room", "coffin room", "morgue", "incinerator",
        "crematorium", "armor", "armory", "armoury", "weapon", "lobby",
        "mainhall", "waiting", "toilet", "bathroom", "restroom", "wc",
        "washroom", "island", "beach", "dock", "shore", "cliff", "cave",
        "office", "frontman", "vip", "control", "server", "storage", "supply",
        "janitor", "utility", "medical", "infirmary", "bunk", "dorm", "hallway",
        "evidencespawn", "cluespawn", "itemspawn"
    },
    GenericObjectNames = {
        ["part"] = true, ["meshpart"] = true, ["model"] = true, ["union"] = true,
        ["unionoperation"] = true, ["handle"] = true, ["attachment"] = true,
        ["hitbox"] = true, ["interact"] = true, ["prompt"] = true, ["basepart"] = true
    },
    BoatNames = {
        "boat", "escapeboat", "detectiveboat", "policeboat", "patrolboat",
        "rescueboat", "coastguard", "tekne", "ship", "gemi", "vessel",
        "yacht", "cruiser", "raft", "skiff", "dinghy", "ferry",
        "deliverzone", "dropoff"
    },
    DepositKeywords = {
        "deposit evidence", "deposite evidence", "deposit", "deposite",
        "deliver", "submit", "drop evidence", "place evidence", "put evidence",
        "store evidence", "teslim", "bırak"
    },
    BoatBlockedKeywords = {
        "passenger", "driver", "drive", "steer", "pilot", "sit", "otur", "seat", "vehicleseat", "door", "kapı"
    },
    TargetEvidenceCount = 8,
    MovementMode = "Tween",
    TweenSpeed = 75,
    ZoneScanRadius = 95,
    MaxUnknownPropSize = 6.5,
    RetryInteractCount = 3,
    NoclipOnMove = true,
    OffsetDistance = Vector3.new(0, 1.2, 1.2)
}

local State = {
    PatrolZones = {},
    CustomZones = {},
    LearnedEvidenceNames = {},
    LearnedMeshIds = {},
    LearnedPromptTexts = {},
    ForceWhitelistObjects = {},
    TempBlacklist = {},
    CollectedCache = {},
    Connections = {},
    CurrentCollected = 0,
    CurrentZoneIndex = 1,
    LoopRunning = false,
    IsMovingOrInteracting = false,
    WasNoclipping = false,
    ActiveTween = nil
}

local BoatMemory = {
    BoatModel = nil,
    DepositPrompt = nil,
    DepositPart = nil,
    DepositTouchPart = nil,
    DepositCFrame = nil,
    RelativeOffset = nil,
    Verified = false,
    ManualLocked = false
}

-- ==========================================
-- ARAYÜZ (GUI) OLUŞTURMA
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SGX_DetectiveV362_" .. tostring(math.random(1000, 9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function mountGui(gui)
    if typeof(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then
            gui.Parent = hui
            return
        end
    end
    if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, gui)
    end
    local okCore = pcall(function()
        gui.Parent = CoreGui
    end)
    if not okCore then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

mountGui(ScreenGui)

local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 46, 0, 46)
FloatingBtn.Position = UDim2.new(0, 15, 0.5, -23)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
FloatingBtn.Text = "SGX"
FloatingBtn.TextColor3 = Color3.fromRGB(235, 64, 90)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.TextSize = 14
FloatingBtn.Parent = ScreenGui
FloatingBtn.ZIndex = 10
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(235, 64, 90)
FloatStroke.Thickness = 1.5
FloatStroke.Parent = FloatingBtn

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 384)
MainFrame.Position = UDim2.new(0.5, -170, 0.18, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(235, 64, 90)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local dragFloatToggle, dragFloatMoved, dragFloatInput, dragFloatStart, floatStartPos
table.insert(State.Connections, FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragFloatToggle = true
        dragFloatMoved = false
        dragFloatStart = input.Position
        floatStartPos = FloatingBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragFloatToggle = false
                if not dragFloatMoved then
                    MainFrame.Visible = not MainFrame.Visible
                end
            end
        end)
    end
end))

table.insert(State.Connections, FloatingBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragFloatInput = input
    end
end))

table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragFloatInput and dragFloatToggle then
        local delta = input.Position - dragFloatStart
        if delta.Magnitude > 8 then
            dragFloatMoved = true
            FloatingBtn.Position = UDim2.new(
                floatStartPos.X.Scale,
                floatStartPos.X.Offset + delta.X,
                floatStartPos.Y.Scale,
                floatStartPos.Y.Offset + delta.Y
            )
        end
    end
end))

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -75, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SQUID GAME X | Dedektif V3.6.2"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -59, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 115, 200)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -31, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 70)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local dragging, dragInput, dragStart, startPos
table.insert(State.Connections, TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end))

table.insert(State.Connections, TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end))

table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end))

local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -24, 0, 74)
StatusBox.Position = UDim2.new(0, 12, 0, 44)
StatusBox.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
StatusBox.BorderSizePixel = 0
StatusBox.Parent = MainFrame
Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 22)
StatusLabel.Position = UDim2.new(0, 8, 0, 4)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Durum: Hazır"
StatusLabel.TextColor3 = Color3.fromRGB(185, 195, 215)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusBox

local ZoneLabel = Instance.new("TextLabel")
ZoneLabel.Size = UDim2.new(1, -16, 0, 20)
ZoneLabel.Position = UDim2.new(0, 8, 0, 26)
ZoneLabel.BackgroundTransparency = 1
ZoneLabel.Text = "Bölge: Taranıyor... | Tekne: Taranıyor..."
ZoneLabel.TextColor3 = Color3.fromRGB(130, 200, 255)
ZoneLabel.Font = Enum.Font.Gotham
ZoneLabel.TextSize = 11
ZoneLabel.TextXAlignment = Enum.TextXAlignment.Left
ZoneLabel.Parent = StatusBox

local CounterLabel = Instance.new("TextLabel")
CounterLabel.Size = UDim2.new(1, -16, 0, 22)
CounterLabel.Position = UDim2.new(0, 8, 0, 48)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = string.format("Doğrulanmış Kanıt: 0 / %d", CONFIG.TargetEvidenceCount)
CounterLabel.TextColor3 = Color3.fromRGB(255, 205, 85)
CounterLabel.Font = Enum.Font.GothamBold
CounterLabel.TextSize = 12
CounterLabel.TextXAlignment = Enum.TextXAlignment.Left
CounterLabel.Parent = StatusBox

local function updateUIStatus(text)
    if StatusLabel and StatusLabel.Parent then
        StatusLabel.Text = "Durum: " .. text
    end
end

local function updateUIZone(text)
    if ZoneLabel and ZoneLabel.Parent then
        ZoneLabel.Text = "Bölge: " .. text
    end
end

local function updateUICounter(count)
    State.CurrentCollected = count
    if CounterLabel and CounterLabel.Parent then
        CounterLabel.Text = string.format("Doğrulanmış Kanıt: %d / %d", State.CurrentCollected, CONFIG.TargetEvidenceCount)
    end
end

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -24, 0, 36)
ToggleBtn.Position = UDim2.new(0, 12, 0, 126)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 170, 95)
ToggleBtn.Text = "BÖLGE DEVRİYESİ VE TOPLAMAYI BAŞLAT"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0.62, -16, 0, 32)
ModeBtn.Position = UDim2.new(0, 12, 0, 168)
ModeBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 64)
ModeBtn.Text = "Hareket: Tween (Akıcı)"
ModeBtn.TextColor3 = Color3.fromRGB(230, 235, 245)
ModeBtn.Font = Enum.Font.GothamMedium
ModeBtn.TextSize = 11
ModeBtn.Parent = MainFrame
Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 8)

local NoclipBtn = Instance.new("TextButton")
NoclipBtn.Size = UDim2.new(0.38, -14, 0, 32)
NoclipBtn.Position = UDim2.new(0.62, 2, 0, 168)
NoclipBtn.BackgroundColor3 = Color3.fromRGB(46, 145, 95)
NoclipBtn.Text = "Noclip: AÇIK"
NoclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NoclipBtn.Font = Enum.Font.GothamBold
NoclipBtn.TextSize = 11
NoclipBtn.Parent = MainFrame
Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0, 8)

local AddZoneBtn = Instance.new("TextButton")
AddZoneBtn.Size = UDim2.new(0.5, -15, 0, 32)
AddZoneBtn.Position = UDim2.new(0, 12, 0, 206)
AddZoneBtn.BackgroundColor3 = Color3.fromRGB(55, 110, 175)
AddZoneBtn.Text = "+ Burayı Bölge Ekle"
AddZoneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddZoneBtn.Font = Enum.Font.GothamBold
AddZoneBtn.TextSize = 11
AddZoneBtn.Parent = MainFrame
Instance.new("UICorner", AddZoneBtn).CornerRadius = UDim.new(0, 6)

local LearnBtn = Instance.new("TextButton")
LearnBtn.Size = UDim2.new(0.5, -15, 0, 32)
LearnBtn.Position = UDim2.new(0.5, 3, 0, 206)
LearnBtn.BackgroundColor3 = Color3.fromRGB(165, 95, 45)
LearnBtn.Text = "Yakındaki Kanıtı Öğren"
LearnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LearnBtn.Font = Enum.Font.GothamBold
LearnBtn.TextSize = 11
LearnBtn.Parent = MainFrame
Instance.new("UICorner", LearnBtn).CornerRadius = UDim.new(0, 6)

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 38, 0, 32)
MinusBtn.Position = UDim2.new(0, 12, 0, 244)
MinusBtn.BackgroundColor3 = Color3.fromRGB(52, 57, 72)
MinusBtn.Text = "-1"
MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.TextSize = 12
MinusBtn.Parent = MainFrame
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 6)

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 38, 0, 32)
PlusBtn.Position = UDim2.new(0, 56, 0, 244)
PlusBtn.BackgroundColor3 = Color3.fromRGB(52, 57, 72)
PlusBtn.Text = "+1"
PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 12
PlusBtn.Parent = MainFrame
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 6)

local GoBoatBtn = Instance.new("TextButton")
GoBoatBtn.Size = UDim2.new(1, -112, 0, 32)
GoBoatBtn.Position = UDim2.new(0, 100, 0, 244)
GoBoatBtn.BackgroundColor3 = Color3.fromRGB(60, 115, 200)
GoBoatBtn.Text = "Tekneye Şimdi Teslim Et"
GoBoatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GoBoatBtn.Font = Enum.Font.GothamBold
GoBoatBtn.TextSize = 11
GoBoatBtn.Parent = MainFrame
Instance.new("UICorner", GoBoatBtn).CornerRadius = UDim.new(0, 6)

local SaveBoatBtn = Instance.new("TextButton")
SaveBoatBtn.Size = UDim2.new(1, -24, 0, 30)
SaveBoatBtn.Position = UDim2.new(0, 12, 0, 282)
SaveBoatBtn.BackgroundColor3 = Color3.fromRGB(32, 138, 150)
SaveBoatBtn.Text = "Tekne / Deposit Konumu Kaydet"
SaveBoatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBoatBtn.Font = Enum.Font.GothamBold
SaveBoatBtn.TextSize = 11
SaveBoatBtn.Parent = MainFrame
Instance.new("UICorner", SaveBoatBtn).CornerRadius = UDim.new(0, 6)

local RebuildZonesBtn = Instance.new("TextButton")
RebuildZonesBtn.Size = UDim2.new(1, -24, 0, 30)
RebuildZonesBtn.Position = UDim2.new(0, 12, 0, 318)
RebuildZonesBtn.BackgroundColor3 = Color3.fromRGB(65, 55, 85)
RebuildZonesBtn.Text = "Oda / Bölge Listesini Yeniden Tara"
RebuildZonesBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
RebuildZonesBtn.Font = Enum.Font.GothamMedium
RebuildZonesBtn.TextSize = 11
RebuildZonesBtn.Parent = MainFrame
Instance.new("UICorner", RebuildZonesBtn).CornerRadius = UDim.new(0, 6)

local FooterLabel = Instance.new("TextLabel")
FooterLabel.Size = UDim2.new(1, -24, 0, 20)
FooterLabel.Position = UDim2.new(0, 12, 0, 354)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text = "SGX İkonuyla veya [RightCtrl] ile Gizle/Aç"
FooterLabel.TextColor3 = Color3.fromRGB(120, 130, 145)
FooterLabel.Font = Enum.Font.Gotham
FooterLabel.TextSize = 11
FooterLabel.Parent = MainFrame

-- ==========================================
-- YARDIMCI FONKSİYONLAR VE DOĞRULAMA
-- ==========================================
table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end))

local function restoreCharacterCollision()
    if not LocalPlayer.Character then return end
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name == "HumanoidRootPart" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Torso" or part.Name == "Head") then
            part.CanCollide = true
        end
    end
end

table.insert(State.Connections, RunService.Stepped:Connect(function()
    if State.IsMovingOrInteracting and CONFIG.NoclipOnMove and LocalPlayer.Character then
        State.WasNoclipping = true
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
        end
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    elseif State.WasNoclipping then
        State.WasNoclipping = false
        restoreCharacterCollision()
    end
end))

local function getCharacterParts()
    local character = LocalPlayer.Character
    if not character then return nil, nil, nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if rootPart and humanoid and humanoid.Health > 0 then
        return character, rootPart, humanoid
    end
    return nil, nil, nil
end

local function unseatCharacter(humanoid)
    if humanoid and humanoid.Sit then
        humanoid.Sit = false
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.15)
    end
end

-- 3 harf ve altı anahtar kelimelerde (et, su, ye, al) yanlış eşleşmeleri önlemek için tam kelime sınırı kullanır
local function matchesKeyword(text, keywordList)
    if not text or text == "" then return false end
    local lowerText = string.lower(tostring(text))
    for _, kw in ipairs(keywordList) do
        local lowerKw = string.lower(kw)
        if #lowerKw <= 3 then
            local escaped = string.gsub(lowerKw, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            if string.find(lowerText, "%f[%w]" .. escaped .. "%f[%W]") then
                return true
            end
        else
            if string.find(lowerText, lowerKw, 1, true) then
                return true
            end
        end
    end
    return false
end

local function getSafeLookCFrame(fromPos, targetPos)
    local flatTarget = Vector3.new(targetPos.X, fromPos.Y, targetPos.Z)
    if (flatTarget - fromPos).Magnitude < 0.05 then
        return CFrame.new(fromPos)
    end
    return CFrame.lookAt(fromPos, flatTarget)
end

local function isPlayerCharacterDescendant(obj)
    local current = obj
    while current and current ~= Workspace do
        if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
            return true
        end
        current = current.Parent
    end
    return false
end

local function isRoomOrMapContainer(model)
    if not model or not model:IsA("Model") then return true end
    if model == Workspace or Players:GetPlayerFromCharacter(model) then return true end
    local lowerName = string.lower(model.Name)
    if matchesKeyword(lowerName, CONFIG.RoomZoneKeywords)
        or matchesKeyword(lowerName, {"map", "building", "level", "rooms", "interior", "exterior", "facility", "island", "floor", "wall", "room"}) then
        return true
    end
    local ok, size = pcall(function() return model:GetExtentsSize() end)
    if ok and size and (size.X > 12 or size.Y > 12 or size.Z > 12) then
        return true
    end
    return false
end

local function isReasonableEvidenceSize(obj)
    local maxDim = CONFIG.MaxUnknownPropSize
    if obj:IsA("BasePart") then
        local s = obj.Size
        return s.X <= maxDim and s.Y <= maxDim and s.Z <= maxDim
    elseif obj:IsA("Model") then
        local ok, s = pcall(function() return obj:GetExtentsSize() end)
        if ok and s then
            return s.X <= maxDim and s.Y <= maxDim and s.Z <= maxDim
        end
    end
    return true
end

local function resolveEvidenceRoot(interactObj)
    local parent = interactObj and interactObj.Parent
    if not parent then return nil, nil end
    if parent:IsA("Attachment") and parent.Parent then
        parent = parent.Parent
    end
    local parentModel = parent:FindFirstAncestorOfClass("Model")
    if parentModel and not isRoomOrMapContainer(parentModel) then
        return parentModel, parent
    end
    return parent, parent
end

local function getTargetCFrame(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then
        return instance.CFrame
    elseif instance:IsA("Model") then
        if instance.PrimaryPart then
            return instance.PrimaryPart.CFrame
        end
        local ok, pivot = pcall(function() return instance:GetPivot() end)
        if ok and pivot then return pivot end
        local part = instance:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.CFrame end
    elseif instance:IsA("Folder") then
        local model = instance:FindFirstChildWhichIsA("Model", true)
        if model then return getTargetCFrame(model) end
        local part = instance:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.CFrame end
    elseif instance:IsA("Attachment") then
        return instance.WorldCFrame
    elseif instance:IsA("ProximityPrompt") or instance:IsA("ClickDetector") or instance:IsA("TouchTransmitter") then
        return getTargetCFrame(instance.Parent)
    end
    return nil
end

-- Görünmez hitbox parçalarına bağlı aktif prompt/click nesnelerini yanlışlıkla elemez
local function isPartOrModelVisible(obj, interactObj)
    if not obj or not obj.Parent then return false end
    if interactObj and (interactObj:IsA("ProximityPrompt") or interactObj:IsA("ClickDetector")) then
        return true
    end
    if obj:IsA("Attachment") then
        return isPartOrModelVisible(obj.Parent, interactObj)
    elseif obj:IsA("BasePart") then
        if obj:FindFirstChildWhichIsA("ProximityPrompt", true) or obj:FindFirstChildWhichIsA("ClickDetector", true) then
            return true
        end
        return obj.Transparency < 0.95
    elseif obj:IsA("Model") then
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("BasePart") and child.Transparency < 0.95 then
                return true
            end
        end
        return false
    end
    return true
end

local function collectMeshIds(rootObj)
    local ids = {}
    if not rootObj then return ids end
    if rootObj:IsA("MeshPart") and rootObj.MeshId ~= "" then
        table.insert(ids, rootObj.MeshId)
    end
    for _, desc in ipairs(rootObj:GetDescendants()) do
        if desc:IsA("MeshPart") and desc.MeshId ~= "" then
            table.insert(ids, desc.MeshId)
        elseif desc:IsA("SpecialMesh") and desc.MeshId ~= "" then
            table.insert(ids, desc.MeshId)
        end
    end
    return ids
end

local function matchesLearnedSignature(rootObj, anchorPart, promptText)
    if State.ForceWhitelistObjects[rootObj] or (anchorPart and State.ForceWhitelistObjects[anchorPart]) then
        return true
    end
    local rName = string.lower(rootObj.Name)
    local aName = anchorPart and string.lower(anchorPart.Name) or ""
    if State.LearnedEvidenceNames[rName] or (aName ~= "" and State.LearnedEvidenceNames[aName]) then
        return true
    end
    if promptText and promptText ~= "" then
        local lowerP = string.lower(promptText)
        for learnedTxt, _ in pairs(State.LearnedPromptTexts) do
            if string.find(lowerP, learnedTxt, 1, true) then
                return true
            end
        end
    end
    for _, mId in ipairs(collectMeshIds(rootObj)) do
        if State.LearnedMeshIds[mId] then
            return true
        end
    end
    return false
end

local function getBackpackGuiCount()
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pGui then return nil end
    for _, lbl in ipairs(pGui:GetDescendants()) do
        if (lbl:IsA("TextLabel") or lbl:IsA("TextButton")) and lbl.Visible and lbl.Text ~= "" then
            local cur, max = string.match(lbl.Text, "(%d+)%s*/%s*(%d+)")
            if cur and tonumber(max) == CONFIG.TargetEvidenceCount then
                return tonumber(cur)
            end
        end
    end
    return nil
end

local function syncBackpackGuiCounter()
    local num = getBackpackGuiCount()
    if num and num ~= State.CurrentCollected then
        updateUICounter(num)
    end
end

local function requestStreamAt(pos)
    pcall(function()
        if typeof(LocalPlayer.RequestStreamAroundAsync) == "function" then
            task.spawn(function()
                pcall(function()
                    LocalPlayer:RequestStreamAroundAsync(pos, 3)
                end)
            end)
        end
    end)
end

local function moveToCFrame(targetCF, customOffset)
    local _, rootPart, humanoid = getCharacterParts()
    if not rootPart or not humanoid or not targetCF then return false end

    unseatCharacter(humanoid)
    requestStreamAt(targetCF.Position)

    if State.ActiveTween then
        pcall(function() State.ActiveTween:Cancel() end)
        State.ActiveTween = nil
    end

    State.IsMovingOrInteracting = true
    local offset = customOffset or CONFIG.OffsetDistance
    local goalPos = targetCF.Position + offset
    local dist = (rootPart.Position - goalPos).Magnitude

    if dist < 2.2 then
        rootPart.CFrame = getSafeLookCFrame(rootPart.Position, targetCF.Position)
        return true
    end

    if CONFIG.MovementMode == "Teleport" then
        rootPart.CFrame = getSafeLookCFrame(goalPos, targetCF.Position)
        task.wait(0.12)
        return true
    end

    local duration = math.clamp(dist / math.max(CONFIG.TweenSpeed, 15), 0.15, 8)
    local goalCF = getSafeLookCFrame(goalPos, targetCF.Position)
    local tween = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = goalCF})
    State.ActiveTween = tween
    tween:Play()

    local completed = false
    local conn = tween.Completed:Connect(function()
        completed = true
    end)

    local elapsed = 0
    while not completed and elapsed < duration + 1.5 do
        if State.ActiveTween ~= tween then
            break
        end
        task.wait(0.05)
        elapsed = elapsed + 0.05
    end

    pcall(function() conn:Disconnect() end)
    if State.ActiveTween == tween then
        State.ActiveTween = nil
    end

    -- Tween bitiminde prompt menzilinin (5-6 stud) dışında kalındıysa son adımı tamamla
    local remaining = (rootPart.Position - goalPos).Magnitude
    if remaining > 4.5 and remaining < 18 then
        rootPart.CFrame = goalCF
        task.wait(0.08)
    end

    return (rootPart.Position - goalPos).Magnitude < 8
end

-- ==========================================
-- AKILLI TEKNE & DEPOSIT BÖLGESİ MODELLEME
-- ==========================================
local function isBlockedBoatPrompt(prompt)
    if not prompt or not prompt.Parent then return true end
    if prompt.Parent:IsA("Seat") or prompt.Parent:IsA("VehicleSeat") then
        return true
    end
    local combined = string.lower(
        (prompt.ActionText or "") .. " " ..
        (prompt.ObjectText or "") .. " " ..
        (prompt.Name or "") .. " " ..
        (prompt.Parent.Name or "")
    )
    return matchesKeyword(combined, CONFIG.BoatBlockedKeywords)
end

local function isDepositPrompt(prompt, allowDisabled)
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return false
    end
    if not allowDisabled and not prompt.Enabled then
        return false
    end
    if isBlockedBoatPrompt(prompt) then
        return false
    end
    local fullText = string.lower(
        (prompt.ActionText or "") .. " " ..
        (prompt.ObjectText or "") .. " " ..
        (prompt.Name or "") .. " " ..
        (prompt.Parent and prompt.Parent.Name or "")
    )
    return matchesKeyword(fullText, CONFIG.DepositKeywords)
end

local function findBoatModelFor(instance)
    local current = instance
    while current and current ~= Workspace do
        if current:IsA("Model") and matchesKeyword(current.Name, CONFIG.BoatNames) then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function detectBoatUnderPlayer()
    local character, rootPart = getCharacterParts()
    if not character or not rootPart then return nil, nil end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }

    local hit = Workspace:Raycast(rootPart.Position, Vector3.new(0, -25, 0), params)
    if hit and hit.Instance then
        local named = findBoatModelFor(hit.Instance)
        if named then
            return named, hit.Instance
        end
        local model = hit.Instance:FindFirstAncestorOfClass("Model")
        if model and model ~= Workspace then
            local ok, size = pcall(function() return model:GetExtentsSize() end)
            if ok and size and size.X < 150 and size.Z < 150 then
                return model, hit.Instance
            end
        end
        if hit.Instance.Size.X < 150 and hit.Instance.Size.Z < 150 then
            return hit.Instance, hit.Instance
        end
    end
    return nil, nil
end

local function findBoatModelInWorkspace()
    if BoatMemory.BoatModel and BoatMemory.BoatModel.Parent then
        return BoatMemory.BoatModel
    end

    local bestBoat = nil
    local bestScore = -1
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Folder")) and not isPlayerCharacterDescendant(obj) then
            if matchesKeyword(obj.Name, CONFIG.BoatNames) and getTargetCFrame(obj) then
                local score = 10
                if obj:FindFirstChildWhichIsA("VehicleSeat", true) or obj:FindFirstChildWhichIsA("Seat", true) then
                    score = score + 20
                end
                if matchesKeyword(obj.Name, {"boat", "tekne", "ship", "gemi", "vessel", "coastguard"}) then
                    score = score + 15
                end
                if score > bestScore then
                    bestScore = score
                    bestBoat = obj
                end
            end
        end
    end
    if bestBoat then
        BoatMemory.BoatModel = bestBoat
        return bestBoat
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") and not isPlayerCharacterDescendant(obj) then
            local model = obj:FindFirstAncestorOfClass("Model")
            if model and model ~= Workspace then
                BoatMemory.BoatModel = model
                return model
            end
        end
    end

    local underModel = detectBoatUnderPlayer()
    if underModel then
        BoatMemory.BoatModel = underModel
        return underModel
    end

    return nil
end

local function saveDepositToMemory(prompt, cf, boatModel, isVerified, isManualLock, touchPart)
    local bModel = boatModel or (prompt and findBoatModelFor(prompt)) or findBoatModelInWorkspace()
    BoatMemory.DepositPrompt = prompt or BoatMemory.DepositPrompt
    BoatMemory.DepositPart = (prompt and prompt.Parent) or BoatMemory.DepositPart
    BoatMemory.DepositTouchPart = touchPart or BoatMemory.DepositTouchPart
    BoatMemory.DepositCFrame = cf
    BoatMemory.BoatModel = bModel
    BoatMemory.Verified = isVerified or BoatMemory.Verified
    if isManualLock ~= nil then
        BoatMemory.ManualLocked = isManualLock
    end

    if bModel and cf then
        local bCF = getTargetCFrame(bModel)
        if bCF then
            BoatMemory.RelativeOffset = bCF:ToObjectSpace(cf)
        end
    end
end

local function findNearbyDepositCandidates(centerPos, radius)
    local foundPrompt = nil
    local foundTouch = nil
    local bestPromptDist = radius
    local bestTouchDist = radius

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if not isPlayerCharacterDescendant(desc) then
            if desc:IsA("ProximityPrompt") and not isBlockedBoatPrompt(desc) then
                local pCF = getTargetCFrame(desc.Parent)
                if pCF then
                    local d = (pCF.Position - centerPos).Magnitude
                    if d < bestPromptDist then
                        if isDepositPrompt(desc, true) then
                            bestPromptDist = d
                            foundPrompt = desc
                        elseif not foundPrompt and d <= 14 then
                            local combined = string.lower((desc.ActionText or "") .. " " .. (desc.ObjectText or "") .. " " .. desc.Parent.Name)
                            if not matchesKeyword(combined, {"collect", "take", "pick", "al", "topla"}) then
                                bestPromptDist = d
                                foundPrompt = desc
                            end
                        end
                    end
                end
            elseif desc:IsA("TouchTransmitter") and desc.Parent and desc.Parent:IsA("BasePart") then
                if not desc.Parent:IsA("Seat") and not desc.Parent:IsA("VehicleSeat") then
                    local d = (desc.Parent.Position - centerPos).Magnitude
                    if d < bestTouchDist then
                        bestTouchDist = d
                        foundTouch = desc.Parent
                    end
                end
            end
        end
    end

    return foundPrompt, foundTouch
end

local function sealManualBoatDepositPoint()
    local _, rootPart = getCharacterParts()
    if not rootPart then
        updateUIStatus("Karakter bulunamadı, nokta kaydedilemedi.")
        return
    end

    local standCF = rootPart.CFrame
    local boatModel = detectBoatUnderPlayer() or findBoatModelInWorkspace()
    local nearPrompt, nearTouch = findNearbyDepositCandidates(rootPart.Position, 24)

    BoatMemory.DepositPrompt = nearPrompt
    BoatMemory.DepositPart = nearPrompt and nearPrompt.Parent or nil
    BoatMemory.DepositTouchPart = nearTouch
    BoatMemory.RelativeOffset = nil
    saveDepositToMemory(nearPrompt, standCF, boatModel, true, true, nearTouch)

    SaveBoatBtn.BackgroundColor3 = Color3.fromRGB(38, 165, 110)
    SaveBoatBtn.Text = "Tekne Konumu Kaydedildi [Güncelle]"

    local boatName = boatModel and boatModel.Name or "Sabit Konum"
    updateUIZone(string.format("%d Oda | Tekne: Kayıtlı (%s)", #State.PatrolZones, boatName))
    updateUIStatus("Deposit Evidence noktası başarıyla kaydedildi!")
end

local function getSmartBoatSternProbePoints(boatModel)
    local points = {}
    if not boatModel or not boatModel.Parent then return points end

    local boatCF = getTargetCFrame(boatModel)
    if not boatCF then return points end

    if BoatMemory.RelativeOffset then
        table.insert(points, boatCF * BoatMemory.RelativeOffset)
    end

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if not isPlayerCharacterDescendant(desc) then
            if desc:IsA("ProximityPrompt") and isDepositPrompt(desc, true) then
                local pCF = getTargetCFrame(desc.Parent)
                if pCF then
                    table.insert(points, 1, pCF + Vector3.new(0, 1.5, 0))
                end
            elseif desc:IsA("BasePart") and desc.Parent and not desc:IsA("Seat") and not desc:IsA("VehicleSeat") then
                local d = (desc.Position - boatCF.Position).Magnitude
                if d <= 50 then
                    local lowerName = string.lower(desc.Name)
                    local hasTouch = desc:FindFirstChildOfClass("TouchTransmitter") ~= nil
                    local hasGui = desc:FindFirstChildOfClass("BillboardGui") ~= nil or desc:FindFirstChildOfClass("SurfaceGui") ~= nil
                    if hasTouch or hasGui or matchesKeyword(lowerName, {"deposit", "evidence", "deliver", "zone", "pad", "circle", "stern", "back", "rear", "trigger", "area"}) then
                        table.insert(points, desc.CFrame + Vector3.new(0, 2, 0))
                    end
                end
            end
        end
    end

    if boatModel:IsA("Model") then
        local ok, boxCF, boxSize = pcall(function() return boatModel:GetBoundingBox() end)
        if ok and boxCF and boxSize then
            local deckY = boxCF.Position.Y + math.min(boxSize.Y * 0.25, 3.5)
            local centerDeck = Vector3.new(boxCF.Position.X, deckY, boxCF.Position.Z)

            local longAxisVec
            local halfLen
            if boxSize.Z >= boxSize.X then
                longAxisVec = boxCF.LookVector
                halfLen = boxSize.Z * 0.38
            else
                longAxisVec = boxCF.RightVector
                halfLen = boxSize.X * 0.38
            end

            local endA = centerDeck + (longAxisVec * halfLen)
            local endB = centerDeck - (longAxisVec * halfLen)

            local helm = boatModel:FindFirstChildWhichIsA("VehicleSeat", true) or boatModel:FindFirstChildWhichIsA("Seat", true)
            if helm then
                local distA = (endA - helm.Position).Magnitude
                local distB = (endB - helm.Position).Magnitude
                local sternPos = (distA >= distB) and endA or endB
                local bowPos = (distA >= distB) and endB or endA
                local midSternPos = centerDeck:Lerp(sternPos, 0.55)

                table.insert(points, CFrame.new(sternPos))
                table.insert(points, CFrame.new(midSternPos))
                table.insert(points, CFrame.new(centerDeck))
                table.insert(points, CFrame.new(bowPos))
            else
                table.insert(points, CFrame.new(endB))
                table.insert(points, CFrame.new(endA))
                table.insert(points, CFrame.new(centerDeck))
            end
        end
    end

    local filtered = {}
    for _, cf in ipairs(points) do
        local tooClose = false
        for _, existing in ipairs(filtered) do
            if (existing.Position - cf.Position).Magnitude < 3.5 then
                tooClose = true
                break
            end
        end
        if not tooClose then
            table.insert(filtered, cf)
        end
    end

    return filtered
end

local function scanAndMemorizeBoatDeposit()
    if BoatMemory.ManualLocked then
        if BoatMemory.BoatModel and BoatMemory.BoatModel.Parent and BoatMemory.RelativeOffset then
            local liveBoatCF = getTargetCFrame(BoatMemory.BoatModel)
            if liveBoatCF then
                local liveCF = liveBoatCF * BoatMemory.RelativeOffset
                BoatMemory.DepositCFrame = liveCF
                local p, t = findNearbyDepositCandidates(liveCF.Position, 20)
                if p then BoatMemory.DepositPrompt = p end
                if t then BoatMemory.DepositTouchPart = t end
                return { Prompt = BoatMemory.DepositPrompt, TouchPart = BoatMemory.DepositTouchPart, CFrame = liveCF, BoatModel = BoatMemory.BoatModel }
            end
        elseif BoatMemory.DepositCFrame and (not BoatMemory.BoatModel or BoatMemory.BoatModel.Parent) then
            local p, t = findNearbyDepositCandidates(BoatMemory.DepositCFrame.Position, 20)
            if p then BoatMemory.DepositPrompt = p end
            if t then BoatMemory.DepositTouchPart = t end
            return { Prompt = BoatMemory.DepositPrompt, TouchPart = BoatMemory.DepositTouchPart, CFrame = BoatMemory.DepositCFrame, BoatModel = BoatMemory.BoatModel }
        else
            BoatMemory.ManualLocked = false
            BoatMemory.Verified = false
            BoatMemory.RelativeOffset = nil
            SaveBoatBtn.BackgroundColor3 = Color3.fromRGB(32, 138, 150)
            SaveBoatBtn.Text = "Tekne / Deposit Konumu Kaydet"
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not isPlayerCharacterDescendant(obj) and isDepositPrompt(obj, true) then
            local cf = getTargetCFrame(obj.Parent)
            if cf then
                local boatModel = findBoatModelFor(obj)
                saveDepositToMemory(obj, cf, boatModel, obj.Enabled, false, nil)
                return { Prompt = obj, TouchPart = nil, CFrame = cf, BoatModel = boatModel }
            end
        end
    end

    local _, rootPart = getCharacterParts()
    if rootPart then
        local nearPrompt, nearTouch = findNearbyDepositCandidates(rootPart.Position, 22)
        local underBoat = detectBoatUnderPlayer()
        if nearPrompt or nearTouch or underBoat then
            local targetCF = (nearPrompt and getTargetCFrame(nearPrompt.Parent))
                or (nearTouch and nearTouch.CFrame)
                or rootPart.CFrame
            saveDepositToMemory(nearPrompt, targetCF, underBoat, true, false, nearTouch)
            return { Prompt = nearPrompt, TouchPart = nearTouch, CFrame = targetCF, BoatModel = underBoat }
        end
    end

    local boatModel = findBoatModelInWorkspace()
    if boatModel then
        local boatCF = getTargetCFrame(boatModel)
        if boatCF then
            local liveCF = (BoatMemory.RelativeOffset and (boatCF * BoatMemory.RelativeOffset))
                or (BoatMemory.DepositPart and getTargetCFrame(BoatMemory.DepositPart))
                or BoatMemory.DepositCFrame

            if not liveCF then
                local probes = getSmartBoatSternProbePoints(boatModel)
                liveCF = probes[1] or (boatCF * CFrame.new(0, 2, 8))
            end

            saveDepositToMemory(BoatMemory.DepositPrompt, liveCF, boatModel, BoatMemory.Verified, false, BoatMemory.DepositTouchPart)
            return { Prompt = BoatMemory.DepositPrompt, TouchPart = BoatMemory.DepositTouchPart, CFrame = liveCF, BoatModel = boatModel }
        end
    end

    return nil
end

local function disableSeatsNear(centerPos, boatModel)
    if boatModel then
        for _, desc in ipairs(boatModel:GetDescendants()) do
            if desc:IsA("Seat") or desc:IsA("VehicleSeat") then
                pcall(function() desc.Disabled = true end)
            end
        end
    end
    if centerPos then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if (desc:IsA("Seat") or desc:IsA("VehicleSeat")) and (desc.Position - centerPos).Magnitude < 45 then
                pcall(function() desc.Disabled = true end)
            end
        end
    end
end

local function triggerDepositInteractions(targetCF, boatModel, keepExistingCoords)
    local _, rootPart, humanoid = getCharacterParts()
    if not rootPart then return false end
    unseatCharacter(humanoid)

    local interacted = false
    local nearPrompt, nearTouch = findNearbyDepositCandidates(rootPart.Position, 24)
    local promptToUse = (BoatMemory.DepositPrompt and BoatMemory.DepositPrompt.Parent and BoatMemory.DepositPrompt) or nearPrompt
    local touchToUse = (BoatMemory.DepositTouchPart and BoatMemory.DepositTouchPart.Parent and BoatMemory.DepositTouchPart) or nearTouch

    if promptToUse and promptToUse.Parent then
        local pCF = getTargetCFrame(promptToUse.Parent)
        if pCF and (rootPart.Position - pCF.Position).Magnitude <= math.max(promptToUse.MaxActivationDistance + 16, 26) then
            rootPart.CFrame = getSafeLookCFrame(rootPart.Position, pCF.Position)
            pcall(function()
                promptToUse.Enabled = true
                promptToUse.RequiresLineOfSight = false
                promptToUse.MaxActivationDistance = math.max(promptToUse.MaxActivationDistance, 25)
            end)
            pcall(function()
                if typeof(fireproximityprompt) == "function" then
                    fireproximityprompt(promptToUse)
                end
            end)
            pcall(function()
                promptToUse:InputHoldBegin()
                task.wait((promptToUse.HoldDuration or 0) + 0.18)
                promptToUse:InputHoldEnd()
            end)
            interacted = true
        end
    end

    if touchToUse and touchToUse.Parent and typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(rootPart, touchToUse, 0)
            task.wait(0.12)
            firetouchinterest(rootPart, touchToUse, 1)
        end)
        interacted = true
    end

    if interacted then
        if not keepExistingCoords then
            saveDepositToMemory(promptToUse, CFrame.new(rootPart.Position), boatModel, true, BoatMemory.ManualLocked, touchToUse)
        else
            BoatMemory.DepositPrompt = promptToUse
            BoatMemory.DepositTouchPart = touchToUse
        end
    end

    return interacted
end

local function depositEvidenceAtBoat()
    updateUIStatus("Tekne Deposit noktasına gidiliyor...")
    local _, rootPart, humanoid = getCharacterParts()
    if not rootPart or not humanoid then return false end
    unseatCharacter(humanoid)

    local info = scanAndMemorizeBoatDeposit()
    if not info or not info.CFrame then
        updateUIStatus("Tekne bulunamadı! Tekneye gidip 'Tekne Konumu Kaydet'e basın.")
        State.IsMovingOrInteracting = false
        return false
    end

    local boatModel = info.BoatModel or findBoatModelInWorkspace()
    disableSeatsNear(info.CFrame.Position, boatModel)

    if BoatMemory.ManualLocked then
        for attempt = 1, CONFIG.RetryInteractCount do
            local freshInfo = scanAndMemorizeBoatDeposit()
            local sealedCF = (freshInfo and freshInfo.CFrame) or info.CFrame

            updateUIStatus(string.format("Kayıtlı Deposit noktasına gidiliyor (%d/%d)...", attempt, CONFIG.RetryInteractCount))
            moveToCFrame(sealedCF, Vector3.new(0, 0.5, 0))

            State.IsMovingOrInteracting = false
            restoreCharacterCollision()
            _, rootPart, humanoid = getCharacterParts()
            if rootPart and humanoid then
                unseatCharacter(humanoid)
                pcall(function() humanoid:MoveTo(sealedCF.Position) end)
            end
            task.wait(0.35)

            if triggerDepositInteractions(sealedCF, boatModel, true) then
                task.wait(0.35)
                updateUICounter(0)
                table.clear(State.CollectedCache)
                table.clear(State.TempBlacklist)
                updateUIStatus("Kanıtlar tekneye teslim edildi!")
                return true
            end
        end

        State.IsMovingOrInteracting = false
        updateUIStatus("Teslimat tetiklenemedi, tekrar deneniyor...")
        return false
    end

    moveToCFrame(info.CFrame, Vector3.new(0, 1.0, 0))
    State.IsMovingOrInteracting = false
    restoreCharacterCollision()
    task.wait(0.3)

    if triggerDepositInteractions(info.CFrame, boatModel, false) then
        task.wait(0.35)
        updateUICounter(0)
        table.clear(State.CollectedCache)
        table.clear(State.TempBlacklist)
        updateUIStatus("Kanıtlar tekneye teslim edildi!")
        return true
    end

    local probePoints = getSmartBoatSternProbePoints(boatModel)
    if #probePoints == 0 then
        table.insert(probePoints, info.CFrame)
    end

    for attempt = 1, CONFIG.RetryInteractCount do
        for idx, probeCF in ipairs(probePoints) do
            _, rootPart, humanoid = getCharacterParts()
            if not rootPart then break end
            unseatCharacter(humanoid)
            disableSeatsNear(probeCF.Position, boatModel)

            updateUIStatus(string.format("Tekne güvertesi taranıyor (%d/%d)...", idx, #probePoints))
            moveToCFrame(probeCF, Vector3.new(0, 1.0, 0))

            State.IsMovingOrInteracting = false
            restoreCharacterCollision()
            if humanoid then
                pcall(function() humanoid:MoveTo(probeCF.Position) end)
            end
            task.wait(0.35)

            if triggerDepositInteractions(probeCF, boatModel, false) then
                task.wait(0.35)
                updateUICounter(0)
                table.clear(State.CollectedCache)
                table.clear(State.TempBlacklist)
                updateUIStatus("Kanıtlar tekneye teslim edildi!")
                return true
            end
        end
        task.wait(0.2)
    end

    State.IsMovingOrInteracting = false
    updateUIStatus("Deposit tetiklenemedi, tekrar deneniyor...")
    return false
end

-- ==========================================
-- ODA / BÖLGE LİSTESİNİ OLUŞTURMA VE YENİDEN TARAMA
-- ==========================================
local function buildPatrolZones()
    table.clear(State.PatrolZones)

    for _, cz in ipairs(State.CustomZones) do
        table.insert(State.PatrolZones, cz)
    end

    local function addZoneIfUnique(name, pos)
        if not pos then return end
        for _, existing in ipairs(State.PatrolZones) do
            if (existing.Position - pos).Magnitude < 25 then
                return
            end
        end
        table.insert(State.PatrolZones, {
            Name = name,
            Position = pos
        })
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder")) and not isPlayerCharacterDescendant(obj) then
            local objName = obj.Name
            if matchesKeyword(objName, CONFIG.RoomZoneKeywords) and not matchesKeyword(objName, CONFIG.BoatNames) then
                local isSingleSmallProp = (obj:IsA("BasePart") and obj.Size.Magnitude < 10)
                    or (obj:IsA("Model") and not isRoomOrMapContainer(obj))
                if not isSingleSmallProp then
                    local cf = getTargetCFrame(obj)
                    if cf then
                        addZoneIfUnique(objName, cf.Position)
                    end
                end
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector")) and not isPlayerCharacterDescendant(obj) then
            local rootTarget, anchorPart = resolveEvidenceRoot(obj)
            if rootTarget and anchorPart then
                local propNames = string.lower(anchorPart.Name .. " " .. rootTarget.Name)
                local promptTxt = obj:IsA("ProximityPrompt")
                    and string.lower((obj.ObjectText or "") .. " " .. (obj.ActionText or "") .. " " .. obj.Name)
                    or string.lower(obj.Name)
                local combinedText = promptTxt .. " " .. propNames

                if not matchesKeyword(combinedText, CONFIG.PromptBlacklist)
                    and not matchesKeyword(propNames, CONFIG.NonEvidencePropBlacklist)
                    and not matchesKeyword(propNames, CONFIG.BoatNames) then
                    local cf = getTargetCFrame(anchorPart)
                    if cf then
                        addZoneIfUnique("Bölge_" .. rootTarget.Name, cf.Position)
                    end
                end
            end
        end
    end

    local boatInfo = scanAndMemorizeBoatDeposit()
    local boatTag = "Tekne: Taranıyor"
    if BoatMemory.ManualLocked then
        boatTag = "Tekne: Kayıtlı"
    elseif boatInfo then
        boatTag = BoatMemory.Verified and "Tekne: Doğrulandı" or "Tekne: Hazır"
    end
    updateUIZone(string.format("%d Oda | %s", #State.PatrolZones, boatTag))
end

-- ==========================================
-- OPTİMİZE YAKINDAKİ KANITLARI ÖĞRENME MOTORU
-- ==========================================
local function learnNearbyEvidences()
    local _, rootPart = getCharacterParts()
    if not rootPart then return end

    local candidates = {}
    local seenRoots = {}

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if (desc:IsA("ProximityPrompt") or desc:IsA("ClickDetector") or desc:IsA("TouchTransmitter"))
            and not isPlayerCharacterDescendant(desc) then
            local skipDeposit = desc:IsA("ProximityPrompt") and isDepositPrompt(desc, true)
            if not skipDeposit then
                local rootObj, anchorPart = resolveEvidenceRoot(desc)
                if rootObj and anchorPart and not seenRoots[rootObj] then
                    if not anchorPart:IsA("Seat") and not anchorPart:IsA("VehicleSeat") then
                        local cf = getTargetCFrame(anchorPart) or getTargetCFrame(rootObj)
                        if cf then
                            local dist = (cf.Position - rootPart.Position).Magnitude
                            if dist <= 30 then
                                local promptStr = ""
                                if desc:IsA("ProximityPrompt") then
                                    promptStr = (desc.ObjectText or "") .. " " .. (desc.ActionText or "")
                                end
                                local combined = string.lower(rootObj.Name .. " " .. anchorPart.Name .. " " .. promptStr)

                                local isHardTrap = matchesKeyword(combined, CONFIG.BoatNames)
                                    or matchesKeyword(combined, {"door", "kapı", "coffin", "tabut", "stove", "ocak"})

                                if dist <= 6.5 or not isHardTrap then
                                    seenRoots[rootObj] = true
                                    table.insert(candidates, {
                                        Root = rootObj,
                                        Anchor = anchorPart,
                                        Prompt = desc:IsA("ProximityPrompt") and desc or nil,
                                        Distance = dist
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then
        updateUIStatus("30 stud yakında öğrenilecek nesne bulunamadı.")
        return
    end

    table.sort(candidates, function(a, b)
        return a.Distance < b.Distance
    end)

    local baseDist = candidates[1].Distance
    local learnedNamesList = {}
    local meshCount = 0

    for i = 1, math.min(#candidates, 3) do
        local item = candidates[i]
        if item.Distance <= baseDist + 10 then
            local rLower = string.lower(item.Root.Name)
            local aLower = string.lower(item.Anchor.Name)

            State.ForceWhitelistObjects[item.Root] = true
            State.ForceWhitelistObjects[item.Anchor] = true
            State.TempBlacklist[item.Root] = nil
            State.CollectedCache[item.Root] = nil

            if not CONFIG.GenericObjectNames[rLower] and #rLower >= 2 then
                State.LearnedEvidenceNames[rLower] = true
            end
            if not CONFIG.GenericObjectNames[aLower] and #aLower >= 2 then
                State.LearnedEvidenceNames[aLower] = true
            end

            for _, mId in ipairs(collectMeshIds(item.Root)) do
                State.LearnedMeshIds[mId] = true
                meshCount = meshCount + 1
            end

            if item.Prompt then
                local objTxt = string.lower(item.Prompt.ObjectText or "")
                local actTxt = string.lower(item.Prompt.ActionText or "")
                if #objTxt >= 3 and not CONFIG.GenericObjectNames[objTxt] then
                    State.LearnedPromptTexts[objTxt] = true
                end
                if #actTxt >= 4 and actTxt ~= "interact" and actTxt ~= "use" then
                    State.LearnedPromptTexts[actTxt] = true
                end
            end

            table.insert(learnedNamesList, item.Root.Name)
        end
    end

    updateUIStatus(string.format("Öğrenildi: %s (Mesh: %d)", table.concat(learnedNamesList, ", "), meshCount))
end

-- ==========================================
-- KANIT TARAMA VE TOPLAMA MOTORU
-- ==========================================
local function evaluateEvidenceCandidate(interactObj)
    local rootTarget, anchorPart = resolveEvidenceRoot(interactObj)
    if not rootTarget or not anchorPart then return nil, nil end

    local blackExpiry = State.TempBlacklist[rootTarget]
    if (blackExpiry and os.clock() < blackExpiry) or State.CollectedCache[rootTarget] then
        return nil, nil
    end

    if not isPartOrModelVisible(rootTarget, interactObj) then
        return nil, nil
    end

    local promptText = ""
    if interactObj:IsA("ProximityPrompt") then
        if not interactObj.Enabled or isDepositPrompt(interactObj, true) then
            return nil, nil
        end
        promptText = (interactObj.ObjectText or "") .. " " .. (interactObj.ActionText or "") .. " " .. interactObj.Name
    end

    if matchesLearnedSignature(rootTarget, anchorPart, promptText) then
        return rootTarget, anchorPart, 1
    end

    local propNames = string.lower(anchorPart.Name .. " " .. rootTarget.Name)
    local lowerPrompt = string.lower(promptText)

    if matchesKeyword(propNames, CONFIG.NonEvidencePropBlacklist)
        or matchesKeyword(propNames, CONFIG.BoatNames)
        or matchesKeyword(lowerPrompt, CONFIG.NonEvidencePropBlacklist)
        or matchesKeyword(lowerPrompt, CONFIG.PromptBlacklist) then
        return nil, nil
    end

    if matchesKeyword(propNames, CONFIG.EvidenceNames)
        or matchesKeyword(lowerPrompt, CONFIG.EvidencePromptKeywords) then
        return rootTarget, anchorPart, 1
    end

    local isPickupAction = matchesKeyword(lowerPrompt, {
        "collect", "take", "pick up", "pickup", "grab", "search", "inspect", "topla", "al", "incele"
    })
    if isPickupAction and isReasonableEvidenceSize(rootTarget) then
        return rootTarget, anchorPart, 2
    end

    return nil, nil
end

local function scanForActiveEvidences(centerPos, maxRadius)
    local results = {}
    local seenObjects = {}

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if (desc:IsA("ProximityPrompt") or desc:IsA("ClickDetector") or desc:IsA("TouchTransmitter"))
            and not isPlayerCharacterDescendant(desc) then
            local rootTarget, anchorPart, priority = evaluateEvidenceCandidate(desc)
            if rootTarget and anchorPart and not seenObjects[rootTarget] then
                local cf = getTargetCFrame(anchorPart) or getTargetCFrame(rootTarget)
                if cf then
                    if not centerPos or not maxRadius or (cf.Position - centerPos).Magnitude <= maxRadius then
                        seenObjects[rootTarget] = true
                        table.insert(results, {
                            Object = rootTarget,
                            AnchorPart = anchorPart,
                            Interact = desc,
                            CFrame = cf,
                            Priority = priority
                        })
                    end
                end
            end
        end
    end

    local _, rootPart = getCharacterParts()
    local refPos = centerPos or (rootPart and rootPart.Position) or Vector3.zero

    table.sort(results, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
        return (a.CFrame.Position - refPos).Magnitude < (b.CFrame.Position - refPos).Magnitude
    end)

    return results
end

local function triggerAndVerifyEvidence(evInfo)
    local _, rootPart = getCharacterParts()
    if not rootPart or not evInfo or not evInfo.Object or not evInfo.Object.Parent then
        return false
    end

    local prevGuiCount = getBackpackGuiCount()
    local interact = evInfo.Interact

    if interact:IsA("ProximityPrompt") and interact.Parent and interact.Enabled then
        local holdTime = interact.HoldDuration or 0
        pcall(function()
            interact.RequiresLineOfSight = false
            interact.MaxActivationDistance = math.max(interact.MaxActivationDistance, 18)
        end)
        pcall(function()
            if typeof(fireproximityprompt) == "function" then
                fireproximityprompt(interact)
            end
        end)
        pcall(function()
            interact:InputHoldBegin()
            if holdTime > 0 then
                task.wait(holdTime + 0.15)
            else
                task.wait(0.12)
            end
            interact:InputHoldEnd()
        end)
    elseif interact:IsA("ClickDetector") and interact.Parent then
        pcall(function()
            if typeof(fireclickdetector) == "function" then
                fireclickdetector(interact)
            end
        end)
    elseif interact:IsA("TouchTransmitter") and evInfo.AnchorPart:IsA("BasePart") then
        pcall(function()
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(rootPart, evInfo.AnchorPart, 0)
                task.wait(0.1)
                firetouchinterest(rootPart, evInfo.AnchorPart, 1)
            else
                rootPart.CFrame = evInfo.AnchorPart.CFrame
            end
        end)
    end

    task.wait(0.22)

    local newGuiCount = getBackpackGuiCount()
    if prevGuiCount and newGuiCount and newGuiCount > prevGuiCount then
        return true
    end
    if not interact.Parent or (interact:IsA("ProximityPrompt") and not interact.Enabled) then
        return true
    end
    if not evInfo.Object.Parent or not isPartOrModelVisible(evInfo.Object, interact) then
        return true
    end

    return false
end
-- ==========================================
-- BUTON BAĞLANTILARI
-- ==========================================
table.insert(State.Connections, MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end))

table.insert(State.Connections, CloseBtn.MouseButton1Click:Connect(function()
    genv.AutoDetective = false
    State.IsMovingOrInteracting = false
    restoreCharacterCollision()
    if State.ActiveTween then pcall(function() State.ActiveTween:Cancel() end) end
    ScreenGui:Destroy()
end))

table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end))

table.insert(State.Connections, GoBoatBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        depositEvidenceAtBoat()
    end)
end))

table.insert(State.Connections, SaveBoatBtn.MouseButton1Click:Connect(function()
    sealManualBoatDepositPoint()
end))

table.insert(State.Connections, MinusBtn.MouseButton1Click:Connect(function()
    updateUICounter(math.max(0, State.CurrentCollected - 1))
end))

table.insert(State.Connections, PlusBtn.MouseButton1Click:Connect(function()
    updateUICounter(State.CurrentCollected + 1)
    if State.CurrentCollected >= CONFIG.TargetEvidenceCount then
        task.spawn(function()
            depositEvidenceAtBoat()
        end)
    end
end))

table.insert(State.Connections, NoclipBtn.MouseButton1Click:Connect(function()
    CONFIG.NoclipOnMove = not CONFIG.NoclipOnMove
    if not CONFIG.NoclipOnMove then
        restoreCharacterCollision()
    end
    NoclipBtn.Text = CONFIG.NoclipOnMove and "Noclip: AÇIK" or "Noclip: KAPALI"
    NoclipBtn.BackgroundColor3 = CONFIG.NoclipOnMove and Color3.fromRGB(46, 145, 95) or Color3.fromRGB(120, 55, 65)
end))

table.insert(State.Connections, ModeBtn.MouseButton1Click:Connect(function()
    if CONFIG.MovementMode == "Tween" then
        CONFIG.MovementMode = "Teleport"
        ModeBtn.Text = "Hareket: Teleport"
    else
        CONFIG.MovementMode = "Tween"
        ModeBtn.Text = "Hareket: Tween (Akıcı)"
    end
end))

table.insert(State.Connections, AddZoneBtn.MouseButton1Click:Connect(function()
    local _, rootPart = getCharacterParts()
    if rootPart then
        local zoneName = "ÖzelBölge #" .. tostring(#State.CustomZones + 1)
        table.insert(State.CustomZones, {
            Name = zoneName,
            Position = rootPart.Position
        })
        table.insert(State.PatrolZones, 1, {
            Name = zoneName,
            Position = rootPart.Position
        })
        updateUIZone(string.format("%s eklendi (Toplam: %d)", zoneName, #State.PatrolZones))
        updateUIStatus("Bulunduğunuz konum devriye rotasına eklendi!")
    end
end))

table.insert(State.Connections, LearnBtn.MouseButton1Click:Connect(function()
    learnNearbyEvidences()
end))

table.insert(State.Connections, RebuildZonesBtn.MouseButton1Click:Connect(function()
    if not BoatMemory.ManualLocked then
        BoatMemory.DepositPrompt = nil
        BoatMemory.DepositPart = nil
        BoatMemory.DepositTouchPart = nil
        BoatMemory.DepositCFrame = nil
        BoatMemory.RelativeOffset = nil
        BoatMemory.Verified = false
    end
    table.clear(State.TempBlacklist)
    table.clear(State.CollectedCache)
    State.CurrentZoneIndex = 1
    buildPatrolZones()
    if BoatMemory.ManualLocked then
        updateUIStatus("Odalar tarandı (Kayıtlı tekne noktası korundu).")
    else
        updateUIStatus("Oda listesi ve tekne hafızası yenilendi!")
    end
end))

table.insert(State.Connections, ToggleBtn.MouseButton1Click:Connect(function()
    genv.AutoDetective = not genv.AutoDetective
    if genv.AutoDetective then
        ToggleBtn.Text = "DURDUR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(205, 55, 75)
        updateUIStatus("Çalışıyor...")
        if #State.PatrolZones == 0 then
            buildPatrolZones()
        end

        if not State.LoopRunning then
            State.LoopRunning = true
            task.spawn(function()
                while genv.AutoDetective do
                    syncBackpackGuiCounter()

                    if State.CurrentCollected >= CONFIG.TargetEvidenceCount then
                        depositEvidenceAtBoat()
                        task.wait(1)
                    else
                        local activeList = scanForActiveEvidences(nil, nil)
                        if #activeList > 0 then
                            local targetEv = activeList[1]
                            updateUIStatus("Kanıt alınıyor: " .. targetEv.Object.Name)
                            moveToCFrame(targetEv.CFrame)
                            task.wait(0.15)

                            local collected = false
                            for try = 1, CONFIG.RetryInteractCount do
                                if not genv.AutoDetective then break end
                                if triggerAndVerifyEvidence(targetEv) then
                                    collected = true
                                    break
                                end
                                task.wait(0.15)
                            end

                            State.IsMovingOrInteracting = false

                            if collected then
                                State.CollectedCache[targetEv.Object] = true
                                updateUICounter(State.CurrentCollected + 1)
                            else
                                State.TempBlacklist[targetEv.Object] = os.clock() + 15
                            end
                            task.wait(0.2)
                        else
                            if #State.PatrolZones == 0 then
                                buildPatrolZones()
                            end

                            if #State.PatrolZones > 0 then
                                if State.CurrentZoneIndex > #State.PatrolZones then
                                    State.CurrentZoneIndex = 1
                                end
                                local zone = State.PatrolZones[State.CurrentZoneIndex]
                                updateUIZone(string.format("[%d/%d] %s", State.CurrentZoneIndex, #State.PatrolZones, zone.Name))
                                State.CurrentZoneIndex = State.CurrentZoneIndex + 1

                                updateUIStatus("Oda taranıyor: " .. zone.Name)
                                moveToCFrame(CFrame.new(zone.Position))
                                State.IsMovingOrInteracting = false
                                task.wait(0.45)

                                local roomEvidences = scanForActiveEvidences(zone.Position, CONFIG.ZoneScanRadius)
                                if #roomEvidences > 0 then
                                    updateUIStatus("Odada kanıt bulundu: " .. roomEvidences[1].Object.Name)
                                end
                            else
                                State.IsMovingOrInteracting = false
                                updateUIStatus("Kanıt ve oda bekleniyor...")
                                task.wait(0.6)
                            end
                        end
                    end
                    task.wait(0.15)
                end

                State.LoopRunning = false
                State.IsMovingOrInteracting = false
                restoreCharacterCollision()
                if State.ActiveTween then pcall(function() State.ActiveTween:Cancel() end) end
                ToggleBtn.Text = "BÖLGE DEVRİYESİ VE TOPLAMAYI BAŞLAT"
                ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 170, 95)
                updateUIStatus("Durduruldu.")
            end)
        end
    else
        State.IsMovingOrInteracting = false
        restoreCharacterCollision()
        if State.ActiveTween then pcall(function() State.ActiveTween:Cancel() end) end
        ToggleBtn.Text = "BÖLGE DEVRİYESİ VE TOPLAMAYI BAŞLAT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 170, 95)
        updateUIStatus("Durduruldu.")
    end
end))

genv.DetectiveCleanup = function()
    genv.AutoDetective = false
    State.IsMovingOrInteracting = false
    restoreCharacterCollision()
    if State.ActiveTween then pcall(function() State.ActiveTween:Cancel() end) end
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(State.Connections)
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end

task.spawn(buildPatrolZones)
