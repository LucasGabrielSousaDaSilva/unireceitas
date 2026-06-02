import 'package:flutter/material.dart';
import '../services/nutrition_service.dart';

class NutritionTableWidget extends StatelessWidget {
  final FoodInfo foodInfo;

  const NutritionTableWidget({
    super.key,
    required this.foodInfo,
  });

  // Base para cálculo de %VD - Dieta de 2000 kcal (Referência genérica ANVISA)
  static const double vdCalorias = 2000;
  static const double vdCarboidratos = 300;
  static const double vdProteinas = 50; 
  static const double vdGordurasTotais = 65; 
  static const double vdGordurasSaturadas = 22;
  static const double vdFibra = 25;
  static const double vdSodio = 2400; // mg

  String _calcVd(double amount, double target) {
    if (target == 0) return '**';
    final percent = (amount / target) * 100;
    return '${percent.round()}%';
  }

  @override
  Widget build(BuildContext context) {
    // Cores inspiradas na tabela de referência
    final corVerdeEscuro = Colors.green.shade900;
    const corVerdeClaro = Color(0xFFCDE11F); // Verde limão da referência

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: corVerdeEscuro, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho Verde
          Container(
            color: corVerdeEscuro,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informação nutricional',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Porção de ${foodInfo.porcao}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantidade por porção / %VD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantidade por porção',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: corVerdeEscuro,
                  ),
                ),
                Text(
                  '%VD*',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: corVerdeEscuro,
                  ),
                ),
              ],
            ),
          ),
          
          // Linhas da tabela
          _buildRow('Valor Energético', '${foodInfo.calorias.toStringAsFixed(0)}kcal', _calcVd(foodInfo.calorias, vdCalorias), true, corVerdeClaro, corVerdeEscuro),
          _buildRow('Carboidratos', '${foodInfo.carboidratos.toStringAsFixed(1)}g', _calcVd(foodInfo.carboidratos, vdCarboidratos), false, corVerdeClaro, corVerdeEscuro),
          _buildRow('Proteínas', '${foodInfo.proteina.toStringAsFixed(1)}g', _calcVd(foodInfo.proteina, vdProteinas), true, corVerdeClaro, corVerdeEscuro),
          _buildRow('Gorduras Totais', '${foodInfo.gordura.toStringAsFixed(1)}g', _calcVd(foodInfo.gordura, vdGordurasTotais), false, corVerdeClaro, corVerdeEscuro),
          _buildRow('Gorduras Saturadas', '${foodInfo.gorduraSaturada.toStringAsFixed(1)}g', _calcVd(foodInfo.gorduraSaturada, vdGordurasSaturadas), true, corVerdeClaro, corVerdeEscuro),
          _buildRow('Açúcar', '${foodInfo.acucar.toStringAsFixed(1)}g', '**', false, corVerdeClaro, corVerdeEscuro), 
          _buildRow('Fibra Alimentar', '${foodInfo.fibra.toStringAsFixed(1)}g', _calcVd(foodInfo.fibra, vdFibra), true, corVerdeClaro, corVerdeEscuro),
          _buildRow('Sódio', '${foodInfo.sodio.toStringAsFixed(0)}mg', _calcVd(foodInfo.sodio, vdSodio), false, corVerdeClaro, corVerdeEscuro),
          _buildRow('Potássio', '${foodInfo.potassio.toStringAsFixed(0)}mg', '**', true, corVerdeClaro, corVerdeEscuro),
          _buildRow('Colesterol', '${foodInfo.colesterol.toStringAsFixed(0)}mg', '**', false, corVerdeClaro, corVerdeEscuro),

          // Rodapé com notas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              '* Valores diários de referência com base em uma dieta de 2.000kcal ou 8.400kJ.\nSeus valores diários podem ser maiores ou menores dependendo de suas necessidades.\n** Valores diários não estabelecidos.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String name, String value, String vd, bool isHighlighted, Color highlightColor, Color textColor) {
    final bgColor = isHighlighted ? highlightColor : Colors.transparent;
    
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              vd,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
