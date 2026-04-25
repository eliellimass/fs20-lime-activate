# Estudo Completo: Sistema de Calcário (Lime) no FS20

## Repositório: `eliellimass/fs20-lime-activate`

---

## 1. VISÃO GERAL

O repositório contém os assets do Farming Simulator 20 (versão mobile), com **3.246 arquivos** distribuídos em três diretórios principais:
- `assets/data/` — Dados do jogo (mapas, foliagem, texturas, placeables, veículos)
- `assets/dataS/` — Scripts Lua, configurações de plataforma, localização, store items
- `assets/dataS2/` — Assets de UI/menu (ícones HUD, texturas de menu)

O sistema de calcário **já existe completamente implementado** no código, mas está **parcialmente desativado na versão mobile**. A seguir, a análise detalhada de cada componente.

---

## 2. O PONTO-CHAVE: O CALCÁRIO ESTÁ COMENTADO/DESATIVADO

### 2.1. `maps_sprayTypes.xml` — **LIME ESTÁ COMENTADO**

**Arquivo:** `assets/data/maps/maps_sprayTypes.xml`

```xml
<sprayTypes>
    <sprayType name="FERTILIZER"       litersPerSecond="0.0060" type="FERTILIZER" groundType="1" />
    <sprayType name="LIQUIDFERTILIZER" litersPerSecond="0.0081" type="FERTILIZER" groundType="1" />
    <sprayType name="MANURE"           litersPerSecond="0.4000" type="FERTILIZER" groundType="2" />
    <sprayType name="LIQUIDMANURE"     litersPerSecond="0.4000" type="FERTILIZER" groundType="3" />
    <sprayType name="DIGESTATE"        litersPerSecond="0.4000" type="FERTILIZER" groundType="3" />
<!--    <sprayType name="LIME"             litersPerSecond="0.0900" type="LIME"       groundType="4" />-->
    <sprayType name="HERBICIDE"        litersPerSecond="0.0081" type="HERBICIDE"  groundType="0" />
</sprayTypes>
```

**O que isso significa:** A linha do spray type LIME está comentada (`<!-- -->`). Sem esse registro, o jogo não reconhece LIME como um tipo de pulverização válido. Mesmo que todo o código Lua suporte calcário, sem essa entrada o `SprayTypeManager` nunca cria o spray type LIME.

**Para ativar:** Descomentar a linha:
```xml
<sprayType name="LIME" litersPerSecond="0.0900" type="LIME" groundType="4" />
```

### 2.2. `platformSettings.xml` — **useLimeCounter = false para mobile**

**Arquivo:** `assets/dataS/platformSettings.xml`

```xml
<!-- Para plataformas normais (PC/Console): -->
<setting name="useLimeCounter" value="true" type="boolean"/>
<setting name="harvestScaleRation" value="0.5 0.15 0.15 0.2" type="vector"/> <!-- spray, plow, lime, weed -->

<!-- Para versão MOBILE (GS_IS_MOBILE_VERSION): -->
<setting name="useLimeCounter" value="false" type="boolean"/>
<setting name="harvestScaleRation" value="1 0 0 0" type="vector"/> <!-- spray, plow, lime, weed -->
```

**O que isso significa:**
- Na versão mobile, `useLimeCounter` é `false`, o que faz `limeCounterNumChannels = 0` e `limeCounterMaxValue = 0`
- O `harvestScaleRation` para mobile é `"1 0 0 0"`, ou seja: 100% spray, **0% plow, 0% lime, 0% weed** — calcário não afeta o rendimento da colheita

**Para ativar:** Mudar no bloco `GS_IS_MOBILE_VERSION`:
```xml
<setting name="useLimeCounter" value="true" type="boolean"/>
<setting name="harvestScaleRation" value="0.5 0.15 0.15 0.2" type="vector"/>
```

### 2.3. `storeItems.xml` — **Lime Stations comentadas**

**Arquivo:** `assets/dataS/storeItems.xml` (linhas 258-266)

```xml
<!-- PLACEABLE SILOS
    <storeItem xmlFilename="$data/placeables/limeStation/limeStation.xml" />
    <storeItem xmlFilename="$data/placeables/limeStation/limeStation02.xml" />
    <storeItem xmlFilename="$data/placeables/limeStation/limeStation03.xml" />
-->
```

