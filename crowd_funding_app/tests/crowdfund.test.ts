import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test comprehensive crowdfunding functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const user1 = accounts.get("wallet_1")!;
        const user2 = accounts.get("wallet_2")!;
        const user3 = accounts.get("wallet_3")!;

        // Initialize categories first
        let block = chain.mineBlock([
            Tx.contractCall("crowdfund", "initialize-categories", [], deployer.address),
        ]);
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result.expectOk(), true);

        // Test 1: Create campaign with advanced features
        block = chain.mineBlock([
            Tx.contractCall("crowdfund", "create-campaign-advanced", [
                types.ascii("Revolutionary AI Platform"),
                types.ascii("Building the future of artificial intelligence with ethical guidelines and transparency"),
                types.uint(1000000000), // 1000 STX goal
                types.uint(14400), // 100 days duration
                types.ascii("technology"),
                types.ascii("AI,blockchain,ethics,innovation")
            ], user1.address),
        ]);
        
        assertEquals(block.receipts.length, 1);
        const campaignId = block.receipts[0].result.expectOk();
        assertEquals(campaignId, types.uint(1));

        // Test 2: Verify campaign details
        let campaign = chain.callReadOnlyFn("crowdfund", "get-campaign", [types.uint(1)], deployer.address);
        let campaignData = campaign.result.expectSome().expectTuple();
        assertEquals(campaignData['title'], types.ascii("Revolutionary AI Platform"));
        assertEquals(campaignData['category'], types.ascii("technology"));
        assertEquals(campaignData['goal'], types.uint(1000000000));
        assertEquals(campaignData['kyc-verified'], types.bool(false));

        // Test 3: Contribute to campaign
        block = chain.mineBlock([
            Tx.contractCall("crowdfund", "contribute-advanced", [
                types.uint(1),
                types.uint(100000000) // 100 STX
            ], user2.address),
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result.expectOk(), types.uint(100000000));

        // Test 4: Verify contribution tracking
        let contribution = chain.callReadOnlyFn("crowdfund", "get-contribution", [
            types.uint(1),
            types.principal(user2.address)
        ], deployer.address);
        assertEquals(contribution.result, types.uint(100000000));

        // Test 5: Test analytics update
        let analytics = chain.callReadOnlyFn("crowdfund", "get-campaign-analytics", [types.uint(1)], deployer.address);
        let analyticsData = analytics.result.expectSome().expectTuple();
        assertEquals(analyticsData['unique-contributors'], types.uint(1));

        // Test 6: Test batch contributions
        block = chain.mineBlock([
            Tx.contractCall("crowdfund", "batch-contribute", [
                types.list([
                    types.tuple({
                        "campaign-id": types.uint(1),
                        "amount": types.uint(50000000) // 50 STX
                    })
                ])
            ], user3.address),
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result.expectOk(), types.uint(0));

        // Test 7: Verify updated campaign state
        campaign = chain.callReadOnlyFn("crowdfund", "get-campaign", [types.uint(1)], deployer.address);
        campaignData = campaign.result.expectSome().expectTuple();
        assertEquals(campaignData['raised'], types.uint(150000000)); // 150 STX total

        // Test 8: Test platform statistics
        let stats = chain.callReadOnlyFn("crowdfund", "get-platform-stats", [], deployer.address);
        let statsData = stats.result.expectTuple();
        assertEquals(statsData['total-campaigns'], types.uint(1));
        assertEquals(statsData['total-funds-raised'], types.uint(150000000));

        // Test 9: Test category statistics
        let categoryInfo = chain.callReadOnlyFn("crowdfund", "get-category-info", [types.ascii("technology")], deployer.address);
        let categoryData = categoryInfo.result.expectSome().expectTuple();
        assertEquals(categoryData['campaign-count'], types.uint(1));
        assertEquals(categoryData['total-raised'], types.uint(150000000));

        console.log("✅ All comprehensive crowdfunding tests passed!");
    },
});

Clarinet.test({
    name: "Test security and validation features",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const user1 = accounts.get("wallet_1")!;

        // Initialize categories
        chain.mineBlock([
            Tx.contractCall("crowdfund", "initialize-categories", [], deployer.address),
        ]);

        // Test invalid title (empty)
        let block = chain.mineBlock([
            Tx.contractCall("crowdfund", "create-campaign-advanced", [
                types.ascii(""),
                types.ascii("Valid description here"),
                types.uint(1000000000),
                types.uint(14400),
                types.ascii("technology"),
                types.ascii("test")
            ], user1.address),
        ]);
        
        assertEquals(block.receipts[0].result.expectErr(), types.uint(130)); // err-invalid-title

        // Test invalid goal (too low)
        block = chain.mineBlock([
            Tx.contractCall("crowdfund", "create-campaign-advanced", [
                types.ascii("Valid Title"),
                types.ascii("Valid description here"),
                types.uint(500000), // Less than minimum
                types.uint(14400),
                types.ascii("technology"),
                types.ascii("test")
            ], user1.address),
        ]);
        
        assertEquals(block.receipts[0].result.expectErr(), types.uint(132)); // err-invalid-goal

        // Test invalid category
        block = chain.mineBlock([
            Tx.contractCall("crowdfund", "create-campaign-advanced", [
                types.ascii("Valid Title"),
                types.ascii("Valid description here"),
                types.uint(1000000000),
                types.uint(14400),
                types.ascii("invalid-category"),
                types.ascii("test")
            ], user1.address),
        ]);
        
        assertEquals(block.receipts[0].result.expectErr(), types.uint(135)); // err-invalid-category

        console.log("✅ All security validation tests passed!");
    },
});

Clarinet.test({
    name: "Test KYC and administrative functions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const user1 = accounts.get("wallet_1")!;

        // Test KYC status update (owner only)
        let block = chain.mineBlock([
            Tx.contractCall("crowdfund", "update-kyc-status", [
                types.principal(user1.address),
                types.bool(true),
                types.uint(2) // Level 2 verification
            ], deployer.address),
        ]);
        
        assertEquals(block.receipts[0].result.expectOk(), true);

        // Verify KYC status
        let kycStatus = chain.callReadOnlyFn("crowdfund", "get-kyc-status", [types.principal(user1.address)], deployer.address);
        let kycData = kycStatus.result.expectSome().expectTuple();
        assertEquals(kycData['verified'], types.bool(true));
        assertEquals(kycData['verification-level'], types.uint(2));

        // Test non-owner trying to update KYC (should fail)
        block = chain.mineBlock([
            Tx.contractCall("crowdfund", "update-kyc-status", [
                types.principal(user1.address),
                types.bool(false),
                types.uint(1)
            ], user1.address),
        ]);
        
        assertEquals(block.receipts[0].result.expectErr(), types.uint(100)); // err-owner-only

        console.log("✅ All KYC and administrative tests passed!");
    },
});