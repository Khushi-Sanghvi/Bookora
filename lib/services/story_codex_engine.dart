import '../models/book.dart';
import '../models/story_codex.dart';
import 'book_metadata_sanitizer.dart';

class StoryCodexEngine {
  StoryCodexEngine._();

  static StoryCodex generateCodex(Book book, {String? fetchedSynopsis}) {
    final titleLower = book.title.toLowerCase();
    final authorLower = book.author.toLowerCase();
    final effectiveSynopsis = (fetchedSynopsis != null && fetchedSynopsis.trim().isNotEmpty)
        ? BookMetadataSanitizer.sanitizeSynopsis(fetchedSynopsis)
        : (book.description.trim().isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(book.description)
            ? BookMetadataSanitizer.sanitizeSynopsis(book.description)
            : book.effectiveBlurb);

    // 1. Curated Flagship Literature

    // God of Malice by Rina Kent
    if (titleLower.contains('god of malice')) {
      return StoryCodex(
        bookId: book.id,
        premise: "Killian Carson is a predator wrapped in sophisticated charm. When Glyndon King catches his attention, an all-consuming obsession pulls them into a dangerous game of control and desire.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "From USA Today bestselling author Rina Kent comes a new STANDALONE dark romance about a villain and his new obsession.\n\nI caught the attention of a monster.\nI didn't ask for it.\nDidn't even see it coming.\nBut the moment I do, it's too late.\n\nKillian Carson is a predator wrapped in sophisticated charm.\nHe's cold-blooded, manipulative, and savage.\nThe worst part is that no one sees his devil side.\nI do.\nAnd that will cost me everything.\n\nI run, but the thing about monsters?\nThey always chase.",
        setting: "Royal Elite & King's University, England",
        timePeriod: "Contemporary Dark Academia",
        atmosphere: "Ominous, Obsessive, Electrifying, Twisted",
        characters: const [
          CodexCharacter(
            name: "Killian Carson",
            role: "Male Lead / Obsessive Villain",
            archetype: "The Charming Sociopath",
            description: "A brilliant, cold-blooded medical student who hides a merciless devil beneath aristocratic refinement.",
            quote: "I run, but the thing about monsters? They always chase.",
          ),
          CodexCharacter(
            name: "Glyndon King",
            role: "Female Lead / Artist",
            archetype: "The Grieving Heiress",
            description: "An introverted art student carrying deep emotional wounds who inadvertently awakens Killian's dark obsession.",
            quote: "I caught the attention of a monster. I didn't ask for it.",
          ),
        ],
        tropes: const [
          "Morally Grey Hero",
          "Touch Her and Die",
          "Obsessive Stalker Romance",
          "Dark Academia",
          "Rival Universities",
        ],
        contentWarnings: const [
          "Dubious Consent / Non-Consensual Themes",
          "Psychological Manipulation",
          "Depictions of Suicidal Ideation",
        ],
        pacing: "Intense & Relentless",
        tone: "Dark, Seductive, Taboo",
        spiceLevel: 4.8,
        emotionalResonance: 4.0,
        suspenseLevel: 4.9,
        relationshipDynamics: const [
          "Killian & Glyndon: All-Consuming Predator-Prey Dynamic to Fierce Mutual Obsession",
        ],
      );
    }

    if (titleLower.contains('reminders of him') ||
        (titleLower.contains('kenna') && authorLower.contains('hoover'))) {
      return StoryCodex(
        bookId: book.id,
        premise: "A troubled young mother seeks redemption after serving five years in prison, fighting for a second chance to know her daughter.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Kenna Rowan returns to the town where it all went wrong, hoping to reunite with her four-year-old daughter. But the bridges she burned prove impossible to rebuild—except through Ledger Ward, the local bar owner with a secret connection to her past.",
        setting: "Shelby, Colorado",
        timePeriod: "Contemporary (2020s)",
        atmosphere: "Melancholic, Tender, Hopeful, Emotionally Raw",
        characters: const [
          CodexCharacter(
            name: "Kenna Rowan",
            role: "Protagonist",
            archetype: "The Penitent Mother",
            description: "A grieving mother determined to earn forgiveness and see her daughter Diem after 5 years of incarceration.",
            quote: "There is no excuse for what I did. But there is a reason.",
          ),
          CodexCharacter(
            name: "Ledger Ward",
            role: "Love Interest & Anchor",
            archetype: "The Reluctant Protector",
            description: "Scotty's best friend and Diem's de facto guardian who finds himself caught between loyalty to the past and compassion for Kenna.",
            quote: "It proves that if you love someone enough, you'll forgive them anything.",
          ),
          CodexCharacter(
            name: "Diem",
            role: "Catalyst",
            archetype: "The Innocent Child",
            description: "Kenna's spirited four-year-old daughter who is growing up without knowing her mother.",
          ),
        ],
        tropes: const [
          "Second Chances",
          "Forbidden Attraction",
          "Grief & Redemption",
          "Small Town Secrets",
        ],
        contentWarnings: const [
          "Car Accident & Death",
          "Incarceration Trauma",
          "Grief & Bereavement",
        ],
        pacing: "Introspective & Measured",
        tone: "Heart-wrenching yet Cathartic",
        spiceLevel: 2.5,
        emotionalResonance: 4.9,
        suspenseLevel: 3.2,
      );
    }

    if (titleLower.contains('it ends with us')) {
      return StoryCodex(
        bookId: book.id,
        premise: "Sometimes the one who loves you is the one who hurts you the most.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Lily hasn't always had it easy, but that's never stopped her from working hard for the life she wants. When she falls for neurosurgeon Ryle Kincaid, everything seems too good to be true—until Atlas Corrigan reappears.",
        setting: "Boston, Massachusetts",
        timePeriod: "Contemporary",
        atmosphere: "Intense, Bittersweet, Resilience-Driven",
        characters: const [
          CodexCharacter(
            name: "Lily Bloom",
            role: "Protagonist",
            archetype: "The Cycle Breaker",
            description: "Determined flower shop owner striving to overcome intergenerational trauma and build a healthy life.",
          ),
          CodexCharacter(
            name: "Ryle Kincaid",
            role: "Complex Partner",
            archetype: "The Driven Specialist",
            description: "A brilliant neurosurgeon with an aversion to relationships who struggles with suppressed aggression.",
          ),
          CodexCharacter(
            name: "Atlas Corrigan",
            role: "First Love & Haven",
            archetype: "The Unwavering Soulmate",
            description: "Lily's high school protector who built a thriving culinary career in Boston.",
          ),
        ],
        tropes: const [
          "First Love Reconnection",
          "Love Triangle Subversion",
          "Overcoming Domestic Trauma",
          "Found Family",
        ],
        contentWarnings: const [
          "Domestic Abuse & Violence",
          "Emotional Manipulation",
        ],
        pacing: "Fast-Paced & Gripping",
        tone: "Emotionally Challenging & Empowering",
        spiceLevel: 3.0,
        emotionalResonance: 4.8,
        suspenseLevel: 3.8,
      );
    }

    if (titleLower.contains('verity')) {
      return StoryCodex(
        bookId: book.id,
        premise: "Whose truth is the lie? A chilling psychological thriller of obsession, secrets, and an autobiography that should never have been read.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Lowen Ashleigh is hired to complete the remaining books of injured bestselling author Verity Crawford, only to discover an unfinished autobiography filled with horrifying admissions about Verity's family.",
        setting: "The Crawford Residence, Vermont",
        timePeriod: "Contemporary",
        atmosphere: "Claustrophobic, Unsettling, Gothic Noir",
        characters: const [
          CodexCharacter(
            name: "Lowen Ashleigh",
            role: "Protagonist",
            archetype: "The Unreliable Narrator",
            description: "A struggling writer tasked with ghostwriting a bestselling series, who uncovers a terrifying secret manuscript.",
          ),
          CodexCharacter(
            name: "Jeremy Crawford",
            role: "Enigmatic Partner",
            archetype: "The Grieving Patriarch",
            description: "Verity's husband who has endured the tragic loss of two daughters and cares for his incapacitated wife.",
          ),
        ],
        tropes: const [
          "Manuscript Within a Story",
          "Isolated Estate Mystery",
          "Psychological Mind Games",
        ],
        contentWarnings: const [
          "Child Harm / Infanticide Mention",
          "Abuse & Manipulation",
        ],
        pacing: "Relentless & Breathless",
        tone: "Dark, Twisted, Suspenseful",
        spiceLevel: 4.0,
        emotionalResonance: 3.8,
        suspenseLevel: 5.0,
      );
    }

    if (titleLower.contains('king of wrath')) {
      return StoryCodex(
        bookId: book.id,
        premise: "A ruthless billionaire forced into an engagement he never wanted with the daughter of his enemy.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Dante Russo thrives on control. But when blackmailed into marrying Vivian Lau, the daughter of his enemy, a fake engagement turns into an all-consuming war of desire.",
        setting: "Manhattan & The Hamptons, New York",
        timePeriod: "Contemporary High Society",
        atmosphere: "Opulent, High-Stakes, Seductive, Gilded",
        characters: const [
          CodexCharacter(
            name: "Dante Russo",
            role: "Male Lead",
            archetype: "The Cold Billionaire",
            description: "CEO of the Russo Group who refuses to be controlled, until Vivian challenges his ice-cold exterior.",
          ),
          CodexCharacter(
            name: "Vivian Lau",
            role: "Female Lead",
            archetype: "The Dutiful Heiress",
            description: "An elegant event planner trying to uphold her family's social standing while fighting her attraction to Dante.",
          ),
        ],
        tropes: const [
          "Enemies to Lovers",
          "Arranged / Forced Marriage",
          "Billionaire Romance",
          "Touch Her and Die",
          "Grumpy x Sunshine",
        ],
        contentWarnings: const [
          "Blackmail & Coercion",
          "Family Pressure",
        ],
        pacing: "Moderate & Simmering",
        tone: "Luxe, Fiery, Addictive",
        spiceLevel: 4.5,
        emotionalResonance: 4.2,
        suspenseLevel: 3.5,
      );
    }

    if (titleLower.contains('dune')) {
      return StoryCodex(
        bookId: book.id,
        premise: "A mythic and emotionally charged hero's journey, following Paul Atreides as he travels to the most dangerous planet in the universe to ensure the future of his family and people.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world where the only thing of value is the 'spice' melange, a drug capable of extending life and enhancing consciousness.",
        setting: "Arrakis (Dune), Caladan & Giedi Prime",
        timePeriod: "Far Future (Year 10,191 AG)",
        atmosphere: "Epic, Mythic, Political, Treacherous",
        characters: const [
          CodexCharacter(
            name: "Paul Atreides",
            role: "Male Lead / Protagonist",
            archetype: "The Kwisatz Haderach / Muad'Dib",
            description: "The young ducal heir of House Atreides who discovers prescient abilities and steps into a galactic messianic destiny.",
            quote: "Fear is the mind-killer. Fear is the little-death that brings total obliteration.",
          ),
          CodexCharacter(
            name: "Chani",
            role: "Female Lead / Love Interest",
            archetype: "The Fremen Warrior",
            description: "A fierce desert warrior and daughter of Liet-Kynes who becomes Paul's confidante and soulmate among the dunes.",
            quote: "Tell me of your home world, Usul.",
          ),
          CodexCharacter(
            name: "Lady Jessica",
            role: "Central Figure",
            archetype: "The Bene Gesserit Priestess",
            description: "Paul's mother and Duke Leto's concubine whose defiance of the Bene Gesserit Sisterhood alters the universe.",
          ),
          CodexCharacter(
            name: "Baron Vladimir Harkonnen",
            role: "Antagonist",
            archetype: "The Ruthless Schemer",
            description: "Head of House Harkonnen who orchestrates the brutal destruction of House Atreides with imperial backing.",
          ),
        ],
        tropes: const [
          "Chosen One Subversion",
          "Ecological Sci-Fi",
          "Interstellar Feudal Politics",
          "Ancient Prophecy",
        ],
        contentWarnings: const [
          "War & Violence",
          "Political Betrayal",
        ],
        pacing: "Epic & Methodical",
        tone: "Philosophical, Majestic, Haunting",
        spiceLevel: 1.0,
        emotionalResonance: 4.2,
        suspenseLevel: 4.8,
      );
    }

    if (titleLower.contains('court of thorns and roses') || titleLower.contains('acotar')) {
      return StoryCodex(
        bookId: book.id,
        premise: "When nineteen-year-old huntress Feyre kills a wolf in the woods, a beast-like creature arrives to demand retribution.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Dragged to a treacherous magical land she knows only from legends, Feyre discovers that her captor is Tamlin, a lethal, immortal faerie who once ruled their world.",
        setting: "Prythian (Spring & Night Courts) and the Mortal Lands",
        timePeriod: "High Fantasy Realm",
        atmosphere: "Enchanting, Dangerous, Sensual, Lush",
        characters: const [
          CodexCharacter(
            name: "Feyre Archeron",
            role: "Female Lead / Protagonist",
            archetype: "The Resilient Huntress",
            description: "A mortal huntress who braves the immortal realm of Prythian to save her human family and ends up breaking an ancient curse.",
            quote: "I was not a pet, not a doll, not an animal. I was a survivor, and I was strong.",
          ),
          CodexCharacter(
            name: "Rhysand",
            role: "Male Lead / Counterpart",
            archetype: "The High Lord of Night",
            description: "The most powerful High Lord in Prythian history, concealing a fiercely loyal and protective heart beneath a ruthless mask.",
            quote: "To the stars who listen—and the dreams that are answered.",
          ),
          CodexCharacter(
            name: "Tamlin",
            role: "High Lord of Spring",
            archetype: "The Cursed Ruler",
            description: "High Lord of the Spring Court whose gilded manor conceals an all-consuming threat Under the Mountain.",
          ),
        ],
        tropes: const [
          "Beauty and the Beast Retelling",
          "Enemies to Lovers",
          "Fae Royalty & Court Intrigue",
          "Fated Mates",
        ],
        contentWarnings: const [
          "Violence & Torture",
          "Captivity & Coercion",
        ],
        pacing: "Fast-Paced & Immersive",
        tone: "Romantic, Mystical, High Stakes",
        spiceLevel: 3.5,
        emotionalResonance: 4.6,
        suspenseLevel: 4.4,
      );
    }

    if (titleLower.contains('fourth wing')) {
      return StoryCodex(
        bookId: book.id,
        premise: "Twenty-year-old Violet Sorrengail was supposed to enter the quiet Scribe Quadrant. Instead, she is ordered into the deadly Riders Quadrant.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Enter the brutal and elite world of a war college for dragon riders. At Basgiath War College, there are only two outcomes: graduate or die.",
        setting: "Basgiath War College, Navarre",
        timePeriod: "War-Torn Fantasy Realm",
        atmosphere: "Electrifying, Brutal, High-Octane, Romantic",
        characters: const [
          CodexCharacter(
            name: "Violet Sorrengail",
            role: "Female Lead / Protagonist",
            archetype: "The Clever Underdog",
            description: "A physically fragile yet exceptionally brilliant cadet who must rely on wits and poison to survive dragon bonding.",
            quote: "I will not die today.",
          ),
          CodexCharacter(
            name: "Xaden Riorson",
            role: "Male Lead / Wingleader",
            archetype: "The Lethal Rebel",
            description: "The formidable third-year wingleader and son of the executed rebellion leader, bound by honor and dangerous attraction to Violet.",
            quote: "You want to survive? Trust me.",
          ),
        ],
        tropes: const [
          "Enemies to Lovers",
          "Deadly Magic Academy",
          "Dragon Riders",
          "Forced Proximity",
        ],
        contentWarnings: const [
          "Graphic Violence & Death",
          "Intense Peril",
        ],
        pacing: "Breathless & Relentless",
        tone: "Action-Packed, Seductive, Fiery",
        spiceLevel: 4.0,
        emotionalResonance: 4.3,
        suspenseLevel: 4.9,
      );
    }

    if (titleLower.contains('twisted games')) {
      return StoryCodex(
        bookId: book.id,
        premise: "Stoic, broody bodyguard Rhys Larsen has two rules: protect his clients at all costs, and never get emotionally involved. Until Bridget von Ascheberg.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Bridget von Ascheberg is a princess with a stubborn streak that matches his own. When her brother abdicates, she is faced with an arranged, loveless marriage—and a secret forbidden desire for the bodyguard sworn to protect her.",
        setting: "Eldorra & Washington D.C.",
        timePeriod: "Contemporary Royal",
        atmosphere: "Sensual, Forbidden, Protective, Luxe",
        characters: const [
          CodexCharacter(
            name: "Rhys Larsen",
            role: "Male Lead / Protector",
            archetype: "The Brooding Bodyguard",
            description: "An elite bodyguard with an ironclad moral code who would tear the world down to keep Princess Bridget safe.",
            quote: "You are mine, Princess. Every breath, every heartbeat.",
          ),
          CodexCharacter(
            name: "Bridget von Ascheberg",
            role: "Female Lead / Royalty",
            archetype: "The Defiant Princess",
            description: "The reluctant heir to the Eldorran throne fighting to maintain her agency and heart in the face of royal duty.",
          ),
        ],
        tropes: const [
          "Bodyguard Romance",
          "Forbidden Love",
          "Princess & Commoner",
          "Grumpy x Sunshine",
        ],
        contentWarnings: const [
          "Explicit Romance",
          "Kidnapping Attempt",
        ],
        pacing: "Simmering & Addictive",
        tone: "Romantic, Protective, Opulent",
        spiceLevel: 4.6,
        emotionalResonance: 4.4,
        suspenseLevel: 3.8,
      );
    }

    if (titleLower.contains('evelyn hugo')) {
      return StoryCodex(
        bookId: book.id,
        premise: "Aging and reclusive Hollywood movie icon Evelyn Hugo is finally ready to tell the truth about her glamorous and scandalous life.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Evelyn chooses unknown magazine reporter Monique Grant to write her memoirs. From making her way to Los Angeles in the 1950s to leaving show business in the 80s, Evelyn unspools a tale of ruthless ambition and unexpected love.",
        setting: "Manhattan & Golden Age Hollywood",
        timePeriod: "1950s–Present Day",
        atmosphere: "Nostalgic, Glamorous, Bittersweet, Heart-Rending",
        characters: const [
          CodexCharacter(
            name: "Evelyn Hugo",
            role: "Protagonist / Hollywood Legend",
            archetype: "The Ambitious Icon",
            description: "A calculated, legendary cinema queen who sacrificed everything to protect the single great love of her life.",
            quote: "They are just husbands. I am Evelyn Hugo.",
          ),
          CodexCharacter(
            name: "Monique Grant",
            role: "Interviewer / Narrator",
            archetype: "The Searching Journalist",
            description: "A young writer grappling with her divorce who discovers a shocking personal connection to Evelyn's past.",
          ),
          CodexCharacter(
            name: "Celia St. James",
            role: "True Love",
            archetype: "The Acclaimed Starlet",
            description: "A brilliant, three-time Oscar winning actress and the secret heart of Evelyn's tumultuous life.",
          ),
        ],
        tropes: const [
          "Framed Narrative",
          "Secret Romance",
          "Hollywood Behind the Scenes",
          "Found Family",
        ],
        contentWarnings: const [
          "Domestic Abuse Mention",
          "Loss & Grief",
        ],
        pacing: "Engrossing & Emotional",
        tone: "Lyrical, Bittersweet, Grand",
        spiceLevel: 2.5,
        emotionalResonance: 5.0,
        suspenseLevel: 3.5,
      );
    }

    if (titleLower.contains('beach read')) {
      return StoryCodex(
        bookId: book.id,
        premise: "A romance writer who no longer believes in love and a literary writer stuck in a rut engage in a summer-long challenge that may just upend everything.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Augustus Everett is an acclaimed author of literary fiction. January Andrews writes bestselling romance. For the summer, they are living in neighboring beach houses and swap genres to cure their writer's block.",
        setting: "North Bear Shores, Lake Michigan",
        timePeriod: "Contemporary Summer",
        atmosphere: "Breezy, Emotional, Banter-Filled, Healing",
        characters: const [
          CodexCharacter(
            name: "January Andrews",
            role: "Female Lead",
            archetype: "The Disillusioned Romantic",
            description: "A bestselling romance author reeling from her father's secret life and a crippling bout of writer's block.",
            quote: "Happily ever after doesn't mean perfect. It means choosing each other every day.",
          ),
          CodexCharacter(
            name: "Augustus Everett",
            role: "Male Lead",
            archetype: "The Cynical Literary Star",
            description: "January's college rival turned neighbor whose melancholic exterior hides profound vulnerability.",
          ),
        ],
        tropes: const [
          "Rivals to Lovers",
          "Forced Proximity",
          "Opposites Attract",
          "Shared Grief & Healing",
        ],
        contentWarnings: const [
          "Parental Infidelity & Death",
          "Depression",
        ],
        pacing: "Witty & Heartfelt",
        tone: "Charming, Emotional, Clever",
        spiceLevel: 3.0,
        emotionalResonance: 4.5,
        suspenseLevel: 2.0,
      );
    }

    // The Cruel Prince / The Folk of the Air by Holly Black
    if (titleLower.contains('cruel prince') || titleLower.contains('folk of the air') || titleLower.contains('wicked king') || titleLower.contains('queen of nothing')) {
      return StoryCodex(
        bookId: book.id,
        premise: "A mortal girl raised in the treacherous High Court of Faerie must outwit immortal royals to claim her own power.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Jude was seven years old when her parents were murdered and she and her two sisters were stolen away to live in the treacherous High Court of Faerie. To win a place at the Court, she must defy Prince Cardan.",
        setting: "Elfhame (High Court of Faerie)",
        timePeriod: "Mythic Faerie Realm",
        atmosphere: "Treacherous, Enchanting, Cutthroat, Seductive",
        characters: const [
          CodexCharacter(
            name: "Jude Duarte",
            role: "Female Lead / Mortal Spy",
            archetype: "The Ruthless Defier",
            description: "A mortal girl in Elfhame who learned that power must be taken by force, defying faerie nobility with lethal strategy and sharp blades.",
            quote: "If I cannot be better than them, I will become so much worse.",
          ),
          CodexCharacter(
            name: "Prince Cardan Greenbriar",
            role: "Male Lead / Prince of Elfhame",
            archetype: "The Wicked Prince",
            description: "The youngest, most arrogant prince of Elfhame who masks his deep vulnerabilities and forbidden longing behind cruelty.",
            quote: "Most of all, I hate you because I think of you. Often. It's disgusting, and I can't stop.",
          ),
          CodexCharacter(
            name: "Madoc",
            role: "Antagonist / Foster Father",
            archetype: "The Bloodthirsty General",
            description: "Fierce redcap general who murdered Jude's mortal parents yet raised her as his own lethal daughter.",
          ),
        ],
        tropes: const [
          "Enemies to Lovers",
          "Fae Court Intrigue",
          "Mortal in a Faerie World",
          "Morally Grey Leads",
          "Political Scheming",
        ],
        contentWarnings: const ["Violence & Bloodshed", "Bullying & Betrayal"],
        pacing: "Fast-Paced & Tense",
        tone: "Clever, Dark, Seductive",
        spiceLevel: 2.5,
        emotionalResonance: 4.4,
        suspenseLevel: 4.8,
      );
    }

    // From Blood and Ash by Jennifer L. Armentrout
    if (titleLower.contains('blood and ash') || titleLower.contains('flesh and fire') || titleLower.contains('war of two queens')) {
      return StoryCodex(
        bookId: book.id,
        premise: "A Maiden chosen by the gods to usher in a new era is drawn to a dangerous golden-eyed guard who threatens everything she believes in.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Chosen from birth to usher in a new era, Poppy's life has never been her own. She is the Maiden, shrouded and untouched. Until Hawke enters her life.",
        setting: "Kingdom of Solis & Atlantia",
        timePeriod: "Fantasy Empire",
        atmosphere: "Sensual, High-Stakes, Arcane, Passionate",
        characters: const [
          CodexCharacter(
            name: "Penellaphe 'Poppy' Balfour",
            role: "Female Lead / The Maiden",
            archetype: "The Veiled Survivor",
            description: "The chosen Maiden veiled and untouched, secretly training as a deadly fighter who longs to experience true freedom and passion.",
            quote: "I would rather be hated for who I am than loved for who I am not.",
          ),
          CodexCharacter(
            name: "Casteel Da'Neer (Hawke)",
            role: "Male Lead / Atlantian Prince",
            archetype: "The Charming Rebel Prince",
            description: "The dangerous Atlantian prince masquerading as Poppy's guard, determined to reclaim his kingdom while falling desperately for her.",
            quote: "You are the most breathtaking, infuriating creature I have ever laid eyes upon.",
          ),
          CodexCharacter(
            name: "Kieran Contram",
            role: "Supporting Figure",
            archetype: "The Wolven Guardian",
            description: "Casteel's fierce, loyal bonded wolven brother and trusted protector.",
          ),
        ],
        tropes: const [
          "Enemies to Lovers",
          "Bodyguard Romance",
          "Hidden Identity",
          "Fated Connections",
          "Vampire / Supernatural Lore",
        ],
        contentWarnings: const ["Explicit Romance", "Graphic Violence"],
        pacing: "Action-Packed & Steamy",
        tone: "Romantic, Intense, Mythic",
        spiceLevel: 4.7,
        emotionalResonance: 4.5,
        suspenseLevel: 4.4,
      );
    }

    // Haunting Adeline / Cat and Mouse Duet by H.D. Carlton
    if (titleLower.contains('haunting adeline') || titleLower.contains('hunting adeline') || titleLower.contains('cat and mouse')) {
      return StoryCodex(
        bookId: book.id,
        premise: "A gothic author uncovers her grandmother's unsolved murder in an inherited manor, pursued by a ruthless vigilante from the shadows.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "The Manipulator and the Shadow. She thought she was safe in Parsons Manor. She was wrong.",
        setting: "Parsons Manor, Washington State",
        timePeriod: "Contemporary Dark",
        atmosphere: "Gothic, Terrifying, Obsessive, Scorching",
        characters: const [
          CodexCharacter(
            name: "Adeline Reilly",
            role: "Female Lead / Author",
            archetype: "The Defiant Prey",
            description: "An independent gothic writer who inherits her great-grandmother's mysterious estate and finds herself hunted in the dark.",
          ),
          CodexCharacter(
            name: "Zade Meadows",
            role: "Male Lead / The Shadow",
            archetype: "The Ruthless Vigilante",
            description: "A dark, highly trained vigilante hacker who wages war on global traffickers while nursing a dangerous obsession with Adeline.",
            quote: "I will burn this entire world before I let anyone hurt you, Little Mouse.",
          ),
        ],
        tropes: const [
          "Morally Grey Anti-Hero",
          "Stalker Romance",
          "Touch Her and Die",
          "Gothic Manor Secrets",
        ],
        contentWarnings: const ["Extreme Dark Themes", "Non-Consensual / Dubious Consent", "Graphic Violence"],
        pacing: "Intense & Relentless",
        tone: "Dark, Unapologetic, Seductive",
        spiceLevel: 5.0,
        emotionalResonance: 3.5,
        suspenseLevel: 5.0,
      );
    }

    // Shatter Me by Tahereh Mafi
    if (titleLower.contains('shatter me') || titleLower.contains('unravel me') || titleLower.contains('ignite me')) {
      return StoryCodex(
        bookId: book.id,
        premise: "One touch is all it takes. One touch, and Juliette Ferrars can kill a fully grown man.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Juliette hasn't touched someone in 264 days. The last time she did, it was an accident, but The Reestablishment locked her up. When she's released as a weapon, she chooses to fight back.",
        setting: "Sector 45 & Omega Point",
        timePeriod: "Dystopian Ruined Earth",
        atmosphere: "Lyrical, Tense, Romantic, Electrifying",
        characters: const [
          CodexCharacter(
            name: "Juliette Ferrars",
            role: "Female Lead / Protagonist",
            archetype: "The Lethal Survivor",
            description: "A young woman whose touch is fatal, locked away in isolation until forced to embrace her extraordinary power.",
            quote: "I am a drop of hurricane water.",
          ),
          CodexCharacter(
            name: "Aaron Warner",
            role: "Male Lead / Supreme Commander",
            archetype: "The Misunderstood Tyrant",
            description: "The ruthless, calculating commander of Sector 45 who recognizes Juliette's true strength and loves her unconditionally.",
            quote: "My heart is heavy and hollow. And that is where I will begin.",
          ),
          CodexCharacter(
            name: "Kenji Kishimoto",
            role: "Supporting Figure / Rebel",
            archetype: "The Loyal Comedian",
            description: "An Omega Point rebel soldier with invisibility powers who becomes Juliette's staunchest friend and confidant.",
          ),
        ],
        tropes: const [
          "Enemies to Lovers",
          "Dystopian Superpowers",
          "Touch Her and Die",
          "Villain Gets the Girl",
        ],
        contentWarnings: const ["Violence", "Torture Mention"],
        pacing: "Fast & Lyrical",
        tone: "Poetic, Fiery, Dynamic",
        spiceLevel: 3.8,
        emotionalResonance: 4.8,
        suspenseLevel: 4.5,
      );
    }

    // Twisted Love by Ana Huang
    if (titleLower.contains('twisted love')) {
      return StoryCodex(
        bookId: book.id,
        premise: "He has a heart of ice. But for her, he'd burn the world.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Alex Volkov is a devil blessed with the face of an angel and cursed with a past he can't escape. When he agrees to look after his best friend's sister, a forbidden obsession begins.",
        setting: "Washington D.C.",
        timePeriod: "Contemporary High Society",
        atmosphere: "Seductive, Brooding, Luxurious, Tense",
        characters: const [
          CodexCharacter(
            name: "Alex Volkov",
            role: "Male Lead",
            archetype: "The Cold Billionaire",
            description: "A brilliant, vengeful Wall Street prodigy whose frozen heart is only melted by his best friend's sister.",
            quote: "You are the light to my dark, sunshine.",
          ),
          CodexCharacter(
            name: "Ava Chen",
            role: "Female Lead",
            archetype: "The Resilient Optimist",
            description: "A free-spirited photography student with childhood trauma who radiates warmth and sees the good in Alex.",
          ),
        ],
        tropes: const [
          "Brother's Best Friend",
          "Grumpy x Sunshine",
          "Touch Her and Die",
          "Revenge Romance",
        ],
        contentWarnings: const ["Trauma & Abuse Mention", "Explicit Romance"],
        pacing: "Simmering & Gripping",
        tone: "Dark, Romantic, Luxe",
        spiceLevel: 4.5,
        emotionalResonance: 4.3,
        suspenseLevel: 4.0,
      );
    }

    // The Love Hypothesis by Ali Hazelwood
    if (titleLower.contains('love hypothesis')) {
      return StoryCodex(
        bookId: book.id,
        premise: "A third-year Ph.D. candidate panics and kisses the first man she sees in a hallway—who turns out to be the department's tyrannical young professor.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "When a fake-relationship between scientists meets the irresistible force of attraction, it throws one woman's carefully calculated theories on love into chaos.",
        setting: "Stanford University, California",
        timePeriod: "Contemporary Academia",
        atmosphere: "Banter-Filled, Charming, Wholesome, Steamy",
        characters: const [
          CodexCharacter(
            name: "Olive Smith",
            role: "Female Lead",
            archetype: "The Practical Scientist",
            description: "A passionate biology Ph.D. student who doesn't believe in lasting love until forced into a fake romance.",
          ),
          CodexCharacter(
            name: "Adam Carlsen",
            role: "Male Lead",
            archetype: "The Grumpy Genius",
            description: "A notoriously harsh, brilliant biology professor whose stoic demeanor softens exclusively for Olive.",
            quote: "I'm not doing this for the department, Olive. I'm doing this for you.",
          ),
        ],
        tropes: const [
          "Fake Dating",
          "Grumpy x Sunshine",
          "Academic Rivals to Lovers",
          "Height Difference",
        ],
        contentWarnings: const ["Academic Sexual Harassment Mention"],
        pacing: "Breezy & Addictive",
        tone: "Witty, Warm, Swoon-Worthy",
        spiceLevel: 3.5,
        emotionalResonance: 4.4,
        suspenseLevel: 2.0,
      );
    }

    // The Hunger Games by Suzanne Collins
    if (titleLower.contains('hunger games') || titleLower.contains('catching fire') || titleLower.contains('mockingjay')) {
      return StoryCodex(
        bookId: book.id,
        premise: "In a dark vision of the near future, twelve boys and twelve girls are forced to participate in a televised battle to the death.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Winning means fame and fortune. Losing means certain death. The nation of Panem forces its twelve districts to send one boy and one girl to compete in the annual Hunger Games.",
        setting: "Panem (The Capitol & District 12)",
        timePeriod: "Post-Apocalyptic Dystopian",
        atmosphere: "Brutal, Harrowing, High-Stakes, Defiant",
        characters: const [
          CodexCharacter(
            name: "Katniss Everdeen",
            role: "Female Lead / The Mockingjay",
            archetype: "The Reluctant Rebel",
            description: "A fierce sixteen-year-old archer from District 12 who volunteers to save her sister and sparks a nation's rebellion.",
            quote: "I volunteer as tribute!",
          ),
          CodexCharacter(
            name: "Peeta Mellark",
            role: "Male Lead / Baker's Son",
            archetype: "The Gentle Strategist",
            description: "A compassionate boy with a silver tongue whose public declaration of love protects Katniss inside the arena.",
            quote: "I just don't want them to change me. If I die, I want to still be me.",
          ),
          CodexCharacter(
            name: "Gale Hawthorne",
            role: "Rebel Hunter",
            archetype: "The Fierce Partisan",
            description: "Katniss's childhood hunting partner in District 12 who harbors revolutionary anger against the Capitol.",
          ),
        ],
        tropes: const [
          "Dystopian Battle Royale",
          "Fake Romance for Survival",
          "Rebellion against Tyranny",
          "Love Triangle",
        ],
        contentWarnings: const ["Graphic Peril & Death", "Oppression & Starvation"],
        pacing: "Fast-Paced & Relentless",
        tone: "Somber, Defiant, Thrilling",
        spiceLevel: 1.0,
        emotionalResonance: 4.8,
        suspenseLevel: 5.0,
      );
    }

    // Pride and Prejudice by Jane Austen
    if (titleLower.contains('pride and prejudice')) {
      return StoryCodex(
        bookId: book.id,
        premise: "Sparks fly when spirited Elizabeth Bennet meets single, rich, and proud Mr. Darcy in 19th-century England.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Elizabeth Bennet is keen and witty, with a sharp eye for social hypocrisies. When she meets the haughty Mr. Darcy, her prejudice clashes with his aristocratic pride.",
        setting: "Hertfordshire & Pemberley, England",
        timePeriod: "Regency Era (1810s)",
        atmosphere: "Witty, Elegant, Intellectual, Romantic",
        characters: const [
          CodexCharacter(
            name: "Elizabeth Bennet",
            role: "Female Lead",
            archetype: "The Witty Rebel",
            description: "A sharp-witted, independent gentlewoman who refuses to marry for convenience or bow to social pressure.",
            quote: "There is a stubbornness about me that never can bear to be frightened at the will of others.",
          ),
          CodexCharacter(
            name: "Fitzwilliam Darcy",
            role: "Male Lead",
            archetype: "The Proud Master",
            description: "The wealthy, reserved master of Pemberley whose haughty demeanor hides profound integrity and devotion.",
            quote: "You have bewitched me, body and soul, and I love, I love, I love you.",
          ),
        ],
        tropes: const [
          "Enemies to Lovers",
          "Opposites Attract",
          "Class Divide Romance",
          "Misunderstandings & Redemption",
        ],
        contentWarnings: const ["Social Coercion & Classism"],
        pacing: "Refined & Engaging",
        tone: "Satirical, Romantic, Luminous",
        spiceLevel: 1.5,
        emotionalResonance: 4.7,
        suspenseLevel: 2.5,
      );
    }

    // The Silent Patient by Alex Michaelides
    if (titleLower.contains('silent patient')) {
      return StoryCodex(
        bookId: book.id,
        premise: "A famous painter shoots her husband five times in the face and never speaks another word.",
        synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
            ? effectiveSynopsis
            : "Alicia Berenson's life is seemingly perfect. One evening, she shoots her husband Gabriel in the face and never speaks again. Forensic psychotherapist Theo Faber is determined to uncover the truth.",
        setting: "The Grove Psychiatric Unit, London",
        timePeriod: "Contemporary Psychological",
        atmosphere: "Claustrophobic, Ominous, Intellectual, Chilling",
        characters: const [
          CodexCharacter(
            name: "Alicia Berenson",
            role: "Female Lead / The Silent Enigma",
            archetype: "The Tragic Artist",
            description: "A gifted painter whose mysterious silence after her husband's murder conceals a shocking reality.",
          ),
          CodexCharacter(
            name: "Theo Faber",
            role: "Male Lead / Psychotherapist",
            archetype: "The Obsessive Healer",
            description: "A forensic psychotherapist whose obsession with curing Alicia borders on dangerous delusion.",
          ),
        ],
        tropes: const [
          "Unreliable Narrator",
          "Psychological Mind Games",
          "Shocking Plot Twist",
          "Dark Secrets",
        ],
        contentWarnings: const ["Murder & Violence", "Domestic Abuse Mention"],
        pacing: "Tense & Methodical",
        tone: "Mysterious, Gripping, Noir",
        spiceLevel: 1.5,
        emotionalResonance: 4.0,
        suspenseLevel: 5.0,
      );
    }

    // 2. Dynamic Synthesis for Any Other Title
    final dominantGenre = book.genres.isNotEmpty ? book.genres.first : "Fiction";
    final cleanPremise = book.effectiveTagline;

    // Real candidate extraction from synopsis (never generic placeholders)
    final dynamicCharacters = extractCandidateCharacters(
      synopsis: effectiveSynopsis,
      author: book.author,
      title: book.title,
      genres: book.genres,
    );

    final dynamicTropes = <String>[];
    if (titleLower.contains('love') || dominantGenre.toLowerCase().contains('romance')) {
      dynamicTropes.addAll(["Forbidden Desire", "Mutual Attraction", "High Emotional Stakes"]);
    } else if (dominantGenre.toLowerCase().contains('thriller') || dominantGenre.toLowerCase().contains('mystery')) {
      dynamicTropes.addAll(["Unraveling Secrets", "Ticking Clock", "Hidden Agendas"]);
    } else if (dominantGenre.toLowerCase().contains('fantasy') || dominantGenre.toLowerCase().contains('sci-fi')) {
      dynamicTropes.addAll(["World in Peril", "Unforeseen Destiny", "Ancient Powers"]);
    } else {
      dynamicTropes.addAll(["Identity & Growth", "Moral Dilemmas", "Consequences of Choice"]);
    }

    return StoryCodex(
      bookId: book.id,
      premise: cleanPremise,
      synopsis: effectiveSynopsis.isNotEmpty && !BookMetadataSanitizer.isTruncatedSynopsis(effectiveSynopsis)
          ? effectiveSynopsis
          : book.effectiveBlurb,
      setting: _inferSetting(book.genres, titleLower),
      timePeriod: _inferTimePeriod(book.genres, titleLower),
      atmosphere: _inferAtmosphere(book.genres, titleLower),
      characters: dynamicCharacters,
      tropes: dynamicTropes,
      contentWarnings: const ["Thematic Intensity", "Emotional Conflict"],
      pacing: "Engaging & Dynamic",
      tone: "Atmospheric & Compelling",
      spiceLevel: book.spiceRating > 0 ? book.spiceRating : 2.0,
      emotionalResonance: book.tearRating > 0 ? book.tearRating : 3.5,
      suspenseLevel: 3.5,
      relationshipDynamics: [
        "Protagonist & Counterpart: Navigating the central crucible of $dominantGenre",
      ],
    );
  }

