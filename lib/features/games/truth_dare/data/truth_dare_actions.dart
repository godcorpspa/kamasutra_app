import 'dart:math';

/// Repository of all truth and dare actions organized by intensity.
/// Each category has 20+ items per intensity level.
class TruthDareActions {
  static final _random = Random();

  static String getTruth(String intensity) {
    final list = _truths[intensity];
    if (list == null || list.isEmpty) return 'Racconta qualcosa di piccante...';
    return list[_random.nextInt(list.length)];
  }

  static String getDare(String intensity) {
    final list = _dares[intensity];
    if (list == null || list.isEmpty) return 'Fai qualcosa di audace!';
    return list[_random.nextInt(list.length)];
  }

  // =========================================================
  // VERITÀ
  // =========================================================
  static const Map<String, List<String>> _truths = {
    'soft': [
      'Qual è il tuo ricordo più bello e romantico insieme?',
      'Cosa ti ha fatto innamorare del partner la prima volta?',
      'Qual è la parte del corpo del partner che ti piace di più?',
      'Hai mai sognato il partner? Racconta il sogno più bello.',
      'Qual è stato il bacio più indimenticabile tra voi?',
      'Cosa ti fa sentire più amato/a dal partner?',
      'C\'è un momento in cui hai sentito il cuore battere fortissimo per il partner?',
      'Qual è la prima cosa che hai notato del partner quando vi siete conosciuti?',
      'Hai mai scritto un messaggio romantico al partner che poi non hai inviato?',
      'Qual è la canzone che ti fa pensare al partner?',
      'Cosa vorresti fare nel prossimo anniversario?',
      'Qual è il complimento più bello che il partner ti abbia mai fatto?',
      'C\'è qualcosa che il partner fa inconsciamente e che ti fa impazzire?',
      'Qual è il tuo momento preferito della giornata con il partner?',
      'Quando hai capito per la prima volta di essere innamorato/a?',
      'Qual è il viaggio dei sogni che vorresti fare insieme?',
      'Hai mai pianto di felicità per qualcosa fatto dal partner?',
      'Qual è il profumo del partner che ti fa impazzire?',
      'Cosa ti piace di più del modo in cui il partner ti abbraccia?',
      'Se dovessi descrivere il partner con 3 parole quali sarebbero?',
    ],
    'spicy': [
      'Qual è la tua fantasia erotica segreta che non hai mai confessato?',
      'Qual è la cosa più audace che vorresti provare a letto?',
      'Dove vorresti fare l\'amore che non avete mai provato?',
      'Cosa ti eccita di più quando il partner ti tocca?',
      'Hai mai fantasticato sul partner in un momento inopportuno? Quando?',
      'Qual è il capo di abbigliamento del partner che ti eccita di più?',
      'Racconta la volta in cui ti sei eccitato/a di più con il partner.',
      'Qual è la posizione sessuale che preferisci e perché?',
      'Hai mai finto un orgasmo? Sii onesto/a!',
      'Cosa vorresti che il partner ti facesse più spesso a letto?',
      'Qual è il tuo punto debole segreto che il partner non conosce?',
      'Hai mai pensato al partner mentre ti toccavi da solo/a?',
      'Qual è il momento più imbarazzante che vi è capitato durante il sesso?',
      'Che tipo di porno ti eccita di più (se ne guardi)?',
      'Hai mai avuto una fantasia che coinvolgesse il partner e qualcun altro?',
      'Qual è la cosa più sexy che il partner abbia mai fatto senza rendersene conto?',
      'Quanto spesso pensi al sesso durante la giornata?',
      'C\'è un giocattolo erotico che vorresti provare?',
      'Qual è stata la migliore esperienza di sesso orale che hai avuto?',
      'Hai mai avuto un sogno erotico esplicito con il partner? Raccontalo.',
    ],
    'extra_spicy': [
      'Qual è la fantasia sessuale più estrema che hai mai avuto?',
      'Hai mai desiderato provare il BDSM? Cosa esattamente?',
      'Qual è la cosa più sporca che vorresti dire al partner durante il sesso?',
      'Hai mai fantasticato sul sesso anale? Racconta.',
      'Qual è la tua fantasia più proibita che non hai mai osato confessare?',
      'Se potessi fare QUALSIASI cosa a letto senza giudizio, cosa faresti?',
      'Hai mai fantasticato su un\'esperienza a tre? Con chi?',
      'Qual è la cosa più estrema che hai mai fatto sessualmente?',
      'Descrivi nel dettaglio come vorresti essere dominato/a.',
      'C\'è qualcosa di sessuale che consideri tabù ma che ti eccita segretamente?',
      'Hai mai desiderato essere legato/a o legare il partner?',
      'Qual è il posto più rischioso dove hai voluto fare sesso?',
      'Racconta la fantasia erotica che ti fa vergognare di più.',
      'Hai mai pensato di filmarvi durante il sesso?',
      'Qual è la cosa più selvaggia che vorresti provare col partner stanotte?',
      'Confessa: c\'è qualcosa che il partner non sa sulle tue preferenze sessuali?',
      'Hai mai fantasticato sulla sottomissione totale? Racconta.',
      'Qual è il tuo feticcio più nascosto?',
      'Descrivi l\'orgasmo più intenso che hai avuto e cosa lo ha provocato.',
      'Se avessi zero inibizioni per una notte, cosa faresti esattamente?',
    ],
  };

