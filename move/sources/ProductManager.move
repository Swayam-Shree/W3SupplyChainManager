module ProductManager {

    use std::signer;
    use aptos_framework::timestamp;

    // Struct to store product details
    struct Product has key, store {
        id: u64,
        owner: address,
        name: vector<u8>,
        description: vector<u8>,
        registered_at: u64,
        movement_log: vector<vector<u8>>,
    }

    // Resource to store products by their unique ID
    struct ProductRegistry has key {
        products: table::Table<u64, Product>,
        last_id: u64,
    }

    // Initialize the product registry resource for an account
    public fun initialize_registry(account: &signer) {
        move_to(account, ProductRegistry {
            products: table::Table::new(),
            last_id: 0,
        });
    }

    // Register a new product
    public fun register_product(
        account: &signer,
        name: vector<u8>,
        description: vector<u8>
    ) {
        let registry = borrow_global_mut<ProductRegistry>(signer::address_of(account));
        let new_id = registry.last_id + 1;

        let product = Product {
            id: new_id,
            owner: signer::address_of(account),
            name,
            description,
            registered_at: timestamp::now_seconds(),
            movement_log: vector::empty(),
        };

        table::add(&mut registry.products, new_id, product);
        registry.last_id = new_id;
    }

    // Log product movement
    public fun log_movement(
        account: &signer,
        product_id: u64,
        movement_description: vector<u8>
    ) {
        let registry = borrow_global_mut<ProductRegistry>(signer::address_of(account));
        let product = table::borrow_mut(&mut registry.products, product_id);

        // Only the product owner can log movements
        assert!(product.owner == signer::address_of(account), 100);

        vector::push_back(&mut product.movement_log, movement_description);
    }

    // Get product details (for querying)
    public fun get_product(product_id: u64): &Product {
        let registry = borrow_global<ProductRegistry>(signer::address_of(account));
        table::borrow(&registry.products, product_id)
    }
}