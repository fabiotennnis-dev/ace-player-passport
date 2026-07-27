// Supabase Edge Function: asaas-webhook
// Deploy: supabase functions deploy asaas-webhook
// URL resultante: https://elihmklizdmjnvstgiqq.supabase.co/functions/v1/asaas-webhook
//
// No painel Asaas: Configurações → Webhooks → adicionar a URL acima
// Eventos necessários: PAYMENT_CONFIRMED, PAYMENT_RECEIVED, SUBSCRIPTION_INACTIVATED

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const PLANOS_LIMITE: Record<string, number> = {
  starter:   30,
  growth:    80,
  pro:       150,
  unlimited: 9999,
};

// Mapa: valor mensal em centavos → id do plano
// Ajuste os valores conforme cadastrado no Asaas
const VALOR_PLANO: Record<number, string> = {
  9900:  'starter',
  19900: 'growth',
  34900: 'pro',
  54900: 'unlimited',
};

Deno.serve(async (req) => {
  // Asaas envia POST com JSON
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response('Invalid JSON', { status: 400 });
  }

  const event   = body.event as string;
  const payment = body.payment as Record<string, unknown> | undefined;

  // Só processa eventos de pagamento confirmado
  if (!['PAYMENT_CONFIRMED', 'PAYMENT_RECEIVED'].includes(event) || !payment) {
    return new Response(JSON.stringify({ ok: true, ignored: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const asaasCustomerId    = payment.customer as string;
  const asaasSubscriptionId = payment.subscription as string | undefined;
  const valorCentavos       = Math.round((payment.value as number) * 100);
  const asaasPaymentId      = payment.id as string;

  // Identifica o plano pelo valor
  const planoId = VALOR_PLANO[valorCentavos];
  if (!planoId) {
    console.warn(`Valor ${valorCentavos} não mapeado para nenhum plano`);
    return new Response(JSON.stringify({ ok: true, ignored: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const limiteAlunos = PLANOS_LIMITE[planoId];

  // Busca a academia pelo asaas_customer_id
  const { data: academia, error: fetchErr } = await supabase
    .from('academias')
    .select('id, plano')
    .eq('asaas_customer_id', asaasCustomerId)
    .single();

  if (fetchErr || !academia) {
    console.error('Academia não encontrada para customer', asaasCustomerId);
    // Retorna 200 para o Asaas não retentar indefinidamente
    return new Response(JSON.stringify({ ok: true, not_found: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Atualiza plano e limite
  const { error: updateErr } = await supabase
    .from('academias')
    .update({
      plano:          planoId,
      limite_alunos:  limiteAlunos,
      ...(asaasSubscriptionId ? { asaas_subscription_id: asaasSubscriptionId } : {}),
    })
    .eq('id', academia.id);

  if (updateErr) {
    console.error('Erro ao atualizar academia', updateErr);
    return new Response(JSON.stringify({ error: 'update failed' }), { status: 500 });
  }

  // Registra o evento no histórico
  await supabase.from('billing_events').insert({
    academia_id: academia.id,
    evento:      'payment_confirmed',
    plano:       planoId,
    valor:       payment.value as number,
    asaas_id:    asaasPaymentId,
  });

  console.log(`Academia ${academia.id} → plano ${planoId} (${limiteAlunos} alunos)`);

  return new Response(JSON.stringify({ ok: true, plano: planoId }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
