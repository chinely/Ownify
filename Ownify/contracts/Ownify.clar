;; Real Estate Property Registry Smart Contract
;; Track property listings with ownership and access control

;; Constants
(define-constant registry-admin tx-sender)
(define-constant err-admin-privilege (err u100))
(define-constant err-property-not-found (err u101))
(define-constant err-property-exists (err u102))
(define-constant err-invalid-address (err u103))
(define-constant err-invalid-valuation (err u104))
(define-constant err-access-denied (err u105))

;; Data variables
(define-data-var total-properties uint u0)

;; Map to store property records
(define-map property-records
  { property-id: uint }
  {
    landlord: principal,
    address: (string-ascii 64),
    valuation: uint,
    registered-at: uint,
    viewing-rights: { inspector: principal, authorized: bool }
  }
)

;; Private functions
(define-private (property-on-record (property-id uint))
  (is-some (map-get? property-records { property-id: property-id }))
)

;; Public functions
(define-public (register-property (address (string-ascii 64)) (valuation uint))
  (let
    (
      (property-id (+ (var-get total-properties) u1))
    )
    (asserts! (> (len address) u0) err-invalid-address)
    (asserts! (< (len address) u65) err-invalid-address)
    (asserts! (> valuation u0) err-invalid-valuation)
    (asserts! (< valuation u1000000000) err-invalid-valuation)
    
    (map-insert property-records
      { property-id: property-id }
      {
        landlord: tx-sender,
        address: address,
        valuation: valuation,
        registered-at: stacks-block-height,
        viewing-rights: { inspector: tx-sender, authorized: true }
      }
    )
    (var-set total-properties property-id)
    (ok property-id)
  )
)

(define-public (amend-property (property-id uint) (new-address (string-ascii 64)) (new-valuation uint))
  (let
    (
      (record (unwrap! (map-get? property-records { property-id: property-id }) err-property-not-found))
    )
    (asserts! (property-on-record property-id) err-property-not-found)
    (asserts! (is-eq (get landlord record) tx-sender) err-access-denied)
    (asserts! (> (len new-address) u0) err-invalid-address)
    (asserts! (< (len new-address) u65) err-invalid-address)
    (asserts! (> new-valuation u0) err-invalid-valuation)
    (asserts! (< new-valuation u1000000000) err-invalid-valuation)
    
    (map-set property-records
      { property-id: property-id }
      (merge record { address: new-address, valuation: new-valuation })
    )
    (ok true)
  )
)

(define-public (delist-property (property-id uint))
  (let
    (
      (record (unwrap! (map-get? property-records { property-id: property-id }) err-property-not-found))
    )
    (asserts! (property-on-record property-id) err-property-not-found)
    (asserts! (is-eq (get landlord record) tx-sender) err-access-denied)
    (map-delete property-records { property-id: property-id })
    (ok true)
  )
)

(define-public (transfer-deed (property-id uint) (new-landlord principal))
  (let
    (
      (record (unwrap! (map-get? property-records { property-id: property-id }) err-property-not-found))
    )
    (asserts! (property-on-record property-id) err-property-not-found)
    (asserts! (is-eq (get landlord record) tx-sender) err-access-denied)
    
    (map-set property-records
      { property-id: property-id }
      (merge record { landlord: new-landlord })
    )
    (ok true)
  )
)

(define-public (grant-viewing-access (property-id uint) (inspector principal))
  (let
    (
      (record (unwrap! (map-get? property-records { property-id: property-id }) err-property-not-found))
    )
    ;; Check property exists first
    (asserts! (property-on-record property-id) err-property-not-found)
    ;; Check caller is the landlord
    (asserts! (is-eq (get landlord record) tx-sender) err-access-denied)
    
    (map-set property-records
      { property-id: property-id }
      (merge record { viewing-rights: { inspector: inspector, authorized: true } })
    )
    (ok true)
  )
)

(define-public (revoke-viewing-access (property-id uint) (inspector principal))
  (let
    (
      (record (unwrap! (map-get? property-records { property-id: property-id }) err-property-not-found))
    )
    ;; Check property exists first
    (asserts! (property-on-record property-id) err-property-not-found)
    ;; Check caller is the landlord
    (asserts! (is-eq (get landlord record) tx-sender) err-access-denied)
    
    (map-set property-records
      { property-id: property-id }
      (merge record { viewing-rights: { inspector: inspector, authorized: false } })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-property-count)
  (ok (var-get total-properties))
)

(define-read-only (get-property-data (property-id uint))
  (match (map-get? property-records { property-id: property-id })
    record-info (ok record-info)
    err-property-not-found
  )
)

(define-private (verify-landlord (property-id int) (landlord principal))
  (match (map-get? property-records { property-id: (to-uint property-id) })
    record-info (is-eq (get landlord record-info) landlord)
    false
  )
)

(define-private (get-valuation-by-landlord (property-id int))
  (default-to u0 
    (get valuation 
      (map-get? property-records { property-id: (to-uint property-id) })
    )
  )
)