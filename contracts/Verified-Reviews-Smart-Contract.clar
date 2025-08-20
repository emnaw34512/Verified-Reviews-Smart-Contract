(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-REVIEW-EXISTS (err u101))
(define-constant ERR-INVALID-RATING (err u102))
(define-constant ERR-REVIEW-NOT-FOUND (err u103))
(define-constant ERR-INVALID-PRODUCT-ID (err u104))
(define-constant ERR-REVIEW-TOO-LONG (err u105))

(define-data-var next-review-id uint u1)
(define-data-var contract-paused bool false)

(define-map reviews 
    uint 
    {
        product-id: (string-ascii 64),
        reviewer: principal,
        rating: uint,
        review-text: (string-utf8 500),
        timestamp: uint,
        verified: bool
    }
)

(define-map user-reviews 
    {user: principal, product-id: (string-ascii 64)} 
    uint
)

(define-map product-stats
    (string-ascii 64)
    {
        total-reviews: uint,
        total-rating: uint,
        average-rating: uint
    }
)

(define-read-only (get-review (review-id uint))
    (map-get? reviews review-id)
)

(define-read-only (get-user-review (user principal) (product-id (string-ascii 64)))
    (match (map-get? user-reviews {user: user, product-id: product-id})
        review-id (map-get? reviews review-id)
        none
    )
)

(define-read-only (get-product-stats (product-id (string-ascii 64)))
    (map-get? product-stats product-id)
)

(define-read-only (get-next-review-id)
    (var-get next-review-id)
)

(define-read-only (is-contract-paused)
    (var-get contract-paused)
)

(define-read-only (get-total-reviews-by-user (user principal))
    (let ((current-id (var-get next-review-id)))
        (fold count-user-reviews (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) {user: user, count: u0, max-id: current-id})
    )
)

(define-private (count-user-reviews (id uint) (acc {user: principal, count: uint, max-id: uint}))
    (if (< id (get max-id acc))
        (match (map-get? reviews id)
            review (if (is-eq (get reviewer review) (get user acc))
                      {user: (get user acc), count: (+ (get count acc) u1), max-id: (get max-id acc)}
                      acc)
            acc)
        acc
    )
)

(define-public (submit-review 
    (product-id (string-ascii 64)) 
    (rating uint) 
    (review-text (string-utf8 500))
)
    (let (
        (current-id (var-get next-review-id))
        (reviewer tx-sender)
        (current-timestamp (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
        (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
        (asserts! (> (len product-id) u0) ERR-INVALID-PRODUCT-ID)
        (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
        (asserts! (<= (len review-text) u500) ERR-REVIEW-TOO-LONG)
        (asserts! (is-none (map-get? user-reviews {user: reviewer, product-id: product-id})) ERR-REVIEW-EXISTS)
        
        (map-set reviews current-id {
            product-id: product-id,
            reviewer: reviewer,
            rating: rating,
            review-text: review-text,
            timestamp: current-timestamp,
            verified: true
        })
        
        (map-set user-reviews {user: reviewer, product-id: product-id} current-id)
        
        (update-product-stats product-id rating)
        
        (var-set next-review-id (+ current-id u1))
        (ok current-id)
    )
)

(define-public (update-review 
    (review-id uint) 
    (rating uint) 
    (review-text (string-utf8 500))
)
    (let ((review (unwrap! (map-get? reviews review-id) ERR-REVIEW-NOT-FOUND)))
        (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq tx-sender (get reviewer review)) ERR-NOT-AUTHORIZED)
        (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
        (asserts! (<= (len review-text) u500) ERR-REVIEW-TOO-LONG)
        
        (let ((old-rating (get rating review))
              (product-id (get product-id review)))
            (map-set reviews review-id (merge review {
                rating: rating,
                review-text: review-text,
                timestamp: (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1)))
            }))
            
            (update-product-stats-on-change product-id old-rating rating)
            (ok true)
        )
    )
)

(define-private (update-product-stats (product-id (string-ascii 64)) (rating uint))
    (let ((current-stats (default-to {total-reviews: u0, total-rating: u0, average-rating: u0} 
                                   (map-get? product-stats product-id))))
        (let ((new-total-reviews (+ (get total-reviews current-stats) u1))
              (new-total-rating (+ (get total-rating current-stats) rating)))
            (map-set product-stats product-id {
                total-reviews: new-total-reviews,
                total-rating: new-total-rating,
                average-rating: (/ new-total-rating new-total-reviews)
            })
        )
    )
)

(define-private (update-product-stats-on-change (product-id (string-ascii 64)) (old-rating uint) (new-rating uint))
    (let ((current-stats (unwrap-panic (map-get? product-stats product-id))))
        (let ((new-total-rating (+ (- (get total-rating current-stats) old-rating) new-rating))
              (total-reviews (get total-reviews current-stats)))
            (map-set product-stats product-id {
                total-reviews: total-reviews,
                total-rating: new-total-rating,
                average-rating: (/ new-total-rating total-reviews)
            })
        )
    )
)

(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (var-set contract-paused (not (var-get contract-paused)))
        (ok (var-get contract-paused))
    )
)

(define-read-only (has-user-reviewed (user principal) (product-id (string-ascii 64)))
    (is-some (map-get? user-reviews {user: user, product-id: product-id}))
)

(define-read-only (get-reviews-by-product (product-id (string-ascii 64)) (limit uint))
    (let ((current-id (var-get next-review-id)))
        (fold filter-product-reviews 
              (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
              {product-id: product-id, reviews: (list), count: u0, limit: limit, max-id: current-id})
    )
)

(define-private (filter-product-reviews 
    (id uint) 
    (acc {product-id: (string-ascii 64), reviews: (list 20 uint), count: uint, limit: uint, max-id: uint})
)
    (if (and (< (get count acc) (get limit acc)) (< id (get max-id acc)))
        (match (map-get? reviews id)
            review (if (is-eq (get product-id review) (get product-id acc))
                      {
                          product-id: (get product-id acc),
                          reviews: (unwrap-panic (as-max-len? (append (get reviews acc) id) u20)),
                          count: (+ (get count acc) u1),
                          limit: (get limit acc),
                          max-id: (get max-id acc)
                      }
                      acc)
            acc)
        acc
    )
)
