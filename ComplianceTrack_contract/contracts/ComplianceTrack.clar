
;; title: ComplianceTrack
;; version: 1.0.0
;; summary: Supply chain tracking smart contract for regulatory compliance verification
;; description: A comprehensive smart contract that tracks products through the supply chain,
;;              verifies compliance with regulatory standards, and maintains an immutable
;;              audit trail for regulatory authorities.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-invalid-compliance (err u105))

;; data vars
(define-data-var next-product-id uint u1)
(define-data-var next-batch-id uint u1)

;; data maps

;; Products registry - tracks individual products in the supply chain
(define-map products
  { product-id: uint }
  {
    name: (string-ascii 100),
    manufacturer: principal,
    category: (string-ascii 50),
    created-at: uint,
    is-active: bool
  }
)

;; Batches - groups of products for tracking through supply chain
(define-map batches
  { batch-id: uint }
  {
    product-id: uint,
    quantity: uint,
    current-owner: principal,
    current-location: (string-ascii 100),
    status: (string-ascii 20), ;; "manufactured", "in-transit", "delivered", "recalled"
    created-at: uint,
    last-updated: uint
  }
)

;; Compliance records - tracks regulatory compliance for batches
(define-map compliance-records
  { batch-id: uint, standard: (string-ascii 50) }
  {
    is-compliant: bool,
    verified-by: principal,
    verification-date: uint,
    expiry-date: (optional uint),
    certificate-hash: (string-ascii 64),
    notes: (string-ascii 200)
  }
)

;; Supply chain events - immutable audit trail
(define-map supply-chain-events
  { event-id: uint }
  {
    batch-id: uint,
    event-type: (string-ascii 30), ;; "transfer", "inspection", "compliance-check", "recall"
    from-party: (optional principal),
    to-party: (optional principal),
    location: (string-ascii 100),
    timestamp: uint,
    metadata: (string-ascii 200)
  }
)

;; Authorized verifiers - principals who can verify compliance
(define-map authorized-verifiers
  { verifier: principal }
  {
    name: (string-ascii 100),
    certification-type: (string-ascii 50),
    authorized-by: principal,
    authorized-at: uint,
    is-active: bool
  }
)

;; Event counter for unique event IDs
(define-data-var next-event-id uint u1)

;; public functions

