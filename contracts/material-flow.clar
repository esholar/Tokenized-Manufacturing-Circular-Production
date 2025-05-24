;; Material Flow Contract
;; Tracks resource circulation throughout the production cycle

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-material-not-found (err u201))
(define-constant err-invalid-quantity (err u202))
(define-constant err-unauthorized (err u203))

;; Data Variables
(define-data-var next-material-id uint u1)
(define-data-var next-batch-id uint u1)

;; Data Maps
(define-map materials
  { material-id: uint }
  {
    name: (string-ascii 50),
    type: (string-ascii 30),
    unit: (string-ascii 10),
    created-at: uint,
    created-by: principal
  }
)

(define-map material-batches
  { batch-id: uint }
  {
    material-id: uint,
    quantity: uint,
    source: (string-ascii 100),
    destination: (string-ascii 100),
    status: (string-ascii 20),
    timestamp: uint,
    facility-id: uint
  }
)

(define-map material-transformations
  { transformation-id: uint }
  {
    input-batch-id: uint,
    output-batch-id: uint,
    process: (string-ascii 50),
    efficiency: uint,
    timestamp: uint,
    facility-id: uint
  }
)

(define-data-var next-transformation-id uint u1)

;; Public Functions

;; Register a new material type
(define-public (register-material (name (string-ascii 50)) (type (string-ascii 30)) (unit (string-ascii 10)))
  (let
    (
      (material-id (var-get next-material-id))
    )
    (map-set materials
      { material-id: material-id }
      {
        name: name,
        type: type,
        unit: unit,
        created-at: block-height,
        created-by: tx-sender
      }
    )

    (var-set next-material-id (+ material-id u1))
    (ok material-id)
  )
)

;; Track material input
(define-public (track-material-input (material-id uint) (quantity uint) (source (string-ascii 100)) (facility-id uint))
  (let
    (
      (batch-id (var-get next-batch-id))
    )
    (asserts! (> quantity u0) err-invalid-quantity)
    (asserts! (is-some (map-get? materials { material-id: material-id })) err-material-not-found)

    (map-set material-batches
      { batch-id: batch-id }
      {
        material-id: material-id,
        quantity: quantity,
        source: source,
        destination: "",
        status: "received",
        timestamp: block-height,
        facility-id: facility-id
      }
    )

    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

;; Track material output
(define-public (track-material-output (material-id uint) (quantity uint) (destination (string-ascii 100)) (facility-id uint))
  (let
    (
      (batch-id (var-get next-batch-id))
    )
    (asserts! (> quantity u0) err-invalid-quantity)
    (asserts! (is-some (map-get? materials { material-id: material-id })) err-material-not-found)

    (map-set material-batches
      { batch-id: batch-id }
      {
        material-id: material-id,
        quantity: quantity,
        source: "",
        destination: destination,
        status: "shipped",
        timestamp: block-height,
        facility-id: facility-id
      }
    )

    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

;; Record material transformation
(define-public (record-transformation (input-batch-id uint) (output-batch-id uint) (process (string-ascii 50)) (efficiency uint) (facility-id uint))
  (let
    (
      (transformation-id (var-get next-transformation-id))
    )
    (asserts! (is-some (map-get? material-batches { batch-id: input-batch-id })) err-material-not-found)
    (asserts! (is-some (map-get? material-batches { batch-id: output-batch-id })) err-material-not-found)
    (asserts! (<= efficiency u100) (err u204))

    (map-set material-transformations
      { transformation-id: transformation-id }
      {
        input-batch-id: input-batch-id,
        output-batch-id: output-batch-id,
        process: process,
        efficiency: efficiency,
        timestamp: block-height,
        facility-id: facility-id
      }
    )

    (var-set next-transformation-id (+ transformation-id u1))
    (ok transformation-id)
  )
)

;; Read-only Functions

;; Get material details
(define-read-only (get-material (material-id uint))
  (map-get? materials { material-id: material-id })
)

;; Get batch details
(define-read-only (get-batch (batch-id uint))
  (map-get? material-batches { batch-id: batch-id })
)

;; Get transformation details
(define-read-only (get-transformation (transformation-id uint))
  (map-get? material-transformations { transformation-id: transformation-id })
)

;; Get total materials count
(define-read-only (get-total-materials)
  (- (var-get next-material-id) u1)
)

;; Get total batches count
(define-read-only (get-total-batches)
  (- (var-get next-batch-id) u1)
)