  static String _inferArchetype(List<String> genres, String titleLower) {
    final gStr = genres.join(' ').toLowerCase();
    if (gStr.contains('romance')) return "The Reluctant Romantic";
    if (gStr.contains('thriller') || gStr.contains('mystery')) return "The Inquisitive Investigator";
    if (gStr.contains('fantasy') || gStr.contains('sci-fi')) return "The Chosen Explorer";
    return "The Complex Protagonist";
  }

  static String _inferSetting(List<String> genres, String titleLower) {
    final gStr = genres.join(' ').toLowerCase();
    if (gStr.contains('fantasy')) return "A Realm of Magic & Ancient Lore";
    if (gStr.contains('sci-fi')) return "Distant Frontier / Future Earth";
    return "Modern Urban & Contemporary Landscape";
  }

  static String _inferTimePeriod(List<String> genres, String titleLower) {
    final gStr = genres.join(' ').toLowerCase();
    if (gStr.contains('historical')) return "Era of Historical Transition";
    if (gStr.contains('sci-fi')) return "Far Future";
    return "Contemporary Era";
  }

  static String _inferAtmosphere(List<String> genres, String titleLower) {
    final gStr = genres.join(' ').toLowerCase();
    if (gStr.contains('dark') || gStr.contains('thriller')) return "Moody, Brooding, Suspense-Laden";
    if (gStr.contains('romance')) return "Passionate, Tender, Emotionally Charged";
    if (gStr.contains('fantasy')) return "Wondrous, Grand, Arcane";
    return "Reflective, Immersive, Thought-Provoking";
  }

