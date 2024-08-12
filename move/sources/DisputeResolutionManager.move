module DisputeResolutionManager {

    use std::signer;
    use aptos_framework::coin;

    struct Dispute has key, store {
        dispute_id: u64,
        claimant: address,
        respondent: address,
        description: vector<u8>,
        resolved: bool,
        ruling: u8,  // 0 for unresolved, 1 for claimant wins, 2 for respondent wins
        payment_id: u64, // Link to the disputed payment
    }

    struct DisputeRegistry has key {
        disputes: table::Table<u64, Dispute>,
        last_dispute_id: u64,
    }

    public fun initialize_registry(account: &signer) {
        move_to(account, DisputeRegistry {
            disputes: table::Table::new(),
            last_dispute_id: 0,
        });
    }

    // File a new dispute
    public fun file_dispute(
        account: &signer,
        respondent: address,
        description: vector<u8>,
        payment_id: u64
    ) {
        let registry = borrow_global_mut<DisputeRegistry>(signer::address_of(account));
        let new_id = registry.last_dispute_id + 1;

        let dispute = Dispute {
            dispute_id: new_id,
            claimant: signer::address_of(account),
            respondent,
            description,
            resolved: false,
            ruling: 0,
            payment_id,
        };

        table::add(&mut registry.disputes, new_id, dispute);
        registry.last_dispute_id = new_id;

        // Mark the associated payment as in dispute
        PaymentManager::mark_dispute(payment_id);
    }

    // Resolve a dispute
    public fun resolve_dispute(account: &signer, dispute_id: u64, ruling: u8) {
        let registry = borrow_global_mut<DisputeRegistry>(signer::address_of(account));
        let dispute = table::borrow_mut(&mut registry.disputes, dispute_id);

        // Only allow resolution if the dispute is unresolved
        assert!(!dispute.resolved, 100);

        // Apply the ruling
        dispute.resolved = true;
        dispute.ruling = ruling;

        // Execute the ruling, e.g., release funds from escrow, refund, etc.
        if (ruling == 1) {
            // Claimant wins
            coin::transfer(account, dispute.claimant, 1000); // Example payout
        } else if (ruling == 2) {
            // Respondent wins
            coin::transfer(account, dispute.respondent, 1000); // Example payout
        }
    }

    // Query dispute status
    public fun get_dispute_status(dispute_id: u64): &Dispute {
        let registry = borrow_global<DisputeRegistry>(signer::address_of(account));
        table::borrow(&registry.disputes, dispute_id)
    }
}
