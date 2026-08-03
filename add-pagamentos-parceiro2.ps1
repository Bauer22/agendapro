$arquivo = 'src\app\pages\ReportsPage.tsx'

if (-not (Test-Path $arquivo)) {
    Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'
    exit 1
}

Copy-Item $arquivo ($arquivo + '.bakpag3') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakpag3')

$txt = Get-Content $arquivo -Raw

if ($txt -match 'qRecebidoPar') {
    Write-Host 'Ja aplicado antes. Nada alterado.'
    exit 0
}

# 1) Queries apos qSaldo
$padraoSaldo = "(let qSaldo = supabase\.from\('v_saldo_conta_corrente'\)[^\r\n]*)"
$q1 = "        let qRecebidoPar = supabase.from('client_payments').select('*').ilike('client_name', parceiroNome).order('payment_date',{ascending:false})"
$q2 = "        let qPagoPar = supabase.from('supplier_payments').select('*').ilike('supplier_name', parceiroNome).order('payment_date',{ascending:false})"
$q3 = "        if (dateFrom) { qRecebidoPar = qRecebidoPar.gte('payment_date', dateFrom); qPagoPar = qPagoPar.gte('payment_date', dateFrom) }"
$q4 = "        if (dateTo)   { qRecebidoPar = qRecebidoPar.lte('payment_date', dateTo);   qPagoPar = qPagoPar.lte('payment_date', dateTo) }"
$nl = [Environment]::NewLine
$queries = '$1' + $nl + $q1 + $nl + $q2 + $nl + $q3 + $nl + $q4
$txt = [regex]::Replace($txt, $padraoSaldo, $queries)

# 2) Promise.all
$mAll = [regex]::Match($txt, 'const \[([^\]]+)\] = await Promise\.all\(\[([^\]]+)\]\)')
if ($mAll.Success) {
    $nomes = $mAll.Groups[1].Value.Trim()
    $qs    = $mAll.Groups[2].Value.Trim()
    $novo  = 'const [' + $nomes + ', rRecebidoPar, rPagoPar] = await Promise.all([' + $qs + ', qRecebidoPar, qPagoPar])'
    $txt = $txt.Replace($mAll.Value, $novo)
    $allOk = $true
} else {
    $allOk = $false
}

# 3) Bloco da tabela (montado linha a linha, sem acentos)
$b = @()
$b += "        var pagRowsPar = [];"
$b += "        (rRecebidoPar && rRecebidoPar.data ? rRecebidoPar.data : []).forEach(function(p){"
$b += "          pagRowsPar.push([ p.payment_date ? new Date(p.payment_date+'T00:00:00').toLocaleDateString('pt-BR') : '-', 'RECEBIMENTO', p.method || '-', 'R$ ' + (Number(p.value)||0).toFixed(2) ]);"
$b += "        });"
$b += "        (rPagoPar && rPagoPar.data ? rPagoPar.data : []).forEach(function(p){"
$b += "          pagRowsPar.push([ p.payment_date ? new Date(p.payment_date+'T00:00:00').toLocaleDateString('pt-BR') : '-', 'PAGAMENTO', p.method || '-', 'R$ ' + (Number(p.value)||0).toFixed(2) ]);"
$b += "        });"
$b += "        if (pagRowsPar.length > 0) {"
$b += "          y = (doc).lastAutoTable ? (doc).lastAutoTable.finalY + 8 : y + 8;"
$b += "          doc.setFontSize(11); doc.setTextColor(0,0,0); doc.setFont('helvetica','bold');"
$b += "          doc.text('Pagamentos e Recebimentos', 12, y);"
$b += "          autoTable(doc, { startY: y + 3, head: [['Data','Tipo','Forma','Valor']], body: pagRowsPar, theme: 'striped', headStyles: { fillColor:[20,30,50], textColor:[255,255,255] }, bodyStyles: { textColor:[20,20,20] }, styles: { fontSize: 8 } });"
$b += "        }"
$b += ""
$bloco = ($b -join $nl)

$idx = $txt.IndexOf('Viagens por Motorista')
if ($idx -lt 0) { $idx = $txt.IndexOf('Viagens por motorista') }

if ($idx -ge 0) {
    $inicioLinha = $txt.LastIndexOf($nl, $idx) + 1
    $txt = $txt.Substring(0, $inicioLinha) + $bloco + $nl + $txt.Substring($inicioLinha)
    $tabelaOk = $true
} else {
    $tabelaOk = $false
}

Set-Content -Path $arquivo -Value $txt -NoNewline

Write-Host ('Queries adicionadas: ' + ($txt -match 'qRecebidoPar'))
Write-Host ('Promise.all atualizado: ' + $allOk)
Write-Host ('Tabela inserida: ' + $tabelaOk)
