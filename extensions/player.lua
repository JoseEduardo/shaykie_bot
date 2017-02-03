--[[
  @Authors: Ben Dol (BeniS)
  @Details: Extension functions that extend the Player class.
]]

function Player:getMoney()
  return self:getItemsCount(3031) + (self:getItemsCount(3035) 
    * 100) + (self:getItemsCount(3043) * 10000)
end

function Player:getFlaskItems()
  local count = 0
  for i=1,#Flasks do
    count = count + self:getItemsCount(Flasks[i])
  end
  return count
end
--[[ SELL ]]
-- TEST
function Player:ShopSellAllItems(itemId)
    local count = self:getItemsCount(itemId)
    return Player:ShopSellItem(itemId, count, true)
end
function Player:ShopSellItem(itemId, count, ignoreEquipped)
    local item = self:getItem(itemId)
    return g_game.sellItem(item, count, ignoreEquipped)
end
--[[ BUY ]]
-- TEST
function Player:ShopBuyItem(itemId, amount, ignoreCapacity, buyWithBackpack)
    local item = self:getItem(itemId)
    return g_game.buyItem(item, amount, ignoreCapacity, buyWithBackpack)
end
-- TEST
function Player:ShopBuyItemsUpTo(item, c, ignoreCapacity, buyWithBackpack)
    local count = c - self:getItemsCount(item)
    if (count > 0) then
        return self:ShopBuyItem(item, count, ignoreCapacity, buyWithBackpack)
    end
    return 0, 0
end
-- TODO
function Player:ShopGetItemPurchasePrice(item)
    local func = (type(item) == "string") and shopGetItemBuyPriceByName or shopGetItemBuyPriceByID
    return func(item)
end
-- TODO
function Player:ShopGetItemSaleCount(item)
    local func = (type(item) == "string") and shopGetItemSaleCountByName or shopGetItemSaleCountByID
    return func(item)
end
function Player:SayToNpc(message, interval)
    local contInc = 0
    for _, msg in ipairs(message) do
        contInc = contInc+(interval*1000)
        scheduleEvent( function()
            Action.talkNPC(msg)
        end, contInc)
    end    
end
function Player:DepositMoney(amount)
	if (type(amount) == 'number') then
		Player:SayToNpc({'hi', 'deposit ' .. math.max(amount, 1), 'yes'}, 2)
	else
		Player:SayToNpc({'hi', 'deposit all', 'yes'}, 2)
    end
end
function Player:WithdrawMoney(amount)
    Player:SayToNpc({'hi', 'withdraw ' .. amount, 'yes'}, 2)
end
function Player:UseItemFromEquipment(slot)
    local player = g_game.getLocalPlayer()
    local item = player:getInventoryItem(slot)
    return g_game.use(item)
end

function Player:OpenMainBackpack(minimize)
    local slot = InventorySlotBack
	return Player:UseItemFromEquipment(InventorySlotBack)
end
-- TODO
function Player:Cast(words, mana)
    if(not mana or Player:Mana() >= mana)then
        return Player:CanCastSpell(words) and Player:Say(words) and wait(300) or 0
    end
end
function Player:DistanceFromPosition(pos)
    return Position.distance(player:getPosition(), pos)
end
function Player:UseLever(pos, itemid)
	return Player:UseItemFromGround(pos)
end
function Player:UseDoor(pos, close)
    local tile = g_map.getTile(pos)
    local tileWalk = tile:isWalkable()
    if close then
        if tileWalk then
            Player:UseItemFromGround(pos)
        end
    else
        if not tileWalk then
            Player:UseItemFromGround(pos)
        end
    end
end
-- TEST
function Player:CutGrass(pos)
    local itemid = nil
    for _, id in ipairs({3308, 3330, 9594, 9596, 9598}) do
        if Player:getItemsCount(id) >= 1 then
            itemid = id
            break
        end
    end
    if itemid then -- we found a machete
        local grass = Player:UseItemWithGround(itemid, pos)
        return Map.IsTileWalkable(x, y, z)
    end
    return false
