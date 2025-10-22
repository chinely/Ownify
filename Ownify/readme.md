# Real Estate Property Registry Smart Contract

A Clarity smart contract for managing real estate property records on the Stacks blockchain with ownership tracking and access control.

## Overview

This smart contract provides a decentralized property registry system where landlords can register, manage, and transfer property ownership while controlling viewing access for inspectors or other authorized parties.

## Features

- **Property Registration**: Register new properties with address and valuation
- **Property Management**: Update property details (address, valuation)
- **Ownership Transfer**: Transfer property ownership to another principal
- **Access Control**: Grant or revoke viewing rights to inspectors
- **Property Delisting**: Remove properties from the registry
- **Read-only Queries**: Retrieve property data and total property count

## Constants

- `registry-admin`: Contract deployer address
- Error codes:
  - `err-admin-privilege` (u100): Admin privilege required
  - `err-property-not-found` (u101): Property does not exist
  - `err-property-exists` (u102): Property already exists
  - `err-invalid-address` (u103): Invalid address format
  - `err-invalid-valuation` (u104): Invalid valuation amount
  - `err-access-denied` (u105): Access denied (not landlord)

## Data Structures

### Property Record
```clarity
{
  landlord: principal,           // Property owner
  address: (string-ascii 64),    // Property address
  valuation: uint,               // Property value
  registered-at: uint,           // Block height at registration
  viewing-rights: {              // Inspector access control
    inspector: principal,
    authorized: bool
  }
}
```

## Public Functions

### `register-property`
Register a new property in the registry.

**Parameters:**
- `address` (string-ascii 64): Property address (1-64 characters)
- `valuation` (uint): Property value (1 to 999,999,999)

**Returns:** `(ok uint)` - Property ID

**Validations:**
- Address must be between 1-64 characters
- Valuation must be between 1 and 999,999,999

### `amend-property`
Update property details (landlord only).

**Parameters:**
- `property-id` (uint): Property identifier
- `new-address` (string-ascii 64): Updated address
- `new-valuation` (uint): Updated valuation

**Returns:** `(ok true)`

**Access:** Landlord only

### `delist-property`
Remove a property from the registry (landlord only).

**Parameters:**
- `property-id` (uint): Property identifier

**Returns:** `(ok true)`

**Access:** Landlord only

### `transfer-deed`
Transfer property ownership to a new landlord.

**Parameters:**
- `property-id` (uint): Property identifier
- `new-landlord` (principal): New owner's address

**Returns:** `(ok true)`

**Access:** Current landlord only

### `grant-viewing-access`
Grant viewing rights to an inspector.

**Parameters:**
- `property-id` (uint): Property identifier
- `inspector` (principal): Inspector's address

**Returns:** `(ok true)`

**Access:** Landlord only

### `revoke-viewing-access`
Revoke viewing rights from an inspector.

**Parameters:**
- `property-id` (uint): Property identifier
- `inspector` (principal): Inspector's address

**Returns:** `(ok true)`

**Access:** Landlord only

## Read-only Functions

### `get-property-count`
Get the total number of registered properties.

**Returns:** `(ok uint)` - Total property count

### `get-property-data`
Retrieve complete property information.

**Parameters:**
- `property-id` (uint): Property identifier

**Returns:** `(ok { landlord, address, valuation, registered-at, viewing-rights })`

## Usage Example

```clarity
;; Register a new property
(contract-call? .property-registry register-property "123 Main St, Lagos" u50000000)
;; Returns: (ok u1)

;; Update property details
(contract-call? .property-registry amend-property u1 "123 Main Street, Lagos" u55000000)

;; Grant viewing access to an inspector
(contract-call? .property-registry grant-viewing-access u1 'ST1INSPECTOR...)

;; Transfer ownership
(contract-call? .property-registry transfer-deed u1 'ST1NEWOWNER...)

;; Get property data
(contract-call? .property-registry get-property-data u1)

;; Get total properties
(contract-call? .property-registry get-property-count)
```

## Security Considerations

- Only property landlords can modify, transfer, or delist their properties
- Only landlords can grant/revoke viewing access
- Property IDs are sequential and immutable
- All state changes are recorded on the blockchain
- Valuation limits prevent overflow attacks

## Deployment

Deploy this contract to the Stacks blockchain using Clarinet or the Stacks CLI:

```bash
clarinet deploy
```

## Testing

Test the contract using Clarinet:

```bash
clarinet test
```
