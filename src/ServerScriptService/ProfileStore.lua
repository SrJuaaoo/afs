-- DataStore failures must never stop construction of the world or local Studio play.
local ProfileStore = {}
ProfileStore.__index = ProfileStore

function ProfileStore.new(service, studio, placeId)
    local self = setmetatable({Studio = studio, Store = nil}, ProfileStore)
    if studio and placeId == 0 then return self end
    local ok, result = pcall(function() return service:GetDataStore("LendasDoAnime_v1") end)
    if ok then self.Store = result else self.Error = tostring(result) end
    return self
end

function ProfileStore:Load(userId)
    if self.Store then
        local ok, data = pcall(function() return self.Store:GetAsync("Player_" .. userId) end)
        if ok then return true, data, false end
        if not self.Studio then return false, nil, false end
    elseif not self.Studio then return false, nil, false end
    return true, nil, true
end

function ProfileStore:Save(userId, profile, sessionOnly)
    if sessionOnly then return true end
    if not self.Store then return false, self.Error or "DataStore indisponível" end
    return pcall(function() self.Store:SetAsync("Player_" .. userId, profile) end)
end

return ProfileStore