end
function Player:UseItemWithGround(itemid, pos)
    g_game.useWith(self:getItem(itemid), pos)
end
-- TEST
function Player:UsePick(pos)
    local itemid = false
    for _, id in ipairs({3456, 9594, 9596, 9598}) do
        if(Player:getItemsCount(id) >= 1)then
            itemid = id
            break
        end
    end
    if (itemid) then -- we found a pick
        local hole = Player:UseItemWithGround(itemid, pos)
        wait(1500, 2000)
        return Map.IsTileWalkable(x, y, z)
    end
    return false
end
-- TEST
function Player:DropItem(pos, itemid, count)
    local items = self:getItems(itemId)
    local countCtrl = 0;
    for i=1,#items do
        if countCtrl <= count then
            g_game.move(items[i], toPos, items[i]:getCount())
            countCtrl = countCtrl + items[i]:getCount()
        end
    end
end
-- TEST
function Player:DropItems(pos, ...)
	local items = {...}
    for i=1,#items do
        self:DropItem(pos, items[i], items[i]:getCount())
    end
end
-- TEST
function Player:DropFlasks(pos)
    Player:DropItems(pos, 283, 284, 285)
end
-- TEST
function Player:Equip(itemid, slot, count)
    local item = salf:getItem(itemid)
    
    local handPos = {['x'] = 65535, ['y'] = slot, ['z'] = 0}
    if item and not player:getInventoryItem(slot) then
      g_game.move(item, handPos, item:getCount())
    end
end
function Player:LookPos()
    local player = g_game.getLocalPlayer()
    local direction = player:getDirection()
    local playerPos = player:getPosition()

    local steps = 1
    if direction == 3 then
        playerPos.x = playerPos.x - steps
    elseif direction == 1 then
        playerPos.x = playerPos.x + steps
    elseif direction == 0 then
        playerPos.y = playerPos.y - steps
    elseif direction == 2 then
        playerPos.y = playerPos.y + steps
    end

    return playerPos
end
function Player:OpenDepot()
    local pos = Player:LookPos()
    local locker = Container.GetByName("Locker")
    local depot  = Container.GetByName("Depot Chest")
    if depot then -- depot is already open
        return depot
    end

    if locker == false then -- locker isn't open
        Player:UseItemFromGround(pos)
    end
    depot = nil
    scheduleEvent( function()
        locker = Container.GetByName("Locker")
        if locker then  -- if the locker opened successfully
            locker:UseItem(0, true) -- open depot
        end
    end, 1000)
    while depot == nil do
        depot = Container.GetByName("Depot Chest")
    end
    return depot
end
--TEST
function Player:OpenDepotBox(number)
    local roman = Helper.ToRomanNumerals(number)
    local depotBox  = Container.GetByName("Depot Box "..roman)
    if depotBox then -- depot is already open
        return depotBox
    end

    depotBox = nil
    scheduleEvent( function()
        depot = Container.GetByName("Depot Chest")
        if depot then  -- if the locker opened successfully
            depot:UseItem(number-1, true) -- open depot
        end
    end, 1000)

    while depotBox == nil do
        depotBox = Container.GetByName("Depot Box "..roman)
    end
    return depotBox
end
function Player:UseItemFromGround(pos)
    local item = nil
    local topStack = 255
    while item == nil do
        item = g_map.getThing(pos, topStack)
        topStack = topStack-1
    end
    g_game.look(item)
    return g_game.use(item)
end
-- Player:DepositItems({3035,1,1},{3031,1,1},{3043,1,1})
function Player:DepositItems(...)
    local items = {...}
    local player = g_game.getLocalPlayer()
    for i=1,#items do
        local itemId  = items[i][1]
        local depotId = items[i][2]
        local qty     = items[i][3]

        local item = player:getItem(itemId)
        if qty > item:getCount() then
            qty = item:getCount()
        end
        local depot = Player:OpenDepot()
        local depotPosition = depot:getSlotPosition()

        depotPosition.z = depotId+1
        g_game.move(item, depotPosition, qty)
    end
