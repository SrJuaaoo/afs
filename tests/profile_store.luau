local ProfileStore = require("../src/ServerScriptService/ProfileStore")
local calls = 0
local denied = {GetDataStore = function()
    calls += 1
    error("You must publish this place to the web to access DataStore.")
end}
local function temporary(adapter)
    local ok, data, session = adapter:Load(42)
    assert(ok and data == nil and session, "Studio deve permitir jogar sem DataStore")
    assert(adapter:Save(42, {Coins = 300}, session), "Sessão temporária não deve tentar gravar")
end
temporary(ProfileStore.new(denied, true, 0))
assert(calls == 0, "Arquivo local não deve tentar abrir DataStore")
temporary(ProfileStore.new(denied, true, 123))
assert(calls == 1)
local production = ProfileStore.new(denied, false, 123)
assert(not production:Load(42), "Produção não deve substituir dados que falharam ao carregar")

local saved = {}
local service = {GetDataStore = function()
    return {
        GetAsync = function(_, key) return saved[key] end,
        SetAsync = function(_, key, data) saved[key] = data end,
    }
end}
local adapter = ProfileStore.new(service, false, 123)
local ok, data, session = adapter:Load(42)
assert(ok and data == nil and not session)
assert(adapter:Save(42, {Coins = 450}, false))
local loaded, profile, temporarySession = adapter:Load(42)
assert(loaded and profile.Coins == 450 and not temporarySession)
local readFailure = {GetDataStore = function()
    return {GetAsync = function() error("API services disabled") end}
end}
temporary(ProfileStore.new(readFailure, true, 123))
assert(not ProfileStore.new(readFailure, false, 123):Load(42))
print("PASS: Studio local, falha de GetDataStore, API desativada, produção protegida e gravação/leitura.")
