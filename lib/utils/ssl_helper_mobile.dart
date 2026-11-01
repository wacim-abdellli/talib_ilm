/// Enforces strict TLS certificate validation. Global bypass disabled.
void enableBadCertificateCatcher() {
  // No-op: All connections strictly validate TLS certificates against system roots.
}