**O que isso significa:** As estações de calcário existem como itens referenciados, mas estão dentro de um bloco comentado. Não aparecem na loja do jogo.

**Para ativar:** Descomentar as linhas e colocá-las fora do bloco de comentário.

---

## 3. ARQUITETURA COMPLETA DO SISTEMA DE CALCÁRIO

### 3.1. Inicialização do Counter (Bits no Density Map)

**Arquivo:** `assets/dataS/scripts/FSBaseMission.lua` (linhas 120-148)

```lua
local useLimeCounter = g_platformSettingsManager:getSetting("useLimeCounter", true)

-- ... alocação de bits ...

self.limeCounterFirstChannel = currentBit
self.limeCounterNumChannels = useLimeCounter and 1 or 0
self.limeCounterMaxValue = 2^self.limeCounterNumChannels - 1
```

**Como funciona:**
- O density map do terreno usa **bits** para armazenar informações sobre cada pixel do campo
- O `limeCounter` ocupa **1 bit** (quando ativo) — valores possíveis: 0 (precisa de calcário) ou 1 (calcário aplicado)
- Quando `useLimeCounter = false`, `limeCounterNumChannels = 0` e `limeCounterMaxValue = 0`, desabilitando efetivamente toda a lógica

### 3.2. Harvest Scale Multiplier (Impacto no Rendimento)

**Arquivo:** `assets/dataS/scripts/FSBaseMission.lua` (linhas 478-494)

```lua
function FSBaseMission:setHarvestScaleRatio(sprayRatio, plowRatio, limeRatio, weedRatio)
    self.harvestSprayScaleRatio = sprayRatio
    self.harvestPlowScaleRatio = plowRatio
    self.harvestLimeScaleRatio = limeRatio
    self.harvestWeedScaleRatio = weedRatio
end

function FSBaseMission:getHarvestScaleMultiplier(fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor)
    local multiplier = 1
    multiplier = multiplier + self.harvestSprayScaleRatio * sprayFactor
    multiplier = multiplier + self.harvestPlowScaleRatio * plowFactor
    multiplier = multiplier + self.harvestLimeScaleRatio * limeFactor  -- +15% quando limeado
    multiplier = multiplier + self.harvestWeedScaleRatio * weedFactor
    return multiplier
end
```

**Como funciona:**
- Com `harvestScaleRation = "0.5 0.15 0.15 0.2"`:
  - Spray (fertilizante): até +50% rendimento
  - Plow (arado): até +15% rendimento
  - **Lime (calcário): até +15% rendimento**
  - Weed (ervas daninhas): até +20% rendimento
- Na versão mobile com `"1 0 0 0"`, o calcário contribui 0% para o multiplicador

### 3.3. Configuração de Savegame

**Arquivo:** `assets/dataS/scripts/FSMissionInfo.lua` (linha 22)
```lua
self.limeRequired = true  -- Padrão: calcário é necessário
```

**Arquivo:** `assets/dataS/scripts/FSCareerMissionInfo.lua` (linha 129)
```lua
self.limeRequired = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.limeRequired"), true)
```

**Arquivo para salvar:** `assets/dataS/scripts/FSCareerMissionInfo.lua` (linha 245)
```lua
setXMLBool(xmlFile, key .. ".settings.limeRequired", self.limeRequired)
```

O setting `limeRequired` é salvo/carregado do XML do savegame e sincronizado via rede em multiplayer pelo `SavegameSettingsEvent.lua`.

### 3.4. Configuração no Menu In-Game

**Arquivo:** `assets/dataS/scripts/gui/InGameMenuGameSettingsFrame.lua`
```lua
-- Checkbox no menu de configurações:
self.checkLimeRequired:setIsChecked(self.missionInfo.limeRequired)
self.checkLimeRequired:setDisabled(not self.hasMasterRights)

function InGameMenuGameSettingsFrame:onClickLimeRequired(state)
    g_currentMission:setLimeRequired(state == CheckedOptionElement.STATE_CHECKED)
end
```

**Função de toggle:**
```lua
function FSBaseMission:setLimeRequired(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.limeRequired then
        self.missionInfo.limeRequired = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
```

---

## 4. SISTEMA DE TIPOS DE FRUTAS E CALCÁRIO

### 4.1. Configuração XML por Tipo de Fruta

**Arquivo:** `assets/data/maps/maps_fruitTypes.xml`

Cada tipo de fruta tem dois atributos relacionados ao calcário:

