# Cellular Optimizer MAX

A native iOS networking optimizer/diagnostic project for stock iOS.

## What it actually optimizes
Stock iOS does not expose APIs for changing modem bands, carrier provisioning, APN internals, baseband parameters, RSRP/SINR/PCI, or radio firmware settings. This project therefore focuses on the parts a signed app can legitimately improve:

- path awareness with NWPathMonitor
- repeated latency/jitter measurements
- throughput sampling
- packet-loss estimation from repeated probes
- URLSession task metrics
- IPv4/IPv6 comparison
- DNS protocol observation
- configurable encrypted DNS through NetworkExtension
- rolling baseline and anomaly detection
- conservative automatic DNS action only when measurements justify it
- no permanent configuration change without user approval

## Build / install
Create a SwiftUI iOS app in Xcode (iOS 17+) and replace the generated Swift files with Sources/*.swift.

For the DNS feature add the Network Extension capability and enable the DNS Settings entitlement if your Apple Developer profile permits it.

This source cannot itself produce an installable IPA. Apple code signing is required.

## Architecture
ProbeEngine -> NetworkMonitor -> OptimizerEngine -> DNSController -> SwiftUI dashboard.

The app intentionally does not use private APIs or jailbreak-only APIs.
