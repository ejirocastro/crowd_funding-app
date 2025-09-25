# 📖 Crowdfunding Platform API Documentation

## Table of Contents
- [Overview](#overview)
- [Public Functions](#public-functions)
- [Read-Only Functions](#read-only-functions)
- [Error Codes](#error-codes)
- [Data Structures](#data-structures)
- [Usage Examples](#usage-examples)

## Overview

The Stacks Crowdfunding Platform provides a comprehensive API for creating and managing decentralized crowdfunding campaigns with advanced security, analytics, and governance features.

## Public Functions

### Campaign Management

#### `create-campaign-advanced`
Creates a new crowdfunding campaign with advanced features.

**Parameters:**
- `title` (string-ascii 100): Campaign title
- `description` (string-ascii 500): Detailed campaign description
- `goal` (uint): Funding goal in microSTX (1 STX = 1,000,000 microSTX)
- `duration` (uint): Campaign duration in blocks
- `category` (string-ascii 50): Campaign category (must be pre-registered)
- `tags` (string-ascii 200): Comma-separated tags for discovery

**Returns:** `(response uint uint)` - Campaign ID on success

**Validation:**
- Title: 1-100 characters, valid ASCII
- Description: 10-500 characters minimum meaningful content
- Goal: Between 1,000,000 (1 STX) and 1,000,000,000,000 (1M STX)
- Duration: Between 144 (1 day) and 144,000 blocks (~1000 days)
- Category: Must exist and be active
- Rate limiting: Max 5 campaigns per block per user

**Example:**
```clarity
(contract-call? .crowdfund create-campaign-advanced
    "Revolutionary AI Platform"
    "Building the future of artificial intelligence with ethical guidelines and transparency"
    u1000000000 ;; 1000 STX goal
    u14400      ;; 100 days duration
    "technology"
    "AI,blockchain,ethics,innovation")
```

#### `contribute-advanced`
Make a contribution to an active campaign with analytics tracking.

**Parameters:**
- `campaign-id` (uint): Target campaign ID
- `amount` (uint): Contribution amount in microSTX

**Returns:** `(response uint uint)` - Contribution amount on success

**Validation:**
- Campaign must exist and be active
- Amount must be greater than 0
- Contributor cannot be campaign creator
- Rate limiting: Max 50 contributions per block per user

**Side Effects:**
- Updates campaign raised amount
- Tracks contributor analytics
- Updates category statistics
- Records contribution velocity

#### `batch-contribute`
Execute multiple contributions in a single transaction for efficiency.

**Parameters:**
- `campaign-amounts` (list 10 {campaign-id: uint, amount: uint}): List of contributions

**Returns:** `(response uint uint)` - Success indicator

**Benefits:**
- Single STX transfer for all contributions
- Reduced transaction fees
- Atomic operation (all or nothing)

### Administrative Functions

#### `initialize-categories`
Initialize default campaign categories (owner only).

**Categories Created:**
- technology
- art
- health
- education
- environment
- social

**Returns:** `(response bool uint)`

#### `update-kyc-status`
Update KYC verification status for a user (owner only).

**Parameters:**
- `user` (principal): Target user address
- `verified` (bool): Verification status
- `level` (uint): Verification level (1-5)

**Returns:** `(response bool uint)`

### Governance Functions

#### `create-governance-proposal`
Create a new governance proposal for community voting.

**Parameters:**
- `title` (string-ascii 100): Proposal title
- `description` (string-ascii 500): Detailed description
- `proposal-type` (string-ascii 50): Type (fee-change, delay-change, etc.)
- `target-value` (uint): New value to be set
- `voting-period` (uint): Voting duration in blocks (max 14,400)

**Requirements:**
- Minimum voting power required
- Governance must be enabled

#### `vote-on-proposal`
Cast a vote on an active governance proposal.

**Parameters:**
- `proposal-id` (uint): Proposal to vote on
- `vote` (bool): true for yes, false for no

**Requirements:**
- Must have voting power
- Cannot vote twice on same proposal
- Voting period must be active

## Read-Only Functions

### Campaign Information

#### `get-campaign`
Retrieve complete campaign information.

**Parameters:**
- `campaign-id` (uint): Campaign ID

**Returns:** `(optional campaign-data)`

#### `get-campaign-analytics`
Get detailed analytics for a campaign.

**Parameters:**
- `campaign-id` (uint): Campaign ID

**Returns:** `(optional analytics-data)`

**Analytics Included:**
- Unique contributors count
- Average contribution amount
- Contribution velocity
- Social signals score

#### `is-campaign-active`
Check if a campaign is currently accepting contributions.

**Parameters:**
- `campaign-id` (uint): Campaign ID

**Returns:** `bool`

### User Information

#### `get-user-campaigns`
Get list of campaigns created by a user.

**Parameters:**
- `user` (principal): User address

**Returns:** `(list 100 uint)` - List of campaign IDs

#### `get-user-contributions`
Get list of campaigns user has contributed to.

**Parameters:**
- `user` (principal): User address

**Returns:** `(list 100 uint)` - List of campaign IDs

#### `get-contribution`
Get contribution amount for specific user and campaign.

**Parameters:**
- `campaign-id` (uint): Campaign ID
- `contributor` (principal): Contributor address

**Returns:** `uint` - Contribution amount

#### `get-kyc-status`
Get KYC verification status for a user.

**Parameters:**
- `user` (principal): User address

**Returns:** `(optional kyc-data)`

### Platform Statistics

#### `get-platform-stats`
Get comprehensive platform statistics.

**Returns:** Platform statistics tuple containing:
- `total-campaigns`: Total campaigns created
- `successful-campaigns`: Successfully funded campaigns
- `failed-campaigns`: Failed campaigns
- `total-funds-raised`: Total STX raised platform-wide
- `contract-paused`: Platform pause status
- `platform-version`: Current contract version

#### `get-category-info`
Get information about a campaign category.

**Parameters:**
- `category` (string-ascii 50): Category name

**Returns:** `(optional category-data)` containing:
- `active`: Category status
- `campaign-count`: Number of campaigns
- `total-raised`: Total funds raised in category

### Governance Information

#### `get-governance-proposal`
Get details of a governance proposal.

**Parameters:**
- `proposal-id` (uint): Proposal ID

**Returns:** `(optional proposal-data)`

#### `get-user-voting-power`
Get voting power for a user.

**Parameters:**
- `user` (principal): User address

**Returns:** `uint` - Voting power amount

#### `is-governance-enabled`
Check if governance features are active.

**Returns:** `bool`

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `err-owner-only` | Function restricted to contract owner |
| 101 | `err-not-found` | Requested resource not found |
| 102 | `err-campaign-ended` | Campaign has ended |
| 103 | `err-campaign-not-ended` | Campaign still active |
| 104 | `err-goal-reached` | Campaign goal already reached |
| 105 | `err-goal-not-reached` | Campaign goal not reached |
| 106 | `err-insufficient-funds` | Insufficient funds for operation |
| 107 | `err-invalid-amount` | Invalid amount specified |
| 108 | `err-unauthorized` | Unauthorized access attempt |
| 109 | `err-campaign-active` | Campaign is still active |
| 110 | `err-invalid-duration` | Invalid campaign duration |
| 130 | `err-invalid-title` | Invalid campaign title |
| 131 | `err-invalid-description` | Invalid campaign description |
| 132 | `err-invalid-goal` | Invalid funding goal |
| 133 | `err-rate-limit-exceeded` | Rate limit exceeded |
| 134 | `err-contract-paused` | Contract is paused |
| 135 | `err-invalid-category` | Invalid campaign category |
| 136 | `err-kyc-required` | KYC verification required |

## Data Structures

### Campaign Data
```clarity
{
    title: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    goal: uint,
    raised: uint,
    end-block: uint,
    created-block: uint,
    status: (string-ascii 20),
    extensions-used: uint,
    max-extensions: uint,
    withdrawal-ready-block: uint,
    has-milestones: bool,
    category: (string-ascii 50),
    tags: (string-ascii 200),
    kyc-verified: bool,
    risk-level: uint,
    featured: bool,
}
```

### Analytics Data
```clarity
{
    unique-contributors: uint,
    average-contribution: uint,
    contribution-velocity: uint,
    social-signals: uint,
}
```

### KYC Data
```clarity
{
    verified: bool,
    verification-block: uint,
    verification-level: uint,
}
```

### Category Data
```clarity
{
    active: bool,
    campaign-count: uint,
    total-raised: uint,
}
```

## Usage Examples

### Complete Campaign Lifecycle

```clarity
;; 1. Initialize platform (owner only)
(contract-call? .crowdfund initialize-categories)

;; 2. Create campaign
(contract-call? .crowdfund create-campaign-advanced
    "Eco-Friendly Water Purifier"
    "Developing affordable water purification technology for developing regions"
    u500000000  ;; 500 STX goal
    u7200       ;; 50 days
    "environment"
    "water,sustainability,health")

;; 3. Contribute to campaign
(contract-call? .crowdfund contribute-advanced
    u1          ;; campaign-id
    u50000000)  ;; 50 STX contribution

;; 4. Check campaign progress
(contract-call? .crowdfund get-campaign u1)
(contract-call? .crowdfund get-campaign-analytics u1)

;; 5. Batch contributions
(contract-call? .crowdfund batch-contribute
    (list 
        {campaign-id: u1, amount: u25000000}
        {campaign-id: u1, amount: u25000000}))

;; 6. Withdraw funds (creator only, after campaign ends and goal reached)
(contract-call? .crowdfund withdraw-funds u1)
```

### Governance Participation

```clarity
;; 1. Create proposal to change platform fee
(contract-call? .crowdfund create-governance-proposal
    "Reduce Platform Fee to 2%"
    "Community proposal to reduce platform fee from 2.5% to 2% to encourage more campaigns"
    "fee-change"
    u200        ;; 2% in basis points
    u1440)      ;; 10 day voting period

;; 2. Vote on proposal
(contract-call? .crowdfund vote-on-proposal
    u1          ;; proposal-id
    true)       ;; vote yes

;; 3. Execute proposal (after voting period ends)
(contract-call? .crowdfund execute-proposal u1)
```

### Analytics and Monitoring

```clarity
;; Platform overview
(contract-call? .crowdfund get-platform-stats)

;; Category performance
(contract-call? .crowdfund get-category-info "technology")
(contract-call? .crowdfund get-category-info "environment")

;; User activity
(contract-call? .crowdfund get-user-campaigns 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
(contract-call? .crowdfund get-user-contributions 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)

;; Campaign details
(contract-call? .crowdfund get-campaign u1)
(contract-call? .crowdfund get-campaign-analytics u1)
```

## Rate Limiting

The platform implements sophisticated rate limiting to prevent spam and ensure fair usage:

- **Campaign Creation**: Maximum 5 campaigns per block per user
- **Contributions**: Maximum 50 contributions per block per user
- **Governance Proposals**: Minimum voting power required

Rate limits reset each block and are tracked per user address.

## Security Features

1. **Input Validation**: All inputs are comprehensively validated
2. **Access Control**: Multi-level permission system
3. **Rate Limiting**: Prevents spam and DoS attacks
4. **Emergency Pause**: Circuit breaker functionality
5. **KYC Integration**: Optional identity verification
6. **Audit Trail**: All actions are recorded on-chain

---

*For additional support or questions, please refer to our [GitHub repository](https://github.com/...) or contact our development team.*