| Atributo | Localização | Significado |
|----------|-------------|-------------|
| `growthRequiresLime` | `<growth>` | Se o crescimento é penalizado sem calcário |
| `consumesLime` | `<options>` | Se plantar consome o calcário do campo |

**Tabela de frutas e configuração lime:**

| Fruta | `growthRequiresLime` | `consumesLime` |
|-------|---------------------|----------------|
| Wheat (trigo) | true | true |
| Barley (cevada) | true | true |
| Oat (aveia) | true | true |
| Cotton (algodão) | true | true |
| Canola (colza) | true | true |
| Sunflower (girassol) | true | true |
| Soybean (soja) | true | true |
| Maize (milho) | true | true |
| Potato (batata) | true | true |
| Sugar Beet (beterraba) | true | true |
| **Grass (grama)** | **false** | **false** |
| **Dry Grass** | **false** | **false** |

### 4.2. Leitura no Lua

**Arquivo:** `assets/dataS/scripts/misc/FruitTypeManager.lua`
```lua
fruitType.growthRequiresLime = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#requiresLime"), true)
fruitType.consumesLime = Utils.getNoNil(getXMLBool(xmlFile, key .. ".options#consumesLime"), true)
```

---

## 5. MECÂNICA DE APLICAÇÃO DE CALCÁRIO NO CAMPO

### 5.1. SprayTypeManager — Registro do Tipo LIME

**Arquivo:** `assets/dataS/scripts/misc/SprayTypeManager.lua` (linhas 90-96)

```lua
sprayType.isFertilizer = typeName == "FERTILIZER"
sprayType.isLime = typeName == "LIME"
sprayType.isHerbicide = typeName == "HERBICIDE"

if not sprayType.isFertilizer and not sprayType.isLime and not sprayType.isHerbicide then
    print("Warning: SprayType '" .. tostring(name) .. "' type '" .. typeName .. "' is invalid.")
    return nil
end
```

### 5.2. Função updateSprayArea — Roteamento

**Arquivo:** `assets/dataS/scripts/utils/FSDensityMapUtil.lua` (linhas 679-695)

```lua
function FSDensityMapUtil.updateSprayArea(...)
    local desc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
    if desc ~= nil then
        if desc.isLime then
            numPixels, totalNumPixels = FSDensityMapUtil.updateLimeArea(...)
        elseif desc.isFertilizer then
            numPixels, totalNumPixels = FSDensityMapUtil.updateFertilizerArea(...)
        elseif desc.isHerbicide then
            numPixels, totalNumPixels = FSDensityMapUtil.updateHerbicideArea(...)
        end
    end
end
```

### 5.3. Função updateLimeArea — Aplicação no Terreno

**Arquivo:** `assets/dataS/scripts/utils/FSDensityMapUtil.lua` (linhas 773-832)

```lua
function FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, 
                                          heightWorldX, heightWorldZ, groundType)
    -- Obtém os modificadores do density map
    local limeCounterFirstChannel = g_currentMission.limeCounterFirstChannel
    local limeCounterNumChannels = g_currentMission.limeCounterNumChannels
    local limeCounterMaxValue = g_currentMission.limeCounterMaxValue

    -- Para cada tipo de fruta plantada:
    for index, entry in pairs(g_currentMission.fruits) do
        -- 1. Define o groundType do spray no terreno
        modifier:executeSet(groundType, filter1)
        -- 2. Seta o lime counter para o valor máximo (campo calcariado)
        modifier:executeSet(limeCounterMaxValue, filter1, filter2)
    end
    
    -- Também aplica em áreas cultivadas/aradas sem fruta
    modifier:executeSet(limeCounterMaxValue, filter1, filter2)
end
```

### 5.4. Consumo de Calcário na Colheita

**Arquivo:** `assets/dataS/scripts/utils/FSDensityMapUtil.lua` (linhas 183-186)

```lua
-- Na função cutFruitArea:
if desc.consumesLime and missionInfo.limeRequired then
    modifier:resetDensityMapAndChannels(detailId, g_currentMission.limeCounterFirstChannel, ...)
    _, _, limeTotalDelta, _ = modifier:executeAdd(-1, filter1)  -- Decrementa o counter
end
```

**O que acontece:** Quando um campo é colhido, se a fruta `consumesLime`, o lime counter é decrementado em 1. Com 1 bit, isso muda de 1→0, indicando que o campo precisa de calcário novamente.

