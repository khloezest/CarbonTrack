;;; ===================================================
;;; CARBONTRACK - PERSONAL CARBON FOOTPRINT TRACKING
;;; ===================================================
;;; A blockchain-based carbon footprint monitoring system with
;;; rewards for emission reductions and carbon offset verification.
;;; Addresses UN SDG 13: Climate Action through personal accountability.
;;; ===================================================

;; ===================================================
;; CONSTANTS AND ERROR CODES
;; ===================================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1200))
(define-constant ERR-INVALID-AMOUNT (err u1201))
(define-constant ERR-INSUFFICIENT-FUNDS (err u1202))
(define-constant ERR-USER-NOT-FOUND (err u1203))
(define-constant ERR-ALREADY-REGISTERED (err u1204))
(define-constant ERR-INVALID-CATEGORY (err u1205))
(define-constant ERR-INVALID-PERIOD (err u1206))
(define-constant ERR-DUPLICATE-ENTRY (err u1207))
(define-constant ERR-INVALID-OFFSET (err u1208))

;; Carbon Categories
(define-constant CATEGORY-TRANSPORT u1)
(define-constant CATEGORY-ENERGY u2)
(define-constant CATEGORY-FOOD u3)
(define-constant CATEGORY-WASTE u4)
(define-constant CATEGORY-CONSUMPTION u5)

;; Transport Types
(define-constant TRANSPORT-CAR u1)
(define-constant TRANSPORT-BUS u2)
(define-constant TRANSPORT-TRAIN u3)
(define-constant TRANSPORT-FLIGHT u4)
(define-constant TRANSPORT-BIKE u5)
(define-constant TRANSPORT-WALK u6)

;; Energy Sources
(define-constant ENERGY-GRID u1)
(define-constant ENERGY-SOLAR u2)
(define-constant ENERGY-WIND u3)
(define-constant ENERGY-HYDRO u4)

;; Emission Factors (grams CO2 per unit)
(define-constant CAR-EMISSION-FACTOR u251) ;; per km
(define-constant BUS-EMISSION-FACTOR u89) ;; per km
(define-constant TRAIN-EMISSION-FACTOR u48) ;; per km
(define-constant FLIGHT-EMISSION-FACTOR u285) ;; per km
(define-constant GRID-ENERGY-FACTOR u500) ;; per kWh

;; Reward Constants
(define-constant REDUCTION-REWARD-RATE u1000) ;; 1000 tokens per kg CO2 reduced
(define-constant VERIFICATION-REWARD u500000) ;; 0.5 STX for verified data
(define-constant OFFSET-TOKEN-RATE u100) ;; 100 tokens per kg CO2 offset

;; Time Constants
(define-constant BLOCKS-PER-DAY u144)
(define-constant BLOCKS-PER-WEEK u1008)
(define-constant BLOCKS-PER-MONTH u4320)

;; ===================================================
;; DATA STRUCTURES
;; ===================================================

;; Carbon Tracker Users
(define-map carbon-users
    { user: principal }
    {
        user-name: (string-ascii 100),
        location: (string-ascii 100),
        registration-date: uint,
        baseline-monthly-emissions: uint, ;; grams CO2
        current-monthly-emissions: uint,
        total-emissions-tracked: uint,
        total-reductions-achieved: uint,
        tracking-streak: uint,
        last-update-date: uint,
        carbon-score: uint, ;; 0-1000, lower is better
        rewards-earned: uint,
        is-active: bool
    }
)

;; Daily Emissions Entries
(define-map emission-entries
    { entry-id: uint }
    {
        user: principal,
        category: uint,
        entry-date: uint,
        transport-km: uint,
        transport-type: uint,
        energy-kwh: uint,
        energy-source: uint,
        food-emissions: uint, ;; estimated grams CO2
        waste-generated: uint, ;; grams
        consumption-items: uint,
        calculated-emissions: uint, ;; total grams CO2
        is-verified: bool,
        verified-by: (optional principal)
    }
)

