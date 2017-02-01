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
-- TODO
function Player:ShopSellAllItems(item)
    return self:ShopSellItem(item, self:ShopGetItemSaleCount(item))
end
function Player:ShopSellItem(item, count)
    local func = (type(item) == "string") and shopSellItemByName or shopSellItemByID
    count = tonumber(count) or 1
    repeat
        local amnt = math.min(count, 100)
        if (func(item, amnt) == 0) then
            return 0, amnt
        end
        wait(300, 600)
        count = (count - amnt)
    until count <= 0
    return 1, 0
end
-- TODO
function Player:ShopBuyItem(item, count)
    local func = (type(item) == "string") and shopBuyItemByName or shopBuyItemByID
    count = tonumber(count) or 1
    repeat
        local amnt = math.min(count, 100)
        if (func(item, amnt) == 0) then
            return 0, amnt
        end
        wait(300,600)
        count = (count - amnt)
    until count <= 0
    return 1, 0
end
-- TODO
function Player:ShopBuyItemsUpTo(item, c)
    local count = c - self:ItemCount(item)
    if (count > 0) then
        return self:ShopBuyItem(item, count)
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
-- TEST
function Player:SayToNpc(message, interval)
    local contInc = 0
    for _, msg in ipairs(message) do
        contInc = contInc+(interval*1000)
        scheduleEvent( function()
            Action.talkNPC(msg)
        end, contInc)
    end    
end
-- TEST
function Player:DepositMoney(amount)
	if (type(amount) == 'number') then
		Player:SayToNpc({'hi', 'deposit ' .. math.max(amount, 1), 'yes'}, 7)
	else
		Player:SayToNpc({'hi', 'deposit all', 'yes'}, 7)
    end
end
-- TEST
function Player:WithdrawMoney(amount)
    Player:SayToNpc({'hi', 'withdraw ' .. amount, 'yes'}, 7)
end
-- TEST
function Player:UseItemFromEquipment(slot)
    return self:getInventoryItem(slot)
end
-- TEST
function Player:OpenMainBackpack(minimize)
    local slot = InventorySlotFinger
	return Player:UseItemFromEquipment(InventorySlotBack)
end
-- TODO
function Player:Cast(words, mana)
    if(not mana or Player:Mana() >= mana)then
        return Player:CanCastSpell(words) and Player:Say(words) and wait(300) or 0
    end
end

function Player:DistanceFromPosition(x, y, z)
    return getDistanceBetween(Player:Position(), {x=x,y=y,z=z})
end
-- TEST
function Player:UseLever(pos, itemid)	
	local ret = 0
	if (itemid == 0 or itemid == nil) then
		repeat
			wait(1500)
		until (Player:UseItemFromGround(pos) ~= 0 or Player:Position().z ~= z)
		return (Player:Position().z == z)
	elseif (itemid > 99) then
		local mapitem = Map.GetTopUseItem(pos)
		while (mapitem.id == itemid and Player:Position().z == z) do
			Player:UseItemFromGround(pos)
			wait(1500)
			mapitem = Map.GetTopUseItem(pos)
		end
		return (Player:Position().z == z)
	end
	return false
end
--TEST
function Player:UseDoor(pos, close)
    close = close or false
    if (not Map.IsTileWalkable(pos) or close) then
        local used = Player:UseItemFromGround(pos)
        wait(1000, 1500)
        return Map.IsTileWalkable(pos) ~= close
    end
end
-- TODO
function Player:CutGrass(pos)
    local itemid = nil
    for _, id in ipairs({3308, 3330, 9594, 9596, 9598}) do
        if(Player:getItemsCount(id) >= 1)then
            itemid = id
            break
        end
    end
    if(itemid)then -- we found a machete
        local grass = Player:UseItemWithGround(itemid, pos)
        wait(1500, 2000)
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
    scheduleEvent( function()
        locker = Container.GetByName("Locker")
        if locker then  -- if the locker opened successfully
            locker:UseItem(0, true) -- open depot
            depot = Container.GetByName("Depot Chest")
        end
    end, 1000)
    return false
