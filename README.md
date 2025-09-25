# CarbonTrack - Personal Carbon Footprint Tracking

A blockchain-based carbon footprint monitoring system with rewards for emission reductions and carbon offset verification.
Addresses **UN SDG 13: Climate Action** through personal accountability.

---

## Features

* **User Registration**: Create a personal carbon profile with baseline emissions.
* **Emission Tracking**: Record daily transport, energy, food, waste, and consumption emissions.
* **Carbon Scoring**: Dynamic scoring system based on monthly improvements vs. baseline.
* **Carbon Offsets**: Register, purchase, and retire carbon offset projects with STX payments.
* **Verification**: Trusted verifiers validate emission entries and offset projects.
* **Rewards**: Incentives for emission reductions, verified data, and offset purchases.
* **Reports**: Generate monthly footprint reports with breakdowns and improvement scores.
* **Community Challenges**: Engage in group reduction challenges with shared rewards.

---

## Smart Contract Structure

### Constants

* Error codes for validation and permissions.
* Predefined carbon categories (transport, energy, food, waste, consumption).
* Emission factors (grams CO₂ per unit).
* Reward system parameters (tokens per kg reduced, verification reward, offset rate).
* Time constants (blocks per day, week, month).

### Data Maps

* `carbon-users`: Registered users with profiles, scores, and totals.
* `emission-entries`: Daily activity logs and calculated CO₂ emissions.
* `offset-projects`: Registered carbon offset projects.
* `offset-purchases`: Purchases and retirements of carbon offsets.
* `monthly-reports`: Monthly carbon footprint summaries.
* `carbon-verifiers`: Approved emission and offset verifiers.
* `carbon-challenges`: Community emission reduction challenges.

### Data Vars

* Sequential IDs for entries, projects, purchases, reports, challenges.
* Platform-wide totals (users, emissions tracked, offsets sold, reward balance).

### Functions

#### User Functions

* `register-user`: Create a carbon tracker profile.
* `record-emissions`: Submit daily emissions and auto-calculate totals.
* `calculate-monthly-footprint`: Get monthly emission vs. baseline data.

#### Offset Functions

* `register-offset-project`: Add a carbon offset project to the system.
* `purchase-offsets`: Buy verified carbon offsets.
* `retire-offsets`: Retire purchased offsets and generate certificates.

#### Verification

* `verify-emissions`: Validate user entries and reward verified contributions.
* `register-verifier`: Add a new verifier (admin only).

#### Platform Stats

* `get-user-profile`: View user carbon profile.
* `get-emission-entry`: Retrieve emission entry details.
* `get-offset-project`: Retrieve project details.
* `get-platform-stats`: Aggregate platform-wide data.

#### Admin

* `fund-rewards`: Deposit funds into reward pool for incentives.

---

## Rewards System

* **Reduction Rewards**: Earn tokens for lowering monthly emissions vs. baseline.
* **Verification Rewards**: STX payments for verified emission entries.
* **Offset Incentives**: Tokenized recognition for verified carbon offset purchases.

---

## Use Cases

* Individuals track daily emissions and receive rewards for reducing them.
* Carbon offset project operators sell verified offsets.
* Verifiers validate data integrity and earn rewards.
* Communities engage in collective emission reduction challenges.

---

## Technical Details

* Built on the **Stacks blockchain**.
* Uses STX transfers for economic incentives.
* Stores user activity, offsets, and verifications on-chain for transparency.
* Carbon certificates secured with SHA-3 (Keccak256) hashing.

---

## License

MIT License.

---

## Author

CarbonTrack Smart Contract — Designed for blockchain-enabled climate action.
