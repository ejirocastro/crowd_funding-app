# Stacks Crowdfunding Smart Contract

## Contract Overview

This is a production-ready crowdfunding smart contract built on the Stacks blockchain, leveraging Bitcoin's security through Clarity smart contracts. The contract enables transparent, secure, and trustless crowdfunding campaigns with comprehensive features for creators, contributors, and platform administrators.

## Key Features

### Core Functionality
- **Goal-based Campaigns**: Set funding goals with automatic success/failure determination
- **Time-limited Campaigns**: Configurable duration with automatic expiration
- **Automatic Refunds**: Failed campaigns automatically enable contributor refunds
- **Platform Fees**: Configurable fee system with automatic collection
- **Withdrawal Delays**: Security feature to prevent immediate fund extraction

### Security Features
- **Input Validation**: Comprehensive parameter validation for all functions
- **Access Control**: Role-based permissions for administrative functions  
- **Emergency Controls**: Contract pause and emergency campaign cancellation
- **Reentrancy Protection**: Safe fund transfer patterns
- **Overflow Protection**: Safe arithmetic operations throughout

### Administrative Features
- **Fee Management**: Adjustable platform fees with maximum limits
- **Admin Permissions**: Granular permission system for different admin roles
- **Contract Pause**: Emergency pause functionality
- **Emergency Actions**: Campaign cancellation and fund recovery

## Contract Architecture

### Constants
- `MAX-CAMPAIGN-DURATION`: Maximum campaign duration (~1000 days)
- `MAX-PLATFORM-FEE`: Maximum platform fee (10%)
- `MIN-CONTRIBUTION`: Minimum contribution amount (1 STX)
- `DEFAULT-WITHDRAWAL-DELAY`: Default withdrawal delay (~1 day)

### Data Structures

#### Campaign Structure
```clarity
{
  title: (string-ascii 100),
  description: (string-ascii 500), 
  creator: principal,
  goal: uint,
  raised: uint,
  end-block: uint,
  created-block: uint,
  status: (string-ascii 20), ;; "active", "funded", "failed", "completed", "cancelled"
  withdrawal-ready-block: uint
}
```

#### Admin Permissions Structure
```clarity
{
  can-pause: bool,
  can-set-fees: bool, 
  can-emergency-withdraw: bool
}
```

## Public Functions

### Core Functions

#### `create-campaign`
Creates a new crowdfunding campaign.

**Parameters:**
- `title`: Campaign title (max 100 chars)
- `description`: Campaign description (max 500 chars)  
- `goal`: Funding goal in microSTX
- `duration`: Campaign duration in blocks

**Returns:** `(ok campaign-id)` on success

**Security Checks:**
- Contract must not be paused
- All parameters must be valid
- Goal must be >= minimum contribution
- Duration must be > 0 and <= maximum

#### `contribute`
Make a contribution to an active campaign.

**Parameters:**
- `campaign-id`: ID of the campaign to contribute to
- `amount`: Contribution amount in microSTX

**Returns:** `(ok total-contribution)` on success

**Security Checks:**
- Campaign must be active and not expired
- Amount must be >= minimum contribution
- Contributor cannot be campaign creator
- Platform fee is automatically deducted

#### `withdraw-funds`
Allows campaign creator to withdraw funds after successful completion.

**Parameters:**
- `campaign-id`: ID of the campaign

**Returns:** `(ok withdrawn-amount)` on success

**Security Checks:**
- Only campaign creator can withdraw
- Campaign must be funded and past withdrawal delay
- Campaign must have reached its goal
- Campaign must be past its end date

#### `claim-refund`
Allows contributors to claim refunds from failed campaigns.

**Parameters:**
- `campaign-id`: ID of the failed campaign

**Returns:** `(ok refund-amount)` on success

**Security Checks:**
- Campaign must be expired and unfunded
- Contributor must have made contributions
- Goal must not have been reached

### Administrative Functions

#### `set-platform-fee`
Updates the platform fee percentage.

**Parameters:**
- `new-fee`: New fee in basis points (e.g., 250 = 2.5%)

**Access:** Admin with fee permissions only

#### `pause-contract` / `unpause-contract`
Emergency pause/unpause of the entire contract.

**Access:** Admin with pause permissions only

#### `set-admin-permissions`
Grants admin permissions to a principal.

**Parameters:**
- `admin`: Principal to grant permissions to
- `can-pause`: Permission to pause contract
- `can-set-fees`: Permission to modify fees
- `can-emergency-withdraw`: Permission to cancel campaigns

**Access:** Contract owner only

## Read-Only Functions

