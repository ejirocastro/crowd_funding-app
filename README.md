# Stacks Crowdfunding Platform

[![Stacks Blockchain](https://img.shields.io/badge/Stacks-Blockchain-purple)](https://stacks.co/)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contracts-orange)](https://clarity-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](https://github.com/stacks-network/crowdfunding-platform)

## Overview

A **production-ready** decentralized crowdfunding platform built on the Stacks blockchain, leveraging Bitcoin's security through Clarity smart contracts. This secure, audited platform enables transparent, trustless crowdfunding campaigns with comprehensive features for creators, contributors, and administrators.

### 🚀 Key Features

#### Core Functionality
- **Goal-Based Campaigns** - Set funding targets with automatic success/failure determination
- **Automatic Refunds** - Failed campaigns enable automatic contributor refunds
- **Platform Fees** - Configurable fee system with transparent collection
- **Withdrawal Delays** - Security feature preventing immediate fund extraction
- **Time-Limited Campaigns** - Configurable duration with automatic expiration

#### Security & Admin Features  
- **Role-Based Access Control** - Granular permissions for different admin functions
- **Emergency Controls** - Contract pause and emergency campaign cancellation
- **Input Validation** - Comprehensive parameter validation and security checks
- **Reentrancy Protection** - Safe fund transfer patterns throughout
- **Bitcoin Security** - Built on Stacks, inheriting Bitcoin's security model

## Architecture

### Technology Stack

- **Blockchain**: Stacks 3.0+ (Bitcoin Layer-2)
- **Smart Contracts**: Clarity Language
- **Development Framework**: Clarinet
- **Testing**: Vitest with Clarinet SDK
- **Runtime**: Node.js with TypeScript
- **Package Manager**: npm

### Project Structure

```
crowd_funding_app/
├── contracts/                 # Clarity smart contracts
├── tests/                     # Test suites
├── settings/                  # Network configurations
│   ├── Devnet.toml           # Development network settings
│   ├── Testnet.toml          # Test network configuration
│   └── Mainnet.toml          # Production network settings
├── Clarinet.toml             # Clarinet project configuration
├── package.json              # Node.js dependencies and scripts
├── tsconfig.json             # TypeScript configuration
└── vitest.config.js          # Testing configuration
```

## Prerequisites

### System Requirements

- **Node.js** >= 18.0.0
- **npm** >= 8.0.0
- **Clarinet** >= 3.0.0
- **Git** >= 2.30.0

### Development Tools

1. **Install Clarinet**
   ```bash
   # macOS
   brew install clarinet
   
   # Windows (via Chocolatey)
   choco install clarinet
   
   # Linux (via curl)
   curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar -xz
   ```

2. **Verify Installation**
   ```bash
   clarinet --version
   node --version
   npm --version
   ```

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/crowd_funding_app.git
cd crowd_funding_app
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Initialize Development Environment
```bash
# Start local Stacks devnet
clarinet devnet start
```

## Configuration

### Network Settings

The application supports three deployment environments:

#### Development (Devnet)
- **File**: `settings/Devnet.toml`
- **Purpose**: Local development and testing
- **Features**: Pre-funded test accounts, fast block times
- **STX Balance**: 100,000,000 STX per account
- **Bitcoin Balance**: 1,000 sBTC per account

#### Testnet
- **File**: `settings/Testnet.toml`
- **Purpose**: Pre-production testing
- **Network**: Stacks Testnet
- **Faucet**: Available for test STX tokens

#### Mainnet
- **File**: `settings/Mainnet.toml`
- **Purpose**: Production deployment
- **Network**: Stacks Mainnet
- **Security**: Enhanced validation and monitoring

### Environment Variables

Create a `.env` file in the project root:

```env
# Network Configuration
NETWORK=devnet
STX_NETWORK=http://localhost:3999

# API Configuration
API_PORT=3000
API_HOST=localhost

# Security
ENABLE_CORS=true
JWT_SECRET=your-jwt-secret-here

# Monitoring
LOG_LEVEL=info
ENABLE_METRICS=true
```

## Development

### Available Scripts

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch for changes and run tests automatically
npm run test:watch

# Start development server
clarinet devnet start

# Deploy contracts to devnet
clarinet deploy --devnet

# Check contract syntax
clarinet check

# Generate contract documentation
clarinet docs
```

### Development Workflow

1. **Start Development Environment**
   ```bash
   clarinet devnet start
   ```

2. **Create Smart Contracts**
   ```bash
   # Add new contract
   clarinet contract new my-contract
   ```

3. **Write Tests**
   ```typescript
   // tests/my-contract.test.ts
   import { describe, expect, it } from "vitest";
   
   describe("My Contract", () => {
     it("should initialize correctly", () => {
       // Test implementation
     });
   });
   ```

4. **Run Tests**
   ```bash
   npm test
   ```

### Code Quality Standards

- **TypeScript**: Strict type checking enabled
- **ESLint**: Code linting and formatting
- **Test Coverage**: Minimum 80% coverage required
- **Documentation**: Comprehensive inline documentation
- **Security**: Regular security audits and best practices

## Testing

### Test Suite Overview

The application includes comprehensive test coverage:

- **Unit Tests**: Individual function and contract testing
- **Integration Tests**: Multi-contract interaction testing
- **End-to-End Tests**: Complete user journey testing
- **Performance Tests**: Gas cost and execution time analysis

### Running Tests

```bash
# Run all tests
npm test

# Run with detailed reporting
npm run test:report

# Run specific test file
npx vitest run tests/specific-test.test.ts

# Run tests in watch mode
npm run test:watch
```

### Test Configuration

Tests are configured in `vitest.config.js` with:
- **Environment**: Clarinet simulated blockchain
- **Custom Matchers**: Clarity-specific assertions
- **Coverage Reporting**: Detailed code coverage analysis
- **Cost Analysis**: Smart contract execution cost tracking

## Deployment

### Development Deployment

1. **Start Devnet**
   ```bash
   clarinet devnet start
   ```

2. **Deploy Contracts**
   ```bash
   clarinet deploy --devnet
   ```

3. **Verify Deployment**
   ```bash
   clarinet console
   ```

### Testnet Deployment

1. **Configure Testnet Settings**
   ```bash
   # Edit settings/Testnet.toml with your testnet configuration
   ```

2. **Deploy to Testnet**
   ```bash
   clarinet deploy --testnet
   ```

3. **Monitor Deployment**
   ```bash
   # Use Stacks Explorer to verify contract deployment
   ```

### Mainnet Deployment

1. **Security Review**
   - Complete security audit
   - Peer code review
   - Penetration testing

2. **Configuration**
   ```bash
   # Update settings/Mainnet.toml with production settings
   ```

3. **Deploy**
   ```bash
   clarinet deploy --mainnet
   ```

4. **Post-Deployment**
   - Monitor contract performance
   - Set up alerting and monitoring
   - Document contract addresses

## API Reference

### Smart Contract Functions

#### Campaign Management
- `create-campaign(title, description, goal, deadline)`
- `contribute(campaign-id, amount)`
- `withdraw-funds(campaign-id)`
- `refund-contribution(campaign-id)`

#### Campaign Queries
- `get-campaign(campaign-id)`
- `get-campaign-balance(campaign-id)`
- `get-contributor-info(campaign-id, contributor)`
- `get-campaign-status(campaign-id)`

### Error Codes

| Code | Description |
|------|-------------|
| 100  | Campaign not found |
| 101  | Campaign deadline passed |
| 102  | Insufficient funds |
| 103  | Campaign already funded |
| 104  | Unauthorized access |
| 105  | Invalid parameters |

## Security

### Security Measures

- **Multi-Signature**: Enhanced security for fund management
- **Time Locks**: Campaign deadline enforcement
- **Access Control**: Role-based permissions
- **Input Validation**: Comprehensive parameter checking
- **Reentrancy Protection**: Safe external calls
- **Overflow Protection**: Safe arithmetic operations

### Best Practices

1. **Smart Contract Security**
   - Regular security audits
   - Formal verification when possible
   - Conservative gas limits
   - Comprehensive error handling

2. **Key Management**
   - Hardware wallet integration
   - Multi-signature setups
   - Regular key rotation
   - Secure key storage

3. **Monitoring**
   - Real-time transaction monitoring
   - Automated alerting
   - Performance metrics
   - Security event logging

## Monitoring & Analytics

### Performance Metrics

- **Transaction Throughput**: TPS monitoring
- **Gas Usage**: Cost optimization tracking
- **Response Times**: API performance metrics
- **Error Rates**: System reliability monitoring

### Business Metrics

- **Campaign Success Rate**: Funding achievement tracking
- **Total Volume**: Platform transaction volume
- **User Engagement**: Active user metrics
- **Platform Growth**: Adoption and usage trends

## Troubleshooting

### Common Issues

#### Contract Deployment Failures
```bash
# Check contract syntax
clarinet check

# Verify network connection
ping localhost

# Check account balances
clarinet console
```

#### Test Failures
```bash
# Run tests with verbose output
npm test -- --verbose

# Clear test cache
npx vitest run --no-cache

# Check TypeScript compilation
npx tsc --noEmit
```

#### Network Issues
```bash
# Reset devnet
clarinet devnet stop
clarinet devnet start

# Check network status
curl http://localhost:3999/v2/info
```

### Getting Help

- **Documentation**: [Stacks Documentation](https://docs.stacks.co/)
- **Community**: [Stacks Discord](https://discord.gg/stacks)
- **Issues**: [GitHub Issues](https://github.com/your-org/crowd_funding_app/issues)
- **Support**: support@your-organization.com

## Contributing

### Development Guidelines

1. **Fork the Repository**
2. **Create Feature Branch** (`git checkout -b feature/amazing-feature`)
3. **Write Tests** for new functionality
4. **Commit Changes** (`git commit -m 'Add amazing feature'`)
5. **Push to Branch** (`git push origin feature/amazing-feature`)
6. **Open Pull Request**

### Code Standards

- Follow TypeScript and Clarity style guides
- Maintain test coverage above 80%
- Include comprehensive documentation
- Use semantic commit messages
- Ensure all CI checks pass

## License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Stacks Foundation** for blockchain infrastructure
- **Hiro Systems** for development tools
- **Bitcoin Core** for underlying security
- **Open Source Community** for libraries and frameworks

---

## Quick Start

```bash
# Clone and setup
git clone https://github.com/your-org/crowd_funding_app.git
cd crowd_funding_app
npm install

# Start development
clarinet devnet start
npm test

# Deploy locally
clarinet deploy --devnet
```

For detailed documentation, visit our [Wiki](https://github.com/your-org/crowd_funding_app/wiki).