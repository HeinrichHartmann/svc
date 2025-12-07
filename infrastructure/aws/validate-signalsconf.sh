#!/usr/bin/env bash
#
# Black-box validation script for signalsconf.io
# Tests DNS, HTTPS certificates, and website accessibility
#

set -euo pipefail

DOMAIN="signalsconf.io"
WWW_DOMAIN="www.signalsconf.io"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

info() {
    echo -e "ℹ $1"
}

section() {
    echo ""
    echo "========================================="
    echo "$1"
    echo "========================================="
}

# DNS resolution tests
check_dns() {
    local domain=$1
    local dns_server=$2
    local dns_name=$3

    if dig @"$dns_server" "$domain" A +short | grep -q '^[0-9]'; then
        local ip=$(dig @"$dns_server" "$domain" A +short | head -1)
        pass "DNS resolves via $dns_name: $domain -> $ip"
        return 0
    else
        fail "DNS does not resolve via $dns_name: $domain"
        return 1
    fi
}

# Certificate validity check
check_certificate() {
    local domain=$1

    info "Checking SSL certificate for $domain..."

    # Get certificate info
    local cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null || true)

    if [ -z "$cert_info" ]; then
        fail "Could not retrieve SSL certificate for $domain"
        return 1
    fi

    # Extract expiry date
    local expiry=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local days_until_expiry=$(( (expiry_epoch - now_epoch) / 86400 ))

    if [ "$days_until_expiry" -gt 7 ]; then
        pass "Certificate valid for $days_until_expiry more days (expires: $expiry)"
    elif [ "$days_until_expiry" -gt 0 ]; then
        warn "Certificate expires soon: $days_until_expiry days (expires: $expiry)"
        ((TESTS_PASSED++))
    else
        fail "Certificate has expired or is invalid"
        return 1
    fi

    # Check certificate subject
    local subject=$(echo "$cert_info" | grep "subject" | cut -d= -f2-)
    info "Certificate subject: $subject"

    return 0
}

# HTTP/HTTPS accessibility check
check_http_access() {
    local url=$1
    local description=$2

    info "Testing HTTP access: $url"

    # Check if curl succeeds
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$url" 2>/dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
        pass "$description returns HTTP $http_code"
        return 0
    elif [ "$http_code" = "000" ]; then
        fail "$description - connection failed"
        return 1
    else
        fail "$description returns HTTP $http_code (expected 200)"
        return 1
    fi
}

# Check HTTPS redirect
check_https_redirect() {
    local domain=$1

    info "Checking HTTP to HTTPS redirect for $domain..."

    local location=$(curl -s -I -L --max-redirects 0 "http://$domain" 2>/dev/null | grep -i "^location:" | awk '{print $2}' | tr -d '\r')

    if [[ "$location" == https://* ]]; then
        pass "HTTP redirects to HTTPS: $location"
        return 0
    else
        warn "HTTP does not redirect to HTTPS (got: $location)"
        ((TESTS_PASSED++))
        return 0
    fi
}

# Content validation
check_content() {
    local url=$1

    info "Checking content at $url..."

    local content=$(curl -s -L --max-time 10 "$url" 2>/dev/null || true)

    if echo "$content" | grep -q "signalsconf.io"; then
        pass "Content contains expected domain name"
        return 0
    else
        warn "Content may not be correct (domain name not found)"
        ((TESTS_PASSED++))
        return 0
    fi
}

# Main test execution
main() {
    echo "================================================"
    echo "Validation Test Suite for $DOMAIN"
    echo "================================================"
    echo "Date: $(date)"
    echo ""

    # DNS Resolution Tests
    section "DNS Resolution Tests"

    # Test against multiple DNS servers
    check_dns "$DOMAIN" "8.8.8.8" "Google DNS (8.8.8.8)"
    check_dns "$DOMAIN" "1.1.1.1" "Cloudflare DNS (1.1.1.1)"
    check_dns "$DOMAIN" "208.67.222.222" "OpenDNS (208.67.222.222)"

    # Check www subdomain
    check_dns "$WWW_DOMAIN" "8.8.8.8" "Google DNS (8.8.8.8)"

    # Get AWS Route53 nameservers for the domain
    info "Looking up authoritative nameservers..."
    local nameservers=$(dig NS "$DOMAIN" +short | head -1)
    if [ -n "$nameservers" ]; then
        info "Authoritative nameserver: $nameservers"
        check_dns "$DOMAIN" "$nameservers" "Authoritative NS"
    fi

    # SSL Certificate Tests
    section "SSL Certificate Tests"

    # Wait a moment for DNS to settle
    sleep 2

    check_certificate "$DOMAIN"
    check_certificate "$WWW_DOMAIN"

    # HTTP/HTTPS Access Tests
    section "HTTP/HTTPS Access Tests"

    check_https_redirect "$DOMAIN"
    check_http_access "https://$DOMAIN" "HTTPS access to $DOMAIN"
    check_http_access "https://$WWW_DOMAIN" "HTTPS access to $WWW_DOMAIN"

    # Content validation
    section "Content Validation"

    check_content "https://$DOMAIN"

    # Summary
    section "Test Summary"

    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
