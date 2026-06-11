-- LL_AnimalClusterLeased
-- Patches AnimalCluster to isolate leased animals from owned ones.
--

AnimalCluster.getHash = Utils.overwrittenFunction(AnimalCluster.getHash,
    function(self, superFunc)
        local hash = superFunc(self)
        if self.isLeased then
            hash = hash + 1000000000000  -- prevent overlap
        end
        return hash
    end
)

-- Set sell price of leased animals
AnimalCluster.getSellPrice = Utils.overwrittenFunction(AnimalCluster.getSellPrice,
    function(self, superFunc)
        if self.isLeased then
            return LL_LeaseLivestock:getAnimalLeaseRate(self.subTypeIndex)
        end
        return superFunc(self)
    end
)

-- Prevent merges between leased and non-leased clusters.
AnimalCluster.merge = Utils.overwrittenFunction(AnimalCluster.merge,
    function(self, superFunc, otherCluster)
        if (self.isLeased or false) ~= (otherCluster.isLeased or false) then
            return false
        end
        return superFunc(self, otherCluster)
    end
)

-- Sync isLeased over the network.
AnimalCluster.readStream = Utils.overwrittenFunction(AnimalCluster.readStream,
    function(self, superFunc, streamId, connection)
        superFunc(self, streamId, connection)
        self.isLeased = streamReadBool(streamId)
    end
)

AnimalCluster.writeStream = Utils.overwrittenFunction(AnimalCluster.writeStream,
    function(self, superFunc, streamId, connection)
        superFunc(self, streamId, connection)
        streamWriteBool(streamId, self.isLeased or false)
    end
)

-- Register #isLeased in the savegame schema.
AnimalCluster.registerSavegameXMLPaths = Utils.overwrittenFunction(
    AnimalCluster.registerSavegameXMLPaths,
    function(schema, superFunc, basePath)
        superFunc(schema, basePath)
        schema:register(XMLValueType.BOOL, basePath .. "#isLeased", false)
    end
)

-- Persist isLeased to savegame XML.
AnimalCluster.saveToXMLFile = Utils.overwrittenFunction(AnimalCluster.saveToXMLFile,
    function(self, superFunc, xmlFile, key, usedModNames)
        superFunc(self, xmlFile, key, usedModNames)
        if self.isLeased then
            xmlFile:setBool(key .. "#isLeased", true)
        end
    end
)

-- Load isLeased from savegame XML.
AnimalCluster.loadFromXMLFile = Utils.overwrittenFunction(AnimalCluster.loadFromXMLFile,
    function(self, superFunc, xmlFile, key)
        local result = superFunc(self, xmlFile, key)
        self.isLeased = xmlFile:getBool(key .. "#isLeased", false)
        return result
    end
)
