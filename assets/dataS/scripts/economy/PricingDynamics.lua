PricingDynamics = {}
local PricingDynamics_mt = Class(PricingDynamics)
PricingDynamics.VERSION = 1
PricingDynamics.AMP_DIST_CONSTANT = 1
PricingDynamics.AMP_DIST_LINEAR_DOWN = 2
PricingDynamics.AMP_DIST_LINEAR_UP = 3
PricingDynamics.TREND_PLATEAU = 1
PricingDynamics.TREND_CLIMBING = 2
PricingDynamics.TREND_FALLING = 3

function PricingDynamics:new(mean, amp, ampVar, ampDist, per, perVar, perDist, plateauFactor, initialPlateauFraction, customMt)
	if customMt == nil then
		customMt = PricingDynamics_mt
	end

	local self = {}

	setmetatable(self, customMt)

	self.curves = {}
	self.plateauDuration = per * plateauFactor
	self.meanValue = mean
	self.isInPlateau = math.random() < initialPlateauFraction
	self.nextPlateauNumber = 0
	self.baseCurve = self:startFirstCycle(nil, amp, ampVar, ampDist, per, perVar, perDist)
	local sinePeriod = self.baseCurve.period

	if self.isInPlateau then
		self.plateauTime = math.random() * self.plateauDuration

		if Utils.getCoinToss() then
			self.baseCurve.time = sinePeriod * 0.25
		else
			self.baseCurve.time = sinePeriod * 0.75
			self.nextPlateauNumber = 1
		end
	else
		self.plateauTime = 0
		local t = self.baseCurve.time

		if t >= self.baseCurve.period * 0.5 and t < self.baseCurve.period * 0.75 then
			self.nextPlateauNumber = 1
		end
	end

	return self
end

function PricingDynamics:addCurve(amp, ampVar, ampDist, per, perVar, perDist)
	local curve = self:startFirstCycle(nil, amp, ampVar, ampDist, per, perVar, perDist)

	table.insert(self.curves, curve)
end

function PricingDynamics:update(dt)
	if self.isInPlateau then
		local newTime = self.plateauTime + dt

		if self.plateauDuration <= newTime then
			self.isInPlateau = false
			self.plateauTime = 0
			self.nextPlateauNumber = 1 - self.nextPlateauNumber
		else
			self.plateauTime = newTime
		end

		return
	end

	local newTime = self.baseCurve.time + dt

	self:updateCurve(self.baseCurve, dt)

	for _, curve in pairs(self.curves) do
		self:updateCurve(curve, dt)
	end

	local nextPlateauTime = self.baseCurve.period * 0.25

	if self.nextPlateauNumber == 1 then
		nextPlateauTime = self.baseCurve.period * 0.75
	end

	if not self.isInPlateau and nextPlateauTime < newTime and newTime < nextPlateauTime + self.baseCurve.period * 0.25 then
		self.isInPlateau = true
		self.plateauTime = 0
		self.baseCurve.time = nextPlateauTime
	end
end

function PricingDynamics:evaluate()
	local value = self.meanValue
	value = value + self:evaluateCurve(self.baseCurve)

	for _, curve in pairs(self.curves) do
		value = value + self:evaluateCurve(curve)
	end

	return value
end

function PricingDynamics:getBaseCurveTrend()
	if self.isInPlateau then
		return PricingDynamics.TREND_PLATEAU
	elseif self.baseCurve.time >= self.baseCurve.period * 0.25 and self.baseCurve.time <= self.baseCurve.period * 0.75 then
		return PricingDynamics.TREND_FALLING
	end

	return PricingDynamics.TREND_CLIMBING
end

function PricingDynamics:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLInt(xmlFile, key .. "#priceVersion", PricingDynamics.VERSION)
	setXMLBool(xmlFile, key .. "#isInPlateau", self.isInPlateau)
	setXMLInt(xmlFile, key .. "#nextPlateauNumber", self.nextPlateauNumber)
	setXMLInt(xmlFile, key .. "#plateauDuration", self.plateauDuration)
	setXMLFloat(xmlFile, key .. "#meanValue", self.meanValue)
	setXMLFloat(xmlFile, key .. "#plateauTime", self.plateauTime)
	self:saveCurveToXMLFile(xmlFile, key, self.baseCurve, "BaseCurve")

	for k, curve in pairs(self.curves) do
		self:saveCurveToXMLFile(xmlFile, key, curve, k)
	end
end

function PricingDynamics:loadFromXMLFile(xmlFile, key)
	if Utils.getNoNil(getXMLInt(xmlFile, key .. "#priceVersion"), 0) ~= PricingDynamics.VERSION then
		return
	end

	self.isInPlateau = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isInPlateau"), self.isInPlateau)
	self.nextPlateauNumber = Utils.getNoNil(getXMLInt(xmlFile, key .. "#nextPlateauNumber"), self.nextPlateauNumber)
	self.meanValue = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#meanValue"), self.meanValue)
	self.plateauTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#plateauTime"), self.plateauTime)
	self.plateauDuration = Utils.getNoNil(getXMLInt(xmlFile, key .. "#plateauDuration"), self.plateauDuration)

	self:loadCurveFromXMLFile(xmlFile, key, self.baseCurve, "BaseCurve")

	for k, curve in pairs(self.curves) do
		self:loadCurveFromXMLFile(xmlFile, key, curve, k)
	end
