#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Corrige as cores dos relatórios PDF (ReportsPage.tsx):
- Texto do corpo das tabelas: preto forte (era cinza quase-branco 226,232,240)
- Cabeçalhos das tabelas: fundo escuro com texto branco legível
- Coluna "Pagamento": vermelho | "Valor/Total/Venda": preto | "Saldo": verde escuro

Uso (dentro de D:\\sistema\\agendapro-cmms):
    python corrigir-cores-relatorios.py
"""
import re, sys, os, shutil

CAMINHO = os.path.join('src', 'app', 'pages', 'ReportsPage.tsx')

if not os.path.exists(CAMINHO):
    print(f'ERRO: nao encontrei {CAMINHO}. Rode este script dentro de D:\\sistema\\agendapro-cmms')
    sys.exit(1)

# Backup antes de mexer
shutil.copy(CAMINHO, CAMINHO + '.bak')
print(f'Backup criado: {CAMINHO}.bak')

with open(CAMINHO, encoding='utf-8') as f:
    src = f.read()

orig = src
trocas = 0

# 1) Texto do corpo quase-branco -> preto forte
antes = src
src = src.replace('doc.setTextColor(226,232,240)', 'doc.setTextColor(20,20,20)')
if src != antes: trocas += src.count('doc.setTextColor(20,20,20)')

# 2) Cabeçalho de tabela: texto ciano fraco -> branco puro (fundo escuro fica, contraste melhora)
src = src.replace('headStyles: { fillColor:[6,13,26], textColor:[0,212,255] }',
                  'headStyles: { fillColor:[20,30,50], textColor:[255,255,255], fontStyle:\'bold\' }')

# 3) Garante corpo preto em TODAS as autoTable: injeta bodyStyles logo após cada headStyles
src = re.sub(
    r"headStyles: \{ fillColor:\[20,30,50\], textColor:\[255,255,255\], fontStyle:'bold' \},",
    "headStyles: { fillColor:[20,30,50], textColor:[255,255,255], fontStyle:'bold' },\n          bodyStyles: { textColor:[20,20,20] },",
    src)

# 4) Linhas alternadas cinza-claro -> um pouco mais definidas (mantém legibilidade)
src = src.replace('alternateRowStyles: { fillColor:[241,245,249] }',
                  'alternateRowStyles: { fillColor:[235,235,235] }')

# 5) Cor do "Valor Total" no header do PDF (245,158,11 laranja) -> mantido (é destaque, ok no papel)

# 6) Colorir colunas específicas via didParseCell — injeta em cada autoTable que tenha
#    a coluna Pagamento, Total/Valor ou Saldo no head.
#    Estratégia: adiciona uma função didParseCell logo após bodyStyles nos autoTable
#    dos relatórios de VENDAS e FINANCEIRO (que têm essas colunas).
#    Como isso depende da posição da coluna, fazemos por nome de header.

hook = """bodyStyles: { textColor:[20,20,20] },
          didParseCell: function(d){
            try {
              if (d.section !== 'body') return;
              var head = (d.table && d.table.columns) ? d.table.columns.map(function(c){return (c && c.dataKey!=null)? String(c.dataKey):'';}) : [];
              // usa o texto do cabeçalho da coluna atual
              var colHead = '';
              if (d.column && d.table && d.table.head && d.table.head[0] && d.table.head[0].cells) {
                var cell = d.table.head[0].cells[d.column.index];
                if (cell && cell.text) colHead = String(cell.text).toLowerCase();
              }
              if (colHead.indexOf('pagamento') >= 0) { d.cell.styles.textColor = [200,0,0]; }
              else if (colHead.indexOf('saldo') >= 0) { d.cell.styles.textColor = [0,100,0]; }
              else if (colHead.indexOf('valor') >= 0 || colHead.indexOf('total') >= 0) { d.cell.styles.textColor = [0,0,0]; }
            } catch(e){}
          },"""

# Substitui APENAS as ocorrências de bodyStyles que acabamos de criar,
# adicionando o hook de cores por coluna.
src = src.replace('bodyStyles: { textColor:[20,20,20] },', hook)

with open(CAMINHO, 'w', encoding='utf-8') as f:
    f.write(src)

if src == orig:
    print('NENHUMA alteracao feita — o arquivo pode ja estar corrigido ou ter formato diferente.')
    print('O backup .bak foi mantido; nada foi perdido.')
else:
    print('OK — cores dos relatorios corrigidas:')
    print(' - Texto do corpo: preto forte')
    print(' - Cabecalhos: fundo escuro + texto branco')
    print(' - Coluna Pagamento: vermelho | Valor/Total: preto | Saldo: verde escuro')
    print(' - Linhas alternadas: cinza mais definido')
    print('')
    print('Se algo sair errado, restaure com:')
    print(f'   copy /Y "{CAMINHO}.bak" "{CAMINHO}"')
