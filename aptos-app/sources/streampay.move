module MyModule::StreamPay {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a subscription service
    struct Subscription has store, key {
        monthly_fee: u64,           // Monthly subscription fee in APT
        total_collected: u64,       // Total amount collected from subscribers
        last_payment_time: u64,     // Timestamp of last payment
        is_active: bool,            // Subscription status
    }

    /// Struct to track subscriber information
    struct Subscriber has store, key {
        service_provider: address,  // Address of the service provider
        next_payment_due: u64,      // Timestamp when next payment is due
        is_subscribed: bool,        // Subscription status
    }

    /// Function to create a subscription service with monthly fee
    public fun create_subscription_service(
        provider: &signer, 
        monthly_fee: u64
    ) {
        let subscription = Subscription {
            monthly_fee,
            total_collected: 0,
            last_payment_time: timestamp::now_seconds(),
            is_active: true,
        };
        move_to(provider, subscription);
    }

    /// Function for users to subscribe and make monthly payments
    public fun subscribe_and_pay(
        subscriber: &signer, 
        provider_address: address
    ) acquires Subscription, Subscriber {
        let provider_subscription = borrow_global_mut<Subscription>(provider_address);
        let subscriber_addr = signer::address_of(subscriber);
        
        // Check if subscription service is active
        assert!(provider_subscription.is_active, 1);
        
        // Process payment
        let payment = coin::withdraw<AptosCoin>(subscriber, provider_subscription.monthly_fee);
        coin::deposit<AptosCoin>(provider_address, payment);
        
        // Update provider's total collected
        provider_subscription.total_collected = provider_subscription.total_collected + provider_subscription.monthly_fee;
        provider_subscription.last_payment_time = timestamp::now_seconds();
        
        // Handle subscriber record
        if (exists<Subscriber>(subscriber_addr)) {
            let subscriber_info = borrow_global_mut<Subscriber>(subscriber_addr);
            subscriber_info.next_payment_due = timestamp::now_seconds() + 2592000; // 30 days in seconds
            subscriber_info.is_subscribed = true;
        } else {
            let new_subscriber = Subscriber {
                service_provider: provider_address,
                next_payment_due: timestamp::now_seconds() + 2592000,
                is_subscribed: true,
            };
            move_to(subscriber, new_subscriber);
        }
    }
}