end

function PricingDynamics:saveCurveToXMLFile(xmlFile, key, curve, name)
	local curveKey = string.format("%s.curve%s", key, tostring(name))

	setXMLFloat(xmlFile, curveKey .. "#nominalAmplitude", curve.nominalAmplitude)
	setXMLFloat(xmlFile, curveKey .. "#nominalAmplitudeVariation", curve.nominalAmplitudeVariation)
	setXMLInt(xmlFile, curveKey .. "#amplitudeDistribution", curve.amplitudeDistribution)
	setXMLInt(xmlFile, curveKey .. "#nominalPeriod", curve.nominalPeriod)
	setXMLInt(xmlFile, curveKey .. "#nominalPeriodVariation", curve.nominalPeriodVariation)
	setXMLInt(xmlFile, curveKey .. "#periodDistribution", curve.periodDistribution)
	setXMLFloat(xmlFile, curveKey .. "#amplitude", curve.amplitude)
	setXMLFloat(xmlFile, curveKey .. "#period", curve.period)
	setXMLFloat(xmlFile, curveKey .. "#time", curve.time)
end

function PricingDynamics:loadCurveFromXMLFile(xmlFile, key, curve, name)
	curve.nominalAmplitude = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".curve" .. name .. "#nominalAmplitude"), curve.nominalAmplitude)
	curve.nominalAmplitudeVariation = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".curve" .. name .. "#nominalAmplitudeVariation"), curve.nominalAmplitudeVariation)
	curve.amplitudeDistribution = Utils.getNoNil(getXMLInt(xmlFile, key .. ".curve" .. name .. "#amplitudeDistribution"), curve.amplitudeDistribution)
	curve.nominalPeriod = Utils.getNoNil(getXMLInt(xmlFile, key .. ".curve" .. name .. "#nominalPeriod"), curve.nominalPeriod)
	curve.nominalPeriodVariation = Utils.getNoNil(getXMLInt(xmlFile, key .. ".curve" .. name .. "#nominalPeriodVariation"), curve.nominalPeriodVariation)
	curve.periodDistribution = Utils.getNoNil(getXMLInt(xmlFile, key .. ".curve" .. name .. "#periodDistribution"), curve.periodDistribution)
	curve.amplitude = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".curve" .. name .. "#amplitude"), curve.amplitude)
	curve.period = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".curve" .. name .. "#period"), curve.period)
	curve.time = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".curve" .. name .. "#time"), curve.time)
end

function PricingDynamics:startFirstCycle(curve, amp, ampVar, ampDist, per, perVar, perDist)
	curve = Utils.getNoNil(curve, {})
	curve.nominalAmplitude = amp
	curve.nominalAmplitudeVariation = ampVar
	curve.amplitudeDistribution = ampDist
	curve.nominalPeriod = per
	curve.nominalPeriodVariation = perVar
	curve.periodDistribution = perDist

	self:startNewCycle(curve)

	curve.time = math.random() * curve.period

	return curve
end

function PricingDynamics:startNewCycle(curve)
	local sinePeriod = curve.nominalPeriod - 2 * self.plateauDuration
	local sinePeriodVariation = sinePeriod * curve.nominalPeriodVariation / curve.nominalPeriod
	curve.amplitude = self:getRandomValue(curve.nominalAmplitude, curve.nominalAmplitudeVariation, curve.amplitudeDistribution)
	curve.period = self:getRandomValue(sinePeriod, sinePeriodVariation, curve.periodDistribution)
	curve.time = 0
end

function PricingDynamics:updateCurve(curve, dt)
	curve.time = curve.time + dt

	if curve.period <= curve.time then
		self:startNewCycle(curve)
	end
end

function PricingDynamics:evaluateCurve(curve)
	return curve.amplitude * math.sin(2 * math.pi * curve.time / curve.period)
end

function PricingDynamics:getRandomValue(center, deviation, distribution)
	local minValue = center - deviation
	local maxValue = center + deviation

	if distribution == PricingDynamics.AMP_DIST_CONSTANT then
		return Utils.randomFloat(minValue, maxValue)
	elseif distribution == PricingDynamics.AMP_DIST_LINEAR_DOWN then
		local r = math.random()

		return maxValue + math.sqrt(r) * (minValue - maxValue)
	elseif distribution == PricingDynamics.AMP_DIST_LINEAR_UP then
		local r = math.random()

		return minValue - math.sqrt(r) * (maxValue - minValue)
	end

	return -math.huge
end
