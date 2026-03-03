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

/// Ladders: key = from, value = to (always advances forward)
const Map<int, int> kLadderMap = {
  4:  14,
  9:  31,
  20: 38,
  28: 84,
  40: 59,
  51: 67,
  63: 81,
  71: 91,
};

/// Holes: key = from, value = to (always goes back)
const Map<int, int> kHoleMap = {
  17: 7,
  54: 34,
  62: 19,
  64: 60,
  87: 24,
  93: 73,
  95: 75,
  99: 78,
};

/// Penance squares (scattered)
const Set<int> kPenanceSquares = {3, 8, 15, 22, 30, 35, 42, 47, 55, 68, 75, 82, 90};

// ==================== REWARDS (50) ====================

const List<GooseContent> kRewards = [
  GooseContent('Il partner ti massaggia dove vuoi per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Il partner ti bacia il collo per 1 minuto 💋', timerSeconds: 60),
  GooseContent('Il partner ti fa lo spogliarello 👀'),
  GooseContent('Il partner ti sussurra le sue fantasie più segrete 🤫'),
  GooseContent('Il partner ti massaggia i piedi per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Il partner ti dedica una danza sensuale solo per te 💃'),
  GooseContent('Il partner ti bacia dove vuoi per 1 minuto 💋', timerSeconds: 60),
  GooseContent('Il partner ti porta in braccio fino al letto 🛏️'),
  GooseContent('Il partner ti accarezza i capelli per 2 minuti ❤️', timerSeconds: 120),
  GooseContent('Il partner ti guarda negli occhi senza parlare per 1 minuto 👀', timerSeconds: 60),
  GooseContent('Il partner ti scrive una parola hot con il dito sul corpo ✍️'),
  GooseContent('Il partner ti dà 10 baci passionali dove vuoi tu 💋'),
  GooseContent('Il partner ti massaggia le spalle per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Il partner ti racconta la sua fantasia più hot 🔥'),
  GooseContent('Il partner deve rimanere in intimo per i prossimi 3 turni 😈'),
  GooseContent('Il partner ti bacia il ventre per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Il partner ti accarezza dove preferisci per 1 minuto ❤️', timerSeconds: 60),
  GooseContent('Il partner ti fa una proposta osé per dopo il gioco 💌'),
  GooseContent('Il partner ti svela il punto più sensibile del suo corpo 🤫'),
  GooseContent('Il partner ti abbraccia forte per 30 secondi 🤗', timerSeconds: 30),
  GooseContent('Il partner ti guida la sua mano dove vuoi 🔥'),
  GooseContent('Il partner ti fa 5 minuti di attenzioni a scelta tua ⏱️', timerSeconds: 300),
  GooseContent('Il partner ti massaggia la schiena per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Il partner si inginocchia davanti a te e ti toglie le scarpe lentamente 👠'),
  GooseContent('Il partner ti bacia le dita lentamente una ad una 💋'),
  GooseContent('Il partner ti svela la sua fantasia più segreta di sempre 🤫'),
  GooseContent('Il partner ti soffia sul collo per 30 secondi 😮‍💨', timerSeconds: 30),
  GooseContent('Il partner ti dedica 5 minuti di piacere totale 🔥', timerSeconds: 300),
  GooseContent('Il partner ti bacia la nuca per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Il partner ti veste o spoglia lentamente a scelta tua 👗'),
  GooseContent('Il partner ti recita una poesia sensuale improvvisata 🎭'),
  GooseContent('Il partner esegue qualsiasi tuo desiderio hot (entro i vostri limiti) 🔥'),
  GooseContent('Il partner ti lecca un dito lentamente 👅'),
  GooseContent('Il partner ti massaggia le gambe per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Il partner ti bacia sulla fronte, sul naso e sulle labbra ❤️'),
  GooseContent('Il partner ti accarezza il viso per 1 minuto ❤️', timerSeconds: 60),
  GooseContent('Il partner deve obbedirti per il prossimo turno 😈'),
  GooseContent('Il partner ti fa un complimento hot su ogni parte del corpo 💌'),
  GooseContent('Il partner ti stringe la mano e ti porta dove vuole ❤️'),
  GooseContent('Il partner ti fa una sorpresa hot a sua scelta 🎁'),
  GooseContent('Il partner ti sussurra ciò che ti farebbe se foste soli 🤫'),
  GooseContent('Il partner ti massaggia con lozione per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Il partner ti bacia le spalle per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Il partner ti guida in una danza intima per 1 minuto 💃', timerSeconds: 60),
  GooseContent('Il partner ti disegna un cuore con il dito su una parte del corpo ❤️'),
  GooseContent('Il partner ti dice 5 cose hot che apprezza del tuo corpo 💌'),
  GooseContent('Il partner ti bacia le caviglie e risale fino alle ginocchia 💋'),
  GooseContent('Il partner ti massaggia la testa per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Il partner mimа la vostra posizione del Kamasutra preferita 🔥'),
  GooseContent('Il partner ti invita a un momento intimo subito dopo il gioco 💑'),
];

