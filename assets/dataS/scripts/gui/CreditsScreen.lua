CreditsScreen = {
	TITLE = 0,
	TEXT = 1,
	SEPARATOR = 2,
	CONTROLS = {
		CREDITS_TITLE_ELEMENT = "creditsTitleElement",
		CREDITS_TEXT_ELEMENT = "creditsTextElement",
		LOGO = "logo",
		CREDITS_SEPARATOR_ELEMENT = "creditsSeparatorElement",
		CREDITS_PLACEHOLDER = "creditsPlaceholder",
		CREDITS_BUTTON = "creditsButton",
		ACHIEVEMENTS_BUTTON = "achievementsButton",
		CREDITS_BOX = "creditsVisibilityBox"
	},
	LIST_TEMPLATE_ELEMENT_NAME = {}
}
local CreditsScreen_mt = Class(CreditsScreen, ScreenElement)

function CreditsScreen:new(target, custom_mt)
	local self = ScreenElement:new(target, custom_mt or CreditsScreen_mt)

	self:registerControls(CreditsScreen.CONTROLS)

	self.returnScreenName = "MainScreen"

	return self
end

function CreditsScreen:onCreate(element)
	self:loadCredits()

	self.creditsStartY = self.creditsPlaceholder.absPosition[2]
end

function CreditsScreen:onOpen()
	CreditsScreen:superClass().onOpen(self)

	for _, item in pairs(self.creditsElements) do
		item:setAlpha(0)
	end

	if g_isPresentationVersionHideMenuButtons then
		self.achievementsButton:setDisabled(true)
	end

	self.nextFadeInCreditsItemId = 1
	self.nextFadeOutCreditsItemId = 1

	self.creditsPlaceholder:setAbsolutePosition(self.creditsPlaceholder.absPosition[1], self.creditsStartY)

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
		self:updateAchievementsButtonState()
		g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.updateAchievementsButtonState, self)
	end
end

function CreditsScreen:onClose()
	g_messageCenter:unsubscribe(MessageType.USER_PROFILE_CHANGED, self)
	CreditsScreen:superClass().onClose(self)
end

function CreditsScreen:update(dt)
	self.creditsPlaceholder:setAbsolutePosition(self.creditsPlaceholder.absPosition[1], self.creditsPlaceholder.absPosition[2] + 7e-05 * dt)

	if self.nextFadeInCreditsItemId <= #self.creditsElements then
		local y = self.creditsElements[self.nextFadeInCreditsItemId].absPosition[2]

		if self.creditsVisibilityBox.absPosition[2] < y then
			self.creditsElements[self.nextFadeInCreditsItemId]:fadeIn(1.2)

			self.nextFadeInCreditsItemId = self.nextFadeInCreditsItemId + 1
		end
	end

	if self.nextFadeOutCreditsItemId <= #self.creditsElements then
		local y = self.creditsElements[self.nextFadeOutCreditsItemId].absPosition[2]

		if y > self.creditsVisibilityBox.absPosition[2] + self.creditsVisibilityBox.size[2] * 0.8 then
			self.creditsElements[self.nextFadeOutCreditsItemId]:fadeOut(4)

			self.nextFadeOutCreditsItemId = self.nextFadeOutCreditsItemId + 1
		end
	else
		self:onClickBack()
	end
end

function CreditsScreen:loadCredits()
	local creditsTexts = nil

	if GS_IS_MOBILE_VERSION then
		creditsTexts = self:loadMobileCredits()
	else
		creditsTexts = self:loadDefaultCredits()
	end

	for i = #self.creditsPlaceholder.elements, 1, -1 do
		self.creditsPlaceholder.elements[i]:delete()
	end

	self.creditsElements = {}

	for _, creditsElem in pairs(creditsTexts) do
		self.currentCreditsText = creditsElem.c
		local newCreditsElem = nil

		if creditsElem.t == CreditsScreen.TITLE then
			newCreditsElem = self.creditsTitleElement:clone(self.creditsPlaceholder)

			newCreditsElem:setText(creditsElem.c)
		elseif creditsElem.t == CreditsScreen.TEXT then
			newCreditsElem = self.creditsTextElement:clone(self.creditsPlaceholder)

			newCreditsElem:setText(creditsElem.c)
		elseif creditsElem.t == CreditsScreen.SEPARATOR then
			newCreditsElem = self.creditsSeparatorElement:clone(self.creditsPlaceholder)
		end

		if newCreditsElem ~= nil then
			newCreditsElem:setAlpha(0)
			table.insert(self.creditsElements, newCreditsElem)
		end
	end

	local height = self.creditsPlaceholder:invalidateLayout(true)
	self.creditsEndY = self.creditsPlaceholder.size[2] + height
