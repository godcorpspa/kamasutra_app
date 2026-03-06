import 'package:equatable/equatable.dart';

// ==================== SQUARE TYPES ====================

enum GooseSquareType {
  normal,   // Casella normale
  ladder,   // 🪜 Scala: avanza + ricompensa dal partner
  hole,     // 🕳️ Buco: torna indietro + penitenza
  penance,  // 🔥 Penitenza hot
  finish,   // 🏆 Arrivo
}

extension GooseSquareTypeExtension on GooseSquareType {
  String get emoji {
    switch (this) {
      case GooseSquareType.normal:  return '';
      case GooseSquareType.ladder:  return '🪜';
      case GooseSquareType.hole:    return '🕳️';
      case GooseSquareType.penance: return '🔥';
      case GooseSquareType.finish:  return '🏆';
    }
  }

  String get nameIt {
    switch (this) {
      case GooseSquareType.normal:  return 'Normale';
      case GooseSquareType.ladder:  return 'Scala';
      case GooseSquareType.hole:    return 'Buco';
      case GooseSquareType.penance: return 'Penitenza';
      case GooseSquareType.finish:  return 'Arrivo';
    }
  }
}

// ==================== BOARD SQUARE ====================

class GooseSquare extends Equatable {
  final int position;
  final GooseSquareType type;
  final int? destination; // For ladder/hole: where to jump

  const GooseSquare({
    required this.position,
    required this.type,
    this.destination,
  });

  @override
  List<Object?> get props => [position, type, destination];
}

// ==================== CONTENT (reward / penance) ====================

class GooseContent {
  final String text;
  final int? timerSeconds; // null = not timed

  const GooseContent(this.text, {this.timerSeconds});
}

// ==================== GAME CONFIG ====================

class GooseGameConfig extends Equatable {
  final String player1Name;
  final String player2Name;

  const GooseGameConfig({
    this.player1Name = 'Giocatore 1',
    this.player2Name = 'Giocatore 2',
  });

  GooseGameConfig copyWith({String? player1Name, String? player2Name}) {
    return GooseGameConfig(
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
    );
  }

  @override
  List<Object?> get props => [player1Name, player2Name];
}

// ==================== BOARD CONSTANTS ====================

/// Ladders: key = from, value = to (jump always +8..+12)
const Map<int, int> kLadderMap = {
   6: 16,   // +10
  13: 21,   // +8
  26: 36,   // +10
  40: 50,   // +10
  53: 63,   // +10
  66: 76,   // +10
  78: 88,   // +10
  85: 95,   // +10
};

/// Holes: key = from, value = to (jump always -8..-10)
/// Extra holes added in the 10-49 range.
const Map<int, int> kHoleMap = {
  18: 9,    // -9  [10-49 zone]
  29: 19,   // -10 [10-49 zone]
  37: 27,   // -10 [10-49 zone]
  44: 34,   // -10 [10-49 zone]
  57: 48,   // -9
  71: 61,   // -10
  83: 73,   // -10
  96: 86,   // -10
};

/// Penance squares (scattered)
const Set<int> kPenanceSquares = {3, 8, 15, 22, 30, 35, 42, 47, 55, 68, 75, 82, 90};

// ==================== REWARDS (120) ====================