### 5.5. Cálculo do limeFactor no Rendimento

```lua
-- Após a colheita:
if desc.growthRequiresLime and missionInfo.limeRequired then
    limeFactor = math.abs(limeTotalDelta) / numPixels
else
    limeFactor = 1  -- Se lime não é necessário, fator = 100%
end
```

---

## 6. SISTEMA DE DISPLAY E HUD

### 6.1. FieldInfoDisplay — Informação ao Olhar para o Campo

**Arquivo:** `assets/dataS/scripts/gui/hud/FieldInfoDisplay.lua`

```lua
FieldInfoDisplay.INFO_TYPE = {
    LIME_STATE = 7,          -- Slot de informação nº 7
}
FieldInfoDisplay.LIME_REQUIRED_THRESHOLD = 0.25  -- 25% dos pixels sem lime = mostrar aviso

function FieldInfoDisplay:setLimeRequired(isRequired)
    if isRequired and g_currentMission.missionInfo.limeRequired then
        limeRow.leftText = "Precisa de calcário"  -- ui_growthMapNeedsLime
    end
end

function FieldInfoDisplay:onFieldDataUpdateFinished(data)
    -- Quando o jogador olha para um campo:
    self:setLimeRequired(0.25 < data.needsLimeFactor)
end
```

### 6.2. MapOverlayGenerator — Visualização no Mapa de Solo

**Arquivo:** `assets/dataS/scripts/gui/base/MapOverlayGenerator.lua`

```lua
-- Índice do estado de solo "Precisa de Lime":
MapOverlayGenerator.SOIL_STATE_INDEX = {
    NEEDS_LIME = GS_IS_MOBILE_VERSION and 2 or 4  -- Diferente índice por plataforma
}

-- Cor no mapa:
MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME = {
    [false] = { 0.0815, 0.6584, 0.4198, 1 },  -- Verde-azulado (modo normal)
    [true]  = { 0.6795, 0.6867, 0.7231, 1 }   -- Cinza claro (modo daltônico)
}

-- Renderização (APENAS fora do mobile):
if not GS_IS_MOBILE_VERSION and soilStateFilter[NEEDS_LIME] then
    setDensityMapVisualizationOverlayStateColor(...)
end
```

**Nota:** A verificação `not GS_IS_MOBILE_VERSION` impede a exibição do overlay de lime no mapa na versão mobile.

---

## 7. FILL TYPE E OBJETOS FÍSICOS

### 7.1. Fill Type LIME

**Arquivo:** `assets/data/maps/maps_fillTypes.xml` (linhas 209-213)

```xml
<fillType name="LIME" title="$l10n_fillType_lime" showOnPriceTable="false" pricePerLiter="0.225">
    <image hud="$dataS2/menu/hud/fillTypes/hud_fill_lime.png" 
           hudSmall="$dataS2/menu/hud/fillTypes/hud_fill_lime_sml.png" />
    <physics massPerLiter="1.2" maxPhysicalSurfaceAngle="15" />
    <pallet filename="$data/objects/bigBagContainer/bigBagContainerLime.xml" />
</fillType>
```

**Nota:** O fill type LIME **está ativo** (não comentado). O preço é 0.225/litro, massa 1.2 kg/litro.

### 7.2. Texturas de Calcário (Existem!)

As texturas físicas do calcário estão presentes:
- `assets/data/fillPlanes/lime_diffuse.png` — Textura difusa
- `assets/data/fillPlanes/lime_normal.png` — Normal map
- `assets/data/fillPlanes/lime_specular.png` — Specular map
- `assets/data/fillPlanes/distance/limeDistance_diffuse.png` — Textura de distância
- `assets/dataS2/menu/hud/fillTypes/hud_fill_lime.png` — Ícone HUD
- `assets/dataS2/menu/hud/fillTypes/hud_fill_lime_sml.png` — Ícone HUD pequeno

### 7.3. Density Map Height Type para Lime

**Arquivo:** `assets/data/maps/maps_densityMapHeightTypes.xml` (linhas 48-51)

```xml
<densityMapHeightType fillTypeName="lime" maxSurfaceAngle="20" fillToGroundScale="1.0" allowsSmoothing="false">
    <collision scale="1.0" baseOffset="0.05" minOffset="0.0" maxOffset="0.05" />
    <textures diffuse="$data/fillPlanes/lime_diffuse.png" 
              normal="$data/fillPlanes/lime_normal.png" 
              distance="$data/fillPlanes/distance/limeDistance_diffuse.png" />
</densityMapHeightType>
```

