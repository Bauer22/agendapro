$arquivo = 'src\app\pages\SalesPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakcc') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakcc')

$txt = Get-Content $arquivo -Raw

if ($txt -match 'recebRowsVen') {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

$nl = [Environment]::NewLine

# Bloco a inserir ANTES do doc.save(`vendas_...`)
# Usa: rep, repVal, rCli, clients, money, doc, autoTable, dateFrom/rFrom, rTo
$b = @()
$b += "      // -- Conta Corrente: recebimentos do periodo + saldo real --"
$b += "      var nomeCliVen = rCli ? (clients.find(function(x){return x.id===rCli;})||{}).name : null;"
$b += "      var qRecVen = supabase.from('client_payments').select('*').order('payment_date',{ascending:false});"
$b += "      if (nomeCliVen) qRecVen = qRecVen.ilike('client_name', nomeCliVen);"
$b += "      if (rFrom) qRecVen = qRecVen.gte('payment_date', rFrom);"
$b += "      if (rTo)   qRecVen = qRecVen.lte('payment_date', rTo);"
$b += "      var qSaldoVen = supabase.from('v_saldo_conta_corrente').select('*');"
$b += "      if (nomeCliVen) qSaldoVen = qSaldoVen.ilike('parceiro', nomeCliVen);"
$b += "      var resCC = await Promise.all([qRecVen, qSaldoVen]);"
$b += "      var rRecVen = resCC[0]; var rSaldoVen = resCC[1];"
$b += "      var recebRowsVen = (rRecVen && rRecVen.data ? rRecVen.data : []).map(function(p){"
$b += "        return [ p.payment_date ? new Date(p.payment_date+'T00:00:00').toLocaleDateString('pt-BR') : '-', p.client_name || '-', p.method || '-', 'R$ ' + (Number(p.value)||0).toFixed(2) ];"
$b += "      });"
$b += "      if (recebRowsVen.length > 0) {"
$b += "        y = (doc).lastAutoTable ? (doc).lastAutoTable.finalY + 8 : y + 8;"
$b += "        doc.setFontSize(11); doc.setTextColor(0,0,0); doc.setFont('helvetica','bold');"
$b += "        doc.text('Recebimentos do Periodo', 12, y);"
$b += "        autoTable(doc, { startY: y + 3, head: [['Data','Cliente','Forma','Valor']], body: recebRowsVen, theme:'striped', headStyles:{fillColor:[16,185,129]}, bodyStyles:{textColor:[20,20,20]}, styles:{fontSize:8} });"
$b += "        y = (doc).lastAutoTable.finalY + 8;"
$b += "      }"
$b += "      var totalRecVen = (rRecVen && rRecVen.data ? rRecVen.data : []).reduce(function(s,p){return s + (Number(p.value)||0);}, 0);"
$b += "      var saldoVen = (rSaldoVen && rSaldoVen.data && rSaldoVen.data.length > 0) ? rSaldoVen.data : [];"
$b += "      y = (doc).lastAutoTable ? (doc).lastAutoTable.finalY + 8 : y + 8;"
$b += "      if (y > 250) { doc.addPage(); y = 20; }"
$b += "      doc.setFontSize(11); doc.setTextColor(0,0,0); doc.setFont('helvetica','bold');"
$b += "      doc.text('Resumo de Conta Corrente', 12, y);"
$b += "      y += 6;"
$b += "      doc.setFontSize(9); doc.setFont('helvetica','normal'); doc.setTextColor(20,20,20);"
$b += "      doc.text('Total Vendido: R$ ' + (repVal||0).toFixed(2), 12, y); y += 5;"
$b += "      doc.text('Total Recebido: R$ ' + totalRecVen.toFixed(2), 12, y); y += 5;"
$b += "      if (saldoVen.length > 0) {"
$b += "        var totReceber = saldoVen.reduce(function(s,x){return s + (Number(x.a_receber)||0);}, 0);"
$b += "        doc.setFont('helvetica','bold');"
$b += "        doc.text('SALDO A RECEBER: R$ ' + totReceber.toFixed(2), 12, y); y += 6;"
$b += "      }"
$b += ""

$bloco = ($b -join $nl)

# Ancora: a linha do doc.save do relatorio de vendas
$idx = $txt.IndexOf("doc.save(`vendas_")
if ($idx -lt 0) { $idx = $txt.IndexOf('doc.save(') }

if ($idx -ge 0) {
    $inicioLinha = $txt.LastIndexOf($nl, $idx) + 1
    $txt = $txt.Substring(0, $inicioLinha) + $bloco + $nl + $txt.Substring($inicioLinha)
    $tabelaOk = $true
} else {
    $tabelaOk = $false
}

Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ('Bloco inserido: ' + $tabelaOk)
Write-Host ('Marcador recebRowsVen presente: ' + ($txt -match 'recebRowsVen'))