  // =========================================================
  // OBBLIGO
  // =========================================================
  static const Map<String, List<String>> _dares = {
    'soft': [
      'Dai un bacio appassionato al partner per almeno 20 secondi',
      'Abbraccia forte il partner sussurrandogli 3 cose che ami di lui/lei',
      'Bacia il collo del partner dolcemente per 30 secondi',
      'Massaggia le mani del partner guardandolo negli occhi',
      'Guarda negli occhi il partner per 1 minuto senza ridere né parlare',
      'Bacia la fronte, il naso e le labbra del partner lentamente',
      'Accarezza il viso del partner con le dita chiudendo gli occhi',
      'Sussurra all\'orecchio del partner cosa ami di più del suo corpo',
      'Dai 10 baci al partner in 10 punti diversi del viso',
      'Balla lento con il partner abbracciato per una canzone intera',
      'Massaggia le spalle del partner per 2 minuti con dolcezza',
      'Scrivi con il dito sulla schiena del partner "Ti amo" e fallo indovinare',
      'Bacia ogni dito della mano del partner uno per uno',
      'Racconta al partner il tuo ricordo più bello insieme guardandolo negli occhi',
      'Fai un massaggio ai piedi del partner per 1 minuto',
      'Abbraccia il partner da dietro e resta così per 1 minuto',
      'Dai un bacio a farfalla sulle palpebre chiuse del partner',
      'Accarezza i capelli del partner cantandogli una canzone',
      'Bacia il polso del partner e sussurra "sei mio/a"',
      'Tieni la mano del partner per 2 minuti accarezzandola senza parlare',
    ],
    'spicy': [
      'Bacia il collo del partner per 1 minuto alternando baci e respiri caldi',
      'Togli un capo di abbigliamento al partner in modo provocante',
      'Fai un massaggio sensuale alla schiena del partner per 3 minuti',
      'Sussurra all\'orecchio del partner la cosa più sexy che vuoi fargli',
      'Dai un bacio appassionato alla francese per 1 minuto',
      'Mordicchia delicatamente il lobo dell\'orecchio del partner',
      'Bacia il partner dalla bocca al collo scendendo fino al petto',
      'Togli la tua maglia lentamente guardando il partner negli occhi',
      'Fai un lap dance di 1 minuto al partner seduto sulla sedia',
      'Accarezza l\'interno coscia del partner con la punta delle dita',
      'Bacia la spalla scoperta del partner alternando morsi leggeri',
      'Il partner sceglie dove vuole essere baciato: esegui per 30 secondi',
      'Lecca il collo del partner dalla clavicola all\'orecchio',
      'Sussurra al partner 5 cose che vuoi fargli stanotte',
      'Togli un indumento al partner usando solo i denti',
      'Fai un massaggio ai glutei del partner sopra i vestiti per 2 minuti',
      'Bacia il partner come se fosse l\'ultima volta: mettici tutta la passione',
      'Strusciarsi contro il partner come in un ballo sensuale per 1 minuto',
      'Bacia e succhia il collo del partner lasciando un segno leggero',
      'Fai un complimento esplicito sulla sessualità del partner guardandolo negli occhi',
    ],
    'extra_spicy': [
      'Fai uno strip tease al partner: togli 3 capi lentamente ballando',
      'Bacia il partner ovunque tranne che sulle labbra per 2 minuti',
      'Mostra al partner esattamente come ti piace essere toccato/a',
      'Fai sesso orale al partner per 2 minuti',
      'Guida le mani del partner esattamente dove vuoi essere toccato/a',
      'Bacia e lecca il corpo del partner dalla bocca al basso ventre',
      'Masturbati davanti al partner per 1 minuto facendoti guardare',
      'Togli tutto al partner lasciando solo l\'intimo, usando solo la bocca',
      'Fai un massaggio erotico con olio al partner per 5 minuti',
      'Lega (dolcemente) le mani del partner e bacialo ovunque per 3 minuti',
      'Mettiti in ginocchio davanti al partner e fai quello che ti chiede',
      'Sussurra la tua fantasia più sporca all\'orecchio del partner e poi agiscila',
      'Fai un body shot: lecca un liquore dal corpo del partner',
      'Il partner si sdraia: esploralo con la bocca per 3 minuti ovunque',
      'Posizione 69 per 2 minuti: datevi piacere orale a vicenda',
      'Benda il partner e stimolalo con le mani e la bocca per 3 minuti',
      'Fai venire il partner usando solo le mani entro 5 minuti',
      'Fai uno spettacolo di autoerotismo per il partner descrivendo cosa senti',
      'Scegli una posizione dal Kamasutra e provatela per almeno 3 minuti',
      'Il partner è completamente alla tua mercé per 5 minuti: fai quello che vuoi',
    ],
  };
}