;; Carbon Offset Projects
(define-map offset-projects
    { project-id: uint }
    {
        project-name: (string-ascii 100),
        project-type: (string-ascii 50),
        location: (string-ascii 100),
        operator: principal,
        total-co2-capacity: uint, ;; grams CO2
        co2-sold: uint,
        price-per-kg: uint, ;; STX per kg CO2
        verification-standard: (string-ascii 50),
        project-start-date: uint,
        project-duration: uint,
        is_active: bool,
        additionality-verified: bool
    }
)

;; Carbon Offset Purchases
(define-map offset-purchases
    { purchase-id: uint }
    {
        buyer: principal,
        project-id: uint,
        co2-amount: uint, ;; grams
        purchase-price: uint,
        purchase-date: uint,
        retirement-date: (optional uint),
        is-retired: bool,
        certificate-hash: (buff 32)
    }
)

;; Monthly Carbon Reports
(define-map monthly-reports
    { report-id: uint }
    {
        user: principal,
        report-month: uint,
        report-year: uint,
        total-emissions: uint,
        category-breakdown: (list 5 uint),
        reduction-vs-baseline: int, ;; can be negative
        offset-purchased: uint,
        net-emissions: uint,
        improvement-score: uint
    }
)

;; Carbon Verifiers
(define-map carbon-verifiers
    { verifier: principal }
    {
        verifier-name: (string-ascii 100),
        certification: (string-ascii 100),
        verifications-completed: uint,
        accuracy-rating: uint,
        registration-date: uint,
        is_active: bool,
        specialization: (list 5 uint)
    }
)

;; Community Challenges
(define-map carbon-challenges
    { challenge-id: uint }
    {
        challenge-name: (string-ascii 100),
        challenge-type: (string-ascii 50),
        target-reduction: uint, ;; percentage * 100
        participant-count: uint,
        total-reward-pool: uint,
        start-date: uint,
        end-date: uint,
        is_active: bool,
        community_progress: uint
    }
)

;; ===================================================
;; DATA VARIABLES
;; ===================================================

(define-data-var next-entry-id uint u1)
(define-data-var next-project-id uint u1)
(define-data-var next-purchase-id uint u1)
(define-data-var next-report-id uint u1)
(define-data-var next-challenge-id uint u1)
(define-data-var total-users uint u0)
(define-data-var total-emissions-tracked uint u0)
(define-data-var total-offsets-sold uint u0)
(define-data-var reward-fund-balance uint u0)

;; ===================================================
;; PRIVATE FUNCTIONS
;; ===================================================

;; Calculate transport emissions
(define-private (calculate-transport-emissions (transport-type uint) (distance-km uint))
    (let (
        (emission-factor (if (is-eq transport-type TRANSPORT-CAR) CAR-EMISSION-FACTOR
                        (if (is-eq transport-type TRANSPORT-BUS) BUS-EMISSION-FACTOR
                        (if (is-eq transport-type TRANSPORT-TRAIN) TRAIN-EMISSION-FACTOR
                        (if (is-eq transport-type TRANSPORT-FLIGHT) FLIGHT-EMISSION-FACTOR
                            u0))))) ;; Bike/walk = 0 emissions
    )
        (* emission-factor distance-km)
    )
)

;; Calculate energy emissions
(define-private (calculate-energy-emissions (energy-source uint) (kwh uint))
    (let (
        (emission-factor (if (is-eq energy-source ENERGY-GRID) GRID-ENERGY-FACTOR
                        u0)) ;; Renewable sources = 0 emissions
    )
        (* emission-factor kwh)
    )
)