### Query Functions
- `get-campaign(campaign-id)`: Get campaign details
- `get-campaign-stats()`: Get global platform statistics
- `get-contribution(campaign-id, contributor)`: Get specific contribution amount
- `get-user-campaigns(user)`: Get campaigns created by user
- `get-user-contributions(user)`: Get campaigns contributed to by user

### Status Check Functions  
- `is-campaign-active(campaign-id)`: Check if campaign accepts contributions
- `is-campaign-successful(campaign-id)`: Check if campaign reached its goal
- `can-withdraw-funds(campaign-id)`: Check if funds can be withdrawn
- `get-campaign-progress(campaign-id)`: Get funding progress percentage

### Platform Info Functions
- `get-platform-settings()`: Get current platform configuration
- `get-campaign-contributors(campaign-id)`: Get list of contributors

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-OWNER-ONLY` | Function restricted to contract owner |
| 101 | `ERR-NOT-FOUND` | Campaign or resource not found |
| 102 | `ERR-CAMPAIGN-ENDED` | Campaign has expired |
| 103 | `ERR-CAMPAIGN-NOT-ENDED` | Campaign still active |
| 104 | `ERR-GOAL-REACHED` | Campaign goal already reached |
| 105 | `ERR-GOAL-NOT-REACHED` | Campaign goal not reached |
| 106 | `ERR-INSUFFICIENT-FUNDS` | Insufficient balance or contribution |
| 107 | `ERR-INVALID-AMOUNT` | Amount is invalid or too small |
| 108 | `ERR-UNAUTHORIZED` | Caller not authorized for action |
| 109 | `ERR-CAMPAIGN-ACTIVE` | Campaign still accepting contributions |
| 110 | `ERR-INVALID-DURATION` | Campaign duration invalid |
| 111 | `ERR-INVALID-PARAMETERS` | One or more parameters invalid |
| 112 | `ERR-ALREADY-EXISTS` | Resource already exists |
| 113 | `ERR-WITHDRAWAL-NOT-READY` | Withdrawal delay not passed |
| 114 | `ERR-INVALID-STATUS` | Campaign in wrong status for operation |
| 115 | `ERR-FEE-TOO-HIGH` | Requested fee exceeds maximum |

## Events

The contract emits events for all major actions:

- `campaign-created`: New campaign created
- `contribution-made`: Contribution received  
- `funds-withdrawn`: Creator withdrew funds
- `refund-claimed`: Contributor claimed refund
- `platform-fee-updated`: Platform fee changed
- `contract-paused`/`contract-unpaused`: Contract state changed
- `admin-permissions-set`: Admin permissions granted
- `campaign-emergency-cancelled`: Campaign cancelled by admin

## Security Considerations

### Input Validation
All public functions validate inputs before execution:
- String lengths within bounds
- Numeric values within reasonable ranges
- Principal addresses properly formatted

### Access Control  
Three-tier permission system:
1. **Contract Owner**: Full control over platform
2. **Admins**: Specific permissions for operations
3. **Users**: Standard campaign and contribution functions

### Fund Safety
- All STX transfers use safe patterns with error handling
- Platform fees automatically sent to designated recipient
- Withdrawal delays prevent immediate fund extraction
- Emergency pause prevents all operations when needed

### Reentrancy Protection
- All external calls (STX transfers) happen after state updates
- Use of `try!` ensures proper error handling and rollback

## Usage Examples

### Creating a Campaign
```clarity
(contract-call? .crowdfund create-campaign 
  "My Project" 
  "Building something amazing"
  u1000000000  ;; 1000 STX goal
  u1440        ;; ~10 days duration
)
```

### Contributing to a Campaign  
```clarity
(contract-call? .crowdfund contribute 
  u1           ;; campaign ID 
  u100000000   ;; 100 STX contribution
)
```

### Withdrawing Funds (Creator)
```clarity
(contract-call? .crowdfund withdraw-funds u1) ;; campaign ID
```

### Claiming Refund (Contributor)
```clarity  
(contract-call? .crowdfund claim-refund u1) ;; campaign ID
```

## Testing

The contract includes comprehensive validation and should be tested with:
1. Campaign lifecycle testing (create -> contribute -> withdraw/refund)
2. Edge case testing (boundary values, timing, permissions)
3. Security testing (reentrancy, overflow, access control)
4. Fee calculation testing
5. Admin function testing

## Deployment

1. Ensure Clarinet environment is set up
2. Run `clarinet check` to validate contract
3. Deploy to desired network using `clarinet deploy`
4. Set initial platform parameters via admin functions
5. Grant admin permissions as needed

## License

MIT License - see LICENSE file for details.