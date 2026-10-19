import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // --- Convincing Romantic & Spicy Bookish Notification Dialogue Vault (100+ Entries) ---
  static final List<Map<String, String>> romanticDialogues = [
    // --- Classic Vault ---
    {
      'title': '💋 Your Fictional Man is Waiting...',
      'body': 'He\'s waiting for you on the next page. Don\'t keep him waiting tonight 🖤',
    },
    {
      'title': '🔥 Just One More Chapter?',
      'body': 'You know you can\'t resist the tension. Open Bookora and see what happens next 🌶️',
    },
    {
      'title': '✨ A Bookish Date Night',
      'body': 'You, a cozy blanket, and an irresistible plot twist. Let\'s read a few pages 💕',
    },
    {
      'title': '🖤 High Spice & Dangerous Obsession',
      'body': 'The heat is rising in your current read! Open Bookora and dive back into the drama 🔥',
    },
    {
      'title': '📖 "He\'d burn the world for her..."',
      'body': '...but he can\'t read this chapter for you! Steal 15 minutes of reading passion tonight 🕯️',
    },
    {
      'title': '⚡ Enemies to Lovers? Fake Dating?',
      'body': 'Your next favorite trope is waiting for you! Open Bookora and keep your streak alive 🔥',
    },
    {
      'title': '💕 Your Bookmark is Feeling Lonely...',
      'body': 'Your fictional lovers miss you! Turn a few pages before calling it a night 🌙',
    },
    {
      'title': '🌶️ Warning: Scorching Chemistry Ahead!',
      'body': 'Things are getting spicy in your library... Don\'t leave your story hanging on a cliffhanger 💋',
    },

    // --- 100+ Spicy Fantasy & Romantasy Dialogues ---
    {
      'title': '🗡️ "Who did this to you?"',
      'body': 'The shadow daddy is sharpening his daggers. Read the next chapter before he burns down the realm 🖤',
    },
    {
      'title': '🦇 "Touch her and you die."',
      'body': 'He just whispered the deadly four words. Open Bookora right now to witness the aftermath 🌶️',
    },
    {
      'title': '👑 Only One Bed in the Tavern...',
      'body': 'The storm is howling, the innkeeper is unapologetic, and the tension is suffocating. Dive back in 🔥',
    },
    {
      'title': '🖤 A Dagger to His Throat',
      'body': '"Are you going to kill me, sweetheart?" Find out what he does when she refuses to flinch 💋',
    },
    {
      'title': '🥀 The Mating Bond Just Snapped',
      'body': 'Golden threads of destiny are burning through his veins. Don\'t leave him on read tonight ✨',
    },
    {
      'title': '🔥 Enemies to Lovers Peak Tension',
      'body': 'They\'re supposed to be mortal enemies, but they\'re standing way too close in the dark corridor 🫦',
    },
    {
      'title': '🌙 Midnight Training Session',
      'body': '"Drop your stance, little viper." He\'s adjusting her grip and the air just ran out of oxygen 🗡️',
    },
    {
      'title': '🩸 A Forbidden Blood Vow',
      'body': 'He knelt before the throne and swore his life—and his soul—to her. Read the aftermath in Bookora 🖤',
    },
    {
      'title': '💋 "You\'re mine to ruin."',
      'body': 'The villain whispered it against her jaw, and suddenly the hero doesn\'t sound so appealing anymore 🌶️',
    },
    {
      'title': '🏰 Locked in the High Tower',
      'body': 'Forbidden glances, velvet robes, and heavy castle doors. Your next spicy encounter is waiting 🕯️',
    },
    {
      'title': '⚡ He Smirked in the Shadows',
      'body': 'That arrogant, winged bastard is up to something unholy. Turn the page to see him crumble for her 🔥',
    },
    {
      'title': '🍷 Poison in His Goblet?',
      'body': '"Drink, my queen. If it\'s poisoned, we die together." The gothic romance is peaking tonight 🖤',
    },
    {
      'title': '🐉 The Dragon Rider is Waiting',
      'body': 'Black flight leathers, crackling lightning, and a soul-deep bond that could scorch the skies ⚡',
    },
    {
      'title': '🫀 "My Heart Only Beats Because of You"',
      'body': 'The ancient warlord is confessing his sins under the moonlight. Don\'t abandon his vulnerability 💕',
    },
    {
      'title': '🌶️ The Slow Burn Finally Caught Fire',
      'body': 'Three hundred pages of lingering glances and suppressed sighs just detonated into flames 💥',
    },
    {
      'title': '🖤 The Villain\'s Secret POV',
      'body': 'He\'d slaughter entire armies just to watch her smile once. Rejoin your dark fantasy obsession 🗡️',
    },
    {
      'title': '🎭 A Masquerade of Deception',
      'body': 'A velvet mask, an anonymous waltz, and a gloved hand tracing her spine in the dark 🥀',
    },
    {
      'title': '⚔️ Sword Sparring Chemistry',
      'body': 'Steel clashes, breath mingles, and neither one of them is actually trying to disarm the other 🫦',
    },
    {
      'title': '✨ Starfall Whispers',
      'body': '"To the stars who listen, and the dreams that are answered." Your fae court is waiting under the night sky 🌌',
    },
    {
      'title': '⛓️ Bound by Magic Chains',
      'body': 'Captive and captor, but who is really holding the leash? Open Bookora to find out 🌶️',
    },
    {
      'title': '💋 "Say My Name, Little Bird"',
      'body': 'He commanded it softly against her ear, and the whole realm lost its composure 🖤',
    },
    {
      'title': '🌧️ Caught in a Magical Downpour',
      'body': 'Soaked through in an ancient cavern with only a single fire and drenched cloaks to shed 🔥',
    },
    {
      'title': '💍 Arranged Marriage to the Dark King',
      'body': 'The vows were ice, but the bridal chamber is pure obsidian fire. Turn to the next chapter 👑',
    },
    {
      'title': '🩸 The Vampire Lord\'s Thirst',
      'body': 'A single crimson drop and a predator completely losing control of his centuries-old composure 🍷',
    },
    {
      'title': '🕯️ Dark Academia Late Night Study',
      'body': 'Restricted archives, ancient grimoires, and dusty shelves hiding stolen kisses between rivals 📜',
    },
    {
      'title': '🖤 "I\'ll Burn Any Kingdom That Hurts You"',
      'body': 'Red flags? No, darling, that is a full crimson royal banner. Read what he does next 🚩',
    },
    {
      'title': '🫦 The Tension is Suffocating',
      'body': 'Their lips were millimeters apart before the chapter ended! Don\'t leave yourself hanging tonight 🌶️',
    },
    {
      'title': '🗡️ Knife at the Dinner Table',
      'body': 'Trading threats over fine wine while their knees brush under the tablecloth. Classic romantasy bliss 🍷',
    },
    {
      'title': '🐾 The Alpha\'s Shadow Looming',
      'body': 'A possessive growl echoing in the foggy woods. Your shapeshifter romance is ready for you 🐺',
    },
    {
      'title': '🔥 "You Are My Ruin and My Salvation"',
      'body': 'The dark immortal dropped to his knees. Witness the fall of a god inside Bookora 🖤',
    },
    {
      'title': '👑 Kneel Before the Crown',
      'body': '"I bow to no one... except you." The arrogant prince just surrendered his pride. Read it now 🫦',
    },
    {
      'title': '🥀 A Deadly Royal Ball',
      'body': 'Poisoned daggers concealed in ballgowns and illicit hands hidden beneath silks. The plot thickens! 💃',
    },
    {
      'title': '⚡ Sparks Arc Between Their Skin',
      'body': 'Pure raw elemental magic colliding with unsuppressed romantic longing. Read chapter next ⚡',
    },
    {
      'title': '🖤 Fictional Boyfriends > Real World',
      'body': 'He has bat wings, dark humor, and unlimited devotion. Why aren\'t you reading right now? 🦇',
    },
    {
      'title': '🌶️ Chapter 55 Energy Loading...',
      'body': 'If you know, you know. Brace yourself, hydrate, and open Bookora right now 🔥',
    },
    {
      'title': '🏹 Hunted by the Shadow Prince',
      'body': '"Run all you want, pet. I find joy in the pursuit." Get back into the chase tonight 🖤',
    },
    {
      'title': '✨ The Ancient Prophecy Lied',
      'body': 'They were foretold to destroy each other, but they\'d rather tear down the stars together 🌌',
    },
    {
      'title': '🩸 A Drop of Fae Blood',
      'body': 'One taste and the mortal world ceased to matter. Your dark fantasy awaits on the nightstand 🍷',
    },
    {
      'title': '💋 "Tell Me to Stop, and I Will."',
      'body': 'Spoiler alert: She didn\'t tell him to stop. Find out what happens next in Bookora 🌶️',
    },
    {
      'title': '🔥 The Warlord\'s Soft Spot',
      'body': 'Merciless to thousands, but kneeling to bandage her bruised knuckles. Absolute elite trope 🩹',
    },
    {
      'title': '🖤 Stealing from the High Lord',
      'body': 'She broke into his private sanctuary and got pinned against the bookshelf. Master thief or willing captive? 📚',
    },
    {
      'title': '🥀 The Curse of the Dark Court',
      'body': 'Only true devotion can break the nocturnal spell. Read the midnight confession now 🌙',
    },
    {
      'title': '⚔️ "I Can Take Care of Myself."',
      'body': '"I know," he growled, stepping in front of the blade anyway. "I just don\'t want to let you." 🖤',
    },
    {
      'title': '🍷 Drunk on Stolen Starlight',
      'body': 'Midnight terrace conversations and whispered confessions between mortal and immortal 🌠',
    },
    {
      'title': '🫦 A Heated Secret in the Altar Room',
      'body': 'Whispering blasphemous promises where the gods themselves can hear. Turn the spicy page 🕯️',
    },
    {
      'title': '🐉 Dragon Wings Wrapping Around Her',
      'body': 'Cold mountain nights don\'t stand a chance against dragon fire and fierce devotion 🖤',
    },
    {
      'title': '🌶️ The Spice Meter Just Broke',
      'body': 'Five out of five chili peppers! Grab an iced drink and crack open your current read 🔥',
    },
    {
      'title': '👑 Stolen Caresses on the Throne',
      'body': 'When the court is dismissed and only shadows remain, the real coronation begins 💋',
    },
    {
      'title': '🖤 "You Look Exquisite When You\'re Furious"',
      'body': 'He is intentionally provoking her just to watch her eyes glow with magical wrath ⚡',
    },
    {
      'title': '🩸 The Blood Sovereign Calls',
      'body': 'Ancient crypts, gothic castles, and a love that defied three centuries of war 🏰',
    },
    {
      'title': '✨ The Stars Witnessed Everything',
      'body': 'A midnight pact sealed with a desperate, breathless kiss on the parapet. Continue reading 🌙',
    },
    {
      'title': '🗡️ "I Would Tear the Skies Apart for You"',
      'body': 'High melodrama? Yes. Unhinged romantic devotion? Absolutely. Get back into Bookora 🖤',
    },
    {
      'title': '🔥 Feigned Indifference Falling Apart',
      'body': 'He pretended not to care until another lord dared to ask for her hand at the banquet 🍷',
    },
    {
      'title': '💋 "Breathe for Me, Darling"',
      'body': 'A single commanding murmur that sent shockwaves across three courts. Dive back in 🌶️',
    },
    {
      'title': '🥀 An Unholy Bargain Made',
      'body': 'One week in his twilight realm in exchange for saving her family. The price was always her heart 🗝️',
    },
    {
      'title': '🦇 The Night Court Beckons',
      'body': 'Dreamers and starlight, wings and wicked grins. Your literary haven is waiting for you ✨',
    },
    {
      'title': '⚔️ Two Blades, One Heartbeat',
      'body': 'Back-to-back against impossible odds, fighting as one lethal, breathtaking entity 🗡️',
    },
    {
      'title': '🖤 "Who Said You Could Leave?"',
      'body': 'A heavy hand against the doorframe blocking her retreat. The banter is about to explode 🔥',
    },
    {
      'title': '🕯️ Midnight Secret Encounters',
      'body': 'Sneaking out past the castle guards for a stolen hour in the moonlit gardens 🌿',
    },
    {
      'title': '🌶️ "You Have No Idea What You Do to Me"',
      'body': 'The stoic commander finally loses his composure against the stone wall. Read the madness 🫦',
    },
    {
      'title': '👑 The Crown Sits Heavy, He Doesn\'t',
      'body': 'Ruthless on the battlefield, completely undone in her private bedchambers 🖤',
    },
    {
      'title': '🩸 Blood Magic & Dark Desires',
      'body': 'The spell requires a binding tether—and neither of them is willing to break it 🔮',
    },
    {
      'title': '🐺 Moonlit Howls & Fated Mates',
      'body': 'The ancient wolf recognized its match across the crowded battlefield. Don\'t miss this chapter 🌕',
    },
    {
      'title': '💋 "Never Apologize for Fire"',
      'body': 'He loves her sharp edges and lethal tongue. Open Bookora and revel in the banter 🔥',
    },
    {
      'title': '🏰 Secret Passages in the Castle',
      'body': 'Behind the tapestry lies an ancient staircase and the person she\'s forbidden to love 🗝️',
    },
    {
      'title': '⚡ Unchecked Magical Resonance',
      'body': 'Their auras collided and shattered the glass chandeliers. The tension is palpable! 💥',
    },
    {
      'title': '🖤 "I Didn\'t Plan on Falling for My Assassin"',
      'body': 'She came to end his life; now he\'s handing her the blade to his heart 🗡️',
    },
    {
      'title': '🥀 Black Roses on Her Pillow',
      'body': 'A token left by the phantom thief who stole more than just the kingdom\'s jewels 🖤',
    },
    {
      'title': '🌶️ The Danger Room Encounter',
      'body': 'Locked together after hours with swords drawn and tempers flaring. Pure romantasy fuel 🔥',
    },
    {
      'title': '✨ Ancient Fae Allure',
      'body': 'Those silver eyes have seen a thousand years, but they\'ve never looked at anyone like this 👁️',
    },
    {
      'title': '🍷 Wine, Poison & Stolen Kisses',
      'body': 'A masquerade toast that turns into a midnight game of cat and mouse 🎭',
    },
    {
      'title': '🫦 "You\'re Playing with Fire, Sweetheart"',
      'body': '"Then let me burn," she replied. Witness the blaze in your current read right now 🌶️',
    },
    {
      'title': '👑 A Queen Who Kneels to No King',
      'body': 'Except maybe to the dark shadow commander who conquered her demons. Read the royal drama 🏰',
    },
    {
      'title': '🗡️ "I\'d Slay Every God for You"',
      'body': 'Blasphemous, dangerous, and completely obsessed. Return to the dark academia archives 🖤',
    },
    {
      'title': '🕯️ Wax Dripping on the Grimoire',
      'body': 'Late hours, forbidden summonings, and a demon companion who is entirely too handsome 🔮',
    },
    {
      'title': '🖤 The Anti-Hero\'s Redemption?',
      'body': 'He won\'t save the world, but he will destroy anyone who dares cross her path 💣',
    },
    {
      'title': '🔥 The Scars He Only Shows Her',
      'body': 'Vulnerability beneath heavy iron armor. The emotional depth is hitting peak level tonight 🥺',
    },
    {
      'title': '💋 "I Have Wanted You Since the First Day"',
      'body': 'Years of repressed yearning pouring out under the starlit canopy. Turn the page! ✨',
    },
    {
      'title': '🦇 Wingspread & Shadows Unleashed',
      'body': 'When someone insults her honor and the darkness in the room starts crawling up the walls 🖤',
    },
    {
      'title': '🩸 Bound by an Eternal Oath',
      'body': 'Their souls are intertwined across lifetimes. Dive back into the epic fantasy saga 📜',
    },
    {
      'title': '🌶️ The Carriage Ride From Hell (or Heaven)',
      'body': 'A bumping carriage, rain lashing against the glass, and way too little personal space 🫦',
    },
    {
      'title': '🏰 Castle Under Siege, Heart in Danger',
      'body': 'Arrows flying outside while the lovers confront the truth they\'ve been avoiding for 40 chapters 🏹',
    },
    {
      'title': '⚡ "Don\'t Test My Restraint"',
      'body': 'His knuckles turned white gripping the mahogany desk. Read what snaps his control 🔥',
    },
    {
      'title': '🖤 Shadow Weaving in the Midnight Hour',
      'body': 'Tender shadows wrapping like silk around her shivering shoulders. High fantasy comfort 🌌',
    },
    {
      'title': '🥀 The Gilded Cage Smashed',
      'body': 'He didn\'t come to capture her; he came to burn the cage to ash. Witness the escape 🕊️',
    },
    {
      'title': '👑 "My Throne is Meaningless Without You"',
      'body': 'The sovereign casts aside the diamond crown. Pure, unadulterated high fantasy romance 💎',
    },
    {
      'title': '🍷 "Drink Deep, My Sorceress"',
      'body': 'An elven potion of vitality, a stolen elixir, and a shared heartbeat in the sanctuary 🧪',
    },
    {
      'title': '🫦 A Heated Glance Across the Council',
      'body': 'Diplomats are arguing warfare while they exchange scandalous promises across the mahogany table 🤫',
    },
    {
      'title': '🗡️ Duel at Dawn, Kisses at Midnight',
      'body': 'Tomorrow they might cross blades on the tournament field, but tonight belongs to them 🌙',
    },
    {
      'title': '🖤 "I\'ll Hold Your Monsters for You"',
      'body': 'Comforting darkness, fierce protection, and late-night emotional unraveling 💕',
    },
    {
      'title': '🔥 The Heat of the Dragon\'s Den',
      'body': 'Surrounded by hoarded gold, ancient treasures, and a fierce protector who covets only her 🐉',
    },
    {
      'title': '💋 "You Are My Undoing, And I Welcome It"',
      'body': 'The stoic high commander giving in completely. Open Bookora and experience the surrender 🖤',
    },
    {
      'title': '✨ Faerie Fruit & Sweet Temptations',
      'body': 'They warned mortals never to taste the fruit of the Underhill... but she took a bite 🍎',
    },
    {
      'title': '🩸 The Dark Sovereign\'s Obsession',
      'body': 'Ruling from a bone throne, yet completely powerless against a single arch of her eyebrow 👑',
    },
    {
      'title': '🌶️ Locked in the Armory',
      'body': 'Surrounded by cold iron, sharp daggers, and rising fever pitch passion. Read chapter next ⚔️',
    },
    {
      'title': '🏰 Whispers in the Royal Conservatory',
      'body': 'Hidden among midnight orchids and exotic flora, stolen touches and silent sighs 🌺',
    },
    {
      'title': '🦇 "Fly with Me, Little Dreamer"',
      'body': 'Soaring above the cloudline with leather wings and a world forgotten far below 🌌',
    },
    {
      'title': '🖤 The Morally Grey Manifesto',
      'body': 'Good guys save the world; the villain burns the world to keep her safe. Choose your side in Bookora 🔥',
    },
    {
      'title': '🥀 Stolen Gloves and Secret Favors',
      'body': 'Tying her ribbon to his lance before he rides into the magical tournament 🏇',
    },
    {
      'title': '💋 "Just One Night. That Was the Deal."',
      'body': 'Neither one of them has any intention of keeping that deal. Read the morning after in Bookora ☀️',
    },
    {
      'title': '🩸 Blood Bound to the Shadow Realm',
      'body': 'The contract is signed in starlight. Your shadow lord is pacing the ramparts waiting for you 🏰',
    },
    {
      'title': '🔥 When He Loses His Cool In Front of Everyone',
      'body': 'The stoic general dropped his war map because she walked into the tent looking breathtaking ⛺',
    },
    {
      'title': '🗝️ The Skeleton Key to His Heart',
      'body': 'He guarded centuries of secrets, but he handed her the key without hesitation 🖤',
    },
    {
      'title': '🌶️ Midnight Bathhouse Rendezvous',
      'body': 'Steam rising from heated springs, rose petals, and whispers that could start a revolution 🫧',
    },
    {
      'title': '🏹 Target Practice or Foreplay?',
      'body': 'His arms wrapped around hers to guide the bowstring. Neither one was aiming at the target 🎯',
    },
    {
      'title': '👑 "Call Me Your Majesty Again, See What Happens"',
      'body': 'The rebel prince just leaned down to whisper a wicked threat. Turn the spicy page 🫦',
    },
    {
      'title': '✨ Starlight Dancing in His Dark Irises',
      'body': 'A millennia of loneliness washed away in a single second. Rejoin the saga tonight 🌌',
    },
    {
      'title': '🖤 "You Don\'t Have to Be Strong Tonight"',
      'body': 'The fierce warrior princess finally collapses into his waiting arms. Grab your tissues 🥺',
    },
    {
      'title': '🍷 Sipping Poison Just to Taste Her Lips',
      'body': 'He knew she was lethal, but he drank from the chalice anyway. Elite high fantasy romance 🖤',
    },
  ];

  static Map<String, String> getRandomRomanticDialogue() {
    final rand = Random();
    return romanticDialogues[rand.nextInt(romanticDialogues.length)];
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // --- 1. Instant Test / Trigger Notification ---
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'bookora_reading_reminders',
      'Reading Reminders',
      channelDescription: 'Daily reading session reminders and streak alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  // --- 2. Schedule Daily Reading Reminder Notification ---
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await initialize();
    await cancelDailyReminder();

    const androidDetails = AndroidNotificationDetails(
      'bookora_reading_reminders',
      'Reading Reminders',
      channelDescription: 'Daily reading session reminders and streak alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        101, // Channel ID for daily reminder
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  // --- 3. Cancel Daily Reminder ---
  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(101);
  }

  // --- 4. Cancel All Notifications ---
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
