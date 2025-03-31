;; Sheet Music Marketplace - Digital payment integration for online sheet music purchases
;; This contract handles the purchase, ownership, and royalty distribution for clarinet sheet music

;; ----- Constants -----
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INSUFFICIENT-FUNDS (err u402))
(define-constant ERR-NOT-AVAILABLE (err u410))
(define-constant ERR-INVALID-PRICE (err u403))
;; ----- Data Variables -----
(define-data-var marketplace-admin principal tx-sender)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee
(define-data-var music-counter uint u0)

;; ----- Data Maps -----
;; Sheet music catalog
(define-map sheet-music-catalog
  { music-id: uint }
  {
    title: (string-utf8 100),
    composer: (string-utf8 100),
    arranger: (string-utf8 100),
    difficulty: (string-utf8 20),
    price: uint,
    owner: principal,
    royalty-percentage: uint,
    metadata-url: (optional (string-utf8 256)),
    available: bool
  }
)

;; User purchases
(define-map user-purchases
  { user: principal, music-id: uint }
  {
    purchased: bool,
    purchase-time: uint,
    license-type: (string-utf8 20),
    download-count: uint
  }
)

;; User balances from sales
(define-map creator-balances
  { creator: principal }
  { balance: uint }
)
;; ----- Public Functions -----

;; Add new sheet music to the catalog
(define-public (list-sheet-music 
    (title (string-utf8 100))
    (composer (string-utf8 100))
    (arranger (string-utf8 100))
    (difficulty (string-utf8 20))
    (price uint)
    (royalty-percentage uint)
    (metadata-url (optional (string-utf8 256)))
  )
  (let
    (
      (music-id (+ (var-get music-counter) u1))
    )
    ;; Verify valid price and royalty
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (<= royalty-percentage u100) ERR-INVALID-PRICE)
    
    ;; Add to catalog
    (map-insert sheet-music-catalog
      { music-id: music-id }
      {
        title: title,
        composer: composer,
        arranger: arranger,
        difficulty: difficulty,
        price: price,
        owner: tx-sender,
        royalty-percentage: royalty-percentage,
        metadata-url: metadata-url,
        available: true
      }
    )
    
    ;; Increment counter
    (var-set music-counter music-id)
    (ok music-id)
  )
)

;; Purchase sheet music
(define-public (purchase-sheet-music (music-id uint) (license-type (string-utf8 20)))
  (let
    (
      (music-item (unwrap! (map-get? sheet-music-catalog { music-id: music-id }) ERR-NOT-FOUND))
      (price (get price music-item))
      (owner (get owner music-item))
      (royalty-percentage (get royalty-percentage music-item))
      (platform-fee (/ (* price (var-get platform-fee-percentage)) u100))
      (creator-fee (/ (* price royalty-percentage) u100))
      (admin-address (var-get marketplace-admin))
    )
    ;; Check if sheet music is available
    (asserts! (get available music-item) ERR-NOT-AVAILABLE)
    
    ;; Process payment
    (try! (stx-transfer? price tx-sender admin-address))
    
    ;; Record purchase
    (map-insert user-purchases
      { user: tx-sender, music-id: music-id }
      {
        purchased: true,
        purchase-time: block-height,
        license-type: license-type,
        download-count: u0
      }
    )
    
    ;; Update creator balance
    (match (map-get? creator-balances { creator: owner })
      existing-balance (map-set creator-balances
        { creator: owner }
        { balance: (+ (get balance existing-balance) creator-fee) }
      )
      (map-insert creator-balances
        { creator: owner }
        { balance: creator-fee }
      )
    )
    
    (ok true)
  )
)

;; Log a download (to track usage)
(define-public (log-download (music-id uint))
  (let
    (
      (purchase-info (unwrap! (map-get? user-purchases { user: tx-sender, music-id: music-id }) ERR-NOT-AUTHORIZED))
    )
    ;; Verify purchase exists
    (asserts! (get purchased purchase-info) ERR-NOT-AUTHORIZED)
    
    ;; Update download count
    (map-set user-purchases
      { user: tx-sender, music-id: music-id }
      (merge purchase-info { download-count: (+ (get download-count purchase-info) u1) })
    )
    
    (ok true)
  )
)

;; Update sheet music metadata
(define-public (update-sheet-music (music-id uint) (price (optional uint)) (available (optional bool)) (metadata-url (optional (string-utf8 256))))
  (let
    (
      (music-item (unwrap! (map-get? sheet-music-catalog { music-id: music-id }) ERR-NOT-FOUND))
    )
    ;; Verify ownership
    (asserts! (is-eq (get owner music-item) tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Update fields if provided
    (map-set sheet-music-catalog
      { music-id: music-id }
      (merge music-item {
        price: (default-to (get price music-item) price),
        available: (default-to (get available music-item) available),
        metadata-url: (match metadata-url
          new-url (some new-url)
          (get metadata-url music-item)
        )
      })
    )
    
    (ok true)
  )
)

;; Withdraw creator earnings
(define-public (withdraw-earnings)
  (let
    (
      (balance-data (unwrap! (map-get? creator-balances { creator: tx-sender }) ERR-NOT-FOUND))
      (amount (get balance amount-data))
    )
    ;; Verify balance
    (asserts! (> amount u0) ERR-INSUFFICIENT-FUNDS)
    
    ;; Transfer funds
    (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
    
    ;; Reset balance
    (map-set creator-balances
      { creator: tx-sender }
      { balance: u0 }
    )
    
    (ok amount)
  )
)