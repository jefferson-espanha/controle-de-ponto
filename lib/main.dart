import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rqzenyisowodympiheod.supabase.co',
    anonKey: 'sb_publishable_yKGWZScOzAmahuDH62c0aw_SjlyvXjj',
  );

  runApp(const PontoApp());
}

class PontoApp extends StatelessWidget {
  const PontoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Ponto',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          surface: const Color(0xFFF8FAFC),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuarioController = TextEditingController();
  final _cargoController = TextEditingController();

  void _entrar() {
    if (_usuarioController.text.trim().isEmpty) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TelaPontoPrincipal(
          usuario: _usuarioController.text.trim(),
          cargoInicial: _cargoController.text.trim().isEmpty
              ? 'Servidor'
              : _cargoController.text.trim(),
          tipoUsuario: 'Padrao',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time_filled,
                  size: 64,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Acesso ao Sistema de Ponto',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Servidor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cargoController,
                  decoration: const InputDecoration(
                    labelText: 'Cargo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _entrar,
                    child: const Text('ENTRAR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegistroPonto {
  int id;
  String data;
  String entrada;
  String almoco;
  String retorno;
  String saida;
  String obs;
  double cursos;
  String certificado;

  RegistroPonto({
    required this.id,
    required this.data,
    this.entrada = '',
    this.almoco = '',
    this.retorno = '',
    this.saida = '',
    this.obs = '',
    this.cursos = 0.0,
    this.certificado = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'entrada': entrada,
      'almoco': almoco,
      'retorno': retorno,
      'saida': saida,
      'obs': obs,
    };
  }
}

class TelaPontoPrincipal extends StatefulWidget {
  final String usuario;
  final String cargoInicial;
  final String tipoUsuario;

  const TelaPontoPrincipal({
    super.key,
    required this.usuario,
    required this.cargoInicial,
    required this.tipoUsuario,
  });

  @override
  State<TelaPontoPrincipal> createState() => _TelaPontoPrincipalState();
}

class _TelaPontoPrincipalState extends State<TelaPontoPrincipal> {
  late String usuarioAtual;
  late String cargo;
  double baseHora = 8.0;
  double metaFacultativo = 0.0;

  String mesSelecionado = '08';
  String anoSelecionado = '2026';

  final List<String> diasSemana = [
    "Segunda dia de corno",
    "Terça",
    "Quarta",
    "Quinta",
    "Sexta",
    "Sábado",
    "Domingo"
  ];
  List<RegistroPonto> registros = [];

  late TextEditingController _ctrlBase;
  late TextEditingController _ctrlMeta;
  late TextEditingController _ctrlCargo;

  @override
  void initState() {
    super.initState();
    usuarioAtual = widget.usuario;
    cargo = widget.cargoInicial;

    _ctrlBase = TextEditingController(text: formatarHoras(baseHora));
    _ctrlMeta = TextEditingController(text: formatarHoras(metaFacultativo));
    _ctrlCargo = TextEditingController(text: cargo);

    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    await _carregarConfiguracoes();
    await _carregarDoSupabase();
  }

  double _parseTextoParaHoras(String texto) {
    if (texto.trim().isEmpty) return 0.0;
    try {
      if (texto.contains(':')) {
        List<String> partes = texto.split(':');
        int h = int.parse(partes[0]);
        int m = partes.length > 1 ? int.parse(partes[1]) : 0;
        int s = partes.length > 2 ? int.parse(partes[2]) : 0;
        return h + (m / 60.0) + (s / 3600.0);
      } else {
        return double.parse(texto.replaceAll(',', '.'));
      }
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> _carregarConfiguracoes() async {
    try {
      final response = await Supabase.instance.client
          .from('configuracoes')
          .select()
          .eq('usuario', usuarioAtual)
          .maybeSingle();

      if (response != null) {
        setState(() {
          baseHora = (response['base_hora'] as num?)?.toDouble() ?? 8.0;
          metaFacultativo =
              (response['meta_facultativo'] as num?)?.toDouble() ?? 0.0;
          cargo = response['cargo'] ?? cargo;

          _ctrlBase.text = formatarHoras(baseHora);
          _ctrlMeta.text = formatarHoras(metaFacultativo);
          _ctrlCargo.text = cargo;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar configuracoes: $e');
    }
  }

  Future<void> _salvarConfiguracoes() async {
    double novaBase = _parseTextoParaHoras(_ctrlBase.text);
    double novaMeta = _parseTextoParaHoras(_ctrlMeta.text);
    String novoCargo = _ctrlCargo.text.trim();

    try {
      await Supabase.instance.client.from('configuracoes').upsert({
        'usuario': usuarioAtual,
        'base_hora': novaBase,
        'meta_facultativo': novaMeta,
        'cargo': novoCargo,
      }, onConflict: 'usuario');

      setState(() {
        baseHora = novaBase;
        metaFacultativo = novaMeta;
        cargo = novoCargo;
        _ctrlBase.text = formatarHoras(baseHora);
        _ctrlMeta.text = formatarHoras(metaFacultativo);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no banco: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _carregarDoSupabase() async {
    _gerarDiasDoMes();
    try {
      final response = await Supabase.instance.client
          .from('registros_ponto')
          .select()
          .like('data', '%/$mesSelecionado/$anoSelecionado');

      if (response != null && response is List) {
        setState(() {
          for (var item in response) {
            int index = registros.indexWhere((r) => r.id == item['id']);
            if (index != -1) {
              registros[index] = RegistroPonto(
                id: item['id'],
                data: item['data'] ?? '',
                entrada: item['entrada'] ?? '',
                almoco: item['almoco'] ?? '',
                retorno: item['retorno'] ?? '',
                saida: item['saida'] ?? '',
                obs: item['obs'] ?? '',
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar registros do Supabase: $e');
    }
  }

  Future<void> _salvarNoSupabase(RegistroPonto reg) async {
    try {
      await Supabase.instance.client
          .from('registros_ponto')
          .upsert(reg.toMap());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no banco: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String formatarHoras(double decimal) {
    int horas = decimal.abs().toInt();
    int minutos = ((decimal.abs() - horas) * 60).round();
    if (minutos == 60) {
      horas += 1;
      minutos = 0;
    }
    String sinal = decimal < 0 ? "-" : "";
    return "$sinal${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:00";
  }

  double calcularTrabalhadoDia(
      String e1, String s1, String e2, String s2, String obs) {
    try {
      double totalSegundos = 0;
      DateTime? dtE1 = _parseTime(e1);
      DateTime? dtS1 = _parseTime(s1);
      DateTime? dtE2 = _parseTime(e2);
      DateTime? dtS2 = _parseTime(s2);

      if (baseHora == 6.0) {
        if (dtE1 != null && dtS1 != null && dtE2 != null && dtS2 != null) {
          double permanencia = dtS2.difference(dtE1).inSeconds.toDouble();
          double intervaloReal = dtE2.difference(dtS1).inSeconds.toDouble();
          totalSegundos = permanencia - intervaloReal + 900;
        } else if (dtE1 != null && dtS2 != null) {
          totalSegundos = dtS2.difference(dtE1).inSeconds.toDouble();
        }
      } else {
        if (dtE1 != null && dtS1 != null && dtE2 != null && dtS2 != null) {
          double t1 = dtS1.difference(dtE1).inSeconds.toDouble();
          double t2 = dtS2.difference(dtE2).inSeconds.toDouble();
          totalSegundos = t1 + t2;
        } else if (dtE1 != null && dtS2 != null) {
          totalSegundos = dtS2.difference(dtE1).inSeconds.toDouble();
        }
      }

      if (obs.toUpperCase().contains("AH:")) {
        try {
          String hTxt = obs.toUpperCase().split("AH:")[1].trim();
          List<String> partes = hTxt.split(':');
          int h = int.parse(partes[0]);
          int m = int.parse(partes[1]);
          totalSegundos += (h * 3600) + (m * 60);
        } catch (_) {}
      }

      return (totalSegundos / 3600.0 * 100).roundToDouble() / 100.0;
    } catch (_) {
      return 0.0;
    }
  }

  DateTime? _parseTime(String timeStr) {
    if (timeStr.trim().isEmpty) return null;
    try {
      List<String> p = timeStr.split(':');
      return DateTime(2026, 1, 1, int.parse(p[0]), int.parse(p[1]),
          p.length > 2 ? int.parse(p[2]) : 0);
    } catch (_) {
      return null;
    }
  }

  void _gerarDiasDoMes() {
    int m = int.parse(mesSelecionado);
    int a = int.parse(anoSelecionado);
    int ultimoDia = DateTime(a, m + 1, 0).day;

    registros = List.generate(ultimoDia, (i) {
      int dia = i + 1;
      String dataStr =
          "${dia.toString().padLeft(2, '0')}/${mesSelecionado.padLeft(2, '0')}/$anoSelecionado";
      return RegistroPonto(id: dia, data: dataStr);
    });
  }

  Future<void> _baterPontoRapido(String tipo) async {
    String agora =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";
    String hojeStr =
        "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}";

    RegistroPonto? regModificado;

    setState(() {
      for (var r in registros) {
        if (r.data == hojeStr) {
          if (tipo == "ENTRADA") r.entrada = agora;
          if (tipo == "ALMOÇO") r.almoco = agora;
          if (tipo == "RETORNO") r.retorno = agora;
          if (tipo == "SAÍDA") r.saida = agora;
          regModificado = r;
        }
      }
    });

    if (regModificado != null) {
      await _salvarNoSupabase(regModificado!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("$tipo registrado às $agora"),
            backgroundColor: Colors.green),
      );
    }
  }

  Widget _btnPonto(String texto, Color cor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: cor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => _baterPontoRapido(texto),
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _gerarEBaixarPDF() async {
    final pdf = pw.Document();

    pw.MemoryImage? imgCabecalho;
    pw.MemoryImage? imgRodape;

    try {
      final ByteData bytesCab = await rootBundle.load('assets/logo.png');
      imgCabecalho = pw.MemoryImage(bytesCab.buffer.asUint8List());
    } catch (e) {
      debugPrint("Logo não encontrado em assets/logo.png: $e");
    }

    try {
      final ByteData bytesRod = await rootBundle.load('assets/rodape.png');
      imgRodape = pw.MemoryImage(bytesRod.buffer.asUint8List());
    } catch (e) {
      debugPrint("Rodapé não encontrado em assets/rodape.png: $e");
    }

    double totalBruto = 0, totalComp = 0, totalDev = 0, totalCursos = 0;

    List<List<String>> dataPdf = [
      [
        "Data",
        "Dia",
        "Entrada",
        "Almoço",
        "Retorno",
        "Saída",
        "Total",
        "Compensado",
        "Devedora",
        "Observações"
      ]
    ];

    for (var reg in registros) {
      List<String> partesData = reg.data.split('/');
      DateTime dtObj = DateTime(int.parse(partesData[2]),
          int.parse(partesData[1]), int.parse(partesData[0]));
      int diaSemanaIdx = dtObj.weekday - 1;

      double hDiaFinal = calcularTrabalhadoDia(
          reg.entrada, reg.almoco, reg.retorno, reg.saida, reg.obs);
      double compDia = 0.0, devDia = 0.0, hExibir = 0.0;

      bool temPonto = [reg.entrada, reg.almoco, reg.retorno, reg.saida]
          .any((x) => x.trim().isNotEmpty);
      bool temAH = reg.obs.toUpperCase().contains("AH:");

      if (temPonto || temAH) {
        if (["FÉRIAS", "ABONADA fodasse", "ATESTADO", "FERIADO", "FACULTATIVO"]
            .any((x) => reg.obs.toUpperCase().contains(x))) {
          hExibir = baseHora;
        } else {
          if (dtObj.weekday < 6) {
            compDia = (hDiaFinal - baseHora) > 0 ? (hDiaFinal - baseHora) : 0.0;
            devDia = (baseHora - hDiaFinal) > 0 ? (baseHora - hDiaFinal) : 0.0;
          } else {
            compDia = hDiaFinal;
          }
          hExibir = hDiaFinal;
        }
      }

      totalComp += compDia;
      totalDev += devDia;
      totalBruto += hExibir;
      totalCursos += reg.cursos;

      String obsFormatada =
          reg.obs.length > 25 ? reg.obs.substring(0, 25) : reg.obs;

      dataPdf.add([
        reg.data,
        diasSemana[diaSemanaIdx].substring(0, 3),
        reg.entrada,
        reg.almoco,
        reg.retorno,
        reg.saida,
        formatarHoras(hExibir),
        formatarHoras(compDia),
        formatarHoras(devDia),
        obsFormatada,
      ]);
    }

    double saldoMes = totalComp - totalDev;
    double exibirExtras = saldoMes > 0 ? saldoMes : 0.0;
    double exibirDev = saldoMes < 0 ? saldoMes.abs() : 0.0;
    double bonusAbatimento = exibirExtras + totalCursos;
    double faltaFac = (metaFacultativo - bonusAbatimento) > 0
        ? (metaFacultativo - bonusAbatimento)
        : 0.0;

    String txtTotal = "Total Trabalhado: ${formatarHoras(totalBruto)}";
    String txtComp = "Horas Extras: ${formatarHoras(exibirExtras)}";
    String txtDev = "Horas Devedoras: ${formatarHoras(exibirDev)}";
    String txtCursos = "Cursos: ${formatarHoras(totalCursos)}";
    String txtFacultativo = (metaFacultativo > 0 && faltaFac <= 0)
        ? "Pendência Facultativo: META OK ✅"
        : (metaFacultativo > 0
            ? "Pendência Facultativo: Faltam ${formatarHoras(faltaFac)}"
            : "Pendência Facultativo: 00:00:00");

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(
            horizontal: 1 * PdfPageFormat.cm, vertical: 0.6 * PdfPageFormat.cm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (imgCabecalho != null)
                pw.Center(
                  child: pw.SizedBox(
                    height: 2.0 * PdfPageFormat.cm,
                    child: pw.Image(imgCabecalho, fit: pw.BoxFit.contain),
                  ),
                )
              else
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey300,
                  child: pw.Center(
                    child: pw.Text("RELATÓRIO DE PONTO ELETRÔNICO",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ),
                ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("SERVIDOR: ${usuarioAtual.toUpperCase()}",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                      pw.SizedBox(height: 2),
                      pw.Text("CARGO: ${cargo.toUpperCase()}",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    ],
                  ),
                  pw.Text("MÊS/ANO: $mesSelecionado/$anoSelecionado",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Expanded(
                child: pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  cellHeight: 11.5,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.1),
                    1: const pw.FlexColumnWidth(1.0),
                    2: const pw.FlexColumnWidth(1.4),
                    3: const pw.FlexColumnWidth(1.4),
                    4: const pw.FlexColumnWidth(1.4),
                    5: const pw.FlexColumnWidth(1.4),
                    6: const pw.FlexColumnWidth(1.4),
                    7: const pw.FlexColumnWidth(1.4),
                    8: const pw.FlexColumnWidth(1.4),
                    9: const pw.FlexColumnWidth(5.8),
                  },
                  headerStyle:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
                  cellStyle: const pw.TextStyle(fontSize: 6.5),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  cellAlignment: pw.Alignment.center,
                  data: dataPdf,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text("$txtTotal | $txtComp | $txtDev | $txtCursos",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
              pw.SizedBox(height: 2),
              pw.Text(txtFacultativo,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                          width: 5.5 * PdfPageFormat.cm,
                          height: 0.5,
                          color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text("Assinatura do Servidor",
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                          width: 5.5 * PdfPageFormat.cm,
                          height: 0.5,
                          color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Text("Chefia Imediata",
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              if (imgRodape != null)
                pw.Center(
                  child: pw.SizedBox(
                    height: 1.2 * PdfPageFormat.cm,
                    child: pw.Image(imgRodape, fit: pw.BoxFit.contain),
                  ),
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _abrirJanelaEdicao(RegistroPonto reg) {
    TextEditingController cE = TextEditingController(
        text: reg.entrada.isEmpty ? "00:00:00" : reg.entrada);
    TextEditingController cA = TextEditingController(
        text: reg.almoco.isEmpty ? "00:00:00" : reg.almoco);
    TextEditingController cR = TextEditingController(
        text: reg.retorno.isEmpty ? "00:00:00" : reg.retorno);
    TextEditingController cS = TextEditingController(
        text: reg.saida.isEmpty ? "00:00:00" : reg.saida);
    TextEditingController cObs = TextEditingController(text: reg.obs);
    TextEditingController cCursos =
        TextEditingController(text: reg.cursos.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar Ponto - ${reg.data}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campoTxt("Entrada", cE),
                _campoTxt("Almoço", cA),
                _campoTxt("Retorno", cR),
                _campoTxt("Saída", cS),
                _campoTxt("Observação", cObs),
                _campoTxt("Horas Curso", cCursos),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children:
                      ["FÉRIAS", "ABONADA", "ATESTADO", "FERIADO"].map((tag) {
                    return ActionChip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      onPressed: () => cObs.text = tag,
                    );
                  }).toList(),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                        label: const Text("FACULTATIVO",
                            style: TextStyle(fontSize: 10)),
                        onPressed: () => cObs.text = "FACULTATIVO"),
                    ActionChip(
                        label: const Text("SEM. PROVA",
                            style: TextStyle(fontSize: 10)),
                        onPressed: () =>
                            cObs.text = "SEMANA DE PROVA AH:02:45"),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white),
              onPressed: () async {
                setState(() {
                  reg.entrada = cE.text;
                  reg.almoco = cA.text;
                  reg.retorno = cR.text;
                  reg.saida = cS.text;
                  reg.obs = cObs.text.toUpperCase();
                  reg.cursos =
                      double.tryParse(cCursos.text.replaceAll(',', '.')) ??
                          0.0;
                });
                await _salvarNoSupabase(reg);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("SALVAR"),
            )
          ],
        );
      },
    );
  }

  Widget _campoTxt(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalComp = 0.0, totalDev = 0.0, totalBruto = 0.0, totalCursos = 0.0;

    List<DataRow> rows = registros.map((reg) {
      List<String> partesData = reg.data.split('/');
      DateTime dtObj = DateTime(int.parse(partesData[2]),
          int.parse(partesData[1]), int.parse(partesData[0]));
      int diaSemanaIdx = dtObj.weekday - 1;

      double hDiaFinal = calcularTrabalhadoDia(
          reg.entrada, reg.almoco, reg.retorno, reg.saida, reg.obs);
      double compDia = 0.0, devDia = 0.0, hExibir = 0.0;

      bool temPonto = [reg.entrada, reg.almoco, reg.retorno, reg.saida]
          .any((x) => x.trim().isNotEmpty);
      bool temAH = reg.obs.toUpperCase().contains("AH:");

      if (temPonto || temAH) {
        if (["FÉRIAS", "ABONADA", "ATESTADO", "FERIADO", "FACULTATIVO"]
            .any((x) => reg.obs.toUpperCase().contains(x))) {
          hExibir = baseHora;
        } else {
          if (dtObj.weekday < 6) {
            compDia = (hDiaFinal - baseHora) > 0 ? (hDiaFinal - baseHora) : 0.0;
            devDia = (baseHora - hDiaFinal) > 0 ? (baseHora - hDiaFinal) : 0.0;
          } else {
            compDia = hDiaFinal;
          }
          hExibir = hDiaFinal;
        }
      } else {
        hExibir = 0.0;
      }

      totalComp += compDia;
      totalDev += devDia;
      totalBruto += hExibir;
      totalCursos += reg.cursos;

      String obsExibir =
          reg.cursos > 0 ? "(${formatarHoras(reg.cursos)}) ${reg.obs}" : reg.obs;
      bool isFds = dtObj.weekday >= 6;

      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>(
            (states) => isFds ? Colors.grey.shade200 : null),
        onSelectChanged: (_) => _abrirJanelaEdicao(reg),
        cells: [
          DataCell(Text(reg.data, style: const TextStyle(fontSize: 13))),
          DataCell(Text(diasSemana[diaSemanaIdx].substring(0, 3),
              style: const TextStyle(fontSize: 13))),
          DataCell(Text(reg.entrada, style: const TextStyle(fontSize: 13))),
          DataCell(Text(reg.almoco, style: const TextStyle(fontSize: 13))),
          DataCell(Text(reg.retorno, style: const TextStyle(fontSize: 13))),
          DataCell(Text(reg.saida, style: const TextStyle(fontSize: 13))),
          DataCell(Text(formatarHoras(hExibir),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold))),
          DataCell(Text(formatarHoras(compDia),
              style: const TextStyle(fontSize: 13, color: Colors.green))),
          DataCell(Text(formatarHoras(devDia),
              style: const TextStyle(fontSize: 13, color: Colors.red))),
          DataCell(Text(obsExibir, style: const TextStyle(fontSize: 13))),
        ],
      );
    }).toList();

    double saldoMes = totalComp - totalDev;
    double exibirExtras = saldoMes > 0 ? saldoMes : 0.0;
    double exibirDev = saldoMes < 0 ? saldoMes.abs() : 0.0;
    double bonusAbatimento = exibirExtras + totalCursos;
    double faltaFac = (metaFacultativo - bonusAbatimento) > 0
        ? (metaFacultativo - bonusAbatimento)
        : 0.0;

    String txtTotal = "Total Trabalhado: ${formatarHoras(totalBruto)}";
    String txtComp = "Horas Extras: ${formatarHoras(exibirExtras)}";
    String txtDev = "Horas Devedoras: ${formatarHoras(exibirDev)}";
    String txtCursos = "Cursos: ${formatarHoras(totalCursos)}";
    String txtFacultativo = (metaFacultativo > 0 && faltaFac <= 0)
        ? "Pendência Facultativo: META OK ✅"
        : (metaFacultativo > 0
            ? "Pendência Facultativo: Faltam ${formatarHoras(faltaFac)}"
            : "Pendência Facultativo: 00:00:00");

    return Scaffold(
      appBar: AppBar(
        title: Text('Sistema de Ponto - $usuarioAtual',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _gerarEBaixarPDF,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btnPonto("ENTRADA", const Color(0xFF27AE60)),
                _btnPonto("ALMOÇO", const Color(0xFFF39C12)),
                _btnPonto("RETORNO", const Color(0xFF2980B9)),
                _btnPonto("SAÍDA", const Color(0xFFC0392B)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text("Mês: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: mesSelecionado,
                  items: List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'))
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    mesSelecionado = v!;
                    _carregarDoSupabase();
                  }),
                ),
                const SizedBox(width: 15),
                const Text("Ano: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: anoSelecionado,
                  items: ['2025', '2026', '2027']
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    anoSelecionado = v!;
                    _carregarDoSupabase();
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: 24,
                  headingRowColor:
                      WidgetStateProperty.all(Colors.grey.shade300),
                  columns: const [
                    DataColumn(
                        label: Text('Data',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Dia',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Ent.',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Alm.',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Ret.',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Sai.',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Comp.',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Dev.',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Obs',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: rows,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blueGrey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    "$txtTotal  |  $txtComp  |  $txtDev  |  $txtCursos",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  txtFacultativo,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: faltaFac <= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text("Hora Base Servidor: ",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(
                        width: 100,
                        height: 38,
                        child: TextField(
                          controller: _ctrlBase,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text("Meta de Horas de ponto facultativo: ",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(
                        width: 100,
                        height: 38,
                        child: TextField(
                          controller: _ctrlMeta,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text("Cargo: ",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(
                        width: 180,
                        height: 38,
                        child: TextField(
                          controller: _ctrlCargo,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onPressed: _salvarConfiguracoes,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text("SALVAR",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}