---

## 8. VEÍCULOS E EQUIPAMENTOS

### 8.1. Sprayer.lua — Suporte ao FillType LIME

**Arquivo:** `assets/dataS/scripts/vehicles/specializations/Sprayer.lua` (linha 295)

```lua
elseif (fillType == FillType.FERTILIZER or fillType == FillType.LIQUIDFERTILIZER 
    or fillType == FillType.HERBICIDE or fillType == FillType.LIME 
    or fillType == FillType.UNKNOWN and (...)) 
    and g_currentMission.missionInfo.helperBuyFertilizer then
```

O código do Sprayer já reconhece `FillType.LIME` para compra automática por helpers.

### 8.2. Tutorial SoilCare — Veículo de Calcário

**Arquivo:** `assets/dataS/scripts/tutorials/TutorialSoilCare.lua` (linhas 53-55)

```lua
-- Veículo usado no tutorial de calcário:
self:addLoadVehicleToList(vehicles, "data/vehicles/bredal/K165/K165.xml", ...)
-- Bredal K165 = espalhador de calcário
```

O tutorial carrega o espalhador com `FillType.LIME` e define o campo como precisando de calcário.

### 8.3. BigBag de Calcário

**Arquivo:** `assets/dataS/scripts/FSBaseMission.lua` (linha 4132)
```lua
LIME = "$data/objects/bigBagContainer/bigBagContainerLime.xml",
```

### 8.4. BuyingStation — Compra de Calcário

**Arquivo:** `assets/dataS/scripts/objects/BuyingStation.lua`
```lua
if fillType == FillType.LIME then
    return self.incomeNameLime  -- Categoria de despesa: "other"
end
```

---

## 9. FIELD JOBS (MISSÕES DE CAMPO)

### 9.1. MissionManager — Cálculo do limeFactor para Missões

**Arquivo:** `assets/dataS/scripts/fieldJobs/MissionManager.lua`
```lua
local limeFactor = FieldUtil.getLimeFactor(field)
-- Usado para determinar se uma missão pode rodar e quanto pagar
```

### 9.2. FieldUtil.getLimeFactor

**Arquivo:** `assets/dataS/scripts/fieldJobs/FieldUtil.lua` (linhas 67-80)
```lua
function FieldUtil.getLimeFactor(field)
    local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)
    if fruitDesc ~= nil and not fruitDesc.growthRequiresLime 
       or not g_currentMission.missionInfo.limeRequired then
        return 1  -- Sem penalidade
    end
    -- Lê o density map para calcular a proporção de pixels com lime
    local _, numPixels, totalPixels = FieldUtil.limeModifier:executeGet(...)
    return numPixels / totalPixels
end
```

### 9.3. Console Commands com Lime

**Arquivo:** `assets/dataS/scripts/fieldJobs/FieldManager.lua`
```
gsSetFieldFruit fieldId fruitName [growthState] [groundLayer] [fertilizerState] [plowingState] [weedState] [limeState]
gsSetFieldFruitAll fruitName [growthState] [...] [limeState]
gsSetFieldGround fieldIndex groundName [...] [limeState]
gsSetFieldGroundAll groundName [...] [limeState]
```

---

## 10. LOCALIZAÇÃO (Português)

**Arquivo:** `assets/dataS/l10n_pt.xml`

| Chave | Tradução PT |
|-------|-------------|
| `fillType_lime` | Cal |
| `function_bigBagLime` | Os Bigbags são usados para reabastecer os pulverizadores de calcário. |
| `setting_limeRequired` | Cal necessário |
| `shopItem_bigBagLime` | Bigbag de calcário |
| `shopItem_limeStation` | Estação de cal |
| `station_lime` | Estação de cal |
| `toolTip_limeRequired` | Define se você precisa de espalhar cal periodicamente... |
| `tutorial_soilCare_text_welcomeLime` | Após três ciclos de colheita, o teu campo vai precisar de cal. |
| `tutorial_soilCare_text_finishedLime` | Ótimo! |
| `ui_growthMapNeedsLime` | Precisa de calcário |

---

## 11. RESUMO DAS ALTERAÇÕES PARA ATIVAR CALCÁRIO NO FS20