const List<GooseContent> kRewards = [
  // ── Massaggi & coccole ──
  GooseContent('Il partner ti massaggia dove vuoi per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Il partner ti massaggia i piedi per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Il partner ti massaggia le spalle per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Il partner ti massaggia la schiena per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Il partner ti massaggia le gambe per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Il partner ti massaggia la testa per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Il partner ti massaggia con lozione per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Il partner ti massaggia i glutei per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Il partner ti massaggia i seni/petto per 2 minuti ❤️‍🔥', timerSeconds: 120),
  GooseContent('Il partner ti massaggia l\'inguine per 30 secondi ❤️‍🔥', timerSeconds: 30),
  GooseContent('Il partner ti massaggia l\'interno coscia salendo lentamente per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Il partner ti massaggia tutto il corpo con olio caldo per 5 minuti 💆', timerSeconds: 300),

  // ── Baci ──
  GooseContent('Il partner ti bacia il collo per 1 minuto 💋', timerSeconds: 60),
  GooseContent('Il partner ti bacia dove vuoi per 1 minuto 💋', timerSeconds: 60),
  GooseContent('Il partner ti dà 10 baci passionali dove vuoi tu 💋'),
  GooseContent('Il partner ti bacia il ventre per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Il partner ti bacia le dita lentamente una ad una 💋'),
  GooseContent('Il partner ti bacia la nuca per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Il partner ti bacia le spalle per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Il partner ti bacia le caviglie e risale fino alle ginocchia 💋'),
  GooseContent('Il partner ti bacia lungo tutta la schiena scendendo fino ai glutei 💋'),
  GooseContent('Il partner ti bacia le labbra con la lingua per 45 secondi 💋', timerSeconds: 45),
  GooseContent('Il partner ti morde il labbro inferiore dolcemente 💋'),
  GooseContent('Il partner ti bacia e morde il lobo dell\'orecchio per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Il partner ti copre di baci dalla testa ai piedi 💋'),
  GooseContent('Il partner ti bacia la pancia scendendo fino al pube 💋'),
  GooseContent('Il partner ti bacia e succhia il collo lasciando un segno 💋'),

  // ── Lingua & orale ──
  GooseContent('Il partner ti lecca lentamente dal collo al ventre 👅'),
  GooseContent('Il partner ti lecca i capezzoli per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Il partner ti lecca un dito lentamente 👅'),
  GooseContent('Il partner ti lecca la schiena scendendo fino ai glutei 👅'),
  GooseContent('Il partner ti lecca e succhia dove preferisci per 45 secondi 👅', timerSeconds: 45),
  GooseContent('Il partner usa la lingua dove preferisci per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Il partner ti lecca il collo e l\'orecchio per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Il partner ti lecca le labbra lentamente 👅'),
  GooseContent('Il partner ti fa un pompino/cunnilingus per 1 minuto 👅', timerSeconds: 60),
  GooseContent('Il partner ti stimola oralmente senza fermarsi per 2 minuti 👅', timerSeconds: 120),
  GooseContent('Il partner ti fa godere oralmente per 45 secondi 👅', timerSeconds: 45),
  GooseContent('Il partner ti porta all\'orgasmo con la bocca 😈'),
  GooseContent('Fate un 69 per 1 minuto 🔥', timerSeconds: 60),
  GooseContent('Fate sesso orale reciproco per 1 minuto 🔥', timerSeconds: 60),
  GooseContent('Il partner ti fa un pompino/cunnilingus profondo per 2 minuti 👅', timerSeconds: 120),
  GooseContent('Il partner ti lecca i testicoli/le grandi labbra per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Il partner ti succhia i capezzoli alternando con morsi leggeri per 1 minuto 👅', timerSeconds: 60),
  GooseContent('Il partner ti lecca il perineo lentamente per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Il partner ti fa un pompino/cunnilingus mentre ti guarda negli occhi 👅', timerSeconds: 90),
  GooseContent('Il partner usa la lingua a cerchi sulla tua zona più sensibile per 1 minuto 👅', timerSeconds: 60),
  GooseContent('Il partner ti fa un deepthroat/cunnilingus profondo e lento 👅', timerSeconds: 60),
  GooseContent('Fate un 69 fino a quando uno dei due non ce la fa più 🔥'),

  // ── Mani & dita ──
  GooseContent('Il partner ti accarezza dove preferisci per 1 minuto ❤️', timerSeconds: 60),
  GooseContent('Il partner ti guida la sua mano dove vuoi 🔥'),
  GooseContent('Il partner ti eccita con dita e lingua insieme per 1 minuto ❤️‍🔥', timerSeconds: 60),
  GooseContent('Il partner ti tocca dove eccita di più per 30 secondi ❤️‍🔥', timerSeconds: 30),
  GooseContent('Il partner ti accarezza l\'interno coscia per 30 secondi ❤️‍🔥', timerSeconds: 30),
  GooseContent('Il partner ti fa godere con le mani per 1 minuto ❤️‍🔥', timerSeconds: 60),
  GooseContent('Il partner ti guarda negli occhi mentre ti tocca lentamente ❤️‍🔥'),
  GooseContent('Il partner ti masturba lentamente per 2 minuti ❤️‍🔥', timerSeconds: 120),
  GooseContent('Il partner ti stimola con le dita dentro e fuori per 1 minuto ❤️‍🔥', timerSeconds: 60),
  GooseContent('Il partner ti accarezza i capezzoli con le dita bagnate 👅'),
  GooseContent('Il partner ti sfiora tutto il corpo con la punta delle dita per 1 minuto ❤️', timerSeconds: 60),
  GooseContent('Il partner ti masturba cambiando ritmo a suo piacimento per 2 minuti ❤️‍🔥', timerSeconds: 120),
  GooseContent('Il partner ti penetra con le dita lentamente per 1 minuto 🔥', timerSeconds: 60),

  // ── Spogliarello & stuzzicamento ──
  GooseContent('Il partner ti fa lo spogliarello 👀'),
  GooseContent('Il partner ti dedica una danza sensuale solo per te 💃'),
  GooseContent('Il partner deve rimanere in intimo per i prossimi 3 turni 😈'),
  GooseContent('Il partner ti veste o spoglia lentamente a scelta tua 👗'),
  GooseContent('Il partner ti spoglia completamente molto lentamente 😈'),
  GooseContent('Il partner ti fa una lap dance sensuale con musica 💃'),
  GooseContent('Il partner ti toglie i pantaloni lentamente con le mani 👖'),
  GooseContent('Il partner si inginocchia davanti a te e ti toglie le scarpe lentamente 👠'),
  GooseContent('Il partner si toglie l\'intimo davanti a te muovendosi sensualmente 😈'),
  GooseContent('Il partner si mette a quattro zampe davanti a te e ti guarda 😈'),
  GooseContent('Il partner ti toglie l\'intimo con i denti 😈'),

  // ── Fantasie & parole ──
  GooseContent('Il partner ti sussurra le sue fantasie più segrete 🤫'),
  GooseContent('Il partner ti racconta la sua fantasia più hot 🔥'),
  GooseContent('Il partner ti svela il punto più sensibile del suo corpo 🤫'),
  GooseContent('Il partner ti fa una proposta osé per dopo il gioco 💌'),
  GooseContent('Il partner ti svela la sua fantasia più segreta di sempre 🤫'),
  GooseContent('Il partner ti dice 5 cose hot che apprezza del tuo corpo 💌'),
  GooseContent('Il partner ti descrive in dettaglio come ti farebbe l\'amore 🔥'),
  GooseContent('Il partner ti sussurra ciò che ti farebbe se foste soli 🤫'),
  GooseContent('Il partner recita una fantasia sessuale esplicita completa 🔥'),
  GooseContent('Il partner ti sussurra parole oscene all\'orecchio per 30 secondi 🔥', timerSeconds: 30),
  GooseContent('Il partner ti fa un complimento hot su ogni parte del corpo 💌'),
  GooseContent('Il partner ti dice esattamente come vuole scoparti stasera 🔥'),
  GooseContent('Il partner ti descrive la posizione sessuale che preferisce con te 🔥'),
  GooseContent('Il partner geme il tuo nome all\'orecchio come se steste facendo l\'amore 🔥'),

  // ── Dominio & gioco di potere ──
  GooseContent('Il partner deve obbedirti per il prossimo turno 😈'),
  GooseContent('Il partner esegue qualsiasi tuo desiderio hot (entro i vostri limiti) 🔥'),
  GooseContent('Il partner ti permette di fare ciò che vuoi a lui/lei per 2 minuti 😈', timerSeconds: 120),
  GooseContent('Il partner ti fa ciò che vuoi tu senza limiti per 3 minuti 🔥', timerSeconds: 180),
  GooseContent('Il partner ti porta in camera e ti lega le mani con la sua cintura 😈'),
  GooseContent('Il partner si sottomette a te per 5 minuti: fai quello che vuoi 😈', timerSeconds: 300),
  GooseContent('Il partner si mette in ginocchio davanti a te e aspetta i tuoi ordini 😈'),
  GooseContent('Il partner ti chiama "padrone/padrona" per i prossimi 3 turni 😈'),
  GooseContent('Il partner ti benda e fa quello che vuole al tuo corpo per 2 minuti 😈', timerSeconds: 120),

  // ── Contatto fisico intenso ──
  GooseContent('Il partner ti stringe i fianchi e ti avvicina a sé lentamente 🔥'),
  GooseContent('Il partner ti soffia sul collo per 30 secondi 😮‍💨', timerSeconds: 30),
  GooseContent('Il partner ti guida in una danza intima per 1 minuto 💃', timerSeconds: 60),
  GooseContent('Il partner ti disegna un cuore con il dito su una parte del corpo ❤️'),
  GooseContent('Il partner ti scrive una parola hot con il dito sul corpo ✍️'),
  GooseContent('Il partner ti siede in grembo e ti abbraccia per 1 minuto ❤️', timerSeconds: 60),
  GooseContent('Il partner simula ciò che ti farebbe a letto senza toccarti 🔥'),
  GooseContent('Il partner strofina il suo corpo contro il tuo lentamente per 1 minuto 🔥', timerSeconds: 60),
  GooseContent('Il partner si stende sopra di te nudo/a e vi baciate per 2 minuti 🔥', timerSeconds: 120),
  GooseContent('Il partner preme il suo bacino contro il tuo simulando la penetrazione 🔥'),
  GooseContent('Il partner ti cavalca sopra vestiti simulando il sesso per 1 minuto 🔥', timerSeconds: 60),

  // ── Attenzioni prolungate ──
  GooseContent('Il partner ti fa 5 minuti di attenzioni a scelta tua ⏱️', timerSeconds: 300),
  GooseContent('Il partner ti dedica 5 minuti di piacere totale 🔥', timerSeconds: 300),
  GooseContent('Il partner ti fa impazzire usando solo le labbra per 1 minuto 💋', timerSeconds: 60),
  GooseContent('Il partner ti fa un\'azione a sorpresa che hai sempre desiderato 🔥'),
  GooseContent('Il partner ti fa una sorpresa hot a sua scelta 🎁'),
  GooseContent('Il partner ti fa un regalo hot a sua scelta entro la fine della serata 🎁'),
  GooseContent('Il partner ti promette il tuo atto sessuale preferito dopo il gioco 😈'),

  // ── Sesso esplicito ──
  GooseContent('Il partner ti masturba fino all\'orgasmo 🔥'),
  GooseContent('Il partner ti fa un pompino/cunnilingus fino a quando vieni 👅'),
  GooseContent('Il partner ti fa venire con la combinazione bocca + mani 👅'),
  GooseContent('Il partner ti fa sesso orale nella posizione che preferisci per 3 minuti 👅', timerSeconds: 180),
  GooseContent('Il partner ti cavalca per 1 minuto (con i vestiti o senza) 🔥', timerSeconds: 60),
  GooseContent('Il partner ti fa una sega/ditalino guardandoti negli occhi 🔥', timerSeconds: 90),
  GooseContent('Il partner ti stuzzica con la punta della lingua sulla zona più sensibile per 2 minuti 👅', timerSeconds: 120),
  GooseContent('Il partner si siede sulla tua faccia per 30 secondi 🔥', timerSeconds: 30),
  GooseContent('Il partner ti fa un handjob/fingering lento e sensuale per 3 minuti ❤️‍🔥', timerSeconds: 180),
  GooseContent('Il partner ti fa un edging: ti porta quasi all\'orgasmo 3 volte senza farti venire 🔥'),
];

