import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class HelpSheet extends StatelessWidget {
  const HelpSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen height check to ensure responsive sheet height
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = (screenHeight * 0.75).clamp(480.0, 700.0);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22).withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(
            color: AppColors.textWhite.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Top notch handle indicator
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              const Text(
                'COMO JOGAR & MODOS',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),

              // Custom TabBar
              TabBar(
                labelColor: AppColors.correct,
                unselectedLabelColor: AppColors.textGray,
                indicatorColor: AppColors.correct,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.rule_rounded, size: 20),
                    text: 'COMO JOGAR',
                  ),
                  Tab(
                    icon: Icon(Icons.sports_esports_rounded, size: 20),
                    text: 'MODOS DE JOGO',
                  ),
                ],
              ),
              const Divider(
                color: Color(0xFF2E2E32),
                height: 1,
                thickness: 1,
              ),

              // TabBarViews
              Expanded(
                child: TabBarView(
                  children: [
                    _buildHowToPlayTab(),
                    _buildGameModesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToPlayTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Descubra a palavra certa em 6 tentativas (nos modos clássicos). Cada palpite deve ser uma palavra válida de 5 letras.',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Depois de enviar, as letras mudam de cor para mostrar o quão perto você estava:',
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Visual Example 1: Correct (Verde)
        _buildFeedbackExample(
          word: 'TERMO',
          highlightIndex: 0,
          highlightColor: AppColors.correct,
          explanation: 'A letra T faz parte da palavra e está na posição correta.',
        ),
        const SizedBox(height: 20),

        // Visual Example 2: Present (Amarelo)
        _buildFeedbackExample(
          word: 'MUNDO',
          highlightIndex: 0,
          highlightColor: AppColors.present,
          explanation: 'A letra M faz parte da palavra, mas está em outra posição.',
        ),
        const SizedBox(height: 20),

        // Visual Example 3: Absent (Cinza)
        _buildFeedbackExample(
          word: 'TEXTO',
          highlightIndex: 2,
          highlightColor: AppColors.absent,
          explanation: 'A letra X não faz parte da palavra em nenhum local.',
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFF2E2E32), height: 32),
        const Text(
          'Dica: Palavras podem ter letras repetidas (ex: "ARARA" tem três "A"). Os acentos são preenchidos automaticamente se a letra base estiver certa!',
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 12,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackExample({
    required String word,
    required int highlightIndex,
    required Color highlightColor,
    required String explanation,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(word.length, (index) {
            final letter = word[index];
            final isHighlighted = index == highlightIndex;

            return Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isHighlighted ? highlightColor : const Color(0xFF2B2B30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHighlighted
                      ? highlightColor
                      : const Color(0xFF3E3E42),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          explanation,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildGameModesTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Mode: Termo
        _buildModeDetails(
          icon: Icons.looks_one_rounded,
          color: AppColors.correct,
          title: 'TERMO (Diário)',
          description: 'O desafio clássico. Adivinhe 1 palavra em até 6 tentativas. Uma palavra secreta nova para todos a cada 24 horas.',
        ),
        const SizedBox(height: 20),

        // Mode: Dueto
        _buildModeDetails(
          icon: Icons.looks_two_rounded,
          color: AppColors.present,
          title: 'DUETO (Diário)',
          description: 'Adivinhe 2 palavras simultâneas em até 7 tentativas. Seus palpites preenchem ambos os tabuleiros ao mesmo tempo.',
        ),
        const SizedBox(height: 20),

        // Mode: Quarteto
        _buildModeDetails(
          icon: Icons.looks_4_rounded,
          color: const Color(0xFFE07C4F),
          title: 'QUARTETO (Diário)',
          description: 'Desafio máximo de multi-tabuleiros. Adivinhe 4 palavras simultaneamente em até 9 tentativas.',
        ),
        const SizedBox(height: 20),

        // Mode: Infinito
        _buildModeDetails(
          icon: Icons.all_inclusive_rounded,
          color: AppColors.present,
          title: 'MODO INFINITO (Treino)',
          description: 'Jogue sem restrições de tempo ou limites diários. Palavras são sorteadas aleatoriamente do dicionário comum e você pode acumular sequências de vitórias (Streak).',
        ),
        const SizedBox(height: 20),

        // Mode: Multiplayer
        _buildModeDetails(
          icon: Icons.group_rounded,
          color: AppColors.multiplayerBackground,
          title: 'MULTIPLAYER (Em Breve)',
          description: 'Compita contra amigos em tempo real para ver quem desvenda a palavra mais rápido. Atualmente em construção!',
          isUnderConstruction: true,
        ),
      ],
    );
  }

  Widget _buildModeDetails({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    bool isUnderConstruction = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222226),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isUnderConstruction) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'OBRAS',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textGray.withValues(alpha: 0.95),
                    fontSize: 12,
                    height: 1.4,
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
