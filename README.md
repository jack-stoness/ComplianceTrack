# ComplianceTrack

ComplianceTrack is a comprehensive supply chain tracking smart contract built on the Stacks blockchain for regulatory compliance verification across industries. It provides an immutable audit trail for products from manufacturing to delivery, ensuring transparency and regulatory compliance throughout the supply chain.

## Features

- **Product Registration**: Register and manage products with detailed metadata
- **Batch Tracking**: Create and track product batches through the entire supply chain
- **Ownership Transfer**: Secure transfer of batch ownership between supply chain participants
- **Status Management**: Real-time status updates (manufactured, in-transit, delivered, recalled)
- **Compliance Verification**: Record and verify regulatory compliance with various standards
- **Authorized Verifiers**: Manage a network of certified compliance verifiers
- **Audit Trail**: Immutable supply chain event logging for complete traceability
- **Recall Management**: Emergency recall functionality for product safety

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Contract Version**: 1.0.0

### Data Structures

- **Products**: Core product information and manufacturer details
- **Batches**: Product batches with quantity, location, and status tracking
- **Compliance Records**: Regulatory compliance verification records
- **Supply Chain Events**: Immutable audit trail of all supply chain activities
- **Authorized Verifiers**: Network of certified compliance verification entities

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- Node.js (for development dependencies)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd ComplianceTrack
```

2. Navigate to the contract directory:
```bash
cd ComplianceTrack_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
clarinet test
```

## Usage Examples

### Register a Product

```clarity
(contract-call? .ComplianceTrack register-product "Pharmaceutical Product A" "pharmaceuticals")
```

### Create a Batch

```clarity
(contract-call? .ComplianceTrack create-batch u1 u1000 "Manufacturing Facility - Location A")
```

### Transfer Batch Ownership

```clarity
(contract-call? .ComplianceTrack transfer-batch u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "Distribution Center B")
```

### Record Compliance Verification

```clarity
(contract-call? .ComplianceTrack record-compliance
  u1
  "FDA-GMP"
  true
  (some u52560)
  "cert-hash-abc123"
  "Passed all FDA Good Manufacturing Practice requirements")
```

## Contract Functions Documentation

### Public Functions

#### register-product
```clarity
(register-product (name (string-ascii 100)) (category (string-ascii 50))) -> (response uint uint)
```
Registers a new product in the system. Only contract owner can register products.

**Parameters:**
- `name`: Product name (max 100 characters)
- `category`: Product category (max 50 characters)

**Returns:** Product ID on success

#### create-batch
```clarity
(create-batch (product-id uint) (quantity uint) (location (string-ascii 100))) -> (response uint uint)
```
Creates a new batch for an existing product. Only the product manufacturer can create batches.

**Parameters:**
- `product-id`: ID of the registered product
- `quantity`: Number of units in the batch
- `location`: Current location of the batch

**Returns:** Batch ID on success

#### transfer-batch
```clarity
(transfer-batch (batch-id uint) (new-owner principal) (new-location (string-ascii 100))) -> (response bool uint)
```
Transfers ownership of a batch to a new party in the supply chain.

**Parameters:**
- `batch-id`: ID of the batch to transfer
- `new-owner`: Principal address of the new owner
- `new-location`: New location of the batch

#### update-batch-status
```clarity
(update-batch-status (batch-id uint) (new-status (string-ascii 20)) (location (string-ascii 100))) -> (response bool uint)
```
Updates the status of a batch. Valid statuses: "manufactured", "in-transit", "delivered", "recalled".

#### authorize-verifier
```clarity
(authorize-verifier (verifier principal) (name (string-ascii 100)) (certification-type (string-ascii 50))) -> (response bool uint)
```
Authorizes a new compliance verifier. Only contract owner can authorize verifiers.

#### record-compliance
```clarity
(record-compliance (batch-id uint) (standard (string-ascii 50)) (is-compliant bool) (expiry-date (optional uint)) (certificate-hash (string-ascii 64)) (notes (string-ascii 200))) -> (response bool uint)
```
Records a compliance verification result. Only authorized verifiers can record compliance.

#### recall-batch
```clarity
(recall-batch (batch-id uint) (reason (string-ascii 200))) -> (response bool uint)
```
Initiates a recall for a batch. Only contract owner or product manufacturer can initiate recalls.

### Read-Only Functions

#### get-product
```clarity
(get-product (product-id uint)) -> (optional {...})
```
Retrieves product information by ID.

#### get-batch
```clarity
(get-batch (batch-id uint)) -> (optional {...})
```
Retrieves batch information by ID.

#### get-compliance-record
```clarity
(get-compliance-record (batch-id uint) (standard (string-ascii 50))) -> (optional {...})
```
Retrieves compliance record for a specific batch and standard.

#### is-batch-compliant
```clarity
(is-batch-compliant (batch-id uint) (standard (string-ascii 50))) -> bool
```
Checks if a batch is currently compliant with a specific standard, considering expiry dates.

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
(contract-call? .ComplianceTrack register-product "Test Product" "test-category")
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments apply --network testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy using Clarinet:
```bash
clarinet deployments apply --network mainnet
```

## Security Notes

### Access Control
- **Contract Owner**: Can register products, authorize verifiers, and initiate recalls
- **Product Manufacturers**: Can create batches for their products and initiate recalls
- **Batch Owners**: Can transfer ownership and update batch status
- **Authorized Verifiers**: Can record compliance verification results

### Security Considerations

1. **Immutable Audit Trail**: All supply chain events are permanently recorded and cannot be modified
2. **Authorization Checks**: All functions include proper authorization checks to prevent unauthorized access
3. **Input Validation**: Status updates are validated against predefined allowed values
4. **Expiry Validation**: Compliance records include expiry date validation for time-sensitive certifications

### Error Codes

- `u100`: Owner-only function called by non-owner
- `u101`: Resource not found
- `u102`: Resource already exists
- `u103`: Unauthorized access attempt
- `u104`: Invalid status value
- `u105`: Invalid compliance data

## Smart Contract Architecture

The contract uses a modular approach with separate data maps for different entities:

- **products**: Core product registry
- **batches**: Batch tracking and ownership
- **compliance-records**: Regulatory compliance verification
- **supply-chain-events**: Immutable audit trail
- **authorized-verifiers**: Compliance verifier network

This separation ensures data integrity while maintaining efficient query capabilities and scalability.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request with detailed description

## License

This project is licensed under the terms specified in the repository license file.