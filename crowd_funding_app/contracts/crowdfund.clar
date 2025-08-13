;; Crowdfunding Smart Contract - Core Campaign Management
;; Basic campaign creation, contribution, and withdrawal functionality

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-campaign-ended (err u102))
(define-constant err-campaign-not-ended (err u103))
(define-constant err-goal-reached (err u104))
(define-constant err-goal-not-reached (err u105))
(define-constant err-insufficient-funds (err u106))
(define-constant err-invalid-amount (err u107))
(define-constant err-unauthorized (err u108))
(define-constant err-campaign-active (err u109))
(define-constant err-invalid-duration (err u110))

;; Data Variables
(define-data-var campaign-counter uint u0)
(define-data-var total-campaigns uint u0)
(define-data-var total-funds-raised uint u0)

;; Core Data Maps
(define-map campaigns
    uint
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        creator: principal,
        goal: uint,
        raised: uint,
        end-block: uint,
        created-block: uint,
        status: (string-ascii 20),
    }
)

(define-map contributions
    {
        campaign-id: uint,
        contributor: principal,
    }
    uint
)

(define-map campaign-contributors
    uint
    (list 500 principal)
)

(define-map user-campaigns
    principal
    (list 100 uint)
)

(define-map user-contributions
    principal
    (list 100 uint)
)

;; Basic Read-only Functions
(define-read-only (get-campaign (campaign-id uint))
    (map-get? campaigns campaign-id)
)

(define-read-only (get-campaign-counter)
    (var-get campaign-counter)
)

(define-read-only (get-contribution
        (campaign-id uint)
        (contributor principal)
    )
    (default-to u0
        (map-get? contributions {
            campaign-id: campaign-id,
            contributor: contributor,
        })
    )
)

(define-read-only (is-campaign-active (campaign-id uint))
    (match (map-get? campaigns campaign-id)
        campaign (and
            (< stacks-block-height (get end-block campaign))
            (is-eq (get status campaign) "active")
        )
        false
    )
)

;; Helper Functions
(define-private (add-to-list
        (item uint)
        (current-list (list 100 uint))
    )
    (unwrap-panic (as-max-len? (append current-list item) u100))
)

(define-private (add-contributor
        (campaign-id uint)
        (contributor principal)
    )
    (let ((current-contributors (get-campaign-contributors campaign-id)))
        (if (is-none (index-of current-contributors contributor))
            (map-set campaign-contributors campaign-id
                (unwrap-panic (as-max-len? (append current-contributors contributor) u500))
            )
            true
        )
    )
)

;; Core Public Functions
(define-public (create-campaign
        (title (string-ascii 100))
        (description (string-ascii 500))
        (goal uint)
        (duration uint)
    )
    (let (
            (campaign-id (+ (var-get campaign-counter) u1))
            (end-block (+ stacks-block-height duration))
        )
        (asserts! (> goal u0) err-invalid-amount)
        (asserts! (> duration u0) err-invalid-duration)

        (map-set campaigns campaign-id {
            title: title,
            description: description,
            creator: tx-sender,
            goal: goal,
            raised: u0,
            end-block: end-block,
            created-block: stacks-block-height,
            status: "active",
        })

        (var-set campaign-counter campaign-id)
        (var-set total-campaigns (+ (var-get total-campaigns) u1))

        (ok campaign-id)
    )
)

(define-public (contribute
        (campaign-id uint)
        (amount uint)
    )
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (new-raised (+ (get raised campaign) amount))
        )
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-campaign-active campaign-id) err-campaign-ended)

        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

        (map-set contributions {
            campaign-id: campaign-id,
            contributor: tx-sender,
        }
            amount
        )

        (map-set campaigns campaign-id (merge campaign { raised: new-raised }))
        (add-contributor campaign-id tx-sender)

        (ok amount)
    )
)

(define-public (withdraw-funds (campaign-id uint))
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (raised-amount (get raised campaign))
        )
        (asserts! (is-eq tx-sender (get creator campaign)) err-unauthorized)
        (asserts! (>= stacks-block-height (get end-block campaign))
            err-campaign-active
        )
        (asserts! (>= raised-amount (get goal campaign)) err-goal-not-reached)

        (try! (as-contract (stx-transfer? raised-amount tx-sender (get creator campaign))))
        (map-set campaigns campaign-id (merge campaign { status: "completed" }))

        (ok raised-amount)
    )
)

(define-public (claim-refund (campaign-id uint))
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (contribution (get-contribution campaign-id tx-sender))
        )
        (asserts! (> contribution u0) err-insufficient-funds)
        (asserts! (>= stacks-block-height (get end-block campaign))
            err-campaign-active
        )
        (asserts! (< (get raised campaign) (get goal campaign)) err-goal-reached)

        (try! (as-contract (stx-transfer? contribution tx-sender tx-sender)))
        (map-delete contributions {
            campaign-id: campaign-id,
            contributor: tx-sender,
        })

        (ok contribution)
    )
)