### Alterações OBRIGATÓRIAS:

| # | Arquivo | Alteração | Impacto |
|---|---------|-----------|---------|
| 1 | `assets/data/maps/maps_sprayTypes.xml` | **Descomentar** a linha do LIME spray type | Registra LIME como tipo de spray válido |
| 2 | `assets/dataS/platformSettings.xml` | Mudar `useLimeCounter` para `true` no bloco mobile | Ativa os bits de counter no density map |
| 3 | `assets/dataS/platformSettings.xml` | Mudar `harvestScaleRation` para incluir lime no bloco mobile | Calcário afeta rendimento da colheita |

### Alterações RECOMENDADAS:

| # | Arquivo | Alteração | Impacto |
|---|---------|-----------|---------|
| 4 | `assets/dataS/storeItems.xml` | Descomentar as limeStation entries | Estações de calcário na loja |
| 5 | `assets/dataS/scripts/gui/base/MapOverlayGenerator.lua` | Remover check `not GS_IS_MOBILE_VERSION` para NEEDS_LIME | Overlay de "precisa de calcário" no mapa de solo |

### O que JÁ FUNCIONA sem alteração:

- Fill type LIME com preço, textura e ícone HUD
- Texturas de calcário (diffuse, normal, specular, distance)
- Density map height type para visualização de pilhas de lime
- Scripts Lua completos (updateLimeArea, cutFruitArea com consumo de lime, etc.)
- Configuração por tipo de fruta (`growthRequiresLime`, `consumesLime`)
- FieldInfoDisplay para mostrar "Precisa de calcário" no HUD
- Savegame settings (limeRequired ON/OFF)
- Console commands com parâmetro limeState
- Suporte do Sprayer a FillType.LIME
- Tutorial SoilCare com etapa de calcário
- BigBag de calcário
- BuyingStation reconhece LIME
- Sincronização multiplayer do setting limeRequired

---

## 12. FLUXO COMPLETO DO CALCÁRIO (Quando Ativado)

```
1. CAMPO NOVO/COLHIDO
   └── limeCounter = 0 (precisa de calcário)

2. JOGADOR APLICA CALCÁRIO (usando espalhador + FillType.LIME)
   └── SprayTypeManager identifica type="LIME"
       └── FSDensityMapUtil.updateSprayArea() detecta desc.isLime
           └── FSDensityMapUtil.updateLimeArea()
               └── Seta limeCounter = limeCounterMaxValue (1)
               └── Seta groundType do spray = 4

3. CAMPO COM CALCÁRIO
   └── limeCounter = 1 (OK)
   └── HUD mostra: sem aviso
   └── Mapa de solo: não destaca esse campo

4. COLHEITA
   └── FSDensityMapUtil.cutFruitArea()
       └── Se consumesLime == true:
           └── limeCounter -= 1 (volta a 0)
       └── limeFactor = limeCounter_delta / numPixels
       └── getHarvestScaleMultiplier() inclui +15% se limeFactor = 1

5. PÓS-COLHEITA
   └── limeCounter = 0 (precisa de calcário novamente)
   └── HUD mostra: "Precisa de calcário" (se needsLimeFactor > 0.25)
   └── Mapa de solo: destaca em cor verde-azulado/cinza

6. CICLO REPETE → Volta ao passo 2
```

---

## 13. OBSERVAÇÕES TÉCNICAS IMPORTANTES

1. **1 bit de lime counter** = o sistema é binário (0 ou 1). Na versão PC/Console com mais bits, poderia ter múltiplos ciclos antes de precisar de calcário novamente.

2. **groundType=4** para LIME no sprayTypes é único — não conflita com fertilizer (1), manure (2), liquidmanure/digestate (3).

3. **A versão mobile tem verificações `GS_IS_MOBILE_VERSION`** espalhadas no código que podem precisar de remoção/ajuste além das listadas acima, principalmente no `MapOverlayGenerator.lua`.

4. **O veículo Bredal K165** (`data/vehicles/bredal/K165/K165.xml`) é o espalhador de calcário usado no tutorial — precisa estar disponível na loja para o jogador usar.

5. **A configuração `limeRequired`** é um toggle in-game — mesmo ativando o sistema, o jogador pode desligar nas configurações do savegame. Quando desligado, `limeFactor` retorna 1 automaticamente (sem penalidade).
