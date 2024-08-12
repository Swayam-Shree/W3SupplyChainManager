module PaymentManager {

    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_account;

    // Payment details for a transaction
    struct Payment has key, store {
        payer: address,
        payee: address,
        amount: u64,
        product_id: u64,
        fulfilled: bool,
        in_dispute: bool, // Flag to indicate if payment is under dispute
    }

    // Resource to store pending payments
    struct PaymentRegistry has key {
        payments: table::Table<u64, Payment>,
        last_payment_id: u64,
    }

    // Initialize payment registry
    public fun initialize_registry(account: &signer) {
        move_to(account, PaymentRegistry {
            payments: table::Table::new(),
            last_payment_id: 0,
        });
    }

    // Create a new payment
    public fun create_payment(
        account: &signer,
        payee: address,
        amount: u64,
        product_id: u64
    ) {
        let registry = borrow_global_mut<PaymentRegistry>(signer::address_of(account));
        let new_id = registry.last_payment_id + 1;

        let payment = Payment {
            payer: signer::address_of(account),
            payee,
            amount,
            product_id,
            fulfilled: false,
            in_dispute: false,
        };

        table::add(&mut registry.payments, new_id, payment);
        registry.last_payment_id = new_id;
    }

    // Fulfill payment upon successful transaction (e.g., product delivery)
    public fun fulfill_payment(account: &signer, payment_id: u64) {
        let registry = borrow_global_mut<PaymentRegistry>(signer::address_of(account));
        let payment = table::borrow_mut(&mut registry.payments, payment_id);

        // Ensure payment has not been fulfilled yet and is not under dispute
        assert!(!payment.fulfilled, 101);
        assert!(!payment.in_dispute, 102);

        // Transfer funds from payer to payee
        coin::transfer(account, payment.payee, payment.amount);

        payment.fulfilled = true;
    }

    // Mark a payment as disputed
    public fun mark_dispute(payment_id: u64) {
        let registry = borrow_global_mut<PaymentRegistry>(signer::address_of(account));
        let payment = table::borrow_mut(&mut registry.payments, payment_id);

        payment.in_dispute = true;
    }

    // Query payment status
    public fun get_payment_status(payment_id: u64): &Payment {
        let registry = borrow_global<PaymentRegistry>(signer::address_of(account));
        table::borrow(&registry.payments, payment_id)
    }
}