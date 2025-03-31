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
