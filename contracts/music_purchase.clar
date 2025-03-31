;; Sheet Music Marketplace - Digital payment integration for online sheet music purchases
;; This contract handles the purchase, ownership, and royalty distribution for clarinet sheet music

;; ----- Constants -----
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INSUFFICIENT-FUNDS (err u402))
(define-constant ERR-NOT-AVAILABLE (err u410))
(define-constant ERR-INVALID-PRICE (err u403))