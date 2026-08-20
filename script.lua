local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Lifting Monster",
    subtitle = "Auto Hatch Crystals",
})

local tab = window:CreateTab({ name = "Hatching", icon = 93364949241311 })

-- All crystal types in the game
local CrystalList = {
    "Blue Crystal",
    "Green Crystal", 
    "Frozen Crystal",
    "Mythical Crystal",
    "InfernoCrystal",
    "Legends Crystal",
    "Dark Nebula Crystal",
    "Muscle Elite Crystal",
    "GalaxyOracle Crystal",
    "Battle Legends Crystal",
    "Sky Eclipse Crystal",
    "Jungle Crystal",
    "Void Crystal"
    "Unlimited Secrets Crystal",
}

-- Local variables
getgenv().AutoHatchCrystal = false
getgenv().SelectedCrystal = "Blue Crystal"
getgenv().HatchDelay = 1

-- Find the remote
local rEvents = game:GetService("ReplicatedStorage"):FindFirstChild("rEvents")
local HatchRemote = rEvents and rEvents:FindFirstChild("openCrystalRemote")

-- Status label
local statusLabel = tab:CreateLabel({
    text = "Status: Waiting...",
    color = Color3.fromRGB(255, 255, 255),
})

-- Update status
local function UpdateStatus(msg, color)
    color = color or Color3.fromRGB(255, 255, 255)
    statusLabel:Set("Status: " .. msg)
end

-- Initial check
if HatchRemote then
    UpdateStatus("Remote found: openCrystalRemote | Ready", Color3.fromRGB(0, 255, 0))
else
    rEvents = game:GetService("ReplicatedStorage"):FindFirstChild("rEvents")
    if rEvents then
        -- Scan rEvents for hatch-related remotes
        for _, child in ipairs(rEvents:GetChildren()) do
            if child.Name:lower():find("crystal") or child.Name:lower():find("hatch") or child.Name:lower():find("egg") then
                HatchRemote = child
                break
            end
        end
    end
    
    if HatchRemote then
        UpdateStatus("Remote found: " .. HatchRemote.Name .. " | Ready", Color3.fromRGB(0, 255, 0))
    else
        UpdateStatus("Remote NOT found! Try re-joining the game.", Color3.fromRGB(255, 0, 0))
    end
end

-- Crystal selection dropdown
local crystalDropdown = tab:CreateDropdown({
    name = "Select Crystal",
    options = CrystalList,
    currentOption = "Blue Crystal",
    callback = function(value)
        getgenv().SelectedCrystal = value
        UpdateStatus("Selected: " .. value .. (getgenv().AutoHatchCrystal and " | Auto-hatching..." or " | Idle"))
    end,
})

-- Auto-hatch loop
local function AutoHatchLoopFn()
    while getgenv().AutoHatchCrystal do
        local success, err = pcall(function()
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("rEvents") and 
                           game:GetService("ReplicatedStorage").rEvents:FindFirstChild("openCrystalRemote")
            
            if remote then
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer("openCrystal", getgenv().SelectedCrystal)
                elseif remote:IsA("RemoteEvent") then
                    remote:FireServer("openCrystal", getgenv().SelectedCrystal)
                end
            else
                -- Fallback: try to find any remote in rEvents
                local rE = game:GetService("ReplicatedStorage"):FindFirstChild("rEvents")
                if rE then
                    for _, child in ipairs(rE:GetChildren()) do
                        if child.Name:lower():find("crystal") or child.Name:lower():find("hatch") then
                            if child:IsA("RemoteFunction") then
                                child:InvokeServer("openCrystal", getgenv().SelectedCrystal)
                            elseif child:IsA("RemoteEvent") then
                                child:FireServer("openCrystal", getgenv().SelectedCrystal)
                            end
                            break
                        end
                    end
                end
            end
        end)
        
        if not success then
            warn("[Lifting Monster] Hatch error:", err)
        end
        
        task.wait(getgenv().HatchDelay)
    end
end

-- Main toggle
tab:CreateToggle({
    name = "Auto Hatch Crystal",
    currentValue = false,
    callback = function(value)
        getgenv().AutoHatchCrystal = value
        
        if value then
            -- Re-fetch remote in case it wasn't ready before
            local rs = game:GetService("ReplicatedStorage")
            local rE = rs:FindFirstChild("rEvents")
            HatchRemote = rE and rE:FindFirstChild("openCrystalRemote")
            
            if not HatchRemote and rE then
                for _, child in ipairs(rE:GetChildren()) do
                    if child.Name:lower():find("crystal") or child.Name:lower():find("hatch") then
                        HatchRemote = child
                        break
                    end
                end
            end
            
            if HatchRemote then
                UpdateStatus("Auto-hatching " .. getgenv().SelectedCrystal .. " | Active", Color3.fromRGB(0, 255, 0))
            else
                UpdateStatus("Active (trying remotes...) | Crystal: " .. getgenv().SelectedCrystal, Color3.fromRGB(255, 200, 0))
            end
            
            task.spawn(AutoHatchLoopFn)
        else
            UpdateStatus("Disabled", Color3.fromRGB(255, 255, 255))
        end
    end,
})

-- Speed options
local delaySection = tab:CreateSection("Speed Settings")

tab:CreateSlider({
    name = "Hatch Delay (seconds)",
    min = 0.1,
    max = 5,
    current = 1,
    increment = 0.1,
    callback = function(value)
        getgenv().HatchDelay = value
    end,
})

-- Manual hatch button
tab:CreateButton({
    name = "Hatch Selected Crystal Once",
    callback = function()
        local rs = game:GetService("ReplicatedStorage")
        local rE = rs:FindFirstChild("rEvents")
        local remote = rE and rE:FindFirstChild("openCrystalRemote")
        
        if remote then
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer("openCrystal", getgenv().SelectedCrystal)
            else
                remote:FireServer("openCrystal", getgenv().SelectedCrystal)
            end
            UpdateStatus("Manually hatched: " .. getgenv().SelectedCrystal, Color3.fromRGB(0, 200, 255))
        else
            UpdateStatus("Remote not found!", Color3.fromRGB(255, 0, 0))
        end
    end,
})

-- Debug: dump all remotes
tab:CreateButton({
    name = "Debug: Scan All Remotes",
    callback = function()
        local rs = game:GetService("ReplicatedStorage")
        local rE = rs:FindFirstChild("rEvents")
        
        if rE then
            local info = "rEvents folder found with " .. #rE:GetChildren() .. " children:\n"
            for _, child in ipairs(rE:GetChildren()) do
                info = info .. "  " .. child.Name .. " (" .. child.ClassName .. ")\n"
            end
            warn(info)
            UpdateStatus("rEvents scanned. Check F9 console.", Color3.fromRGB(0, 200, 255))
        else
            -- Broader scan
            local info = "rEvents NOT found. Scanning ReplicatedStorage for remotes:\n"
            for _, child in ipairs(rs:GetChildren()) do
                if child:IsA("RemoteFunction") or child:IsA("RemoteEvent") or child:IsA("Folder") then
                    info = info .. "  " .. child.Name .. " (" .. child.ClassName .. ")\n"
                    if child:IsA("Folder") then
                        for _, sub in ipairs(child:GetChildren()) do
                            info = info .. "    - " .. sub.Name .. " (" .. sub.ClassName .. ")\n"
                        end
                    end
                end
            end
            warn(info)
            UpdateStatus("Check F9 console for remote scan results.", Color3.fromRGB(0, 200, 255))
        end
    end,
})

-- Info label
tab:CreateLabel({
    text = "Crystal list includes all known types",
    color = Color3.fromRGB(180, 180, 180),
})
