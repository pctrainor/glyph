# Glyph Translate — Language Corpus Research Prompts

## Overview
These prompts are designed for Gemini Deep Research to generate comprehensive linguistic data for Glyph Translate's offline phrasebook system. Each prompt targets a specific language family or region, focusing on practical conversational phrases, grammatical patterns, and cultural context.

## How to Use
1. Copy each prompt below into Gemini with Deep Research enabled
2. Save the output as structured JSON/markdown
3. The data feeds into both the web demo phrasebook (demoExperiences.ts) and the Swift TranslationService corpus

---

## Research Prompt 1: Indigenous South American Languages (Quechua, Aymara, Guarani)

```
I'm building an offline translation system for a mobile app. I need comprehensive conversational data for three indigenous South American languages: Quechua (Cusco/Southern dialect), Aymara, and Guarani (Paraguayan Jopará).

For EACH language, provide:

1. **Greeting & Farewell phrases** (20+): formal/informal, time-of-day specific, ceremonial
2. **Essential survival phrases** (30+): directions, emergency, medical, food/water, accommodation, transportation
3. **Numbers 1-100** with pronunciation guide
4. **Days of week, months, seasons** in both traditional calendar and Western equivalent
5. **Common conversational phrases** (50+): questions, responses, expressions of emotion, politeness markers
6. **Grammar cheat sheet**: 
   - Word order (SOV/SVO etc)
   - Evidentiality markers (especially Quechua's direct/reported/inferential)
   - Suffix/agglutination patterns with examples
   - Pronoun system
   - Verb conjugation for present/past/future with 5 common verbs
7. **Cultural context notes**: taboo topics, respectful address, regional variations
8. **Unique linguistic features**: concepts that don't translate to English
9. **Phonetic guide**: IPA transcription for all phrases
10. **Dialectal variations**: major regional differences to be aware of

Format as structured JSON with keys: { phrase_key, source_text, ipa, literal_translation, natural_translation, notes, formality_level }
```

---

## Research Prompt 2: Pacific & Oceanian Languages (Māori, Hawaiian, Samoan, Tongan, Fijian, Tahitian)

```
I'm building an offline translation system. I need comprehensive conversational data for six Polynesian/Oceanian languages: Te Reo Māori, ʻŌlelo Hawaiʻi, Gagana Sāmoa, Lea Fakatonga, Na Vosa Vakaviti (Fijian), and Reo Tahiti (Tahitian).

For EACH language, provide:

1. **Greeting systems** (15+ per language): including traditional greetings, spiritual/cultural greetings (e.g., Māori mihimihi, Hawaiian aloha variations)
2. **Essential phrases** (30+): navigation, weather, ocean/nature terminology (crucial for island cultures), food, family, respect terms
3. **Number systems** with any unique counting systems (e.g., traditional vs modern)
4. **Kinship terms**: family relationship vocabulary (these cultures have nuanced family terms)
5. **Nature vocabulary** (20+): ocean, sky, plants, animals — central to these cultures
6. **Cultural protocol phrases**: proper way to enter a marae/fale, ask permission, show respect to elders
7. **Grammar patterns**:
   - Particle systems (tense/aspect markers)
   - Possessive classes (a-class vs o-class in Polynesian languages)
   - Reduplication patterns
   - Directional particles
8. **Cognate mapping**: show relationships between these languages (Proto-Polynesian roots)
9. **Pronunciation guide**: macron usage, glottal stops, vowel length importance
10. **Endangered status data**: number of speakers, revitalization efforts, resources available

Format as JSON: { phrase_key, source_text, pronunciation_guide, english, cultural_notes, is_formal }
```

---

## Research Prompt 3: Sub-Saharan African Languages (Yoruba, Igbo, Hausa, Zulu, Xhosa, Shona, Swahili, Amharic, Somali, Kinyarwanda)

```
I need comprehensive conversational translation data for ten African languages across different families:

**Niger-Congo**: Yoruba, Igbo, Zulu, Xhosa, Shona, Swahili, Kinyarwanda
**Afroasiatic**: Hausa, Amharic, Somali

For EACH language, provide:

1. **Greeting systems** (15+): morning/afternoon/evening, respect-based (elder/peer/younger), call-and-response patterns
2. **Tonal information** (for tonal languages): tone marks on all phrases, explanation of how tone changes meaning
3. **Essential conversation** (40+): introductions, market/shopping, directions, health, emotions, time
4. **Noun class systems** (for Bantu languages): explanation of all classes with examples
5. **Click consonants** (for Zulu/Xhosa): detailed phonetic description and practice words
6. **Ge'ez script guide** (for Amharic): character chart with pronunciations
7. **Proverbs & idioms** (10 per language): with cultural explanation
8. **Respect/honorific systems**: age-based, title-based, gender-based address forms
9. **Grammar essentials**:
   - Verb conjugation patterns
   - Negation
   - Question formation
   - Possessives
   - Pluralization rules
10. **Market/trade phrases** (15+): bargaining, prices, quantities — practical commerce vocabulary
11. **Regional dialect notes**: major variations within each language

Format as JSON: { phrase_key, source_text, tone_marks, ipa, english, grammar_notes, cultural_context }
```

