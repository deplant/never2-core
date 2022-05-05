# NEVER Phase II - Auctions

## Contest Submission 

This submission is a set of contracts for NEVER Phase 2 contest. 
It contains implementations both for TIP3 and CurrencyCollection implementations.

Submission is based on Stablecoin Design by Mitja Goroshevsky and Andrey Lyashin: 
(https://mitja.gitbook.io/papers/v/ever-and-never-binary-system/) and 
Phase I Contest work by Pruvendo - (https://github.com/Pruvendo/not_oracle).

## Contents

* **Bank**(AuctionManager) contract (Bid-implementation-agnostic)
* **Auction** contract (Bid-implementation-agnostic)
* **Bid** contract with 3 implementations
* **DAuction** contract with 3 implementations
* **EVER Reserve** contract

[Submission](NEVER Phase II Auctions Submission.pdf) describes flows of Auction, Election cycles and DAuction trading.

## DevNet

**Bank Address:** 
`0:a9bac404ec0c47e14260c74fbfd2bdbf120de46f49de78b3439e82665cada0c8`

## Run tests (Ubuntu)

## Prererequisites
- Java 17
- Git

## JDK

```wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz
tar xvf openjdk-17.0.2_linux-x64_bin.tar.gz     
export JAVA_HOME=<path>/jdk-17.0.2
```

## Git 
```
cd ~
git clone https://github.com/deplant/never2-core.git
cd never2-core
```

## Run tests
```
gradlew test --tests "tst.AuctionsTest.fullTest"
```