;; Calculate total daily emissions
(define-private (calculate-total-emissions 
    (transport-emissions uint)
    (energy-emissions uint)
    (food-emissions uint)
    (waste-generated uint)
    (consumption-items uint))
    
    (let (
        (waste-emissions (* waste-generated u2)) ;; 2g CO2 per gram waste
        (consumption-emissions (* consumption-items u1000)) ;; 1kg CO2 per item estimate
    )
        (+ (+ transport-emissions energy-emissions) 
           (+ (+ food-emissions waste-emissions) consumption-emissions))
    )
)

;; Update carbon score based on emissions
(define-private (update-carbon-score (user principal) (monthly-emissions uint) (baseline uint))
    (match (map-get? carbon-users { user: user })
        user-data
            (let (
                (reduction-percentage (if (> baseline u0)
                                       (/ (* (- baseline monthly-emissions) u10000) baseline)
                                       u0))
                (new-score (if (> reduction-percentage u2000) ;; 20% reduction
                             (- (get carbon-score user-data) u50)
                             (if (< reduction-percentage u0) ;; Increase in emissions
                                 (+ (get carbon-score user-data) u30)
                                 (get carbon-score user-data))))
                (final-score (if (> new-score u1000) u1000 
                            (if (< new-score u0) u0 new-score)))
            )
            (map-set carbon-users
                { user: user }
                (merge user-data { carbon-score: final-score })
            )
            true
            )
        false
    )
)

;; Validate category
(define-private (is-valid-category (category uint))
    (or (is-eq category CATEGORY-TRANSPORT)
        (or (is-eq category CATEGORY-ENERGY)
            (or (is-eq category CATEGORY-FOOD)
                (or (is-eq category CATEGORY-WASTE)
                    (is-eq category CATEGORY-CONSUMPTION)))))
)

;; ===================================================
;; PUBLIC FUNCTIONS - USER REGISTRATION
;; ===================================================

;; Register as carbon tracker
(define-public (register-user
    (user-name (string-ascii 100))
    (location (string-ascii 100))
    (estimated-monthly-emissions uint))
    
    (let (
        (registration-date stacks-block-height)
    )
    
    (asserts! (is-none (map-get? carbon-users { user: tx-sender })) ERR-ALREADY-REGISTERED)
    (asserts! (> estimated-monthly-emissions u0) ERR-INVALID-AMOUNT)
    
    ;; Register user
    (map-set carbon-users
        { user: tx-sender }
        {
            user-name: user-name,
            location: location,
            registration-date: registration-date,
            baseline-monthly-emissions: estimated-monthly-emissions,
            current-monthly-emissions: u0,
            total-emissions-tracked: u0,
            total-reductions-achieved: u0,
            tracking-streak: u0,
            last-update-date: u0,
            carbon-score: u500, ;; Start at middle score
            rewards-earned: u0,
            is-active: true
        }
    )
    
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
    )
)

;; ===================================================
;; PUBLIC FUNCTIONS - EMISSION TRACKING
;; ===================================================

;; Record daily emissions
(define-public (record-emissions
    (transport-km uint)
    (transport-type uint)
    (energy-kwh uint)
    (energy-source uint)
    (food-emissions uint)
    (waste-generated uint)
    (consumption-items uint))
    
    (let (
        (user-data (unwrap! (map-get? carbon-users { user: tx-sender }) ERR-USER-NOT-FOUND))
        (entry-id (var-get next-entry-id))
        (transport-emissions (calculate-transport-emissions transport-type transport-km))
        (energy-emissions (calculate-energy-emissions energy-source energy-kwh))
        (total-emissions (calculate-total-emissions transport-emissions energy-emissions food-emissions waste-generated consumption-items))
    )
    
    (asserts! (get is-active user-data) ERR-USER-NOT-FOUND)
    
    ;; Record emission entry
    (map-set emission-entries
        { entry-id: entry-id }
        {
            user: tx-sender,
            category: CATEGORY-TRANSPORT, ;; Primary category
            entry-date: stacks-block-height,
            transport-km: transport-km,
            transport-type: transport-type,
            energy-kwh: energy-kwh,
            energy-source: energy-source,
            food-emissions: food-emissions,
            waste-generated: waste-generated,
            consumption-items: consumption-items,
            calculated-emissions: total-emissions,
            is-verified: false,
            verified-by: none
        }
    )
    
    ;; Update user totals
    (map-set carbon-users
        { user: tx-sender }
        (merge user-data {
            total-emissions-tracked: (+ (get total-emissions-tracked user-data) total-emissions),
            last-update-date: stacks-block-height,
            tracking-streak: (+ (get tracking-streak user-data) u1)
        })
    )
    
    (var-set next-entry-id (+ entry-id u1))
    (var-set total-emissions-tracked (+ (var-get total-emissions-tracked) total-emissions))
    
    (ok total-emissions)
    )
)