// ==================== PENANCES (120) ====================

const List<GooseContent> kPenances = [
  // ── Massaggi & servizio ──
  GooseContent('Massaggia il partner dove vuole per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Fai un massaggio alla schiena del partner per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Fai il massaggio alle spalle del partner per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Massaggia i glutei del partner per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Massaggia il petto/seni del partner per 2 minuti ❤️‍🔥', timerSeconds: 120),
  GooseContent('Massaggia l\'inguine del partner per 30 secondi ❤️‍🔥', timerSeconds: 30),
  GooseContent('Massaggia le gambe del partner salendo lentamente per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Massaggia tutto il corpo del partner con olio per 5 minuti 💆', timerSeconds: 300),
  GooseContent('Massaggia i piedi del partner per 2 minuti 💆', timerSeconds: 120),

  // ── Baci ──
  GooseContent('Bacia il partner dove vuole per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Fai 10 baci passionali al partner dove vuole lui/lei 💋'),
  GooseContent('Bacia il collo del partner per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Bacia il ventre del partner per 20 secondi 💋', timerSeconds: 20),
  GooseContent('Bacia e mordi dolcemente il lobo dell\'orecchio del partner per 20 secondi 💋', timerSeconds: 20),
  GooseContent('Bacia il partner lungo tutta la schiena scendendo fino ai glutei 💋'),
  GooseContent('Bacia il partner con la lingua per 45 secondi 💋', timerSeconds: 45),
  GooseContent('Mordi il labbro inferiore del partner dolcemente 💋'),
  GooseContent('Bacia la pancia del partner scendendo fino al pube 💋'),
  GooseContent('Bacia e succhia il collo del partner lasciando un segno 💋'),
  GooseContent('Bacia l\'interno coscia del partner avvicinandoti al centro 💋'),
  GooseContent('Bacia ogni centimetro del corpo nudo del partner 💋'),

  // ── Lingua & orale ──
  GooseContent('Lecca il partner dal collo al ventre lentamente 👅'),
  GooseContent('Lecca i capezzoli del partner per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Lecca il collo e l\'orecchio del partner per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Lecca le labbra del partner lentamente 👅'),
  GooseContent('Usa la lingua dove vuole il partner per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Fai un pompino/cunnilingus al partner per 1 minuto 👅', timerSeconds: 60),
  GooseContent('Stimola il partner oralmente per 2 minuti senza fermarti 👅', timerSeconds: 120),
  GooseContent('Fai godere il partner oralmente per 45 secondi 👅', timerSeconds: 45),
  GooseContent('Fate un 69 per 1 minuto 🔥', timerSeconds: 60),
  GooseContent('Eccita il partner con dita e lingua insieme per 1 minuto ❤️‍🔥', timerSeconds: 60),
  GooseContent('Fai un pompino/cunnilingus profondo al partner per 2 minuti 👅', timerSeconds: 120),
  GooseContent('Lecca i testicoli/le grandi labbra del partner per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Succhia i capezzoli del partner alternando con morsi leggeri per 1 minuto 👅', timerSeconds: 60),
  GooseContent('Lecca il perineo del partner lentamente per 30 secondi 👅', timerSeconds: 30),
  GooseContent('Fai un pompino/cunnilingus al partner guardandolo negli occhi 👅', timerSeconds: 90),
  GooseContent('Usa la lingua a cerchi sulla zona più sensibile del partner per 1 minuto 👅', timerSeconds: 60),
  GooseContent('Fai un deepthroat/cunnilingus profondo e lento al partner 👅', timerSeconds: 60),
  GooseContent('Fai un 69 al partner fino a quando uno dei due non ce la fa più 🔥'),
  GooseContent('Fai sesso orale al partner nella sua posizione preferita per 3 minuti 👅', timerSeconds: 180),
  GooseContent('Lecca il partner dalla caviglia fino all\'inguine senza fermarti 👅'),

  // ── Mani & dita ──
  GooseContent('Lascia che il partner ti tocchi dove vuole per 30 secondi ❤️', timerSeconds: 30),
  GooseContent('Tocca il partner dove eccita di più per 30 secondi ❤️‍🔥', timerSeconds: 30),
  GooseContent('Accarezza l\'interno coscia del partner per 30 secondi ❤️‍🔥', timerSeconds: 30),
  GooseContent('Fai godere il partner con le mani per 1 minuto ❤️‍🔥', timerSeconds: 60),
  GooseContent('Guarda il partner negli occhi mentre lo tocchi lentamente ❤️‍🔥'),
  GooseContent('Masturba il partner lentamente per 2 minuti ❤️‍🔥', timerSeconds: 120),
  GooseContent('Stimola il partner con le dita dentro e fuori per 1 minuto ❤️‍🔥', timerSeconds: 60),
  GooseContent('Accarezza i capezzoli del partner con le dita bagnate 👅'),
  GooseContent('Sfiora tutto il corpo del partner con la punta delle dita per 1 minuto ❤️', timerSeconds: 60),
  GooseContent('Masturba il partner cambiando ritmo a tuo piacimento per 2 minuti ❤️‍🔥', timerSeconds: 120),
  GooseContent('Penetra il partner con le dita lentamente per 1 minuto 🔥', timerSeconds: 60),
  GooseContent('Fai una sega/ditalino al partner guardandolo negli occhi 🔥', timerSeconds: 90),

  // ── Spogliarello & provocazione ──
  GooseContent('Fai uno spogliarello lento davanti al partner 😈'),
  GooseContent('Rimani in intimo per i prossimi 3 turni 😈'),
  GooseContent('Balla in modo sensuale davanti al partner per 1 minuto 💃', timerSeconds: 60),
  GooseContent('Togli un capo di abbigliamento al partner lentamente 👗'),
  GooseContent('Fai uno spogliarello con musica (metti la musica!) 💃'),
  GooseContent('Fai una lap dance al partner con musica 💃'),
  GooseContent('Togli i pantaloni al partner lentamente con le mani 👖'),
  GooseContent('Spoglia il partner completamente molto lentamente 😈'),
  GooseContent('Togli un capo intimo al partner con i denti 😈'),
  GooseContent('Togliti l\'intimo davanti al partner muovendoti sensualmente 😈'),
  GooseContent('Mettiti a quattro zampe davanti al partner e guardalo 😈'),
  GooseContent('Mostra al partner come ti tocchi quando sei solo/a 🔥'),

  // ── Fantasie & parole ──
  GooseContent('Descrivi ad alta voce il tuo desiderio più segreto 🤫'),
  GooseContent('Sussurra all\'orecchio del partner cosa gli faresti stanotte 🔥'),
  GooseContent('Racconta la tua fantasia più hot senza vergogna 🔥'),
  GooseContent('Di\' al partner 3 cose che ti piacciono del suo corpo in modo esplicito 💌'),
  GooseContent('Confessa il tuo spot più sensibile al partner 🤫'),
  GooseContent('Guarda il partner negli occhi e di\' la tua fantasia più proibita 👀'),
  GooseContent('Racconta un sogno erotico che hai fatto 🔥'),
  GooseContent('Descrivi in dettaglio cosa faresti al partner se foste soli 🤫'),
  GooseContent('Ammetti la cosa più hot che pensi del partner in questo momento 🔥'),
  GooseContent('Racconta al partner come immagini la vostra prossima serata hot 🔥'),
  GooseContent('Recita ad alta voce la tua fantasia sessuale più esplicita 🔥'),
  GooseContent('Di\' ad alta voce 3 cose che vorresti che il partner ti facesse 🔥'),
  GooseContent('Fai una dichiarazione hot al partner guardandolo negli occhi 💌'),
  GooseContent('Di\' 5 cose che ti eccitano del partner senza filtri 💌'),
  GooseContent('Descrivi ad alta voce come faresti l\'amore al partner stasera 🔥'),
  GooseContent('Di\' al partner esattamente come vuoi essere scopato/a 🔥'),
  GooseContent('Gemi il nome del partner come se steste facendo l\'amore 🔥'),
  GooseContent('Descrivi la posizione sessuale che preferisci con il partner 🔥'),

  // ── Dominio & sottomissione ──
  GooseContent('Esegui un ordine hot a scelta del partner 😈'),
  GooseContent('Obbedisci a un comando hot del partner per il prossimo turno 😈'),
  GooseContent('Il partner decide il tuo forfait: esegui senza proteste! 😈'),
  GooseContent('Accetta una sfida hot proposta dal partner 😈'),
  GooseContent('Lascia che il partner decida la tua prossima mossa di coppia 😈'),
  GooseContent('Lascia che il partner ti leghi delicatamente le mani per 30 secondi ❤️', timerSeconds: 30),
  GooseContent('Lega le mani del partner con la tua cintura per 30 secondi 😈', timerSeconds: 30),
  GooseContent('Lascia che il partner faccia ciò che vuole a te per 2 minuti 😈', timerSeconds: 120),
  GooseContent('Fai al partner ciò che vuole lui/lei per 3 minuti 🔥', timerSeconds: 180),
  GooseContent('Rimani immobile mentre il partner fa quello che vuole per 1 minuto ❤️', timerSeconds: 60),
  GooseContent('Mettiti in ginocchio davanti al partner e aspetta i suoi ordini 😈'),
  GooseContent('Chiama il partner "padrone/padrona" per i prossimi 3 turni 😈'),
  GooseContent('Fatti bendare e lascia che il partner ti tocchi dove vuole per 2 minuti 😈', timerSeconds: 120),

  // ── Contatto fisico intenso ──
  GooseContent('Imita la posizione del Kamasutra che preferisci 🔥'),
  GooseContent('Mostra al partner dove vuoi essere baciato/a 💋'),
  GooseContent('Mostra al partner come ti piace essere toccato/a 🔥'),
  GooseContent('Scrivi con un dito sul corpo del partner una parola hot ✍️'),
  GooseContent('Spingi il partner contro il muro e bacialo passionalmente 🔥'),
  GooseContent('Simula ciò che faresti al partner a letto senza toccarlo 🔥'),
  GooseContent('Siediti in grembo al partner abbracciandolo per 1 minuto ❤️', timerSeconds: 60),
  GooseContent('Strofina il tuo corpo contro quello del partner per 1 minuto 🔥', timerSeconds: 60),
  GooseContent('Stenditi sopra il partner nudo/a e baciatevi per 2 minuti 🔥', timerSeconds: 120),
  GooseContent('Premi il tuo bacino contro quello del partner simulando la penetrazione 🔥'),
  GooseContent('Cavalca il partner sopra i vestiti simulando il sesso per 1 minuto 🔥', timerSeconds: 60),
  GooseContent('Siediti sulla faccia del partner per 30 secondi 🔥', timerSeconds: 30),
  GooseContent('Dimostra al partner in cosa sei bravo/a a letto adesso 🔥'),

  // ── Sesso esplicito ──
  GooseContent('Masturba il partner fino all\'orgasmo 🔥'),
  GooseContent('Fai un pompino/cunnilingus al partner fino a quando viene 👅'),
  GooseContent('Fai venire il partner con la combinazione bocca + mani 👅'),
  GooseContent('Fai un handjob/fingering lento e sensuale al partner per 3 minuti ❤️‍🔥', timerSeconds: 180),
  GooseContent('Fai un edging al partner: portalo quasi all\'orgasmo 3 volte senza farlo venire 🔥'),
  GooseContent('Prometti al partner un atto hot a sua scelta entro stasera 🎁'),
  GooseContent('Fai al partner una cosa che non ha mai ricevuto prima 🔥'),
];