---

## Research Prompt 4: North American Indigenous Languages (Cherokee, Navajo, Ojibwe, Inuktitut)

```
I need conversational data for four North American indigenous languages: Cherokee (ᏣᎳᎩ ᎦᏬᏂᎯᏍᏗ), Navajo (Diné bizaad), Ojibwe (Anishinaabemowin), and Inuktitut (ᐃᓄᒃᑎᑐᑦ).

For EACH language, provide:

1. **Writing system guide**:
   - Cherokee syllabary: complete chart with pronunciations
   - Navajo: special characters and tone marks
   - Ojibwe: double-vowel orthography system
   - Inuktitut: syllabics chart (ᐃ ᐱ ᑎ etc.) with roman transliteration
2. **Essential greetings & phrases** (25+): seasonal greetings, clan-based introductions where relevant
3. **Nature/land vocabulary** (30+): animals, plants, weather, landforms, directions (these are linguistically rich domains)
4. **Polysynthetic word structures**: break down 10 complex words showing how morphemes combine
5. **Verb-centric grammar**:
   - How verbs encode subject, object, tense, aspect, mode
   - Navajo classifier stems
   - Cherokee pronominal prefixes
   - Ojibwe animate/inanimate noun classes
   - Inuktitut ergative-absolutive patterns
6. **Kinship systems**: detailed family terms (many have no English equivalent)
7. **Counting systems** (1-20 minimum)
8. **Ceremonial/respectful language**: appropriate vs inappropriate contexts for learners
9. **Dialectal information**: major regional variants
10. **Learning resources**: recommended materials, apps, community programs
11. **Speaker population & status**: current vitality data

Format as JSON: { phrase_key, native_script, romanized, ipa, english, morpheme_breakdown, cultural_sensitivity_notes }
```

---

## Research Prompt 5: Celtic & European Minority Languages (Welsh, Irish, Scottish Gaelic, Breton, Basque)

```
I need comprehensive conversational data for five European minority/endangered languages: Welsh (Cymraeg), Irish (Gaeilge), Scottish Gaelic (Gàidhlig), Breton (Brezhoneg), and Basque (Euskara).

For EACH language, provide:

1. **Mutation systems** (for Celtic languages):
   - Complete lenition/nasalization/aspiration tables
   - When each mutation is triggered
   - Examples in conversational context
2. **Essential phrases** (35+): greetings, directions, shopping, dining, emergency, weather, emotions
3. **Counting systems**:
   - Welsh vigesimal (base-20) system
   - Irish traditional vs simplified counting
   - Basque number system
4. **Verb systems**:
   - Celtic conjugated prepositions
   - Irish/Welsh verbal noun constructions
   - Basque auxiliary verb system + ergative case
   - Breton verb mutations
5. **VSO word order** (Celtic languages): pattern explanation with 20 example sentences
6. **Basque ergative-absolutive case system**: complete case chart with examples
7. **Formal/informal address**: tu/vous equivalents, dialectal preferences
8. **Regional dialects**:
   - Irish: Connacht, Munster, Ulster differences
   - Welsh: North vs South
   - Basque: dialect continuum
9. **Idiomatic expressions** (10+ per language): with cultural context
10. **Pronunciation guides**: Welsh ll and dd, Irish broad/slender consonants, Basque tx/tz/ts
11. **Revitalization status**: speaker numbers, education programs, media availability

Format as JSON: { phrase_key, source_text, ipa, english, mutation_info, dialect_notes, formality }
```

---

## Research Prompt 6: Caucasian & Central Asian Languages (Georgian, Armenian, Azerbaijani, Kazakh, Uzbek, Mongolian)

