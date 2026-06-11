-- LL_LeaseLivestock
-- Main driver for LL
--

LL_LeaseLivestock = {}
LL_LeaseLivestock.dir = g_currentModDirectory

function LL_LeaseLivestock:loadMap()
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
    if g_animalScreen ~= nil and g_animalScreen.buttonBuy ~= nil then
        g_animalScreen.buttonLease = g_animalScreen.buttonBuy:clone(g_animalScreen.buttonsPanel)
        g_animalScreen.buttonLease:setText(g_i18n:getText("ll_leaseButton"))
        g_animalScreen.buttonLease:setInputAction("LL_LEASE")
        g_animalScreen.buttonLease:setVisible(false)
        g_animalScreen.buttonLease.onClickCallback = AnimalScreen.onClickLease
        g_animalScreen.buttonLease.onClickCallbackTarget = g_animalScreen
        g_animalScreen.buttonsPanel:invalidateLayout()
    end
end

function LL_LeaseLivestock:onPeriodChanged()
    if not g_currentMission:getIsServer() then return end
    for _, husbandry in ipairs(g_currentMission.husbandrySystem.placeables) do
        local farmId = husbandry:getOwnerFarmId()
        for _, cluster in ipairs(husbandry:getClusters()) do
            if cluster.isLeased then
                local rate = LL_LeaseLivestock:getAnimalLeaseRate(cluster.subTypeIndex) * cluster.numAnimals
                g_currentMission:addMoney(-rate, farmId, MoneyType.LIVESTOCK_LEASING_COST, true, true)
            end
        end
    end
end

function LL_LeaseLivestock:getAnimalLeaseRate(subTypeIndex)
    local buyPrice = g_currentMission.animalSystem:getAnimalBuyPrice(subTypeIndex, 18)
    local leaseRatePerPeriod = math.floor(buyPrice / 24)
    return leaseRatePerPeriod
end

-- Adds animals to the husbandry, charges the first period, and records the lease.
function LL_LeaseLivestock:addLease(object, subTypeIndex, age, numAnimals, farmId, leaseRatePerPeriod, buyoutPrice)
    local animalSystem = g_currentMission.animalSystem
    local cluster = animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
    cluster.isLeased = true
    if cluster:getSupportsMerging() then
        cluster.numAnimals = numAnimals
        cluster.age = age
        cluster.subTypeIndex = subTypeIndex
        object:addCluster(cluster)
    else
        for _ = 1, numAnimals do
            cluster = animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
            cluster.isLeased = true
            cluster.numAnimals = 1
            cluster.age = age
            object:addCluster(cluster)
        end
    end

    g_currentMission:addMoney(-leaseRatePerPeriod, farmId, MoneyType.LIVESTOCK_LEASING_COST, true, true)
end

addModEventListener(LL_LeaseLivestock)

-- Add Money Type and entries needed to display on finance screen

table.insert(FinanceStats.statNames, "livestockLeasingCost")
FinanceStats.statNameToIndex["livestockLeasingCost"] = #FinanceStats.statNames

FinanceStats.new = Utils.overwrittenFunction(FinanceStats.new, function(customMt, superFunc)
    local self = superFunc(customMt)
    FinanceStats.statNamesI18n["livestockLeasingCost"] = g_i18n:getText("ll_finance_livestockLeasingCost", g_currentModName)
    return self
end)

MoneyType.LIVESTOCK_LEASING_COST = MoneyType.register("livestockLeasingCost", "ll_finance_livestockLeasingCost", g_currentModName)