;; Register a new product
(define-public (register-product (name (string-ascii 100)) (category (string-ascii 50)))
  (let (
    (product-id (var-get next-product-id))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set products
      { product-id: product-id }
      {
        name: name,
        manufacturer: tx-sender,
        category: category,
        created-at: block-height,
        is-active: true
      }
    )
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

;; Create a new batch
(define-public (create-batch (product-id uint) (quantity uint) (location (string-ascii 100)))
  (let (
    (batch-id (var-get next-batch-id))
    (product (unwrap! (map-get? products { product-id: product-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender (get manufacturer product)) err-unauthorized)
    (asserts! (get is-active product) err-not-found)
    (map-set batches
      { batch-id: batch-id }
      {
        product-id: product-id,
        quantity: quantity,
        current-owner: tx-sender,
        current-location: location,
        status: "manufactured",
        created-at: block-height,
        last-updated: block-height
      }
    )
    (var-set next-batch-id (+ batch-id u1))
    (unwrap-panic (log-supply-chain-event batch-id "batch-created" none (some tx-sender) location "Initial batch creation"))
    (ok batch-id)
  )
)

;; Transfer batch ownership
(define-public (transfer-batch (batch-id uint) (new-owner principal) (new-location (string-ascii 100)))
  (let (
    (batch (unwrap! (map-get? batches { batch-id: batch-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender (get current-owner batch)) err-unauthorized)
    (map-set batches
      { batch-id: batch-id }
      (merge batch {
        current-owner: new-owner,
        current-location: new-location,
        status: "in-transit",
        last-updated: block-height
      })
    )
    (unwrap-panic (log-supply-chain-event batch-id "transfer" (some tx-sender) (some new-owner) new-location "Batch ownership transferred"))
    (ok true)
  )
)

;; Update batch status
(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 20)) (location (string-ascii 100)))
  (let (
    (batch (unwrap! (map-get? batches { batch-id: batch-id }) err-not-found))
  )
    (asserts! (is-eq tx-sender (get current-owner batch)) err-unauthorized)
    (asserts! (or (is-eq new-status "manufactured")
                  (is-eq new-status "in-transit")
                  (is-eq new-status "delivered")
                  (is-eq new-status "recalled")) err-invalid-status)
    (map-set batches
      { batch-id: batch-id }
      (merge batch {
        current-location: location,
        status: new-status,
        last-updated: block-height
      })
    )
    (unwrap-panic (log-supply-chain-event batch-id "status-update" none (some tx-sender) location new-status))
    (ok true)
  )
)

;; Authorize a compliance verifier
(define-public (authorize-verifier (verifier principal) (name (string-ascii 100)) (certification-type (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-verifiers
      { verifier: verifier }
      {
        name: name,
        certification-type: certification-type,
        authorized-by: tx-sender,
        authorized-at: block-height,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Record compliance verification
(define-public (record-compliance
    (batch-id uint)
    (standard (string-ascii 50))
    (is-compliant bool)
    (expiry-date (optional uint))
    (certificate-hash (string-ascii 64))
    (notes (string-ascii 200)))
  (let (
    (batch (unwrap! (map-get? batches { batch-id: batch-id }) err-not-found))
    (verifier (unwrap! (map-get? authorized-verifiers { verifier: tx-sender }) err-unauthorized))
  )
    (asserts! (get is-active verifier) err-unauthorized)
    (map-set compliance-records
      { batch-id: batch-id, standard: standard }
      {
        is-compliant: is-compliant,
        verified-by: tx-sender,
        verification-date: block-height,
        expiry-date: expiry-date,
        certificate-hash: certificate-hash,
        notes: notes
      }
    )
    (unwrap-panic (log-supply-chain-event batch-id "compliance-check" none (some tx-sender) (get current-location batch) standard))
    (ok true)
  )
)

;; Recall a batch
(define-public (recall-batch (batch-id uint) (reason (string-ascii 200)))
  (let (
    (batch (unwrap! (map-get? batches { batch-id: batch-id }) err-not-found))
    (product (unwrap! (map-get? products { product-id: (get product-id batch) }) err-not-found))
  )
    (asserts! (or (is-eq tx-sender contract-owner)
                  (is-eq tx-sender (get manufacturer product))) err-unauthorized)
    (map-set batches
      { batch-id: batch-id }
      (merge batch {
        status: "recalled",
        last-updated: block-height
      })
    )
    (unwrap-panic (log-supply-chain-event batch-id "recall" none (some tx-sender) (get current-location batch) reason))
    (ok true)
  )
)

;; read only functions

;; Get product information
(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

;; Get batch information
(define-read-only (get-batch (batch-id uint))
  (map-get? batches { batch-id: batch-id })
)

;; Get compliance record
(define-read-only (get-compliance-record (batch-id uint) (standard (string-ascii 50)))
  (map-get? compliance-records { batch-id: batch-id, standard: standard })
)

;; Get supply chain event
(define-read-only (get-supply-chain-event (event-id uint))
  (map-get? supply-chain-events { event-id: event-id })
)

;; Get verifier information
(define-read-only (get-verifier (verifier principal))
  (map-get? authorized-verifiers { verifier: verifier })
)

;; Check if batch is compliant with a specific standard
(define-read-only (is-batch-compliant (batch-id uint) (standard (string-ascii 50)))
  (match (map-get? compliance-records { batch-id: batch-id, standard: standard })
    compliance-record (and (get is-compliant compliance-record)
                          (match (get expiry-date compliance-record)
                            expiry (< block-height expiry)
                            true))
    false
  )
)

;; Get next available IDs
(define-read-only (get-next-product-id)
  (var-get next-product-id)
)

(define-read-only (get-next-batch-id)
  (var-get next-batch-id)
)

(define-read-only (get-next-event-id)
  (var-get next-event-id)
)

;; private functions

;; Log supply chain events
(define-private (log-supply-chain-event
    (batch-id uint)
    (event-type (string-ascii 30))
    (from-party (optional principal))
    (to-party (optional principal))
    (location (string-ascii 100))
    (metadata (string-ascii 200)))
  (let (
    (event-id (var-get next-event-id))
  )
    (map-set supply-chain-events
      { event-id: event-id }
      {
        batch-id: batch-id,
        event-type: event-type,
        from-party: from-party,
        to-party: to-party,
        location: location,
        timestamp: block-height,
        metadata: metadata
      }
    )
    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)

