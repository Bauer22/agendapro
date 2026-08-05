$arquivo = 'src\app\pages\SalesPage.tsx'

if (-not (Test-Path $arquivo)) { Write-Host 'ERRO: rode dentro de D:\sistema\agendapro-cmms'; exit 1 }

Copy-Item $arquivo ($arquivo + '.bakedit') -Force
Write-Host ('Backup criado: ' + $arquivo + '.bakedit')

$txt = Get-Content $arquivo -Raw
$nl = [Environment]::NewLine

if ($txt -match 'editLancModal') { Write-Host 'Ja aplicado antes. Nada alterado.'; exit 0 }

$r = @{}

# ---- 1) Estados novos (apos payModal) ----
$de1 = "  const [payModal, setPayModal] = useState(false)"
$para1 = $de1 + $nl + "  const [editLancModal, setEditLancModal] = useState(false)" + $nl + "  const [editLanc, setEditLanc] = useState<any>({})"
if ($txt.Contains($de1)) { $txt = $txt.Replace($de1, $para1); $r['1_estados']=$true } else { $r['1_estados']=$false }

# ---- 2) podeExcluir por origem (inclui ajustes) ----
$de2 = "                            const podeExcluir = l.tipo==='RECEBIMENTO' || l.tipo==='PAGAMENTO'"
$para2 = "                            const ORIGENS_FIN = ['client_payments','supplier_payments','account_adjustments']" + $nl + "                            const podeExcluir = ORIGENS_FIN.includes(l.origem)"
if ($txt.Contains($de2)) { $txt = $txt.Replace($de2, $para2); $r['2_podeExcluir']=$true } else { $r['2_podeExcluir']=$false }

# ---- 3) Trava de seguranca na deleteLancamento ----
$de3 = "  async function deleteLancamento(origem: string, id: string) {"
$para3 = $de3 + $nl + "    if (!['client_payments','supplier_payments','account_adjustments'].includes(origem)) { toast.error('Este lancamento so pode ser alterado na tela de origem'); return }"
if ($txt.Contains($de3)) { $txt = $txt.Replace($de3, $para3); $r['3_trava']=$true } else { $r['3_trava']=$false }

# ---- 4) Funcoes editarLancamento + saveEditLanc (inseridas apos deleteLancamento) ----
$deFim = "    toast.success('LanÃ§amento excluÃ­do âœ…')" + $nl + "    loadExtrato()" + $nl + "  }"
# fallback sem acento se nao casar
if (-not $txt.Contains($deFim)) {
    $mFim = [regex]::Match($txt, "toast\.success\('Lan[^\n]*exclu[^\n]*'\)\s*[\r\n]+\s*loadExtrato\(\)\s*[\r\n]+\s*\}")
    if ($mFim.Success) { $deFim = $mFim.Value }
}
$fn = @()
$fn += ""
$fn += "  function editarLancamento(l: any) {"
$fn += "    if (!['client_payments','supplier_payments','account_adjustments'].includes(l.origem)) { toast.error('Este lancamento so pode ser alterado na tela de origem'); return }"
$fn += "    setEditLanc({ id: l.id, origem: l.origem, tipo: l.tipo, data: l.data, valor: (+l.credito!==0? +l.credito : +l.debito), descricao: l.descricao||'' })"
$fn += "    setEditLancModal(true)"
$fn += "  }"
$fn += ""
$fn += "  async function saveEditLanc() {"
$fn += "    if (saving) return"
$fn += "    if (!editLanc.valor || editLanc.valor<=0) { toast.error('Informe um valor valido'); return }"
$fn += "    setSaving(true)"
$fn += "    var campoData = editLanc.origem==='account_adjustments' ? 'adj_date' : 'payment_date'"
$fn += "    var campoValor = 'value'"
$fn += "    var patch = {}"
$fn += "    patch[campoData] = editLanc.data"
$fn += "    patch[campoValor] = parseFloat(editLanc.valor)"
$fn += "    if (editLanc.origem==='account_adjustments') { patch['descricao'] = editLanc.descricao }"
$fn += "    const { error } = await supabase.from(editLanc.origem).update(patch).eq('id', editLanc.id)"
$fn += "    setSaving(false)"
$fn += "    if (error) { toast.error('Erro ao salvar: ' + error.message); return }"
$fn += "    toast.success('Lancamento atualizado')"
$fn += "    setEditLancModal(false); setEditLanc({}); loadExtrato()"
$fn += "  }"
$bloco = ($fn -join $nl)
if ($txt.Contains($deFim)) { $txt = $txt.Replace($deFim, $deFim + $nl + $bloco); $r['4_funcoes']=$true } else { $r['4_funcoes']=$false }

