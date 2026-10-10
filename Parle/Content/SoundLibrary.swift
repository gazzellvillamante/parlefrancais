import Foundation

struct MinimalPair: Hashable {
    let a: String
    let b: String
}

struct SoundLesson: Identifiable, Hashable {
    enum Kind: String, CaseIterable {
        case vowel = "Vowels"
        case nasal = "Nasal vowels"
        case consonant = "Consonants"
        case linking = "Linking & rhythm"
    }

    let id: String
    let symbol: String
    let title: String
    let kind: Kind
    let explanation: String
    let howTo: [String]
    let examples: [Phrase]
    var pairs: [MinimalPair] = []
}

private func w(_ french: String, _ english: String) -> Phrase {
    Phrase(french: french, english: english)
}

enum SoundLibrary {
    static let lessons: [SoundLesson] = [
        // MARK: Vowels
        SoundLesson(
            id: "y", symbol: "[y]", title: "The French “u”", kind: .vowel,
            explanation: "This sound doesn't exist in English and is the one learners mix up most. Confusing it with “ou” changes the meaning: “tu” (you) vs “tout” (all).",
            howTo: [
                "Say “ee” as in “see”.",
                "Keep your tongue exactly there, pressed behind your lower teeth.",
                "Now round your lips tightly, as if to whistle.",
            ],
            examples: [w("tu", "you"), w("rue", "street"), w("vu", "seen"), w("une", "a / one"), w("sur", "on"), w("la lune", "the moon"), w("Tu as vu la rue ?", "Did you see the street?")],
            pairs: [MinimalPair(a: "tu", b: "tout"), MinimalPair(a: "rue", b: "roue"), MinimalPair(a: "vu", b: "vous"), MinimalPair(a: "dessus", b: "dessous")]
        ),
        SoundLesson(
            id: "u", symbol: "[u]", title: "The “ou” sound", kind: .vowel,
            explanation: "Written “ou”, it's close to English “oo” in “food”, but shorter and with lips pushed further forward.",
            howTo: [
                "Pull your tongue back.",
                "Push your rounded lips forward.",
                "Keep it short and pure — don't glide into a “w”.",
            ],
            examples: [w("tout", "all"), w("vous", "you"), w("nous", "we"), w("rouge", "red"), w("bonjour", "hello"), w("beaucoup", "a lot"), w("Où est tout le monde ?", "Where is everyone?")],
            pairs: [MinimalPair(a: "tout", b: "tu"), MinimalPair(a: "roue", b: "rue"), MinimalPair(a: "doux", b: "du")]
        ),
        SoundLesson(
            id: "eu", symbol: "[ø]", title: "Closed “eu”", kind: .vowel,
            explanation: "Written “eu” or “œu” at the end of a syllable. It's an “é” with rounded lips.",
            howTo: [
                "Say “é” (like “ay” without the glide).",
                "Keep the tongue there and round your lips.",
            ],
            examples: [w("deux", "two"), w("peu", "little"), w("bleu", "blue"), w("jeu", "game"), w("il pleut", "it's raining"), w("heureux", "happy")],
            pairs: [MinimalPair(a: "deux", b: "doux"), MinimalPair(a: "peu", b: "pou"), MinimalPair(a: "jeu", b: "joue")]
        ),
        SoundLesson(
            id: "oe", symbol: "[œ]", title: "Open “eu”", kind: .vowel,
            explanation: "The same “eu” spelling, but with the mouth more open, usually before a pronounced consonant: “peur”, “fleur”.",
            howTo: [
                "Say “è” as in “mère”.",
                "Round your lips while keeping the jaw open.",
            ],
            examples: [w("peur", "fear"), w("fleur", "flower"), w("sœur", "sister"), w("heure", "hour"), w("jeune", "young"), w("neuf", "nine")]
        ),
        SoundLesson(
            id: "e", symbol: "[e] / [ɛ]", title: "“é” vs “è”", kind: .vowel,
            explanation: "“é” is closed and tense, like “ay” in “say” but with no glide. “è”, “ê” and “ai” are more open, like “e” in “bed”.",
            howTo: [
                "For “é”, smile slightly and keep the jaw high.",
                "For “è”, drop the jaw a little.",
                "Never glide: hold one pure vowel.",
            ],
            examples: [w("été", "summer"), w("café", "coffee"), w("parler", "to speak"), w("mère", "mother"), w("très", "very"), w("fête", "party")],
            pairs: [MinimalPair(a: "les", b: "lait"), MinimalPair(a: "fée", b: "fait"), MinimalPair(a: "été", b: "était")]
        ),
        SoundLesson(
            id: "schwa", symbol: "[ə]", title: "The silent-ish “e”", kind: .vowel,
            explanation: "The “e” in “le”, “de”, “je”. It's often dropped entirely in everyday speech: “samedi” → “sam'di”, “je ne sais pas” → “j'sais pas”.",
            howTo: [
                "Relax your mouth and round your lips slightly.",
                "Keep it short — and feel free to drop it between consonants.",
            ],
            examples: [w("le", "the"), w("de", "of"), w("je", "I"), w("petit", "small"), w("demain", "tomorrow"), w("samedi", "Saturday")]
        ),

        // MARK: Nasal vowels
        SoundLesson(
            id: "an", symbol: "[ɑ̃]", title: "“an” / “en”", kind: .nasal,
            explanation: "Air flows through the nose and the mouth at the same time. The “n” or “m” is NOT pronounced — it just tells you the vowel is nasal.",
            howTo: [
                "Open your mouth as for “ah”, tongue low and back.",
                "Let air escape through your nose.",
                "Don't touch your tongue to the roof of your mouth (no “n”).",
            ],
            examples: [w("an", "year"), w("enfant", "child"), w("temps", "time"), w("dans", "in"), w("chambre", "bedroom"), w("vent", "wind")],
            pairs: [MinimalPair(a: "vent", b: "vin"), MinimalPair(a: "lent", b: "long"), MinimalPair(a: "temps", b: "ton")]
        ),
        SoundLesson(
            id: "on", symbol: "[ɔ̃]", title: "“on” / “om”", kind: .nasal,
            explanation: "A nasal “o” with tightly rounded lips. Contrast it with the plain “o” in “beau”.",
            howTo: [
                "Round your lips as for “oh”.",
                "Send the air through your nose.",
            ],
            examples: [w("bon", "good"), w("nom", "name"), w("maison", "house"), w("pont", "bridge"), w("monde", "world"), w("onze", "eleven")],
            pairs: [MinimalPair(a: "bon", b: "beau"), MinimalPair(a: "pont", b: "pot"), MinimalPair(a: "long", b: "lent")]
        ),
        SoundLesson(
            id: "in", symbol: "[ɛ̃]", title: "“in” / “ain” / “un”", kind: .nasal,
            explanation: "A nasal “è”. Most speakers in France pronounce “un” the same way.",
            howTo: [
                "Spread your lips slightly, as for “è”.",
                "Let the air go through your nose.",
            ],
            examples: [w("vin", "wine"), w("pain", "bread"), w("main", "hand"), w("un", "one"), w("bien", "well"), w("important", "important")],
            pairs: [MinimalPair(a: "vin", b: "vent"), MinimalPair(a: "pain", b: "pont"), MinimalPair(a: "main", b: "mon")]
        ),

        // MARK: Consonants
        SoundLesson(
            id: "r", symbol: "[ʁ]", title: "The French R", kind: .consonant,
            explanation: "Made at the back of the throat, close to the sound of a light gargle. The tip of the tongue does nothing.",
            howTo: [
                "Keep the tip of your tongue resting behind your lower front teeth.",
                "Raise the back of your tongue toward the soft palate.",
                "Push air through the narrow gap — a soft, raspy friction.",
                "Practise with “gare”, then “gr”, then “r” alone.",
            ],
            examples: [w("rouge", "red"), w("Paris", "Paris"), w("très", "very"), w("merci", "thank you"), w("gare", "station"), w("grand", "big"), w("Il y a une grenouille dans la rivière.", "There's a frog in the river.")]
        ),
        SoundLesson(
            id: "j", symbol: "[ʒ] / [ʃ]", title: "“j” and “ch”", kind: .consonant,
            explanation: "French “j” (and “g” before e/i) is the sound in “measure”. French “ch” is the English “sh”.",
            howTo: [
                "For [ʃ], say “sh” with rounded lips.",
                "For [ʒ], keep the same position and add your voice.",
            ],
            examples: [w("je", "I"), w("jour", "day"), w("manger", "to eat"), w("jardin", "garden"), w("chat", "cat"), w("chercher", "to look for")],
            pairs: [MinimalPair(a: "joue", b: "chou"), MinimalPair(a: "gens", b: "chant"), MinimalPair(a: "bouger", b: "boucher")]
        ),
        SoundLesson(
            id: "gn", symbol: "[ɲ]", title: "“gn”", kind: .consonant,
            explanation: "Like the “ny” in “canyon” or the Spanish “ñ”, said as one sound.",
            howTo: [
                "Press the middle of your tongue against the roof of your mouth.",
                "Release it into the following vowel.",
            ],
            examples: [w("montagne", "mountain"), w("campagne", "countryside"), w("gagner", "to win"), w("ligne", "line"), w("Espagne", "Spain"), w("champignon", "mushroom")]
        ),
        SoundLesson(
            id: "ill", symbol: "[j]", title: "“ill” and “y”", kind: .consonant,
            explanation: "“ill” after a vowel, or “ille” at the end of many words, sounds like the English “y” in “yes”. Exceptions: “ville”, “mille”, “tranquille” use an “l”.",
            howTo: [
                "Glide quickly from “ee” into the next sound.",
                "Don't pronounce any “l”.",
            ],
            examples: [w("fille", "girl"), w("famille", "family"), w("travailler", "to work"), w("soleil", "sun"), w("oreille", "ear"), w("payer", "to pay")],
            pairs: [MinimalPair(a: "fille", b: "ville")]
        ),
        SoundLesson(
            id: "silent", symbol: "∅", title: "Silent final letters", kind: .consonant,
            explanation: "Most final consonants are silent: “petit”, “grand”, “beaucoup”. The plural “-ent” on verbs is silent too. Final C, R, F and L are usually pronounced (think “CaReFuL”).",
            howTo: [
                "Stop the word on its last vowel sound.",
                "Exceptions to remember: “avec”, “sac”, “neuf”, “hôtel”, “bonjour”.",
            ],
            examples: [w("petit", "small"), w("grand", "big"), w("beaucoup", "a lot"), w("ils parlent", "they speak"), w("avec", "with"), w("neuf", "nine")]
        ),

        // MARK: Linking
        SoundLesson(
            id: "liaison", symbol: "‿", title: "Liaison", kind: .linking,
            explanation: "A normally silent final consonant is pronounced when the next word starts with a vowel or silent h. “s” and “x” become [z], “d” becomes [t].",
            howTo: [
                "Carry the consonant over to start the next word: “les‿amis” → “lé-za-mi”.",
                "Required after articles, pronouns and numbers: “les”, “des”, “nous”, “un”, “deux”.",
                "Never after “et”: “et‿un” has no liaison.",
            ],
            examples: [w("les amis", "the friends"), w("vous avez", "you have"), w("nous allons", "we go"), w("un petit ami", "a boyfriend"), w("deux heures", "two hours"), w("ils ont", "they have")],
            pairs: [MinimalPair(a: "ils sont", b: "ils ont"), MinimalPair(a: "nous savons", b: "nous avons")]
        ),
        SoundLesson(
            id: "enchainement", symbol: "⌒", title: "Enchaînement & rhythm", kind: .linking,
            explanation: "French flows as a chain of syllables with equal weight, stressing only the last syllable of each group. A pronounced final consonant slides onto the next vowel.",
            howTo: [
                "Give every syllable the same length — no strong stresses inside words.",
                "Lengthen only the final syllable of a phrase.",
                "Link: “elle‿a” → “è-la”, “avec‿elle” → “a-vè-kèl”.",
            ],
            examples: [w("elle a", "she has"), w("avec elle", "with her"), w("il est ici", "he is here"), w("une amie", "a friend"), w("Je suis américain.", "I'm American."), w("Tu viens ce soir ?", "Are you coming tonight?")]
        ),
    ]
}
