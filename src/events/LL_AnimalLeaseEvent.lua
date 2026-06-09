-- LL_AnimalLeaseEvent
-- Client --> Server: request to lease animals into a husbandry
-- Server --> Client: errorCode
--

LL_AnimalLeaseEvent = {}
LL_AnimalLeaseEvent.LEASE_SUCCESS = 0
LL_AnimalLeaseEvent.LEASE_ERROR_NO_PERMISSION = 1
LL_AnimalLeaseEvent.LEASE_ERROR_NOT_ENOUGH_MONEY = 2
LL_AnimalLeaseEvent.LEASE_ERROR_NOT_ENOUGH_SPACE = 3
LL_AnimalLeaseEvent.LEASE_ERROR_ANIMAL_NOT_SUPPORTED = 4
LL_AnimalLeaseEvent.LEASE_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED = 5
LL_AnimalLeaseEvent.LEASE_ERROR_OBJECT_DOES_NOT_EXIST = 6
LL_AnimalLeaseEvent.LEASE_ERROR_NO_BARN_AVAILABLE = 7

local LL_AnimalLeaseEvent_mt = Class(LL_AnimalLeaseEvent, Event)
InitStaticEventClass(LL_AnimalLeaseEvent, "LL_AnimalLeaseEvent")

function LL_AnimalLeaseEvent.emptyNew()
    return Event.new(LL_AnimalLeaseEvent_mt)
end

function LL_AnimalLeaseEvent.new(object, subTypeIndex, age, numAnimals)
    local self = LL_AnimalLeaseEvent.emptyNew()
    self.object = object
    self.subTypeIndex = subTypeIndex
    self.age = age
    self.numAnimals = numAnimals
    return self
end

function LL_AnimalLeaseEvent.newServerToClient(errorCode)
    local self = LL_AnimalLeaseEvent.emptyNew()
    self.errorCode = errorCode
    return self
end

function LL_AnimalLeaseEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 3)
    else
        self.object = NetworkUtil.readNodeObject(streamId)
        self.subTypeIndex = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_SUB_TYPE)
        self.age = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_AGE)
        self.numAnimals = streamReadUInt8(streamId)
    end
    self:run(connection)
end

function LL_AnimalLeaseEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.object)
        streamWriteUIntN(streamId, self.subTypeIndex, AnimalCluster.NUM_BITS_SUB_TYPE)
        streamWriteUIntN(streamId, self.age, AnimalCluster.NUM_BITS_AGE)
        streamWriteUInt8(streamId, self.numAnimals)
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
    end
end

function LL_AnimalLeaseEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(LL_AnimalLeaseEvent, self.errorCode)
        return
    end

    if not g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then
        connection:sendEvent(LL_AnimalLeaseEvent.newServerToClient(LL_AnimalLeaseEvent.LEASE_ERROR_NO_PERMISSION))
        return
    end

    local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
    local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
    local farmId = farm.farmId
    local buyPrice = g_currentMission.animalSystem:getAnimalBuyPrice(self.subTypeIndex, self.age) * self.numAnimals
    local leaseRatePerPeriod = math.ceil(buyPrice / 24)

    local errorCode = LL_AnimalLeaseEvent.validate(self.object, self.subTypeIndex, self.age, self.numAnimals, leaseRatePerPeriod, farmId)
    if errorCode ~= nil then
        connection:sendEvent(LL_AnimalLeaseEvent.newServerToClient(errorCode))
        return
    end

    LL_leaseLivestock:addLease(self.object, self.subTypeIndex, self.age, self.numAnimals, farmId, leaseRatePerPeriod, buyPrice)
    connection:sendEvent(LL_AnimalLeaseEvent.newServerToClient(LL_AnimalLeaseEvent.LEASE_SUCCESS))
end

function LL_AnimalLeaseEvent.validate(object, subTypeIndex, _, numAnimals, leaseRatePerPeriod, farmId)
    if object == nil then
        return LL_AnimalLeaseEvent.LEASE_ERROR_OBJECT_DOES_NOT_EXIST
    end
    if not object:getSupportsAnimalSubType(subTypeIndex) then
        return LL_AnimalLeaseEvent.LEASE_ERROR_ANIMAL_NOT_SUPPORTED
    end
    if object:getNumOfFreeAnimalSlots() < numAnimals then
        return LL_AnimalLeaseEvent.LEASE_ERROR_NOT_ENOUGH_SPACE
    end
    local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(subTypeIndex)
    if #g_currentMission.husbandrySystem:getPlaceablesByFarm(farmId, animalTypeIndex) == 0 then
        return LL_AnimalLeaseEvent.LEASE_ERROR_NO_BARN_AVAILABLE
    end
    if g_currentMission.husbandrySystem:getNumOfFreeAnimalSlots(farmId, subTypeIndex) < numAnimals then
        return LL_AnimalLeaseEvent.LEASE_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED
    end
    if g_currentMission:getMoney(farmId) < leaseRatePerPeriod then
        return LL_AnimalLeaseEvent.LEASE_ERROR_NOT_ENOUGH_MONEY
    end
    return nil
end
