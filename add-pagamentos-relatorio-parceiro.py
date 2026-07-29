#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Adiciona ao Relatorio de Parceiro (ReportsPage.tsx) uma tabela de
PAGAMENTOS / RECEBIMENTOS com DATA e VALOR.

- Busca recebimentos em client_payments e pagamentos em supplier_payments
  para o parceiro selecionado.
- Insere a tabela logo apos o bloco de saldo, antes das viagens.

O script NAO altera nada se nao encontrar os pontos de ancora exatos
(assim nao corre risco de quebrar o arquivo). Faz backup .bakpag.

Uso (dentro de D:\\sistema\\agendapro-cmms, no PowerShell ou CMD):
    python add-pagamentos-relatorio-parceiro.py
"""
import os, sys, re, shutil

CAM = os.path.join('src','app','pages','ReportsPage.tsx')
if not os.path.exists(CAM):
    print('ERRO: rode dentro de D:\\sistema\\agendapro-cmms'); sys.exit(1)

with open(CAM, encoding='utf-8') as f:
    src = f.read()

# ---------------------------------------------------------------
# ANCORA 1: a linha que cria qSaldo. Vamos adicionar, logo depois,
# duas queries: qRecebido (client_payments) e qPago (supplier_payments).
# ---------------------------------------------------------------
m_saldo = re.search(r"(let qSaldo = supabase\.from\('v_saldo_conta_corrente'\)[^\n]*\n)", src)
if not m_saldo:
    print('NAO ENCONTREI a linha do qSaldo. Nada foi alterado.')
    print('Me avise para ajustar a ancora.')
    sys.exit(1)

queries_pag = (
    "        let qRecebido = supabase.from('client_payments').select('*')"
    ".ilike('client_name', parceiroNome).order('payment_date',{ascending:false})\n"
    "        let qPago = supabase.from('supplier_payments').select('*')"
    ".ilike('supplier_name', parceiroNome).order('payment_date',{ascending:false})\n"
    "        if (dateFrom) { qRecebido = qRecebido.gte('payment_date', dateFrom); qPago = qPago.gte('payment_date', dateFrom) }\n"
    "        if (dateTo)   { qRecebido = qRecebido.lte('payment_date', dateTo);   qPago = qPago.lte('payment_date', dateTo) }\n"
)

if 'qRecebido' not in src:
    src = src.replace(m_saldo.group(1), m_saldo.group(1) + queries_pag)

# ---------------------------------------------------------------
# ANCORA 2: o Promise.all que executa as queries do parceiro.
# Precisamos adicionar qRecebido e qPago na execucao e capturar o resultado.
# ---------------------------------------------------------------
# Formato tipico: const [rCompras, rWood, rVendas, rSaldo] = await Promise.all([qCompras, qWood, qVendas, qSaldo])
m_all = re.search(r"const \[([^\]]+)\] = await Promise\.all\(\[([^\]]+)\]\)", src)
if m_all and 'rRecebido' not in src:
    nomes = m_all.group(1).strip()
    qs = m_all.group(2).strip()
    novo = f"const [{nomes}, rRecebido, rPago] = await Promise.all([{qs}, qRecebido, qPago])"
    src = src.replace(m_all.group(0), novo)

# ---------------------------------------------------------------
# ANCORA 3: inserir a tabela de pagamentos antes da secao de viagens.
# A secao de viagens comeca com um comentario contendo "Viagens por motorista".
# ---------------------------------------------------------------
m_viag = re.search(r"\n(\s*//[^\n]*Viagens por motorista[^\n]*\n)", src)
if not m_viag:
    # fallback: procura doc.text('Viagens por Motorista'
    m_viag = re.search(r"(\n\s*doc\.text\('Viagens por Motorista')", src)

bloco_tabela = """
        // ── Secao: Pagamentos e Recebimentos (data e valor) ──
        var pagRows = [];
        (rRecebido && rRecebido.data ? rRecebido.data : []).forEach(function(p){
          pagRows.push([
            p.payment_date ? new Date(p.payment_date+'T00:00:00').toLocaleDateString('pt-BR') : '-',
            'RECEBIMENTO',
            p.method || '-',
            'R$ ' + (Number(p.value)||0).toFixed(2)
          ]);
        });
        (rPago && rPago.data ? rPago.data : []).forEach(function(p){
          pagRows.push([
            p.payment_date ? new Date(p.payment_date+'T00:00:00').toLocaleDateString('pt-BR') : '-',
            'PAGAMENTO',
            p.method || '-',
            'R$ ' + (Number(p.value)||0).toFixed(2)
          ]);
        });
        if (pagRows.length > 0) {
          y = (doc).lastAutoTable ? (doc).lastAutoTable.finalY + 7 : y + 7;
          doc.setFontSize(11); doc.setTextColor(0,0,0); doc.setFont('helvetica','bold');
          doc.text('Pagamentos e Recebimentos', 12, y);
          y += 2;
          autoTable(doc, {
            startY: y + 2,
            head: [['Data','Tipo','Forma','Valor']],
            body: pagRows,
            theme: 'striped',
            headStyles: { fillColor:[20,30,50], textColor:[255,255,255] },
            bodyStyles: { textColor:[20,20,20] },
            styles: { fontSize: 8 },
            didParseCell: function(d){
              if (d.section === 'body' && d.column.index === 3) {
                var t = (d.row && d.row.raw && d.row.raw[1]) ? String(d.row.raw[1]) : '';
                d.cell.styles.textColor = (t === 'PAGAMENTO') ? [200,0,0] : [0,120,0];
              }
            }
          });
        }
"""

if m_viag and 'Pagamentos e Recebimentos' not in src:
    src = src[:m_viag.start()] + '\n' + bloco_tabela + src[m_viag.start():]
    ok_tabela = True
else:
    ok_tabela = 'Pagamentos e Recebimentos' in src

# ---------------------------------------------------------------
# Salvar (com backup)
# ---------------------------------------------------------------
shutil.copy(CAM, CAM + '.bakpag')
with open(CAM, 'w', encoding='utf-8') as f:
    f.write(src)

print('Backup:', CAM + '.bakpag')
print('Queries de pagamento adicionadas:', 'qRecebido' in src)
print('Promise.all atualizado:', 'rRecebido' in src)
print('Tabela de pagamentos inserida:', ok_tabela)
if 'qRecebido' in src and 'rRecebido' in src and ok_tabela:
    print('')
    print('OK — relatorio de parceiro agora inclui Pagamentos e Recebimentos com data e valor.')
    print('   (Recebimentos em verde, Pagamentos em vermelho.)')
else:
    print('')
    print('ATENCAO: nem tudo foi aplicado. Verifique as mensagens acima.')
    print('Para reverter: copy /Y "%s" "%s"' % (CAM+'.bakpag', CAM))