end

function CreditsScreen:loadMobileCredits()
	local creditsTexts = {}

	table.insert(creditsTexts, {
		c = "Developed by",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "GIANTS Software GmbH",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Executive Producer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Christian Ammann",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Lead Programmer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Stefan Geiger",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Creative Director",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Thomas Frey",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Lead Designer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Renzo Thönen",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Producer & Lead Artist",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Marc Schwegler",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Associate Producer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Laëtitia Sodoyer",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Senior Programmers",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Thomas Brunner",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Eddie Edwards",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Programmers",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Manuel Leithner",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Samo Jordan",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Stefan Maurus",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Jos Kuijpers",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Andreas Dechambenoit",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Nicolas Wrobel",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Bojan Kerec",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Olivier Foure",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Marius Hofmann",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Technical Artists",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Evgeniy Zaitsev",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Horia Serban",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Senior Vehicle Artist",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Tomas Dostal",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Vehicle Artist",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Ivan Stanchev",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Environment Artist",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Angelo Panciotto",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Florian Busse",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Maximilian Frömter",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Graphic Designers",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Anett Jaschke",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Sandra Meier",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Thomas Flachs",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Vehicle Integration",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Chris Wachter",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Daniel Witzel",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Audio Designer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Tiago Inácio",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "QA Lead",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Kenneth Burgess",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "QA Analysts",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Stephan Bongartz",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Jana Stephan",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Benjamin Neußinger",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Martin Schücker",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "PR & Marketing Manager",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Martin Rabl",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Community Manager",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Lars Malcharek",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH then
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Published by Focus Home Interactive",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Chief Operating Officer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "John Bert",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Production Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Luc Heninger",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Head of Line Production",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Xavier Marot",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Head of Content",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Théophile Gaudron",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Executive Release Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Mohad Semlali",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Line Producer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Maxime Béjat",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Associate Line Producer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Charles Baratte",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Release Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Nathalie Phung",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Thierry Ching",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Florent D’hervé",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Associate User Researchers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Clément Charvin",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Anaïtis de France",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "QA Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Marie-Thérèse Nguyen",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Alan Vitige",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "QA Lead",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Grégory Collomb",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "QA Analyst",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Jonathan Delage",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Jérémy Felix",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Jonathan Prungnaud",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Marketing Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Thomas Barrau",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Creative Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Dessil Basmadjian",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Operational Marketing Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Pierre Gonzalvez",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Creative Producer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Xavier Assemat",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Brand Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Yolène Poirel",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Lead Community & Influencer Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Nicolas Weil",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Community Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Quentin Yueh Yu Lee",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Marcus Hansson",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Sarah Makdad",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Advertising Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Sébastion Goyens",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Julia Grenier",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Press Relation Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Julie Carneiro",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Marie-Caroline Le Vacon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Lead Cinematic Artists",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Maxime Guémon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Jean-Philippe Bouix",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Cinematic Artists",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Emmanuel Bahu-Leyser",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Artistic Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "François Weytens",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Graphists",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Mélanie Pompon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Mazarine Touzet",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Adrion Gion",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Christine Zhang",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Sales Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Aurélie Rodrigues",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Business Development Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Vincent Chataignier",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Business Unit",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Charlotte Derquennes",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Trade Marketing Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Tristan Hauvette",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Trade Marketing Coordinator",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Sing-Fun Shek",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Content Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Boris Kohler-Nudelmont",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Emilie Regnier",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Event Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Julie Valladon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Erell Guichard",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Special Thanks",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Romuald Lebrun",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
	end

	return creditsTexts
end

function CreditsScreen:loadDefaultCredits()
	local creditsTexts = {}

	table.insert(creditsTexts, {
		c = "Developed by",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "GIANTS Software GmbH",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Executive Producer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Christian Ammann",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Lead Programmer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Stefan Geiger",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Creative Director",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Thomas Frey",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Lead Designer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Renzo Thönen",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Lead Artist",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Marc Schwegler",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Associate Producer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Laëtitia Sodoyer",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		table.insert(creditsTexts, {
			c = "Senior Programmer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Thomas Brunner",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "PlayStation®4 Programmer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Eddie Edwards",
			t = CreditsScreen.TEXT
		})
	else
		table.insert(creditsTexts, {
			c = "Senior Programmers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Thomas Brunner",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Eddie Edwards",
			t = CreditsScreen.TEXT
		})
	end

	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Programmers",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Manuel Leithner",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Samo Jordan",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Stefan Maurus",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Jos Kuijpers",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Andreas Dechambenoit",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Stefan Rietberger",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Nicolas Wrobel",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Bojan Kerec",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Marius Hofmann",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Emil Drefers",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Manuel Widmer",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Gino van den Bergen",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Senior Technical Artist",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Evgeniy Zaitsev",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Senior Vehicle Artist",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Tomas Dostal",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Artists",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Horia Serban",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Ivan Stanchev",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Angelo Panciotto",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Florian Busse",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Maximilian Frömter",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Anett Jaschke",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Jozef Rolincin",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Thomas Flachs",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Vehicle Integration",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Chris Wachter",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Daniel Witzel",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Raphael Greshake",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Lead Audio Designer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "László Vincze",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Audio Designer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Tiago Inácio",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Chief Operations Officer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Yann le Tensorer",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "QA Lead",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Jan-Hendrik Pfitzner",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "QA Analysts",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Stephan Bongartz",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Patryk Suzin",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Kenneth Burgess",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Chris Zoltán",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "PR & Marketing Manager",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Martin Rabl",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Community Manager",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Lars Malcharek",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Customer Support Lead",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Pedro Fernández",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Customer Support Representatives",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Janice Nguizani",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Chris Zoltán",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Web Developers",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Eric J. Baeppler",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Marten Boessenkool",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Graphic Designer",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Anett Jaschke",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Video Artist",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Lukas Miller",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Event Manager",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Marie-Anne Leterme",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = " Localization",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = " Lionbridge Game Services",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Main Theme/Main Menu Music:",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "László Vincze and Péter Nagy-Miklós",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Radio & Music",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Audio Network GmbH",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})

	if GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_PC or g_languageShort ~= "de" and g_languageShort ~= "pl" and g_languageShort ~= "cz" and g_languageShort ~= "hu" and g_languageShort ~= "ro" then
		if getGameTerritory() == "jp" then
			table.insert(creditsTexts, {
				t = CreditsScreen.SEPARATOR
			})
			table.insert(creditsTexts, {
				c = "Licensed to and published in Japan by Oizumi Amuzio Inc.",
				t = CreditsScreen.TEXT
			})
			table.insert(creditsTexts, {
				t = CreditsScreen.SEPARATOR
			})
			table.insert(creditsTexts, {
				c = "Manager",
				t = CreditsScreen.TITLE
			})
			table.insert(creditsTexts, {
				c = "Kota Sugawara",
				t = CreditsScreen.TEXT
			})
			table.insert(creditsTexts, {
				t = CreditsScreen.SEPARATOR
			})
			table.insert(creditsTexts, {
				c = "Localization",
				t = CreditsScreen.TITLE
			})
			table.insert(creditsTexts, {
				c = "Casie Wong",
				t = CreditsScreen.TEXT
			})
			table.insert(creditsTexts, {
				c = "Yuriko Kera",
				t = CreditsScreen.TEXT
			})
			table.insert(creditsTexts, {
				t = CreditsScreen.SEPARATOR
			})
			table.insert(creditsTexts, {
				c = "PR/Marketing",
				t = CreditsScreen.TITLE
			})
			table.insert(creditsTexts, {
				c = "Jin Sato",
				t = CreditsScreen.TEXT
			})
			table.insert(creditsTexts, {
				t = CreditsScreen.SEPARATOR
			})
			table.insert(creditsTexts, {
				c = "Web Design",
				t = CreditsScreen.TITLE
			})
			table.insert(creditsTexts, {
				c = "Manami Kuwata",
				t = CreditsScreen.TEXT
			})
			table.insert(creditsTexts, {
				t = CreditsScreen.SEPARATOR
			})
		end

		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Published by Focus Home Interactive",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Chief Operating Officer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "John Bert",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Production Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Luc Heninger",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Head of Line Production",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Xavier Marot",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Head of Content",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Théophile Gaudron",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Executive Release Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Mohad Semlali",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Line Producer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Maxime Béjat",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Associate Line Producer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Charles Baratte",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Release Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Nathalie Phung",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Thierry Ching",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Florent D’hervé",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Associate User Researchers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Clément Charvin",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Anaïtis de France",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "QA Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Marie-Thérèse Nguyen",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Alan Vitige",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "QA Lead",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Grégory Collomb",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "QA Analyst",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Jonathan Delage",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Jérémy Felix",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Jonathan Prungnaud",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Marketing Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Thomas Barrau",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Creative Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Dessil Basmadjian",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Operational Marketing Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Pierre Gonzalvez",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Creative Producer",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Xavier Assemat",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Brand Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Yolène Poirel",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Lead Community & Influencer Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Nicolas Weil",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Community Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Quentin Yueh Yu Lee",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Marcus Hansson",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Sarah Makdad",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Advertising Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Sébastion Goyens",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Julia Grenier",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Press Relation Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Julie Carneiro",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Marie-Caroline Le Vacon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Lead Cinematic Artists",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Maxime Guémon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Jean-Philippe Bouix",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Cinematic Artists",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Emmanuel Bahu-Leyser",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Artistic Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "François Weytens",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Graphists",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Mélanie Pompon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Mazarine Touzet",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Adrion Gion",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Christine Zhang",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Sales Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Aurélie Rodrigues",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Business Development Director",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Vincent Chataignier",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Business Unit",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Charlotte Derquennes",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Trade Marketing Manager",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Tristan Hauvette",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Trade Marketing Coordinator",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Sing-Fun Shek",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Content Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Boris Kohler-Nudelmont",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Emilie Regnier",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Event Managers",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Julie Valladon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			c = "Erell Guichard",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
		table.insert(creditsTexts, {
			c = "Special Thanks",
			t = CreditsScreen.TITLE
		})
		table.insert(creditsTexts, {
			c = "Romuald Lebrun",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
	elseif g_languageShort == "de" then
		table.insert(creditsTexts, {
			c = "Published in Germany by astragon",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
	else
		table.insert(creditsTexts, {
			c = "Published in Poland by CDP.PL",
			t = CreditsScreen.TEXT
		})
		table.insert(creditsTexts, {
			t = CreditsScreen.SEPARATOR
		})
	end

	table.insert(creditsTexts, {
		t = CreditsScreen.TITLE,
		c = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2003-2019 GIANTS Software GmbH"
	})
	table.insert(creditsTexts, {
		c = "Farming Simulator",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "GIANTS Software and its logos are trademarks",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "or registered trademarks of GIANTS Software",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "All rights reserved.",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "All manufacturers, agricultural machinery,",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "agricultural equipment, names, brands and",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "associated imagery featured in this game",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "in some cases include trademarks and/or",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "copyrighted materials of their",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "respective owners. The agricultural",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "machines and equipment in this game",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "may be different from the actual machines",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "in shapes, colours and performance.",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Uses Lua",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.TITLE,
		c = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1994-2019 Lua.org, PUC-Rio"
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Uses LuaJIT",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.TITLE,
		c = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 2005-2019 Mike Pall"
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Uses Ogg Vorbis",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.TITLE,
		c = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1994-2019 Xiph.Org Foundation"
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Uses Zlib",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.TITLE,
		c = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1995-2019 Jean-loup Gailly"
	})
	table.insert(creditsTexts, {
		c = "and Mark Adler",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "This software is based in part on",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "the work of the Independent JPEG Group",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.TITLE,
		c = "Copyright " .. g_i18n:getText("ui_copyrightSymbol") .. " 1991-2019 Independent JPEG Group"
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "Special Thanks to",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Martin Bärwolf",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Mike Pall",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "Andrés Villegas",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		t = CreditsScreen.SEPARATOR
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "Thanks for playing!",
		t = CreditsScreen.TEXT
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})
	table.insert(creditsTexts, {
		c = "",
		t = CreditsScreen.TITLE
	})

	return creditsTexts
end

function CreditsScreen:onCareerClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.careerButton)
	g_mainScreen:onCareerClick(element)
end

function CreditsScreen:onAchievementsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.achievementsButton)
	g_mainScreen:onAchievementsClick(element)
end

function CreditsScreen:updateAchievementsButtonState()
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
		self.achievementsButton:setDisabled(not getIsUserSignedIn())
	end
end
