-- LL_AnimalRebuyEvent
-- Client --> Server: request to buy out an active lease
-- Server --> Client: errorCode
--

LL_AnimalRebuyEvent = {}
LL_AnimalRebuyEvent.REBUY_SUCCESS = 0
LL_AnimalRebuyEvent.REBUY_ERROR_NO_PERMISSION = 1
LL_AnimalRebuyEvent.REBUY_ERROR_NOT_ENOUGH_MONEY = 2
LL_AnimalRebuyEvent.REBUY_ERROR_NOT_LEASED = 3
LL_AnimalRebuyEvent.REBUY_ERROR_WRONG_FARM = 4

local LL_AnimalRebuyEvent_mt = Class(LL_AnimalRebuyEvent, Event)
InitStaticEventClass(LL_AnimalRebuyEvent, "LL_AnimalRebuyEvent")

function LL_AnimalRebuyEvent.emptyNew()
    return Event.new(LL_AnimalRebuyEvent_mt)
end

function LL_AnimalRebuyEvent.new(leaseId)
    local self = LL_AnimalRebuyEvent.emptyNew()
    self.leaseId = leaseId
    return self
end

function LL_AnimalRebuyEvent.newServerToClient(errorCode)
    local self = LL_AnimalRebuyEvent.emptyNew()
    self.errorCode = errorCode
    return self
end

function LL_AnimalRebuyEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 3)
    else
        self.leaseId = streamReadInt32(streamId)
    end
    self:run(connection)
end

function LL_AnimalRebuyEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        streamWriteInt32(streamId, self.leaseId)
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
    end
end

function LL_AnimalRebuyEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(LL_AnimalRebuyEvent, self.errorCode)
        return
    end

    if not g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then
        connection:sendEvent(LL_AnimalRebuyEvent.newServerToClient(LL_AnimalRebuyEvent.REBUY_ERROR_NO_PERMISSION))
        return
    end

    local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
    local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
    local farmId = farm.farmId

    local errorCode = LL_AnimalRebuyEvent.validate(self.leaseId, farmId)
    if errorCode ~= nil then
        connection:sendEvent(LL_AnimalRebuyEvent.newServerToClient(errorCode))
        return
    end

    LL_leaseLivestock:rebuyLease(self.leaseId, farmId)
    connection:sendEvent(LL_AnimalRebuyEvent.newServerToClient(LL_AnimalRebuyEvent.REBUY_SUCCESS))
end

function LL_AnimalRebuyEvent.validate(leaseId, farmId)
    local lease = LL_leaseLivestock.leases[leaseId]
    if lease == nil then
        return LL_AnimalRebuyEvent.REBUY_ERROR_NOT_LEASED
    end
    if lease.farmId ~= farmId then
        return LL_AnimalRebuyEvent.REBUY_ERROR_WRONG_FARM
    end
    local remaining = math.max(lease.buyoutPrice - lease.totalPaid, 0)
    if g_currentMission:getMoney(farmId) < remaining then
        return LL_AnimalRebuyEvent.REBUY_ERROR_NOT_ENOUGH_MONEY
    end
    return nil
end
