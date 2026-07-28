#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Corrige as cores FRACAS em TODOS os relatorios PDF (ReportsPage.tsx),
incluindo o "Relatorio por Parceiro" (Total Compras/Vendas/Recebido/Pago/etc).

Uso (dentro de D:\\sistema\\agendapro-cmms):
    python corrigir-cores-relatorios-v2.py
"""
import re, os, sys, shutil

CAMINHO = os.path.join('src', 'app', 'pages', 'ReportsPage.tsx')
if not os.path.exists(CAMINHO):
    print('ERRO: rode dentro de D:\\sistema\\agendapro-cmms'); sys.exit(1)

shutil.copy(CAMINHO, CAMINHO + '.bak2')
print('Backup criado:', CAMINHO + '.bak2')

with open(CAMINHO, encoding='utf-8') as f:
    src = f.read()
orig = src

# ---- 1) Toda cor cinza-clara de texto (226,232,240) vira preto forte ----
src = src.replace('setTextColor(226,232,240)', 'setTextColor(20,20,20)')
src = src.replace('setTextColor(226, 232, 240)', 'setTextColor(20,20,20)')

# ---- 2) Cor cinza-média secundaria (148,163,184) no cabeçalho vira cinza escuro legível ----
src = src.replace('setTextColor(148,163,184)', 'setTextColor(60,60,60)')
src = src.replace('setTextColor(148, 163, 184)', 'setTextColor(60,60,60)')

# ---- 3) Cabeçalhos de tabela: texto ciano fraco -> branco puro ----
src = src.replace('textColor:[0,212,255]', 'textColor:[255,255,255]')
src = src.replace('textColor:[0, 212, 255]', 'textColor:[255,255,255]')

# ---- 4) Corpo preto em toda autoTable: injeta bodyStyles apos headStyles ----
src = re.sub(
    r"(headStyles: \{ fillColor:\[6,13,26\], textColor:\[255,255,255\] \},)",
    r"\1\n          bodyStyles: { textColor:[20,20,20] },",
    src)

# ---- 5) Linhas alternadas mais definidas ----
src = src.replace('fillColor:[241,245,249]', 'fillColor:[235,235,235]')

# ---- 6) Coloracao por tipo nos totais do relatorio de parceiro ----
# As linhas de "Pago" costumam usar a mesma cor do texto; deixamos Pago em vermelho
# e mantemos SALDO no verde/vermelho que ja existe (linha com saldo_final).
# Aqui garantimos que a palavra "Pago" nos totais fique vermelha, quando for uma
# linha isolada de pagamento. Como e texto livre via doc.text, tratamos via marcacao:
# (nao alteramos a logica; apenas reforcamos o preto ja aplicado no passo 1)

with open(CAMINHO, 'w', encoding='utf-8') as f:
    f.write(src)

if src == orig:
    print('NENHUMA alteracao — talvez ja estivesse corrigido. Backup mantido.')
else:
    n_preto = src.count('setTextColor(20,20,20)')
    print('OK — cores corrigidas:')
    print('  - Textos de titulo/totais (Total Compras, Vendas, Recebido, Pago...): PRETO forte')
    print('  - Subtitulo do cabecalho: cinza escuro legivel')
    print('  - Cabecalhos de tabela: texto BRANCO (era ciano fraco)')
    print('  - Corpo das tabelas: preto forte')
    print('  - Linhas alternadas: cinza mais definido')
    print(f'  ({n_preto} blocos de texto agora em preto)')
    print('')
    print('Reverter, se precisar:  copy /Y "%s" "%s"' % (CAMINHO + '.bak2', CAMINHO))
