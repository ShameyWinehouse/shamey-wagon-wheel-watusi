VORPutils = {}
TriggerEvent("getUtils", function(utils)
    VORPutils = utils
	print = VORPutils.Print:initialize(print)
end)


Config = {}
Config.ShameyDebug = false


function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end



Citizen.CreateThread(function()
	while true do

		local objectPool = GetGamePool('CObject') 

		for i = 1, #objectPool do -- Loop through each vehicle
			local object = objectPool[i]
			if IsEntityAttachedToAnyVehicle(object) then
				-- print("attached", dump(GetEntityModel(object)))
				if GetEntityModel(object) == -285977940 then -- It's a fucking padlock
					DeleteEntity(object)
					print("deleted padlock", object)
				end
			end
		end
		Citizen.Wait(5000)
	end
end)


local hitlistWagons = {}
-- Check for potentially perma-stuck wagons
Citizen.CreateThread(function()
	while true do
		
		processHitlist()
		
		checkForWagonsToHitlist()
		
		Citizen.Wait(10 * 1000)
	end
end)

function processHitlist()
	for k,v in pairs(hitlistWagons) do
		if Config.ShameyDebug then print("v", v) end
		if Config.ShameyDebug then print("GetGameTimer()", GetGameTimer()) end
		if v < GetGameTimer() then
			if Config.ShameyDebug then print("time expired on hitlisted wagon") end
			
			-- Check if it's still stuck after waiting
			if isLocalsWagonStuck(k) then
				deleteWagon(k)
			else
				hitlistWagons[k] = nil
			end
		end
	end
end

function checkForWagonsToHitlist()
	local vehiclePool = GetGamePool('CVehicle') -- Get the list of vehicles from the pool

	-- Loop thru each vehicle
	for i = 1, #vehiclePool do 
		local wagon = vehiclePool[i]
		if isLocalsWagonStuck(wagon) then
		
			if Config.ShameyDebug then print('potentially perma-stuck wagon? ', dump(wagon), dump(GetEntityCoords(wagon))) end
			if hitlistWagons[wagon] == nil then
				hitlistWagons[wagon] = GetGameTimer() + 6000 -- 6 secs from now 
			end
		end
	end
end

function isLocalsWagonStuck(wagon)
	-- If wagon is stopped
	if IsEntityAVehicle(wagon) and IsVehicleStopped(wagon) then
	
		local isDraftVehicle = Citizen.InvokeNative(0xEA44E97849E9F3DD, wagon)
		if isDraftVehicle then
		
			local driver = Citizen.InvokeNative(0x2963B5C1637E8A27, wagon) -- GetDriverOfVehicle
			if IsPedAPlayer(driver) == false and driver ~= PlayerPedId() then
				-- Get the horse
				local horse = Citizen.InvokeNative(0xA8BA0BAE0173457B, wagon, 0) -- GetPedInDraftHarness
				-- If the horse is NOT stopped (i.e. trotting in place)
				if horse and not IsPedStopped(horse) then
					return true
				end
			end
		end
	end
	return false
end

function deleteWagon(wagon)
	-- Delete driver & wagon
	local driver = Citizen.InvokeNative(0x2963B5C1637E8A27, wagon) -- GetDriverOfVehicle

	if IsPedAPlayer(driver) == false and driver ~= PlayerPedId() then

		if driver then
			DeleteEntity(driver)
		end

		DeleteEntity(wagon)
		print("deleted stuck wagon")
	end
end