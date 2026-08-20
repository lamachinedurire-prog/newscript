local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Lifting Monster",
    subtitle = "Auto Hatch Crystals",
})

local tab = window:CreateTab({ name = "Hatching", icon = 93364949241311 })

-- Auto-detect the hatching remote
local HatchRemote = nil
local EggFolder = nil

-- Common remote paths to search
local RemotePaths = {
    "ReplicatedStorage.Remote.Egg.Server.Purchase",
    "ReplicatedStorage.Remotes.Egg.Server.Purchase",
    "ReplicatedStorage.EggHatchingRemotes.AutoHatch",
    "ReplicatedStorage.Events.Hatch",
    "ReplicatedStorage.Remotes.HatchCrystal",
    "ReplicatedStorage.Remote.Crystal.Server.Hatch",
    "ReplicatedStorage.Eggs.Hatch",
    "ReplicatedStorage.REMOTES.Hatch",
    "ReplicatedStorage.HatchRemote",
}

-- Search for the hatching remote
function FindHatchRemote()
    for _, path in ipairs(RemotePaths) do
        local parts = path:split(".")
        local obj = game
        local found = true
        for _, part in ipairs(parts) do
            obj = obj:FindFirstChild(part)
            if not obj then
                found = false
                break
            end
        end
        if found then
            return obj
        end
    end
    return nil
end

-- Find egg/crystal objects in workspace
function FindCrystals()
    local crystals = {}
    
    -- Common names for crystals/eggs
    local crystalNames = {"Crystal", "Egg", "CrystalEgg", "CrystalOre", "Ore", "Gem"}
    
    for _, name in ipairs(crystalNames) do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
                if obj.Name:find(name, 1, true) or obj.Name:lower():find("crystal", 1, true) or obj.Name:lower():find("egg", 1, true) then
                    -- Check if it has a ClickDetector or ProximityPrompt (hatchable)
                    if obj:FindFirstChildOfClass("ClickDetector") or obj:FindFirstChildOfClass("ProximityPrompt") then
                        table.insert(crystals, obj)
                    end
                end
            end
        end
    end
    
    -- Also check folders named Eggs or Crystals
    local eggFolder = workspace:FindFirstChild("Eggs") or workspace:FindFirstChild("Crystals") or workspace:FindFirstChild("CrystalOres")
    if eggFolder then
        for _, child in ipairs(eggFolder:GetChildren()) do
            if child:IsA("Model") or child:IsA("Part") then
                table.insert(crystals, child)
            end
        end
    end
    
    return crystals
end

-- Try to hatch using ClickDetector
function ClickCrystal(crystal)
    local detector = crystal:FindFirstChildOfClass("ClickDetector")
    if detector then
        fireclickdetector(detector)
        return true
    end
    local prompt = crystal:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        return true
    end
    return false
end

-- Variables
getgenv().AutoHatch = false
getgenv().HatchCooldown = 0.5

local statusLabel = tab:CreateLabel({ text = "Status: Searching for remotes...", color = Color3.fromRGB(255, 255, 255) })

-- Auto-detect on load
local function Initialize()
    HatchRemote = FindHatchRemote()
    
    if HatchRemote then
        statusLabel:Set("Status: Remote found: " .. HatchRemote:GetFullName() .. " | Type: " .. HatchRemote.ClassName)
    else
        -- Last resort: scan all RemoteFunctions/RemoteEvents in ReplicatedStorage
        for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if (obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent")) and 
               (obj.Name:lower():find("hatch") or obj.Name:lower():find("purchase") or obj.Name:lower():find("egg") or obj.Name:lower():find("crystal")) then
                HatchRemote = obj
                statusLabel:Set("Status: Found remote: " .. obj:GetFullName())
                break
            end
        end
        
        if not HatchRemote then
            statusLabel:Set("Status: No hatch remote found. Using ClickDetector fallback.")
        end
    end
end

-- Auto hatch logic
local function AutoHatchLoop()
    while getgenv().AutoHatch do
        local success, result = pcall(function()
            if HatchRemote then
                -- Find crystals to hatch
                local crystals = FindCrystals()
                
                if #crystals > 0 then
                    for _, crystal in ipairs(crystals) do
                        if not getgenv().AutoHatch then break end
                        
                        -- Fire the remote with the crystal/egg
                        if HatchRemote:IsA("RemoteFunction") then
                            HatchRemote:InvokeServer(crystal)
                        elseif HatchRemote:IsA("RemoteEvent") then
                            HatchRemote:FireServer(crystal)
                        end
                        
                        task.wait(getgenv().HatchCooldown)
                    end
                else
                    -- If no crystals found via workspace, try invoking remote with no args
                    if HatchRemote:IsA("RemoteFunction") then
                        local result = HatchRemote:InvokeServer()
                    elseif HatchRemote:IsA("RemoteEvent") then
                        HatchRemote:FireServer()
                    end
                end
            else
                -- Fallback: click crystals directly
                local crystals = FindCrystals()
                for _, crystal in ipairs(crystals) do
                    if not getgenv().AutoHatch then break end
                    ClickCrystal(crystal)
                    task.wait(getgenv().HatchCooldown)
                end
            end
        end)
        
        if not success then
            warn("[Lifting Monster] Hatch error:", result)
        end
        
        task.wait(0.3)
    end
end

-- Toggle
tab:CreateToggle({
    name = "Auto Hatch Any Crystal",
    currentValue = false,
    callback = function(value)
        getgenv().AutoHatch = value
        
        if value then
            -- Re-initialize to find remotes if not found yet
            if not HatchRemote then
                Initialize()
            end
            
            -- Check if there are crystal folders with specific structure
            EggFolder = workspace:FindFirstChild("Crystals") or workspace:FindFirstChild("Eggs") 
                        or workspace:FindFirstChild("CrystalOres")
            
            if EggFolder then
                statusLabel:Set("Status: Active | Found folder: " .. EggFolder.Name .. " (" .. #EggFolder:GetChildren() .. " items)")
            elseif HatchRemote then
                statusLabel:Set("Status: Active | Using remote: " .. HatchRemote:GetFullName())
            else
                statusLabel:Set("Status: Active | Using ClickDetector fallback")
            end
            
            -- Start the loop
            task.spawn(AutoHatchLoop)
        else
            statusLabel:Set("Status: Disabled")
        end
    end,
})

-- Manual scan button
tab:CreateButton({
    name = "Scan for Crystals / Remotes",
    callback = function()
        Initialize()
        
        -- Also scan for crystals
        local crystals = FindCrystals()
        statusLabel:Set("Status: Found " .. #crystals .. " crystals | Remote: " .. (HatchRemote and HatchRemote:GetFullName() or "None (using click)"))
    end,
})

-- Status display
local infoLabel = tab:CreateLabel({ 
    text = "Crystals found: 0 | Remote: scanning...", 
    color = Color3.fromRGB(200, 200, 200) 
})

-- Periodic crystal counter
task.spawn(function()
    while task.wait(3) do
        local count = #FindCrystals()
        local remoteStr = HatchRemote and HatchRemote:GetFullName() or "ClickDetector mode"
        infoLabel:Set("Crystals found: " .. count .. " | Remote: " .. remoteStr)
    end
end)

-- Run initialization
task.delay(1, Initialize)