```
I need conversational translation data for six languages spanning the Caucasus and Central Asia: Georgian (ქართული), Armenian (Հայերեն), Azerbaijani (Azərbaycan), Kazakh (Қазақ тілі), Uzbek (Oʻzbek tili), and Mongolian (Монгол хэл).

For EACH language, provide:

1. **Script guides**:
   - Georgian Mkhedruli alphabet (33 letters): chart with pronunciations
   - Armenian alphabet (38 letters): chart with pronunciations
   - Kazakh Latin + Cyrillic dual script
   - Mongolian Cyrillic (and traditional script basics)
2. **Essential phrases** (30+): greetings, hospitality phrases (extremely important in these cultures), directions, shopping, dining
3. **Hospitality vocabulary** (15+): these cultures have rich guest/host traditions — toasting, offering food, welcoming guests
4. **Numbers 1-100** with pronunciation
5. **Grammar essentials**:
   - Georgian verb system (screeves, person agreement)
   - Armenian Eastern vs Western differences
   - Turkic vowel harmony (Azerbaijani, Kazakh, Uzbek)
   - Mongolian case system
   - Agglutinative patterns in all Turkic languages
6. **Polite address**: formal/informal, age-based respect terms, professional titles
7. **Food & drink vocabulary** (15+): regional cuisine terms, tea/coffee culture phrases
8. **Travel phrases** (15+): Silk Road terminology, landscape words, transportation
9. **Cultural phrases**: common proverbs, wedding/celebration terms, religious/secular greetings
10. **Dialectal notes**: major regional variations

Format as JSON: { phrase_key, native_script, romanized, ipa, english, grammar_notes, cultural_context }
```

---

## Research Prompt 7: Southeast Asian Languages (Khmer, Burmese, Lao, Sinhala, Nepali)

```
I need conversational data for five South/Southeast Asian languages that use unique scripts: Khmer (ខ្មែរ), Burmese (မြန်မာ), Lao (ລາວ), Sinhala (සිංහල), and Nepali (नेपाली).

For EACH language, provide:

1. **Script guides**:
   - Khmer: consonant chart (33), vowel symbols, subscript consonants
   - Burmese: circular script character chart, tone marks
   - Lao: consonant classes (high/mid/low), vowel chart
   - Sinhala: consonant + vowel chart with pronunciation
   - Nepali Devanagari: differences from Hindi usage
2. **Essential phrases** (30+): greetings, Buddhist/cultural greetings, directions, shopping, food, health
3. **Register/politeness systems**:
   - Khmer: royal/religious/common registers
   - Burmese: formal particles, age-based address
   - Lao: respect particles
   - Sinhala: formal/informal verb endings
   - Nepali: respect levels (tapāī/timi/ta)
4. **Tonal information** (for tonal languages): Burmese (4 tones), Lao (6 tones) — all phrases with tone marks
5. **Numbers 1-100** in both native and spoken form
6. **Buddhist/temple vocabulary** (10+): relevant for cultural visits
7. **Food vocabulary** (20+): essential cuisine terms, dietary needs
8. **Grammar essentials**:
   - Word order patterns
   - Classifier/counter words
   - Verb serialization
   - Negation patterns
   - Question markers
9. **Cultural etiquette phrases**: monastery visits, greeting monks, foot etiquette, head etiquette
10. **Romanization systems**: official transliteration for each language

Format as JSON: { phrase_key, native_script, romanized, ipa, english, tone_info, register_level, cultural_notes }
```

---

## Master Integration Prompt

```
I'm building Glyph Translate, an offline translation system for iOS. I have conversational data for 80+ languages. I need you to help me create a UNIVERSAL PHRASE KEY SYSTEM that maps concepts across all languages consistently.

Create a hierarchical phrase key structure:

1. **Category Level**: greeting, farewell, emergency, direction, food, health, emotion, commerce, nature, family, time, weather, politeness, question
2. **Specificity Level**: e.g., greeting.formal, greeting.informal, greeting.morning, greeting.cultural
3. **Variant Level**: e.g., greeting.formal.elder, greeting.formal.stranger

Provide:
- Complete key hierarchy (200+ unique phrase keys)
- English reference phrase for each key
- Priority rating (1-5) for offline inclusion
- Size estimate for embedding all languages
- Suggested compression strategy for QR delivery
- Apple Translation framework language code mapping for each of our 80+ target languages
- Which languages Apple supports natively vs which need our custom corpus

This will be the backbone of our translation dictionary system.
```

---

## Notes for Implementation

### Web Demo (QR-delivered HTML)
- The phrasebook dictionary in `demoExperiences.ts` uses the simplified phrase-key→translation mapping
- Limited to ~40 phrases per language due to QR size constraints
- Focus on highest-priority survival & greeting phrases

### Swift App (On-device)
- Apple's Translation framework handles supported languages natively
- Custom corpus data from this research fills gaps for unsupported languages
- `TranslationService.swift` stores the language catalog
- Full phrase database can be bundled as JSON in the app bundle

### Priority Languages for Research
1. **Critical** (endangered, <100k speakers): Cherokee, Navajo, Ojibwe, Hawaiian, Tahitian, Inuktitut
2. **High** (significant cultural value, limited digital resources): Quechua, Aymara, Guarani, Māori, Welsh, Irish, Scottish Gaelic, Breton, Basque
3. **Medium** (regional importance): Georgian, Armenian, Mongolian, Khmer, Burmese, Lao, Sinhala
4. **Standard** (well-resourced but included for completeness): Major world languages already well-served by Apple's framework