end
function Player:UseItemFromGround(pos)
    local item = g_map.getThing(pos, 2)
    g_game.look(item)
    return g_game.use(item)
end
-- TODO
function Player:DepositItems(...)
    local function depositToChildContainer(fromCont, fromSpot, parent, slot)
        local bid = parent:GetItemData(slot).id
        if(Item.isContainer(bid))then -- valid container
            parent:UseItem(slot, true) -- open backpack on the slot
            wait(500, 900)
            local child = Container.GetLast() -- get the child opened backpack
            if(child:ID() == bid)then -- the child bp id matches the itemid clicked; failsafe
                local bic = child:ItemCount()
                if(child:ItemCapacity() == bic)then -- backpack is full, even closer
                    local fic = fromCont:ItemCount()
                    fromCont:MoveItemToContainer(fromSpot, child:Index(), bic - 1)
                    wait(500, 900)
                    if(fic > fromCont:ItemCount())then -- item moved successfully
                        return {child:Index(), bic - 1}
                    else -- failed to move, recurse further
                        return depositToChildContainer(fromCont, fromSpot, child, bic - 1)
                    end
                end
            end
        end
        return false
    end

    setBotEnabled(false) -- turn off walker/looter/targeter

    local indexes = Container.GetIndexes() -- store open indexes so we only loop through backpacks we had open before we started depositing
    local depot = Player:OpenDepot()
    if (depot) then -- did we open depot?
		local items = {}
		for i = 1, #arg do
			local data = arg[i]
			newitem = {}
			if (type(data) == 'table') then
				newitem[1] = Item.GetItemIDFromDualInput(data[1])
				newitem[2] = data[2]
			else
				newitem[1] = Item.GetItemIDFromDualInput(data)
				newitem[2] = 0
			end
			items[i] = newitem
		end
    
        local bp = Container.GetFirst()
        local children = {}
        while(bp:isOpen())do
            if table.contains(indexes, bp:Index())then
                local name = bp:Name()
                if(name ~= "Locker") and (name ~= "Depot Chest")then
                    local offset = 0
                    for spot = 0, bp:ItemCount() - 1 do -- loop through all the items in loot backpack
                        local item = bp:GetItemData(spot - offset)
                        local data = table.contains(items, item.id, 1)
                        if (data) then -- the item is in the deposit list
                            local slot = data[2] -- which depot slot to deposit to
                            local depositCont, depositSlot = depot, slot
                            local child = children[slot + 1]
                            if(child)then -- we have already recursed to a child for this slot
                                depositCont, depositSlot = Container.GetFromIndex(child[1]), child[2]
                            elseif(not Container.GetByName("Depot Chest"):isOpen())then -- this slot has not been recursed AND depot is closed :(
                                local reopen = Player:OpenDepot() -- try to reopen depot
                                if(reopen)then -- if successful
                                    depot = reopen -- register our new depot =D
                                    depositCont = depot -- pass to our move function
                                end
                            end
                            local bpc = bp:ItemCount()
                            bp:MoveItemToContainer(spot - offset, depositCont:Index(), depositSlot)
                            wait(600, 1500)
                            if(bpc > bp:ItemCount())then -- item moved successfully
                                offset = offset + 1 -- we took an item out, the ones afterwards will shift back one
                            else -- item did not move succesfully
                                local cont = depositToChildContainer(bp, spot - offset, depositCont, depositSlot) -- try to move in child containers
                                if(cont)then -- deposited item successfully
                                    children[slot + 1] = cont
                                    offset = offset + 1 -- we took an item out, the ones afterwards will shift back one
                                else
                                    children[slot + 1] = nil
                                end
                            end
                        end
                    end
                end
            end
            bp = bp:GetNext() -- next backpack
        end
    end
    setBotEnabled(true)
    --delayWalker(2500)
end
-- TODO
function Player:WithdrawItems(slot, ...)
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
-- TODO
function Player:CloseContainers()
    for i = 0, 15 do
        closeContainer(i)
        wait(100)
    end
end