  /// Identifies if a book has a handcrafted literary profile
  static bool isCuratedBook(Book book) {
    final titleLower = book.title.toLowerCase();
    return titleLower.contains('god of malice') ||
        titleLower.contains('reminders of him') ||
        titleLower.contains('it ends with us') ||
        titleLower.contains('verity') ||
        titleLower.contains('king of wrath') ||
        titleLower.contains('twisted games') ||
        titleLower.contains('twisted love') ||
        titleLower.contains('dune') ||
        titleLower.contains('court of thorns and roses') ||
        titleLower.contains('acotar') ||
        titleLower.contains('fourth wing') ||
        titleLower.contains('evelyn hugo') ||
        titleLower.contains('beach read') ||
        titleLower.contains('cruel prince') ||
        titleLower.contains('blood and ash') ||
        titleLower.contains('haunting adeline') ||
        titleLower.contains('shatter me') ||
        titleLower.contains('love hypothesis') ||
        titleLower.contains('hunger games') ||
        titleLower.contains('pride and prejudice') ||
        titleLower.contains('silent patient');
  }

  static final Set<String> _knownAuthorsBlacklist = {
    'colleen hoover', 'hoover', 'sarah j maas', 'sarah maas', 'maas',
    'rebecca yarros', 'yarros', 'emily henry', 'henry', 'ali hazelwood', 'hazelwood',
    'taylor jenkins reid', 'reid', 'ana huang', 'huang', 'rina kent', 'kent',
    'lucy score', 'score', 'hannah grace', 'grace', 'elena armas', 'armas',
    'penelope douglas', 'douglas', 'lauren asher', 'asher', 'elle kennedy', 'kennedy',
    'jennifer l armentrout', 'jennifer armentrout', 'armentrout', 'holly black', 'black',
    'leigh bardugo', 'bardugo', 'suzanne collins', 'collins', 'george r r martin', 'martin',
    'j k rowling', 'jk rowling', 'rowling', 'brandon sanderson', 'sanderson',
    'neil gaiman', 'gaiman', 'v e schwab', 've schwab', 'schwab', 'cassandra clare', 'clare',
    'tessa bailey', 'bailey', 'christina lauren', 'lauren', 'freida mcfadden', 'mcfadden',
    'alex michaelides', 'michaelides', 'holly jackson', 'jackson', 'john green', 'green',
    'rick riordan', 'riordan', 'stephen king', 'king', 'agatha christie', 'christie',
    'jane austen', 'austen', 'charlotte bronte', 'bronte', 'emily bronte',
    'charles dickens', 'dickens', 'f scott fitzgerald', 'fitzgerald',
    'george orwell', 'orwell', 'harper lee', 'mary shelley', 'shelley',
    'bram stoker', 'stoker', 'oscar wilde', 'wilde', 'arthur conan doyle', 'doyle',
    'leo tolstoy', 'tolstoy', 'fyodor dostoevsky', 'dostoevsky', 'franz kafka', 'kafka',
    'ernest hemingway', 'hemingway', 'j r r tolkien', 'tolkien', 'c s lewis', 'lewis',
    'frank herbert', 'herbert', 'isaac asimov', 'asimov', 'dan brown',
    'gillian flynn', 'flynn', 'paula hawkins', 'hawkins', 'lisa jewell', 'jewell',
    'shari lapena', 'lapena', 'ruth ware', 'ware', 'lucy foley', 'foley',
    'riley sager', 'sager', 'karen m mcmanus', 'mcmanus', 'stephanie garber', 'garber',
    'tahereh mafi', 'mafi', 'sabaa tahir', 'tahir', 'victoria aveyard', 'aveyard',
    'tracy wolff', 'wolff', 'laura thalassa', 'thalassa', 'carissa broadbent', 'broadbent',
    'raven kennedy', 'danielle l jensen', 'jensen', 'scarlett st clair', 'st clair',
    'h d carlton', 'hd carlton', 'carlton', 'tillie cole', 'cole', 'shantel tessier', 'tessier',
    'sophie lark', 'lark', 'runyx', 'mia sheridan', 'sheridan', 'brittainy c cherry', 'cherry',
    'meghan quinn', 'quinn', 'vi keeland', 'keeland', 'penelope ward', 'ward',
    'devney perry', 'perry', 'elsie silver', 'silver',
  };

