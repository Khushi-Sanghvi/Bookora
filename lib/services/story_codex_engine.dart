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

    // 2. Dynamic Synthesis for Any Other Title
    final dominantGenre = book.genres.isNotEmpty ? book.genres.first : "Fiction";
    final cleanPremise = book.effectiveTagline;

    // Real candidate extraction from synopsis (never generic placeholders)
    final dynamicCharacters = _extractCandidateCharacters(
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
        titleLower.contains('dune') ||
        titleLower.contains('court of thorns and roses') ||
        titleLower.contains('acotar') ||
        titleLower.contains('fourth wing') ||
        titleLower.contains('evelyn hugo') ||
        titleLower.contains('beach read');
  }

  /// Extracts verified character names from the synopsis text while rigorously excluding authors
  static List<CodexCharacter> _extractCandidateCharacters({
    required String synopsis,
    required String author,
    required String title,
    required List<String> genres,
  }) {
    if (synopsis.trim().isEmpty) return const [];
    final characters = <CodexCharacter>[];
    final seen = <String>{};

    final authorLower = author.trim().toLowerCase();
    final authorParts = authorLower.split(RegExp(r'[\s,.-]+')).where((p) => p.length >= 3).toSet();
    final titleLower = title.trim().toLowerCase();

    final stopWords = {
      'The', 'When', 'What', 'Where', 'Then', 'This', 'That', 'With', 'From', 'After',
      'Before', 'Into', 'Over', 'Under', 'Every', 'Some', 'Author', 'Novel', 'Book',
      'Story', 'Edition', 'USA', 'Today', 'New', 'York', 'Times', 'Bestselling',
      'First', 'Second', 'Third', 'Chapter', 'Volume', 'National', 'International',
      'Lead', 'Character', 'Central', 'Protagonist', 'Counterpart', 'Summer', 'Winter',
    };

    final nameRegex = RegExp(r'\b([A-Z][a-z]{1,15}(?:\s+[A-Z][a-z]{1,15}))\b');
    final matches = nameRegex.allMatches(synopsis);

    for (final match in matches) {
      final cand = match.group(1)!.trim();
      final candLower = cand.toLowerCase();
      final firstWord = cand.split(' ').first;

      if (stopWords.contains(firstWord)) continue;
      if (candLower == titleLower) continue;
      if (authorLower.isNotEmpty && (candLower == authorLower || authorLower.contains(candLower))) continue;
      if (authorParts.any((p) => candLower.contains(p))) continue;
      if (seen.contains(candLower)) continue;

      seen.add(candLower);
      final isFirst = characters.isEmpty;
      final role = isFirst ? 'Protagonist / Lead' : (characters.length == 1 ? 'Central Figure / Counterpart' : 'Supporting Figure');

      // Find excerpt sentence
      String bio = 'Key figure shaping the narrative conflict and themes.';
      final sentences = synopsis.split(RegExp(r'(?<=[.!?])\s+'));
      for (final s in sentences) {
        if (s.contains(cand) && s.length > 20 && s.length < 200) {
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

