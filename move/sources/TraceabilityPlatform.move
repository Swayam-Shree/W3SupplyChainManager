module TraceabilityPlatform {

    use std::signer;
    use ProductManager;
    use PaymentManager;
    use DisputeResolutionManager;

    // Initialize the platform by setting up registries for product, payment, and dispute
    public fun initialize_platform(account: &signer) {
        ProductManager::initialize_registry(account);
        PaymentManager::initialize_registry(account);
        DisputeResolutionManager::initialize_registry(account);
    }

    // Register a product and create a corresponding payment
    public fun register_and_pay(
        account: &signer,
        name: vector<u8>,
        description: vector<u8>,
        payee: address,
        amount: u64
    ) {
        ProductManager::register_product(account, name, description);
        let product_id = ProductManager::get_product(product_id);
        PaymentManager::create_payment(account, payee, amount, product_id.id);
    }

    // Log product movement and fulfill payment
    public fun complete_transaction(
        account: &signer,
        product_id: u64,
        movement_description: vector<u8>,
        payment_id: u64
    ) {
        ProductManager::log_movement(account, product_id, movement_description);
        PaymentManager::fulfill_payment(account, payment_id);
    }

    // Handle disputes by linking them to the payment
    public fun file_and_resolve_dispute(
        account: &signer,
        respondent: address,
        description: vector<u8>,
        payment_id: u64,
        ruling: u8
    ) {
        DisputeResolutionManager::file_dispute(account, respondent, description, payment_id);
        let dispute_id = DisputeResolutionManager::get_dispute_status(dispute_id);
        DisputeResolutionManager::resolve_dispute(account, dispute_id.dispute_id, ruling);
    }
}