// ==================== PENANCES (50) ====================

const List<GooseContent> kPenances = [
  GooseContent('Massaggia il partner dove vuole per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Descrivi ad alta voce il tuo desiderio più segreto 🤫'),
  GooseContent('Bacia il partner dove vuole per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Fai uno spogliarello lento davanti al partner 😈'),
  GooseContent('Rimani in intimo per i prossimi 3 turni 😈'),
  GooseContent('Sussurra all\'orecchio del partner cosa gli faresti stanotte 🔥'),
  GooseContent('Fai 10 baci passionali al partner dove vuole lui/lei 💋'),
  GooseContent('Racconta la tua fantasia più hot senza vergogna 🔥'),
  GooseContent('Imita la posizione del Kamasutra che preferisci 🔥'),
  GooseContent('Lascia che il partner ti tocchi dove vuole per 30 secondi ❤️', timerSeconds: 30),
  GooseContent('Fai un massaggio alla schiena del partner per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Balla in modo sensuale davanti al partner per 1 minuto 💃', timerSeconds: 60),
  GooseContent('Di\' al partner 3 cose che ti piacciono del suo corpo in modo esplicito 💌'),
  GooseContent('Lascia che il partner ti baci dove vuole per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Confessa il tuo spot più sensibile al partner 🤫'),
  GooseContent('Esegui un ordine hot a scelta del partner 😈'),
  GooseContent('Fai il massaggio ai piedi del partner per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Guarda il partner negli occhi e di\' la tua fantasia più proibita 👀'),
  GooseContent('Rimani immobile mentre il partner ti accarezza per 30 secondi ❤️', timerSeconds: 30),
  GooseContent('Mostra al partner dove vuoi essere baciato/a 💋'),
  GooseContent('Canta sottovoce una canzone romantica/sexy al partner 🎵'),
  GooseContent('Scrivi con un dito sul corpo del partner una parola hot ✍️'),
  GooseContent('Lascia che il partner decida la tua prossima mossa di coppia 😈'),
  GooseContent('Fai una dichiarazione hot al partner guardandolo negli occhi 💌'),
  GooseContent('Racconta un sogno erotico che hai fatto 🔥'),
  GooseContent('Rimani in silenzio mentre il partner ti tocca dove vuole per 20 secondi ❤️', timerSeconds: 20),
  GooseContent('Fai il massaggio alla testa del partner per 2 minuti 💆', timerSeconds: 120),
  GooseContent('Bacia il collo del partner per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Recita una scena romantica con il partner come protagonisti 🎭'),
  GooseContent('Lascia che il partner ti leghi delicatamente le mani per 30 secondi ❤️', timerSeconds: 30),
  GooseContent('Mostra al partner come ti piace essere toccato/a 🔥'),
  GooseContent('Di\' 5 cose che ti eccitano del partner senza filtri 💌'),
  GooseContent('Accetta una sfida hot proposta dal partner 😈'),
  GooseContent('Fai il massaggio alle spalle del partner per 3 minuti 💆', timerSeconds: 180),
  GooseContent('Porta il partner in braccio (o faglielo fare a te) 🤗'),
  GooseContent('Bacia e mordi dolcemente il lobo dell\'orecchio del partner per 20 secondi 💋', timerSeconds: 20),
  GooseContent('Lascia che il partner ti copra di baci per 30 secondi ❤️', timerSeconds: 30),
  GooseContent('Descrivi in dettaglio cosa faresti al partner se foste soli 🤫'),
  GooseContent('Togli un capo di abbigliamento al partner lentamente 👗'),
  GooseContent('Fai un complimento hot su ogni parte del corpo del partner che tocchi 💌'),
  GooseContent('Obbedisci a un comando hot del partner per il prossimo turno 😈'),
  GooseContent('Bacia il ventre del partner per 20 secondi 💋', timerSeconds: 20),
  GooseContent('Ammetti la cosa più hot che pensi del partner in questo momento 🔥'),
  GooseContent('Stai fermo/a mentre il partner disegna sul tuo corpo per 30 secondi ❤️', timerSeconds: 30),
  GooseContent('Di\' al partner "sei irresistibile" e dimostraglielo subito 💋'),
  GooseContent('Il partner decide il tuo forfait: esegui senza proteste! 😈'),
  GooseContent('Di\' ad alta voce 3 cose che vorresti che il partner ti facesse 🔥'),
  GooseContent('Fai uno spogliarello con musica (metti la musica!) 💃'),
  GooseContent('Lascia che il partner ti baci lungo il braccio per 30 secondi 💋', timerSeconds: 30),
  GooseContent('Racconta al partner come immagini la vostra prossima serata hot 🔥'),
];
