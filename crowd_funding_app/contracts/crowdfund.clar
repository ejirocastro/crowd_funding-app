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
;; Advanced Campaign Features - Milestones, Extensions, Enhanced Refunds

;; Additional Constants
(define-constant err-milestone-not-found (err u111))
(define-constant err-milestone-already-reached (err u112))
(define-constant err-milestone-not-reached (err u113))
(define-constant err-extension-limit-exceeded (err u114))
(define-constant err-cannot-extend (err u115))

;; Additional Data Variables
(define-data-var milestone-counter uint u0)
(define-data-var withdrawal-delay uint u144) ;; 1 day default

;; Extended Campaign Map (add to existing)
;; Add these fields to campaigns map:
;; extensions-used: uint,
;; max-extensions: uint,
;; withdrawal-ready-block: uint,
;; has-milestones: bool,

;; Advanced Data Maps
(define-map milestones
    uint
    {
        campaign-id: uint,
        title: (string-ascii 100),
        description: (string-ascii 300),
        target-amount: uint,
        target-block: uint,
        is-reached: bool,
        funds-released: uint,
    }
)

(define-map campaign-milestones
    uint
    (list 10 uint)
)

(define-map refund-requests
    {
        campaign-id: uint,
        contributor: principal,
    }
    {
        amount: uint,
        requested-block: uint,
        reason: (string-ascii 200),
    }
)

(define-map campaign-updates
    uint
    (list
        20
        {
            update-block: uint,
            title: (string-ascii 100),
            content: (string-ascii 500),
        }
    )
)

;; Milestone Management
(define-public (create-milestone
        (campaign-id uint)
        (title (string-ascii 100))
        (description (string-ascii 300))
        (target-amount uint)
        (target-block uint)
    )
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (milestone-id (+ (var-get milestone-counter) u1))
            (current-milestones (get-campaign-milestones campaign-id))
        )
        (asserts! (is-eq tx-sender (get creator campaign)) err-unauthorized)
        (asserts! (is-campaign-active campaign-id) err-campaign-ended)
        (asserts! (> target-amount u0) err-invalid-amount)
        (asserts! (< (len current-milestones) u10) err-extension-limit-exceeded)

        (map-set milestones milestone-id {
            campaign-id: campaign-id,
            title: title,
            description: description,
            target-amount: target-amount,
            target-block: target-block,
            is-reached: false,
            funds-released: u0,
        })

        (map-set campaign-milestones campaign-id
            (unwrap-panic (as-max-len? (append current-milestones milestone-id) u10))
        )

        (var-set milestone-counter milestone-id)
        (ok milestone-id)
    )
)

(define-public (extend-campaign
        (campaign-id uint)
        (extension-blocks uint)
    )
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (extensions-used (get extensions-used campaign))
        )
        (asserts! (is-eq tx-sender (get creator campaign)) err-unauthorized)
        (asserts! (is-campaign-active campaign-id) err-campaign-ended)
        (asserts! (< extensions-used (get max-extensions campaign))
            err-extension-limit-exceeded
        )

        (map-set campaigns campaign-id
            (merge campaign {
                end-block: (+ (get end-block campaign) extension-blocks),
                extensions-used: (+ extensions-used u1),
            })
        )
        (ok true)
    )
)

(define-public (request-refund
        (campaign-id uint)
        (reason (string-ascii 200))
    )
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (contribution (get-contribution campaign-id tx-sender))
        )
        (asserts! (> contribution u0) err-insufficient-funds)
        (asserts! (is-campaign-active campaign-id) err-campaign-ended)

        (map-set refund-requests {
            campaign-id: campaign-id,
            contributor: tx-sender,
        } {
            amount: contribution,
            requested-block: stacks-block-height,
            reason: reason,
        })
        (ok true)
    )
)

(define-public (post-update
        (campaign-id uint)
        (title (string-ascii 100))
        (content (string-ascii 500))
    )
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (current-updates (get-campaign-updates campaign-id))
            (new-update {
                update-block: stacks-block-height,
                title: title,
                content: content,
            })
        )
        (asserts! (is-eq tx-sender (get creator campaign)) err-unauthorized)
        (asserts! (< (len current-updates) u20) err-extension-limit-exceeded)

        (map-set campaign-updates campaign-id
            (unwrap-panic (as-max-len? (append current-updates new-update) u20))
        )
        (ok true)
    )
)

;; Read-only functions for advanced features
(define-read-only (get-milestone (milestone-id uint))
    (map-get? milestones milestone-id)
)