end
-- Player:WithdrawItems('Backpack', {3031,1,1})
function Player:WithdrawItems(slot, ...)
    local items = {...}
    local player = g_game.getLocalPlayer()
    for i=1,#items do
        local itemId  = items[i][1]
        local boxID   = items[i][2]
        local qty     = items[i][3]

        local depotBox = Player:OpenDepotBox(boxID)
        local slotDest = Container.GetByName(slot)
        print(itemId)
        local itemInDepot = depotBox:getItemsById(itemId)
        for x=1,#itemInDepot do
            if qty > itemInDepot[x]:getCount() then
                qty = itemInDepot[x]:getCount()
            end
            g_game.move(itemInDepot[x], slotDest:getSlotPosition(), qty)
        end
    end
end
-- TODO
function Player:WithdrawItems2(slot, ...)
    local function withdrawFromChildContainers(items, parent, slot)
        local bid = parent:GetItemData(slot).id
        if (#items > 0) and (Item.isContainer(bid)) then
            parent:UseItem(slot, true) -- open backpack on the slot
        else
            return true
        end
        wait(500, 900)
        local child = Container.GetLast() -- get the child opened backpack
        if (child:ID() == bid) then -- the child bp id matches the itemid clicked, close enough
            local childCount = child:ItemCount()
            local offset = 0
            local count = {}
            for spot = 0, childCount - 1 do -- loop through all the items in depot backpack
                local item = child:GetItemData(spot - offset)
                local data, index = table.contains(items, item.id, 1)--, table.find(items, item.id)
                if (data) then
                    if (not count[item.id]) then count[item.id] = 0 end -- start the count
                    local dest = Container.GetFirst()
                    local skip = false
                    local toMove = item.count -- we think we're going to move all the item at first, this may change below
                    
                    local slotnum = tonumber(data[2])
                    if (slotnum) then
                        slot = slotnum
                    end
                    toMove = math.min(data[3] - count[item.id], item.count) -- get what's left to withdraw or all of the item, whichever is least
                    if((count[item.id] + toMove) > data[3])then -- this is probably not needed, but just incase we are trying to move more than the limit
                        skip = true -- skip the entire moving
                        table.remove(items, index) -- remove the item from the list
                    end
                    
                    if not (skip) then
                        local compCount = child:CountItemsOfID(item.id)
                        child:MoveItemToContainer(spot - offset, dest:Index(), slot, toMove)
                        wait(500, 900)
                        if(compCount > child:CountItemsOfID(item.id))then -- less of the itemid in there now, item moved successfully.. most likely.
                            count[item.id] = count[item.id] + toMove
                            if(toMove == item.count)then -- if we deposited a full item stack then decrease the offset, if not remove the item since we're done.
                                offset = offset + 1
                            else
                                table.remove(items, index)
                            end
                        else
                            return true -- we didn't move the item, container is full. TODO: recurse the player containers.
                        end
                    end
                end
            end
            return withdrawFromChildContainers(items, child, child:ItemCount() - 1)
        end
        return false
    end
    setBotEnabled(false) -- turn off walker/looter/targeter
    local depot = Player:OpenDepot()
    if (depot) then -- did we open depot?
		local items = {}
		for i = 1, #arg do
			local data = arg[i]
			items[i] = {Item.GetItemIDFromDualInput(data[1]), data[2], data[3]}
		end
		
        withdrawFromChildContainers(items, depot, slot)
    end
    setBotEnabled(true)
    --delayWalker(2500)
end
function Player:CloseContainers()
    for _,container in pairs(g_game.getContainers()) do
        g_game.close(container)
    end
end