;; ===================================================
;; PUBLIC FUNCTIONS - CARBON OFFSETS
;; ===================================================

;; Register carbon offset project
(define-public (register-offset-project
    (project-name (string-ascii 100))
    (project-type (string-ascii 50))
    (location (string-ascii 100))
    (total-co2-capacity uint)
    (price-per-kg uint)
    (verification-standard (string-ascii 50))
    (project-duration uint))
    
    (let (
        (project-id (var-get next-project-id))
    )
    
    (asserts! (> total-co2-capacity u0) ERR-INVALID-AMOUNT)
    (asserts! (> price-per-kg u0) ERR-INVALID-AMOUNT)
    (asserts! (> project-duration u0) ERR-INVALID-AMOUNT)
    
    ;; Register project
    (map-set offset-projects
        { project-id: project-id }
        {
            project-name: project-name,
            project-type: project-type,
            location: location,
            operator: tx-sender,
            total-co2-capacity: total-co2-capacity,
            co2-sold: u0,
            price-per-kg: price-per-kg,
            verification-standard: verification-standard,
            project-start-date: stacks-block-height,
            project-duration: project-duration,
            is_active: true,
            additionality-verified: false
        }
    )
    
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
    )
)

;; Purchase carbon offsets
(define-public (purchase-offsets (project-id uint) (co2-amount uint))
    (let (
        (project-data (unwrap! (map-get? offset-projects { project-id: project-id }) ERR-INVALID-OFFSET))
        (user-data (unwrap! (map-get? carbon-users { user: tx-sender }) ERR-USER-NOT-FOUND))
        (purchase-id (var-get next-purchase-id))
        (co2-kg (/ co2-amount u1000))
        (total-cost (* co2-kg (get price-per-kg project-data)))
        (remaining-capacity (- (get total-co2-capacity project-data) (get co2-sold project-data)))
    )
    
    (asserts! (get is_active project-data) ERR-INVALID-OFFSET)
    (asserts! (<= co2-amount remaining-capacity) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> co2-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Transfer payment to project operator
    (try! (stx-transfer? total-cost tx-sender (get operator project-data)))
    
    ;; Record purchase
    (map-set offset-purchases
        { purchase-id: purchase-id }
        {
            buyer: tx-sender,
            project-id: project-id,
            co2-amount: co2-amount,
            purchase-price: total-cost,
            purchase-date: stacks-block-height,
            retirement-date: none,
            is-retired: false,
            certificate-hash: (keccak256 (unwrap-panic (to-consensus-buff? purchase-id)))
        }
    )
    
    ;; Update project sold amount
    (map-set offset-projects
        { project-id: project-id }
        (merge project-data {
            co2-sold: (+ (get co2-sold project-data) co2-amount)
        })
    )
    
    (var-set next-purchase-id (+ purchase-id u1))
    (var-set total-offsets-sold (+ (var-get total-offsets-sold) co2-amount))
    
    (ok purchase-id)
    )
)

;; Retire carbon offsets
(define-public (retire-offsets (purchase-id uint))
    (let (
        (purchase-data (unwrap! (map-get? offset-purchases { purchase-id: purchase-id }) ERR-INVALID-OFFSET))
    )
    
    (asserts! (is-eq tx-sender (get buyer purchase-data)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-retired purchase-data)) ERR-DUPLICATE-ENTRY)
    
    ;; Retire offsets
    (map-set offset-purchases
        { purchase-id: purchase-id }
        (merge purchase-data {
            retirement-date: (some stacks-block-height),
            is-retired: true
        })
    )
    
    (ok (get co2-amount purchase-data))
    )
)

