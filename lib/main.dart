import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart'; // Importação do Dio
import 'package:qr_flutter/qr_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const request = "https://api.hgbrasil.com/finance?format=json&key=526b3c9d";

void main() async {
  runApp(MaterialApp(
    home: const Home(),
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    ),
  ));
}

// Função para buscar dados e verificar a conexão com a internet
Future<Map> getData() async {
  // Verificação de conexão antes de realizar a requisição
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    // Retorna um erro caso não haja conexão
    throw Exception("No internet connection");
  }

  // Inicializando o Dio
  Dio dio = Dio();

  try {
    // Faz a requisição utilizando Dio
    Response response = await dio.get(request);
    return response.data; // Dio já decodifica o JSON automaticamente
  } catch (e) {
    throw Exception("Erro ao carregar dados: $e");
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final realController = TextEditingController();
  final dolarController = TextEditingController();
  final euroController = TextEditingController();
  final bitcoinController = TextEditingController();

  double? dolar;
  double? euro;
  double? bitcoin;

  void _realChanged(String text) {
    if (text.isEmpty) {
      _clearAll();
      return;
    }
    double real = double.parse(text);
    dolarController.text = (real / dolar!).toStringAsFixed(2);
    euroController.text = (real / euro!).toStringAsFixed(2);
    bitcoinController.text =
        (real / bitcoin!).toStringAsFixed(6); // Conversão para Bitcoin
  }

  void _dolarChanged(String text) {
    if (text.isEmpty) {
      _clearAll();
      return;
    }
    double dolar = double.parse(text);
    realController.text = (dolar * this.dolar!).toStringAsFixed(2);
    euroController.text = (dolar * this.dolar! / euro!).toStringAsFixed(2);
    bitcoinController.text = (dolar * this.dolar! / bitcoin!)
        .toStringAsFixed(6); // Conversão para Bitcoin
  }

  void _euroChanged(String text) {
    if (text.isEmpty) {
      _clearAll();
      return;
    }
    double euro = double.parse(text);
    realController.text = (euro * this.euro!).toStringAsFixed(2);
    dolarController.text = (euro * this.euro! / dolar!).toStringAsFixed(2);
    bitcoinController.text = (euro * this.euro! / bitcoin!)
        .toStringAsFixed(6); // Conversão para Bitcoin
  }

  void _bitChanged(String text) {
    if (text.isEmpty) {
      _clearAll();
      return;
    }
    double bitcoin = double.parse(text);
    realController.text = (bitcoin * this.bitcoin!).toStringAsFixed(2);
    dolarController.text =
        (bitcoin * this.bitcoin! / dolar!).toStringAsFixed(2);
    euroController.text = (bitcoin * this.bitcoin! / euro!).toStringAsFixed(2);
  }

  void _clearAll() {
    realController.text = "";
    dolarController.text = "";
    euroController.text = "";
    bitcoinController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.monetization_on),
            Expanded(
              child: Center(
                child: Text(
                  "Conversor de Moedas",
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 64),
        child: FutureBuilder<Map>(
          future: getData(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const Center(
                  child: CircularProgressIndicator(),
                );
              default:
                if (snapshot.hasError) {
                  // Exibe mensagem de erro ao carregar dados (sem conexão)
                  return const Center(
                    child: Text("Erro ao Carregar Dados :("),
                  );
                } else {
                  dolar = snapshot.data!["results"]["currencies"]["USD"]["buy"];
                  euro = snapshot.data!["results"]["currencies"]["EUR"]["buy"];
                  bitcoin =
                      snapshot.data!["results"]["currencies"]["BTC"]["buy"];

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 8),
                        buildTextField(context, "Reais", "R\$ ", realController,
                            _realChanged),
                        const Divider(),
                        buildTextField(context, "Dólares", "US\$ ",
                            dolarController, _dolarChanged),
                        const Divider(),
                        buildTextField(context, "Euros", "€ ", euroController,
                            _euroChanged),
                        const Divider(),
                        buildTextField(context, "Bitcoin", "BTC ",
                            bitcoinController, _bitChanged)
                      ],
                    ),
                  );
                }
            }
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("QR Code"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 200, // Ajuste o tamanho conforme necessário
                        height: 200,
                        child: QrImageView(
                          data:
                              "00020126430014br.gov.bcb.pix0114+55869944538290203Pix52040000530398654040.505802BR5921MATUSALEN COSTA ALVES6008PIRIPIRI6229052578CztVdU9U5CEmu3TXZuIGEWr6304BE7F", // Substitua pelo seu dado
                          version: QrVersions.auto,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Fechar"),
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.coffee),
        ),
      ),
    );
  }
}

Widget buildTextField(BuildContext context, String label, String prefix,
    TextEditingController controller, Function(String) onChanged) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixText: prefix,
    ),
    style: TextStyle(
      fontSize: 25.0,
      color: Theme.of(context).colorScheme.onSurface,
    ),
    onChanged: onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      // Permite apenas números e um ponto, com o ponto permitido apenas após um número
      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
    ],
  );
}