# ---- 5) Grid: abrir espaco para 2 botoes (44px) ----
$de5 = "gridTemplateColumns: podeExcluir?'50px 1fr 62px 62px 22px':'50px 1fr 62px 62px'"
$para5 = "gridTemplateColumns: podeExcluir?'50px 1fr 62px 62px 44px':'50px 1fr 62px 62px'"
if ($txt.Contains($de5)) { $txt = $txt.Replace($de5, $para5); $r['5_grid']=$true } else { $r['5_grid']=$false }

# ---- 6) Botao editar ao lado do excluir ----
$de6 = "                                {podeExcluir && (" + $nl + "                                  <span onClick={()=>deleteLancamento(l.origem, l.id)}"
$para6 = "                                {podeExcluir && (" + $nl + "                                  <span onClick={()=>editarLancamento(l)} style={{textAlign:'center',color:'var(--cy)',cursor:'pointer',fontWeight:700}} title=`"Editar`">edit</span>" + $nl + "                                )}" + $nl + "                                {podeExcluir && (" + $nl + "                                  <span onClick={()=>deleteLancamento(l.origem, l.id)}"
if ($txt.Contains($de6)) { $txt = $txt.Replace($de6, $para6); $r['6_botao_editar']=$true } else { $r['6_botao_editar']=$false }

# ---- 7) Modal de edicao (antes do modal de pagamento) ----
$md = @()
$md += "          <Modal open={editLancModal} onClose={()=>setEditLancModal(false)} title=`"Editar Lancamento`""
$md += "            footer={<><Btn onClick={()=>setEditLancModal(false)}>Cancelar</Btn><Btn onClick={saveEditLanc} variant=`"primary`" size=`"md`" disabled={saving}>{saving?'Salvando...':'Salvar'}</Btn></>}>"
$md += "            <div style={{fontSize:'10px',color:'var(--t3)',marginBottom:'8px'}}>Tipo: <b>{editLanc.tipo}</b></div>"
$md += "            <Input label=`"Data`" value={editLanc.data} onChange={(v:string)=>setEditLanc((e:any)=>({...e,data:v}))} type=`"date`" />"
$md += "            <Input label=`"Valor R$`" value={editLanc.valor} onChange={(v:string)=>setEditLanc((e:any)=>({...e,valor:v}))} type=`"number`" />"
$md += "            {editLanc.origem==='account_adjustments' && (<Input label=`"Descricao`" value={editLanc.descricao} onChange={(v:string)=>setEditLanc((e:any)=>({...e,descricao:v}))} />)}"
$md += "          </Modal>"
$md += ""
$modalTxt = ($md -join $nl)
$de7 = "          <Modal open={payModal} onClose={()=>setPayModal(false)}"
if ($txt.Contains($de7)) { $txt = $txt.Replace($de7, $modalTxt + "          <Modal open={payModal} onClose={()=>setPayModal(false)}"); $r['7_modal']=$true } else { $r['7_modal']=$false }

Set-Content -Path $arquivo -Value $txt -NoNewline

foreach ($k in ($r.Keys | Sort-Object)) { Write-Host ($k + ': ' + $r[$k]) }
$todos = $true; foreach ($v in $r.Values) { if (-not $v) { $todos = $false } }
Write-Host ''
if ($todos) { Write-Host 'OK - todas as 7 alteracoes aplicadas.' }
else { Write-Host 'ATENCAO: nem tudo aplicado. Reverta com: Copy-Item ' + $arquivo + '.bakedit ' + $arquivo + ' -Force' }
