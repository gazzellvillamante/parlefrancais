import Foundation

private func p(_ french: String, _ english: String, tip: String? = nil) -> Phrase {
    Phrase(french: french, english: english, tip: tip)
}

enum PhraseLibrary {
    static let units: [LessonUnit] = [
        // MARK: Beginner
        LessonUnit(id: "greetings", title: "Greetings", subtitle: "Hello, goodbye and politeness",
                   icon: "hand.wave", level: .beginner, phrases: [
            p("Bonjour !", "Hello! / Good morning!", tip: "The 'n' is not pronounced: the 'on' is a nasal vowel. Say 'bon' through your nose."),
            p("Bonsoir.", "Good evening."),
            p("Salut, ça va ?", "Hi, how's it going?", tip: "Raise your voice at the end to make it a question."),
            p("Ça va bien, merci.", "I'm fine, thanks."),
            p("Comment allez-vous ?", "How are you? (formal)", tip: "Liaison: the silent 't' of 'comment' links to 'allez' → 'comman-t-allez'."),
            p("Enchanté.", "Nice to meet you."),
            p("Au revoir !", "Goodbye!", tip: "Natives often swallow the 'e': 'au r'voir'."),
            p("À bientôt !", "See you soon!"),
            p("Bonne journée !", "Have a good day!", tip: "'Bonne' is not nasal: the double 'n' is pronounced, like 'bun'."),
            p("Merci beaucoup.", "Thank you very much.", tip: "'Beaucoup' ends in an 'oo' sound. The 'p' is silent."),
            p("De rien.", "You're welcome."),
            p("S'il vous plaît.", "Please."),
        ]),
        LessonUnit(id: "introductions", title: "Introducing yourself", subtitle: "Name, age, where you live",
                   icon: "person.crop.circle", level: .beginner, phrases: [
            p("Je m'appelle Marie.", "My name is Marie."),
            p("Comment tu t'appelles ?", "What's your name?"),
            p("J'habite à Paris.", "I live in Paris.", tip: "The 'h' in 'habite' is silent, so 'je' becomes 'j''."),
            p("Je viens des États-Unis.", "I come from the United States.", tip: "Liaison: 'des‿États' sounds like 'dé-zé-ta'."),
            p("J'ai vingt-cinq ans.", "I'm twenty-five years old.", tip: "'Vingt' sounds like 'vin'. Link 'cinq ans' → 'cin-kan'."),
            p("Je suis étudiant.", "I'm a student."),
            p("Je parle un peu français.", "I speak a little French."),
            p("J'apprends le français.", "I'm learning French."),
            p("Je ne comprends pas.", "I don't understand."),
            p("Pouvez-vous répéter, s'il vous plaît ?", "Could you repeat that, please?"),
            p("Parlez plus lentement, s'il vous plaît.", "Speak more slowly, please."),
        ]),
        LessonUnit(id: "numbers", title: "Numbers", subtitle: "Count from one to a thousand",
                   icon: "number", level: .beginner, phrases: [
            p("un, deux, trois, quatre, cinq", "1, 2, 3, 4, 5"),
            p("six, sept, huit, neuf, dix", "6, 7, 8, 9, 10", tip: "The final 'x' of 'six' and 'dix' sounds like 's' when the number stands alone."),
            p("onze, douze, treize, quatorze, quinze", "11, 12, 13, 14, 15"),
            p("seize, dix-sept, dix-huit, dix-neuf, vingt", "16, 17, 18, 19, 20"),
            p("trente, quarante, cinquante, soixante", "30, 40, 50, 60", tip: "'Soixante' is 'swa-sant': the 'x' sounds like 's'."),
            p("soixante-dix, quatre-vingts, quatre-vingt-dix", "70, 80, 90", tip: "70 = 60+10, 80 = 4×20, 90 = 4×20+10."),
            p("cent, mille", "100, 1000"),
        ]),
        LessonUnit(id: "essentials", title: "Everyday essentials", subtitle: "Words you'll use every day",
                   icon: "star", level: .beginner, phrases: [
            p("Oui, bien sûr.", "Yes, of course.", tip: "'Sûr' uses the French 'u': lips rounded, tongue forward."),
            p("Excusez-moi.", "Excuse me."),
            p("Pardon.", "Sorry."),
            p("Où sont les toilettes ?", "Where are the restrooms?"),
            p("Je ne sais pas.", "I don't know."),
            p("C'est combien ?", "How much is it?"),
            p("D'accord.", "Okay."),
            p("Pas de problème.", "No problem."),
            p("Il fait beau aujourd'hui.", "The weather is nice today."),
            p("J'ai faim.", "I'm hungry."),
            p("J'ai soif.", "I'm thirsty."),
        ]),

        // MARK: Elementary
        LessonUnit(id: "cafe", title: "At the café", subtitle: "Order food and drinks",
                   icon: "cup.and.saucer", level: .elementary, phrases: [
            p("Je voudrais un café, s'il vous plaît.", "I'd like a coffee, please."),
            p("Un croissant et un jus d'orange.", "A croissant and an orange juice.", tip: "The final 't' of 'croissant' is silent."),
            p("L'addition, s'il vous plaît.", "The bill, please."),
            p("Est-ce que je peux payer par carte ?", "Can I pay by card?"),
            p("Une table pour deux, s'il vous plaît.", "A table for two, please."),
            p("Qu'est-ce que vous recommandez ?", "What do you recommend?"),
            p("Je suis végétarien.", "I'm vegetarian."),
            p("C'était délicieux !", "It was delicious!"),
            p("Une carafe d'eau, s'il vous plaît.", "A jug of tap water, please."),
            p("Je vais prendre le plat du jour.", "I'll have the dish of the day."),
        ]),
        LessonUnit(id: "directions", title: "Getting around", subtitle: "Directions and transport",
                   icon: "map", level: .elementary, phrases: [
            p("Où est la gare ?", "Where is the train station?"),
            p("C'est loin d'ici ?", "Is it far from here?"),
            p("Tournez à gauche.", "Turn left."),
            p("Allez tout droit.", "Go straight ahead."),
            p("C'est à droite.", "It's on the right."),
            p("Un billet pour Lyon, s'il vous plaît.", "A ticket to Lyon, please."),
            p("À quelle heure part le train ?", "What time does the train leave?"),
            p("Je cherche la station de métro.", "I'm looking for the metro station."),
            p("Je suis perdu.", "I'm lost."),
            p("Pouvez-vous m'aider ?", "Can you help me?"),
        ]),
        LessonUnit(id: "shopping", title: "Shopping", subtitle: "Prices, sizes and paying",
                   icon: "bag", level: .elementary, phrases: [
            p("Je regarde seulement, merci.", "I'm just looking, thanks."),
            p("Vous avez ça en plus grand ?", "Do you have this in a bigger size?"),
            p("Je peux l'essayer ?", "Can I try it on?"),
            p("Ça coûte combien ?", "How much does it cost?"),
            p("C'est trop cher.", "It's too expensive."),
            p("Je le prends.", "I'll take it."),
            p("Un kilo de pommes, s'il vous plaît.", "A kilo of apples, please."),
            p("Avez-vous un sac ?", "Do you have a bag?"),
            p("C'est tout, merci.", "That's all, thanks."),
        ]),
        LessonUnit(id: "time", title: "Time & plans", subtitle: "Days, hours and making plans",
                   icon: "clock", level: .elementary, phrases: [
            p("Quelle heure est-il ?", "What time is it?", tip: "Link 'heure est-il' → 'heu-rè-til'."),
            p("Il est huit heures.", "It's eight o'clock.", tip: "Liaison: 'huit‿heures' → 'hui-teur'."),
            p("On se voit demain ?", "Shall we meet tomorrow?"),
            p("Je suis libre ce soir.", "I'm free tonight."),
            p("Qu'est-ce que tu fais ce week-end ?", "What are you doing this weekend?"),
            p("J'ai rendez-vous à midi.", "I have an appointment at noon."),
            p("Je suis en retard, désolé.", "I'm late, sorry."),
            p("lundi, mardi, mercredi, jeudi, vendredi", "Monday to Friday"),
            p("samedi et dimanche", "Saturday and Sunday"),
            p("À tout à l'heure !", "See you later (today)!"),
        ]),

        // MARK: Intermediate
        LessonUnit(id: "smalltalk", title: "Small talk", subtitle: "Keep a conversation going",
                   icon: "bubble.left.and.bubble.right", level: .intermediate, phrases: [
            p("Qu'est-ce que tu fais dans la vie ?", "What do you do for a living?"),
            p("Ça fait longtemps que tu habites ici ?", "Have you lived here long?"),
            p("J'adore cette ville.", "I love this city."),
            p("Tu as des frères et sœurs ?", "Do you have brothers and sisters?"),
            p("Quel temps fait-il chez toi ?", "What's the weather like where you live?"),
            p("Je suis venu en vacances.", "I came on vacation."),
            p("Qu'est-ce que tu aimes faire le week-end ?", "What do you like to do at the weekend?"),
            p("C'est vraiment intéressant.", "That's really interesting."),
            p("Je n'en ai aucune idée.", "I have no idea."),
            p("On pourrait prendre un verre un de ces jours.", "We could grab a drink one of these days."),
        ]),
        LessonUnit(id: "feelings", title: "Feelings & opinions", subtitle: "Say what you think and feel",
                   icon: "heart", level: .intermediate, phrases: [
            p("Je suis très content.", "I'm very happy."),
            p("Je suis un peu fatigué.", "I'm a bit tired."),
            p("À mon avis, c'est une bonne idée.", "In my opinion, it's a good idea.", tip: "Liaison: 'mon‿avis' → 'mo-na-vi'."),
            p("Je suis d'accord avec toi.", "I agree with you."),
            p("Je ne suis pas sûr.", "I'm not sure."),
            p("Ça m'énerve !", "That annoys me!"),
            p("Ça me fait plaisir.", "That makes me happy. / My pleasure."),
            p("J'ai hâte de te voir.", "I can't wait to see you.", tip: "'Hâte' has an aspirated h: no liaison, no elision — but still no 'h' sound."),
            p("Tu me manques.", "I miss you. (literally: you are missing to me)"),
            p("Ce n'est pas grave.", "It's no big deal."),
        ]),
        LessonUnit(id: "tricky", title: "Tricky sounds", subtitle: "Sentences packed with French sounds",
                   icon: "waveform", level: .intermediate, phrases: [
            p("Il y a une grenouille dans la rivière.", "There's a frog in the river.", tip: "Practise the French R from the back of the throat."),
            p("Tu as vu la rue ?", "Did you see the street?", tip: "Every 'u' here is the French [y]: say 'ee' with rounded lips."),
            p("Où est tout le monde ?", "Where is everyone?", tip: "'Où' and 'tout' use the [u] sound, like English 'oo'."),
            p("Un bon vin blanc.", "A good white wine.", tip: "Four nasal vowels in a row. Don't pronounce any 'n'."),
            p("Je veux deux œufs.", "I want two eggs.", tip: "'Œufs' in the plural sounds like 'eu' — the 'fs' is silent."),
            p("Le cheval et le chien.", "The horse and the dog."),
            p("Une bouteille de vin rouge.", "A bottle of red wine."),
            p("Il pleut à Bordeaux.", "It's raining in Bordeaux."),
            p("Mon grand frère prend le train.", "My big brother takes the train."),
            p("Les enfants sont arrivés.", "The children have arrived.", tip: "Two liaisons: 'les‿enfants' (z) and 'sont‿arrivés' (t)."),
        ]),

        // MARK: Advanced
        LessonUnit(id: "native", title: "Natural speech", subtitle: "Sound like a native speaker",
                   icon: "bolt", level: .advanced, phrases: [
            p("Qu'est-ce que tu veux faire ce soir ?", "What do you want to do tonight?", tip: "Fast speech: 'Kès-keu tu veux…'"),
            p("Il faut que j'y aille.", "I have to go."),
            p("Je ne sais pas trop.", "I'm not really sure."),
            p("T'inquiète, c'est pas grave.", "Don't worry, it's fine.", tip: "Casual French often drops the 'ne'."),
            p("Tu veux qu'on se retrouve où ?", "Where do you want to meet?"),
            p("Je viens de finir mon travail.", "I just finished work."),
            p("On verra bien.", "We'll see."),
            p("Ça dépend de toi.", "It depends on you."),
            p("Il y a du monde aujourd'hui !", "It's crowded today!"),
            p("Je m'en occupe.", "I'll take care of it."),
        ]),
        LessonUnit(id: "idioms", title: "Expressions", subtitle: "Colourful everyday idioms",
                   icon: "quote.bubble", level: .advanced, phrases: [
            p("Il pleut des cordes.", "It's raining cats and dogs."),
            p("J'ai le cafard.", "I'm feeling down."),
            p("Ce n'est pas la mer à boire.", "It's not that hard."),
            p("Je suis dans la lune.", "I'm daydreaming."),
            p("Ça coûte les yeux de la tête.", "It costs an arm and a leg.", tip: "Liaison: 'les‿yeux' → 'lé-zyeu'."),
            p("Il m'a posé un lapin.", "He stood me up."),
            p("J'ai d'autres chats à fouetter.", "I have bigger fish to fry."),
            p("Ça ne me dit rien.", "That doesn't ring a bell. / I don't feel like it."),
            p("C'est la fin des haricots !", "It's all over!", tip: "Aspirated h: no liaison in 'des haricots'."),
            p("Il ne faut pas pousser mémé dans les orties.", "Don't push your luck."),
        ]),
        LessonUnit(id: "twisters", title: "Tongue twisters", subtitle: "Virelangues to train your mouth",
                   icon: "sparkles", level: .advanced, phrases: [
            p("Les chaussettes de l'archiduchesse sont-elles sèches ?", "Are the archduchess's socks dry?"),
            p("Un chasseur sachant chasser doit savoir chasser sans son chien.", "A hunter who knows how to hunt must know how to hunt without his dog."),
            p("Ton thé t'a-t-il ôté ta toux ?", "Did your tea cure your cough?"),
            p("Je veux et j'exige d'exquises excuses.", "I want and demand exquisite apologies."),
            p("Trois tortues trottaient sur un trottoir très étroit.", "Three turtles trotted on a very narrow sidewalk."),
            p("Cinq gros rats grillent dans la grosse graisse grasse.", "Five fat rats grill in the big greasy fat."),
            p("Si six scies scient six cyprès, six cent six scies scient six cent six cyprès.", "If six saws saw six cypresses, six hundred and six saws saw six hundred and six cypresses."),
        ]),
    ]

    static func units(for level: Level) -> [LessonUnit] {
        units.filter { $0.level == level }
    }

    /// Phrases used for the onboarding level check, easiest first.
    static let placementPhrases: [Phrase] = [
        p("Bonjour, je m'appelle Paul.", "Hello, my name is Paul."),
        p("Je voudrais un café, s'il vous plaît.", "I'd like a coffee, please."),
        p("Il y a une grenouille dans la rivière.", "There's a frog in the river."),
    ]

    static var allPhrases: [Phrase] { units.flatMap(\.phrases) }
}
