;; Realm Legends Platform Smart Contract
;; Handles in-game asset ownership and trading functionality

;; Constants
(define-constant platform-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-not-authorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-invalid-price (err u104))
(define-constant max-character-level u100)
(define-constant max-character-experience u10000)
(define-constant max-item-metadata-length u256)
(define-constant max-batch-operation-size u10)  ;; Limit batch operations to prevent potential gas issues

;; Data Variables
(define-map game-items 
    { item-id: uint }
    { owner: principal, item-metadata-uri: (string-utf8 256), can-transfer: bool })

(define-map item-market-prices
    { item-id: uint }
    { price: uint })

(define-map character-progression
    { character-owner: principal }
    { experience: uint, level: uint })

(define-map marketplace-item-listings
    { item-id: uint }
    { seller: principal, price: uint, listed-at: uint })

;; Item Counter
(define-data-var total-item-count uint u0)

;; Helper Functions

;; Validate item exists and return item data
(define-private (get-item-checked (item-id uint))
    (let ((item (map-get? game-items { item-id: item-id })))
        (asserts! (and 
                (is-some item)
                (<= item-id (var-get total-item-count)))
            err-not-found)
        (ok (unwrap-panic item))))

;; Validate metadata URI length
(define-private (validate-item-metadata-uri (uri (string-utf8 256)))
    (let ((uri-length (len uri)))
        (and 
            (> uri-length u0)
            (<= uri-length max-item-metadata-length))))

;; Public Functions

;; Batch Mint new game items
(define-public (batch-mint-game-items 
    (item-metadata-uris (list 10 (string-utf8 256))) 
    (transferable-list (list 10 bool)))
    (begin
        (asserts! (is-eq tx-sender platform-owner) err-owner-only)
        (asserts! (and 
            (> (len item-metadata-uris) u0)
            (<= (len item-metadata-uris) max-batch-operation-size)
            (is-eq (len item-metadata-uris) (len transferable-list))) 
            err-invalid-input)
        (let ((minted-items 
            (map mint-single-item 
                item-metadata-uris 
                transferable-list)))
            (ok minted-items))))

;; Helper function for batch minting
(define-private (mint-single-item 
    (uri (string-utf8 256))
    (can-transfer bool))
    (let 
        ((item-id (+ (var-get total-item-count) u1)))
        (asserts! (validate-item-metadata-uri uri) err-invalid-input)
        (map-set game-items
            { item-id: item-id }
            { owner: platform-owner,
              item-metadata-uri: uri,
              can-transfer: can-transfer })
        (var-set total-item-count item-id)
        (ok item-id)))

;; Batch Transfer game items
(define-public (batch-transfer-game-items 
    (item-ids (list 10 uint)) 
    (recipients (list 10 principal)))
    (begin
        (asserts! (and 
            (> (len item-ids) u0)
            (<= (len item-ids) max-batch-operation-size)
            (is-eq (len item-ids) (len recipients))) 
            err-invalid-input)
        (let ((transfers 
            (map transfer-single-item 
                item-ids 
                recipients)))
            (ok transfers))))

;; Helper function for batch transfer
(define-private (transfer-single-item 
    (item-id uint)
    (recipient principal))
    (let 
        ((item (unwrap-panic (get-item-checked item-id))))
        (asserts! (and
                (is-eq (get owner item) tx-sender)
                (get can-transfer item)
                (not (is-eq recipient tx-sender)))  ;; Prevent self-transfers
            err-not-authorized)
        (map-set game-items
            { item-id: item-id }
            { owner: recipient,
              item-metadata-uri: (get item-metadata-uri item),
              can-transfer: (get can-transfer item) })
        (ok true)))

;; Mint single game item
(define-public (mint-game-item (item-metadata-uri (string-utf8 256)) (can-transfer bool))
    (let
        ((item-id (+ (var-get total-item-count) u1)))
        (asserts! (is-eq tx-sender platform-owner) err-owner-only)
        (asserts! (validate-item-metadata-uri item-metadata-uri) err-invalid-input)
        (map-set game-items
            { item-id: item-id }
            { owner: tx-sender,
              item-metadata-uri: item-metadata-uri,
              can-transfer: can-transfer })
        (var-set total-item-count item-id)
        (ok item-id)))

