-- 📁 Game Structure Exporter (3 Levels + Counts) - FIXED
local HttpService = game:GetService("HttpService")

local function getTypeCount(parent)
	local models, folders = 0, 0
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Model") then models += 1 end
		if child:IsA("Folder") then folders += 1 end
	end
	return models > 0 and " (" .. models .. " Model" .. (models > 1 and "s" or "") .. ")" or "", 
	folders > 0 and " (" .. folders .. " Folder" .. (folders > 1 and "s" or "") .. ")" or ""
end

local function exportHierarchy(parent, indent, level, output)
	indent = indent or ""
	level = level or 0
	output = output or {}

	if level > 2 then return output end

	local children = parent:GetChildren()
	table.sort(children, function(a, b) return a.Name:lower() < b.Name:lower() end)

	for i, child in ipairs(children) do
		local isLast = i == #children
		local linePrefix = isLast and "└── " or "├── "

		local modelCount, folderCount = getTypeCount(child)

		local line = indent .. linePrefix .. child.Name .. " (" .. child.ClassName .. ")" .. modelCount .. folderCount
		table.insert(output, line)

		if level < 2 and #child:GetChildren() > 0 then
			exportHierarchy(child, indent .. (isLast and "    " or "│   "), level + 1, output)
		end
	end

	return output
end

print("📁 3-LEVEL EXPORT WITH COUNTS...")
print("================================")

local fullStructure = {"GAME HIERARCHY (3 LEVELS + COUNTS)", "Date: " .. os.date()}

-- Workspace + Services
local roots = {"Workspace", "ReplicatedStorage", "ServerStorage", "ServerScriptService", "StarterGui", "StarterPlayer"}
for _, rootName in ipairs(roots) do
	local root = game:GetService(rootName)
	table.insert(fullStructure, "\n📦 " .. rootName)

	local hierarchy = exportHierarchy(root)
	for _, line in ipairs(hierarchy) do
		table.insert(fullStructure, line)
	end
end

local output = table.concat(fullStructure, "\n")
print(output)

pcall(function() 
	setclipboard(output) 
	print("\n✅ COPIED TO CLIPBOARD!") 
end)