  /// Strict author and non-character detector
  static bool isAuthorOrNonCharacter(String candidate, String author, String title, [String? synopsis]) {
    final candClean = candidate.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
    if (candClean.isEmpty || candClean.length < 2) return true;

    // 1. Check title match
    final titleClean = title.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
    if (candClean == titleClean) return true;

    // 2. Comprehensive Author Matching (Supports "First Last", "Last, First", and sub-tokens)
    final authorClean = author.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
    if (authorClean.isNotEmpty) {
      if (candClean == authorClean || authorClean.contains(candClean) || candClean.contains(authorClean)) {
        return true;
      }
      final authorWords = authorClean.split(RegExp(r'\s+')).where((w) => w.length >= 2).toSet();
      final candWords = candClean.split(RegExp(r'\s+')).where((w) => w.length >= 2).toSet();

      // If candidate is a subset of author words or matches any author word
      if (candWords.isNotEmpty && candWords.every((w) => authorWords.contains(w))) {
        return true;
      }
      for (final word in authorWords) {
        if (candClean == word || candWords.contains(word)) {
          return true;
        }
      }
    }

    // 3. Known famous authors blacklist
    if (_knownAuthorsBlacklist.contains(candClean)) return true;
    for (final auth in _knownAuthorsBlacklist) {
      if (candClean == auth) return true;
    }

    // 4. Non-character publishing and marketing stopwords
    const blacklist = {
      'the', 'when', 'what', 'where', 'then', 'this', 'that', 'with', 'from', 'after',
      'before', 'into', 'over', 'under', 'every', 'some', 'author', 'novel', 'book',
      'story', 'edition', 'standalone', 'paperback', 'hardcover', 'kindle', 'bestseller',
      'bestselling', 'national', 'international', 'penguin', 'harpercollins', 'simon',
      'schuster', 'macmillan', 'bloomsbury', 'goodreads', 'review', 'times', 'york',
      'today', 'usa today', 'new york times', 'chapter', 'prologue', 'epilogue', 'volume',
      'series', 'trilogy', 'central protagonist', 'key counterpart', 'lead character',
      'united states', 'new york', 'london', 'england', 'paris', 'america',
      'january', 'february', 'march', 'april', 'may', 'june', 'july', 'august',
      'september', 'october', 'november', 'december', 'monday', 'tuesday', 'wednesday',
      'thursday', 'friday', 'saturday', 'sunday', 'summer', 'winter', 'spring', 'fall',
      'editor', 'illustrator', 'translator', 'narrator', 'foreword', 'preface',
      'fiction', 'nonfiction', 'memoir', 'autobiography', 'biography', 'special edition',
      'collector', 'deluxe', 'reading', 'readers', 'recommendation', 'praise', 'fans of',
      'award winning', 'acclaimed', 'critics', 'publisher', 'audiobook',
    };
    if (blacklist.contains(candClean)) return true;

    // 5. Contextual author blurb detection in synopsis
    if (synopsis != null && synopsis.isNotEmpty) {
      final synLower = synopsis.toLowerCase();
      final candEscaped = RegExp.escape(candClean);
      final authorContextPatterns = [
        RegExp(r'\b(?:by|author|written by|novel by|from author|bestselling author|acclaimed author)\s+' + candEscaped + r'\b'),
        RegExp(r'\b' + candEscaped + r'\s+(?:delivers|presents|writes|returns with|crafts|weaves|pens)\b'),
        RegExp(r'\b(?:praise for|fans of)\s+' + candEscaped + r'\b'),
      ];
      for (final p in authorContextPatterns) {
        if (p.hasMatch(synLower)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Extracts verified character names from the synopsis text while rigorously excluding authors
  static List<CodexCharacter> extractCandidateCharacters({
    required String synopsis,
    required String author,
    required String title,
    required List<String> genres,
  }) {
    if (synopsis.trim().isEmpty) return const [];
    final characters = <CodexCharacter>[];
    final seen = <String>{};

    final titleLower = title.trim().toLowerCase();

    // 1. Lead Introduction Patterns (Captures both single names and two-word names)
    final leadPatterns = [
      RegExp(r'\b([A-Z][a-z]{2,15}(?:\s+[A-Z][a-z]{2,15})?)\s+(?:is|was)\s+(?:a|an|the)\s+([a-zA-Z\s]{3,40})'),
      RegExp(r'When\s+([A-Z][a-z]{2,15}(?:\s+[A-Z][a-z]{2,15})?)\s+([a-zA-Z\s]{4,35}),'),
      RegExp(r'Told\s+(?:from\s+the\s+perspective\s+of|alternating\s+between)\s+([A-Z][a-z]{2,15}(?:\s+[A-Z][a-z]{2,15})?)\s+and\s+([A-Z][a-z]{2,15}(?:\s+[A-Z][a-z]{2,15})?)'),
      RegExp(r'For\s+([A-Z][a-z]{2,15}(?:\s+[A-Z][a-z]{2,15})?),\s+'),
      RegExp(r'Enter\s+([A-Z][a-z]{2,15}(?:\s+[A-Z][a-z]{2,15})?),\s+(?:a|an)\s+'),
    ];

    final sentences = synopsis.split(RegExp(r'(?<=[.!?])\s+'));

    for (final pattern in leadPatterns) {
      for (final match in pattern.allMatches(synopsis)) {
        for (int i = 1; i <= match.groupCount; i++) {
          final cand = match.group(i)?.trim();
          if (cand == null || cand.length < 3) continue;
          if (isAuthorOrNonCharacter(cand, author, title, synopsis)) continue;
          final candLower = cand.toLowerCase();
          if (seen.contains(candLower)) continue;

          seen.add(candLower);
          final isFirst = characters.isEmpty;
          final role = isFirst ? 'Protagonist / Lead' : (characters.length == 1 ? 'Central Figure / Counterpart' : 'Supporting Figure');

          String bio = 'Key figure shaping the narrative conflict and themes.';
          for (final s in sentences) {
            if (s.contains(cand) && s.length > 25 && s.length < 220) {
              bio = s.trim();
              break;
            }
          }

          characters.add(CodexCharacter(
            name: cand,
            role: role,
            archetype: _inferArchetype(genres, titleLower),
            description: bio,
          ));

          if (characters.length >= 3) break;
        }
        if (characters.length >= 3) break;
      }
      if (characters.length >= 3) break;
    }

    if (characters.length >= 2) return characters;

    // 2. Frequency & Prominence Matching (Supporting Two-Word and Single-Name Proper Nouns)
    final properNounRegex = RegExp(r'\b([A-Z][a-z]{2,15}(?:\s+[A-Z][a-z]{2,15})?)\b');
    final nameFrequency = <String, int>{};

    for (final match in properNounRegex.allMatches(synopsis)) {
      final cand = match.group(1)!.trim();
      if (isAuthorOrNonCharacter(cand, author, title, synopsis)) continue;
      nameFrequency[cand] = (nameFrequency[cand] ?? 0) + 1;
    }

    final sortedCandidates = nameFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCandidates) {
      final cand = entry.key;
      final candLower = cand.toLowerCase();
      if (seen.contains(candLower)) continue;

      seen.add(candLower);
      final isFirst = characters.isEmpty;
      final role = isFirst ? 'Protagonist / Lead' : (characters.length == 1 ? 'Central Figure / Counterpart' : 'Supporting Figure');

      String bio = 'Key figure shaping the central conflict and emotional stakes of the narrative.';
      for (final s in sentences) {
        if (s.contains(cand) && s.length > 25 && s.length < 220) {
          bio = s.trim();
          break;
        }
      }

      characters.add(CodexCharacter(
        name: cand,
        role: role,
        archetype: _inferArchetype(genres, titleLower),
        description: bio,
      ));

      if (characters.length >= 3) break;
    }

    return characters;
  }
}