;; Transfer game item ownership
(define-public (transfer-game-item (item-id uint) (recipient principal))
    (begin
        (asserts! (<= item-id (var-get total-item-count)) err-invalid-input)
        (let ((item (try! (get-item-checked item-id))))
            (asserts! (and
                    (is-eq (get owner item) tx-sender)
                    (get can-transfer item)
                    (not (is-eq recipient tx-sender)))  ;; Prevent self-transfers
                err-not-authorized)
            (map-set game-items
                { item-id: item-id }
                { owner: recipient,
                  item-metadata-uri: (get item-metadata-uri item),
                  can-transfer: (get can-transfer item) })
            (ok true))))

;; List game item for sale with enhanced marketplace listing
(define-public (list-game-item-for-sale (item-id uint) (price uint))
    (begin
        (asserts! (<= item-id (var-get total-item-count)) err-invalid-input)
        (let ((item (try! (get-item-checked item-id))))
            (asserts! (and 
                    (is-eq (get owner item) tx-sender)
                    (> price u0)
                    (get can-transfer item))  ;; Ensure item is transferable
                err-invalid-price)
            (map-set marketplace-item-listings
                { item-id: item-id }
                { seller: tx-sender, 
                  price: price, 
                  listed-at: block-height })
            (ok true))))

;; Purchase listed game item with enhanced marketplace mechanics
(define-public (purchase-game-item (item-id uint))
    (begin
        (asserts! (<= item-id (var-get total-item-count)) err-invalid-input)
        (let
            ((item (try! (get-item-checked item-id)))
             (listing (unwrap! (map-get? marketplace-item-listings { item-id: item-id }) err-not-found)))
            (asserts! (and
                    (not (is-eq (get seller listing) tx-sender))
                    (get can-transfer item))
                err-not-authorized)
            (try! (stx-transfer? (get price listing) tx-sender (get seller listing)))
            (map-set game-items
                { item-id: item-id }
                { owner: tx-sender,
                  item-metadata-uri: (get item-metadata-uri item),
                  can-transfer: (get can-transfer item) })
            (map-delete marketplace-item-listings { item-id: item-id })
            (ok true))))

;; Remove game item from marketplace listing
(define-public (delist-game-item (item-id uint))
    (begin
        ;; Validate item-id is within the range of minted items
        (asserts! (<= item-id (var-get total-item-count)) err-invalid-input)
        
        ;; Try to get the listing, return error if not found
        (let ((listing (unwrap! (map-get? marketplace-item-listings { item-id: item-id }) err-not-found)))
            ;; Ensure only the seller can delist
            (asserts! (is-eq tx-sender (get seller listing)) err-not-authorized)
            
            ;; Delete the marketplace listing
            (map-delete marketplace-item-listings { item-id: item-id })
            
            ;; Return success
            (ok true))))

;; Update character progression stats with validation
(define-public (update-character-progression (experience uint) (level uint))
    (begin
        (asserts! (<= experience max-character-experience) err-invalid-input)
        (asserts! (<= level max-character-level) err-invalid-input)
        (map-set character-progression
            { character-owner: tx-sender }
            { experience: experience, level: level })
        (ok true)))

;; Read-only Functions

;; Get game item details
(define-read-only (get-game-item-details (item-id uint))
    (if (<= item-id (var-get total-item-count))
        (map-get? game-items { item-id: item-id })
        none))

;; Get marketplace listing details
(define-read-only (get-marketplace-listing (item-id uint))
    (map-get? marketplace-item-listings { item-id: item-id }))

;; Get character progression stats
(define-read-only (get-character-progression (character-owner principal))
    (map-get? character-progression { character-owner: character-owner }))

;; Get total game items minted
(define-read-only (get-total-game-items)
    (var-get total-item-count))