(define-read-only (get-campaign-milestones (campaign-id uint))
    (default-to (list) (map-get? campaign-milestones campaign-id))
)

(define-read-only (get-campaign-updates (campaign-id uint))
    (default-to (list) (map-get? campaign-updates campaign-id))
)
;; Fee Management and Platform Controls

;; Additional Constants
(define-constant err-fee-too-high (err u122))
(define-constant err-withdrawal-period-active (err u116))

;; Fee and Admin Data Variables
(define-data-var platform-fee uint u250) ;; 2.5% fee (250 basis points)
(define-data-var fee-recipient principal contract-owner)
(define-data-var total-platform-fees uint u0)

;; Fee and Admin Data Maps
(define-map campaign-fees
    uint
    uint
)

(define-map admin-permissions
    principal
    {
        can-pause: bool,
        can-set-fees: bool,
        can-manage-governance: bool,
    }
)

;; Enhanced Contribution with Fees
(define-public (contribute-with-fees
        (campaign-id uint)
        (amount uint)
    )
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (fee-amount (/ (* amount (var-get platform-fee)) u10000))
            (net-amount (- amount fee-amount))
            (new-raised (+ (get raised campaign) net-amount))
        )
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-campaign-active campaign-id) err-campaign-ended)

        ;; Transfer full amount from contributor
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

        ;; Transfer fee to fee recipient if fee > 0
        (if (> fee-amount u0)
            (try! (as-contract (stx-transfer? fee-amount tx-sender (var-get fee-recipient))))
            true
        )

        ;; Track fees
        (var-set total-platform-fees (+ (var-get total-platform-fees) fee-amount))
        (map-set campaign-fees campaign-id
            (+ (get-campaign-fee campaign-id) fee-amount)
        )

        ;; Update contribution and campaign
        (map-set contributions {
            campaign-id: campaign-id,
            contributor: tx-sender,
        }
            net-amount
        )

        (map-set campaigns campaign-id (merge campaign { raised: new-raised }))

        ;; Check if goal reached with withdrawal delay
        (if (>= new-raised (get goal campaign))
            (map-set campaigns campaign-id
                (merge campaign {
                    raised: new-raised,
                    status: "funded",
                    withdrawal-ready-block: (+ stacks-block-height (var-get withdrawal-delay)),
                })
            )
            true
        )

        (ok net-amount)
    )
)

;; Admin Fee Management
(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u1000) err-fee-too-high) ;; Max 10%

        (var-set platform-fee new-fee)
        (ok true)
    )
)

(define-public (set-fee-recipient (new-recipient principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set fee-recipient new-recipient)
        (ok true)
    )
)

(define-public (withdraw-platform-fees (amount uint))
    (let ((available-fees (var-get total-platform-fees)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= amount available-fees) err-insufficient-funds)

        (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
        (var-set total-platform-fees (- available-fees amount))
        (ok amount)
    )
)

;; Admin Controls
(define-public (set-admin-permissions
        (admin principal)
        (can-pause bool)
        (can-set-fees bool)
        (can-manage-governance bool)
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)

        (map-set admin-permissions admin {
            can-pause: can-pause,
            can-set-fees: can-set-fees,
            can-manage-governance: can-manage-governance,
        })
        (ok true)
    )
)

;; Emergency Functions
(define-public (emergency-pause (campaign-id uint))
    (let ((campaign (unwrap! (map-get? campaigns campaign-id) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set campaigns campaign-id (merge campaign { status: "paused" }))
        (ok true)
    )
)

(define-public (admin-pause-campaign (campaign-id uint))
    (let (
            (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
            (permissions (map-get? admin-permissions tx-sender))
        )
        (asserts!
            (or
                (is-eq tx-sender contract-owner)
                (match permissions
                    perms (get can-pause perms)
                    false
                )
            )
            err-owner-only
        )

        (map-set campaigns campaign-id (merge campaign { status: "paused" }))
        (ok true)
    )
)

;; Read-only functions for fees and admin
(define-read-only (get-platform-fee)
    (var-get platform-fee)
)

(define-read-only (get-total-platform-fees)
    (var-get total-platform-fees)
)

(define-read-only (get-campaign-fee (campaign-id uint))
    (default-to u0 (map-get? campaign-fees campaign-id))
)

(define-read-only (calculate-fee (amount uint))
    (* amount (var-get platform-fee))
)

(define-read-only (get-admin-permissions (admin principal))
    (map-get? admin-permissions admin)
)
