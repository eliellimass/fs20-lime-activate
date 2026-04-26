# Comparação FS19 vs FS20 — groundShader e Density Map

## Resumo da Causa Raiz

A textura de calcário **não funciona** no FS20 porque o mapa (`mapUSM.i3d`) está configurado com um **density map de apenas 5 bits** — layout de plataforma mobile. O código Lua do desktop (`FSBaseMission.lua`) espera **12 bits** para armazenar todos os canais (spray type com 3 bits, ângulo com 2 bits, spray level, plow counter, lime counter).

**O valor `groundType=4` do calcário (binário `100`) precisa de 3 bits no canal de spray. Com apenas 1 bit disponível no density map, o valor 4 é truncado para 0 — resultado: nenhuma textura aparece.**

---

## Diferenças entre FS19 e FS20 no groundShader.xml

| Aspecto | FS19 | FS20 |
|---------|------|------|
| CustomShader version | 4 | 5 |
| Seção `<UvUsages>` | Não existe | Adicionada (7 entradas, incluindo groundLayerDiffuseMap) |
| LodLevel atributo | `subsequentPassForceMode="use"` | `alphaForceMode="use"` |
| `#define USE_GROUND_LAYER_COLOR` | Não existe (textura sempre ativa) | Adicionado como guard condicional (estava comentado) |
| Guard `TERRAIN_DETAIL_CHANNEL_2` | Sempre definido (se GPU_PROFILE permite) | Desativado quando USE_GROUND_LAYER_COLOR não está definido |
| POST_DIFFUSE_COLOR_FS | Textura sempre amostrada | Envolvido em `#if defined(USE_GROUND_LAYER_COLOR)` com fallback de escurecimento |
| FINAL_POS_FS guard | `#if !defined(DIFFUSE)` | `#if !defined(LIGHTING) \|\| defined(NOT_IN_ZFILL)` |
| FINAL_POS_FS sum | `globals.groundType * (noise...)` | `((globals.groundType > 0) + 0.0001) * (noise...)` |

### Conclusão do Shader
O código de amostragem de textura do shader é **funcionalmente idêntico** entre FS19 e FS20 quando `USE_GROUND_LAYER_COLOR` está ativado. O shader **não é** o problema.

---

## A VERDADEIRA Causa: Density Map no i3d

### Configuração ATUAL do i3d (mapUSM.i3d, linha 1065)
```xml
numDensityMapChannels="5"
combinedValuesChannels="0 3 0;4 1 0;3 1 1"
```

Layout de 5 bits (configuração MOBILE):
```
Bit 0-2: Ground Type (3 bits, valores 0-7) → blendMap.x
Bit 3:   Spray       (1 bit, apenas 0/1)  → blendMap2.x
Bit 4:   Angle       (1 bit, apenas 0/1)  → blendMap.y
```

### Configuração ESPERADA pelo Lua Desktop (FSBaseMission.lua, linhas 114-148)
```lua
terrainDetailType:  bits 0-2  (3 bits)  -- Ground Type
spray:              bits 3-5  (3 bits)  -- useSprayDiffuseMaps=true → 3 bits!
angle:              bits 6-7  (2 bits)  -- useTerrainDetailAngle=true → 2 bits
sprayLevel:         bits 8-9  (2 bits)  -- useMultipleSprayLevels=true
plowCounter:        bit 10    (1 bit)   -- usePlowCounter=true
limeCounter:        bit 11    (1 bit)   -- useLimeCounter=true
Total: 12 bits
```

### O Que Acontece com Cada Spray Type

| Spray Type | groundType | Binário | Bits 3-5 disponíveis | Valor armazenado (5 bits) | Textura |
|------------|------------|---------|----------------------|---------------------------|---------|
| Herbicide | 0 | 000 | bit 3=0 | 0 | - |
| Fertilizer | 1 | 001 | bit 3=1 | 1 | OK |
| Manure | 2 | 010 | bit 3=0, bit 4=1 | 2 (mas bit 4 é ângulo!) | Corrompido |
| LiquidManure | 3 | 011 | bit 3=1, bit 4=1 | 3 (bit 4 invade ângulo!) | Corrompido |
| **LIME** | **4** | **100** | **bit 3=0, bit 4=0, bit 5=NÃO EXISTE** | **0** | **ZERO = invisível!** |

**Para o calcário**: O valor 4 (binário `100`) tem o bit significativo na posição 5, que NÃO EXISTE no density map de 5 bits. Resultado: o shader recebe 0 no canal de spray → nenhuma textura de overlay aparece.

---

## Correções Necessárias (3 no total)

### Correção 1: groundShader.xml ✅ (já feita no PR #1)
```diff
-//#define USE_GROUND_LAYER_COLOR
+#define USE_GROUND_LAYER_COLOR
```

### Correção 2: maps_sprayTypes.xml ✅ (já feita no PR #1)
```diff
-<!--  <sprayType name="LIME" ... /> -->
+<sprayType name="LIME" litersPerSecond="0.0900" type="LIME" groundType="4" />
```

### Correção 3: mapUSM.i3d ❌ (NOVA — esta era a peça que faltava!)
```diff
-numDensityMapChannels="5"
-combinedValuesChannels="0 3 0;4 1 0;3 1 1"
+numDensityMapChannels="12"
+combinedValuesChannels="0 3 0;6 2 0;3 3 1"
```

Novo layout de 12 bits:
```
Bit 0-2:  Ground Type  (3 bits) → blendMap.x  (terreno base)
Bit 3-5:  Spray Type   (3 bits) → blendMap2.x (textura de overlay — fertilizer/manure/lime)
Bit 6-7:  Angle        (2 bits) → blendMap.y  (rotação de textura)
Bit 8-9:  Spray Level  (2 bits) — acesso Lua apenas
Bit 10:   Plow Counter (1 bit)  — acesso Lua apenas
Bit 11:   Lime Counter (1 bit)  — acesso Lua apenas
```

---

## Como o Pipeline Funciona (Após as 3 Correções)

1. **Jogador aplica calcário** → Lua chama `updateLimeArea(groundType=4)`
2. **Lua escreve** valor 4 nos bits 3-5 do density map (canal de spray, 3 bits)
3. **Engine renderiza** blendMap2.x = 4/7 ≈ 0.571
4. **Shader calcula** `arrayIndex = floor(0.571 * 8) = 4`
5. **Shader amostra** `groundLayerDiffuseMap` no índice `4 - 2 = 2`
6. **Textura** `groundLayer_diffuse-0-2.png` (calcário) é exibida no terreno

---

## IMPORTANTE: Requer Novo Jogo

A alteração de `numDensityMapChannels` de 5 para 12 muda o formato do density map. Saves existentes usam density map de 5 bits e **não são compatíveis** com o novo layout de 12 bits. É necessário **iniciar um novo jogo/save** após aplicar esta correção.

---

## Arquivos Distribuição

```
fix-groundShader/data/shaders/groundShader.xml     ← #define USE_GROUND_LAYER_COLOR ativado
fix-sprayTypes/data/maps/maps_sprayTypes.xml        ← LIME spray type descomentado
fix-densityMap/data/maps/mapUSM.i3d                  ← density map 12 bits + 3 bits spray
```