;; ===================================================
;; PUBLIC FUNCTIONS - VERIFICATION
;; ===================================================

;; Verify emission entry
(define-public (verify-emissions (entry-id uint))
    (let (
        (entry-data (unwrap! (map-get? emission-entries { entry-id: entry-id }) ERR-INVALID-AMOUNT))
        (verifier-data (unwrap! (map-get? carbon-verifiers { verifier: tx-sender }) ERR-NOT-AUTHORIZED))
    )
    
    (asserts! (get is_active verifier-data) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-verified entry-data)) ERR-DUPLICATE-ENTRY)
    
    ;; Mark as verified
    (map-set emission-entries
        { entry-id: entry-id }
        (merge entry-data {
            is-verified: true,
            verified-by: (some tx-sender)
        })
    )
    
    ;; Reward user for verified data
    (try! (as-contract (stx-transfer? VERIFICATION-REWARD tx-sender (get user entry-data))))
    
    ;; Update verifier stats
    (map-set carbon-verifiers
        { verifier: tx-sender }
        (merge verifier-data {
            verifications-completed: (+ (get verifications-completed verifier-data) u1)
        })
    )
    
    (ok true)
    )
)

;; ===================================================
;; READ-ONLY FUNCTIONS
;; ===================================================

;; Get user carbon profile
(define-read-only (get-user-profile (user principal))
    (map-get? carbon-users { user: user })
)

;; Get emission entry
(define-read-only (get-emission-entry (entry-id uint))
    (map-get? emission-entries { entry-id: entry-id })
)

;; Get offset project
(define-read-only (get-offset-project (project-id uint))
    (map-get? offset-projects { project-id: project-id })
)

;; Calculate monthly emissions
(define-read-only (calculate-monthly-footprint (user principal) (month uint) (year uint))
    (match (map-get? carbon-users { user: user })
        user-data
            {
                baseline-emissions: (get baseline-monthly-emissions user-data),
                current-emissions: (get current-monthly-emissions user-data),
                reduction-achieved: (- (get baseline-monthly-emissions user-data) (get current-monthly-emissions user-data)),
                carbon-score: (get carbon-score user-data)
            }
        {
            baseline-emissions: u0,
            current-emissions: u0,
            reduction-achieved: u0,
            carbon-score: u1000
        }
    )
)

;; Get platform statistics
(define-read-only (get-platform-stats)
    {
        total-users: (var-get total-users),
        total-emissions-tracked: (var-get total-emissions-tracked),
        total-offset-projects: (var-get next-project-id),
        total-offsets-sold: (var-get total-offsets-sold),
        total-entries: (var-get next-entry-id)
    }
)

;; ===================================================
;; ADMIN FUNCTIONS
;; ===================================================

;; Register carbon verifier
(define-public (register-verifier
    (verifier-name (string-ascii 100))
    (certification (string-ascii 100))
    (specialization (list 5 uint)))
    
    (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (map-set carbon-verifiers
        { verifier: tx-sender }
        {
            verifier-name: verifier-name,
            certification: certification,
            verifications-completed: u0,
            accuracy-rating: u100,
            registration-date: stacks-block-height,
            is_active: true,
            specialization: specialization
        }
    )
    
    (ok true)
    )
)

;; Fund reward pool
(define-public (fund-rewards (amount uint))
    (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set reward-fund-balance (+ (var-get reward-fund-balance) amount))
    (ok (var-get reward-fund-balance))
    )
)