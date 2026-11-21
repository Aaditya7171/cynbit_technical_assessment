// this is an example of how I'd handle form Errors and payment status

export async function submitWithRecovery(operation, setPending) {
  setPending(true);

  try {
    const result = await operation();

    if (result?.success === true) return { ok: true };

    return {
      ok: false, code: 'SUBMISSION_NOT_CONFIRMED',
      message: 'Submission was not confirmed. Check your details or plis contact support'
    };

  } catch {
    // If a request fails, it doesn't always mean the server
    // didn't save the data. We should check before retrying
    return {
      ok: false,
      code: 'STATUS_UNKNOWN',
      message: 'We could not confirm the result, Check the status before retrying'
    };
  } finally {
    setPending(false);
  }
}

export function paymentView(status) {
  if (status === 'PAID') {
    return {
      kind: 'success',
      text: 'Payment Confirmed.'
    };
  }
  if (status === 'FAILED') {
    return {
      kind: 'error',
      text: 'Payment failed according to the verified server status.'
    };
  }
  return {
    kind: 'pending',
    text: 'Payment status is not yet confirmed. Please check again before paying.'
  };
}
