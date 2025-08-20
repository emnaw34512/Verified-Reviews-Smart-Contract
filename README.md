# ⭐ Verified Reviews Smart Contract

A blockchain-based review system that ensures authenticity by tying reviews to wallet addresses, preventing fake reviews and maintaining transparency.

## 🚀 Features

- **✅ Wallet-verified Reviews**: Each review is tied to a unique wallet address
- **🔒 Duplicate Prevention**: One review per wallet per product
- **📊 Rating System**: 1-5 star rating system with automatic averaging
- **📝 Review Updates**: Users can update their existing reviews
- **📈 Product Statistics**: Automatic calculation of average ratings and review counts
- **⏸️ Admin Controls**: Contract owner can pause operations if needed
- **🔍 Query Functions**: Multiple ways to retrieve review data

## 📋 Contract Functions

### Public Functions

#### `submit-review`
Submit a new review for a product.
```clarity
(submit-review "product-123" u5 u"Amazing product, highly recommended!")
```
- **product-id**: String identifier for the product (max 64 characters)
- **rating**: Integer from 1-5
- **review-text**: Review content (max 500 characters)

#### `update-review`
Update an existing review (only by the original reviewer).
```clarity
(update-review u1 u4 u"Updated review text")
```
- **review-id**: ID of the review to update
- **rating**: New rating (1-5)
- **review-text**: New review content

#### `toggle-contract-pause`
Pause/unpause the contract (owner only).
```clarity
(toggle-contract-pause)
```

### Read-Only Functions

#### `get-review`
Get a specific review by ID.
```clarity
(get-review u1)
```

#### `get-user-review`
Get a user's review for a specific product.
```clarity
(get-user-review 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE "product-123")
```

#### `get-product-stats`
Get statistics for a product (total reviews, average rating).
```clarity
(get-product-stats "product-123")
```

#### `has-user-reviewed`
Check if a user has reviewed a specific product.
```clarity
(has-user-reviewed 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE "product-123")
```

#### `get-reviews-by-product`
Get reviews for a product (limited results).
```clarity
(get-reviews-by-product "product-123" u10)
```

## 🛠️ Setup & Deployment

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation
1. Clone the repository
2. Navigate to the project directory
3. Run tests: `clarinet test`
4. Deploy: `clarinet deploy`

### Testing
```bash
clarinet test
```

### Local Development
```bash
clarinet console
```

## 📊 Data Structures

### Review Structure
```clarity
{
    product-id: (string-ascii 64),
    reviewer: principal,
    rating: uint,
    review-text: (string-utf8 500),
    timestamp: uint,
    verified: bool
}
```

### Product Stats Structure
```clarity
{
    total-reviews: uint,
    total-rating: uint,
    average-rating: uint
}
```

## 🔧 Error Codes

- `u100`: Not authorized
- `u101`: Review already exists
- `u102`: Invalid rating (must be 1-5)
- `u103`: Review not found
- `u104`: Invalid product ID
- `u105`: Review text too long

## 🎯 Use Cases

- **🛍️ E-commerce**: Product reviews on marketplaces
- **🏨 Services**: Restaurant, hotel, and service reviews
- **📱 Apps**: App store reviews with verified users
- **🎮 Gaming**: Game reviews and ratings
- **🎓 Education**: Course and instructor reviews

## 🔐 Security Features

- **Wallet Authentication**: Reviews are cryptographically tied to wallet addresses
- **Anti-spam**: One review per wallet per product prevents review bombing
- **Immutable History**: All reviews are stored on-chain for transparency
- **Owner Controls**: Contract can be paused in emergencies

## 📝 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

---

Built with ❤️ on Stacks blockchain