// ==================== FINAL REWARDS (victory prizes) ====================

const List<GooseContent> kFinalRewards = [
  // ── Posizioni sessuali ──
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nMissionario con le gambe sulle spalle 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nPecorina (doggy style) 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nCowgirl / Amazzone 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nReverse cowgirl 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nA cucchiaio (spooning) 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\n69 fino all\'orgasmo 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nLotus: seduti uno di fronte all\'altra 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nIn piedi contro il muro 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nSulla sedia / divano 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nA gambe incrociate (pretzel) 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nMissionario con cuscino sotto i fianchi 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nDoggy style con una mano tra le gambe 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nSul tavolo / ripiano della cucina 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nCowgirl al contrario con le mani legate 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il partner sceglie la posizione!\nSotto la doccia 🔥'),

  // ── Atti sessuali espliciti ──
  GooseContent('🏆 PREMIO FINALE: Cunnilingus fino all\'orgasmo!\nIl perdente deve farlo senza fermarsi 👅'),
  GooseContent('🏆 PREMIO FINALE: Pompino fino all\'orgasmo!\nIl perdente deve farlo senza fermarsi 👅'),
  GooseContent('🏆 PREMIO FINALE: Sesso orale a volontà!\nIl vincitore decide quanto dura e come 👅'),
  GooseContent('🏆 PREMIO FINALE: 69 fino all\'orgasmo reciproco!\nNessuno si ferma prima 🔥'),
  GooseContent('🏆 PREMIO FINALE: Il vincitore viene servito!\nIl partner fa tutto ciò che chiede per 10 minuti 😈', timerSeconds: 600),
  GooseContent('🏆 PREMIO FINALE: Deepthroat / cunnilingus profondo!\nIl perdente deve dare il massimo per 5 minuti 👅', timerSeconds: 300),
  GooseContent('🏆 PREMIO FINALE: Handjob / fingering fino all\'orgasmo!\nIl perdente usa solo le mani ❤️‍🔥'),
  GooseContent('🏆 PREMIO FINALE: Sesso nella posizione preferita del vincitore!\nSenza limiti di tempo 🔥'),
  GooseContent('🏆 PREMIO FINALE: Edging estremo!\nIl perdente porta il vincitore quasi all\'orgasmo 5 volte prima di farlo venire 🔥'),
  GooseContent('🏆 PREMIO FINALE: Schiavo/a sessuale per 15 minuti!\nIl perdente obbedisce a ogni ordine 😈', timerSeconds: 900),
  GooseContent('🏆 PREMIO FINALE: Striptease completo + lap dance!\nPoi il vincitore decide come finire la serata 💃'),
  GooseContent('🏆 PREMIO FINALE: Massaggio erotico completo con happy ending!\nOlio, candele e piacere totale 💆'),
  GooseContent('🏆 PREMIO FINALE: Il vincitore sceglie 3 atti sessuali!\nIl perdente li esegue tutti senza discutere 🔥'),
  GooseContent('🏆 PREMIO FINALE: Sesso orale reciproco + posizione a scelta!\nPrima il 69, poi il vincitore sceglie come continuare 🔥'),
  GooseContent('🏆 PREMIO FINALE: Notte di passione totale!\nIl vincitore decide tutto: posizioni, ritmo e durata 🔥'),
];
