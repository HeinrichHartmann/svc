# Terraform Infrastructure Migration Plan

## Overview
Reorganizing terraform infrastructure to separate:
- Global personal infrastructure → `~/box/infrastructure/personal/`
- Project-specific infrastructure → `~/box/infrastructure/signals/`
- Server-specific infrastructure → `/svc/infrastructure/terraform/`

## Current Structure
```
/svc/infrastructure/
├── terraform/
│   ├── main.tf                        # Provider configs
│   ├── heinrichhartmann_com.tf        # Public website
│   ├── heinrichhartmann_net.tf        # Mixed: zone + all server records
│   ├── lenas_staudengarten_de.tf      # Family domain
│   ├── checkly.tf                     # Monitoring
│   └── terraform.tfstate              # Current state
└── signals_tf/
    ├── main.tf
    └── signalsconf_io.tf              # Conference infrastructure
```

## Target Structure
```
~/box/infrastructure/
├── personal/
│   ├── main.tf                        # Provider configs
│   ├── heinrichhartmann_com.tf        # Public website
│   ├── heinrichhartmann_net.tf        # DNS zone + all server records
│   ├── lenas_staudengarten_de.tf      # Family domain
│   ├── checkly.tf                     # Monitoring
│   └── terraform.tfstate              # Moved state
└── signals/
    ├── main.tf
    ├── signalsconf_io.tf              # Conference infrastructure
    └── terraform.tfstate              # Moved state

/svc/infrastructure/
└── terraform/
    ├── main.tf                        # Minimal provider config
    ├── hhair25_records.tf             # Only this server's DNS
    └── terraform.tfstate              # New/minimal state
```

## Migration Steps

### Phase 1: Setup (Safe, No State Changes)

1. **Create target directories:**
   ```bash
   cd ~/box
   mkdir -p infrastructure/personal
   mkdir -p infrastructure/signals
   ```

2. **Initialize git tracking** (if ~/box is a git repo):
   ```bash
   cd ~/box
   git add infrastructure/
   ```

### Phase 2: Move Signals (Independent State)

3. **Move signals terraform:**
   ```bash
   # Signals has separate state, safe to move
   mv /svc/infrastructure/signals_tf/* ~/box/infrastructure/signals/

   # Test that it still works
   cd ~/box/infrastructure/signals
   terraform init
   terraform plan  # Should show no changes
   ```

### Phase 3: Split heinrichhartmann_net.tf (Requires State Surgery)

4. **Extract server-specific records:**

   Create `/svc/infrastructure/terraform/hhair25_records.tf`:
   ```hcl
   # Reference the existing Route53 zone (managed in ~/box)
   data "aws_route53_zone" "hhnet" {
     name = "heinrichhartmann.net"
   }

   # Only this server's records
   resource "aws_route53_record" "hhair25" {
     zone_id = data.aws_route53_zone.hhnet.zone_id
     name    = "hhair25.ts.heinrichhartmann.net"
     type    = "A"
     records = ["100.107.249.31"]
     ttl     = 300
   }

   resource "aws_route53_record" "hhair25_wildcard" {
     zone_id = data.aws_route53_zone.hhnet.zone_id
     name    = "*.hhair25.ts.heinrichhartmann.net"
     type    = "A"
     records = ["100.107.249.31"]
     ttl     = 300
   }
   ```

5. **Move global files to ~/box/infrastructure/personal/:**
   ```bash
   cd /svc/infrastructure/terraform
   cp main.tf ~/box/infrastructure/personal/
   cp heinrichhartmann_com.tf ~/box/infrastructure/personal/
   cp heinrichhartmann_net.tf ~/box/infrastructure/personal/
   cp lenas_staudengarten_de.tf ~/box/infrastructure/personal/
   cp checkly.tf ~/box/infrastructure/personal/
   cp terraform.tfstate ~/box/infrastructure/personal/
   cp terraform.tfstate.backup ~/box/infrastructure/personal/
   ```

6. **Remove moved records from state in /svc:**
   ```bash
   cd /svc/infrastructure/terraform

   # Import the zone as data source (read-only reference)
   terraform init

   # Remove all resources except hhair25 records
   # This is complex - better to start fresh
   ```

### Phase 4: Clean Separation (Recommended Approach)

**ALTERNATIVE SAFER APPROACH:**

Instead of state surgery, use a clean separation:

1. **Move everything to ~/box/infrastructure/personal/ first:**
   ```bash
   mv /svc/infrastructure/terraform/* ~/box/infrastructure/personal/
   ```

2. **In ~/box/infrastructure/personal/:**
   - Keep all current files
   - Remove hhair25-specific records from heinrichhartmann_net.tf
   - `terraform plan` to verify
   - `terraform apply` to update

3. **In /svc/infrastructure/terraform/:**
   - Create fresh main.tf with minimal AWS provider
   - Create hhair25_records.tf with data source + records
   - `terraform init`
   - `terraform import` the hhair25 records (or just apply to create)

## Validation

After migration:

1. **Test ~/box/infrastructure/personal/:**
   ```bash
   cd ~/box/infrastructure/personal
   terraform plan  # Should show removal of hhair25 records only
   ```

2. **Test ~/box/infrastructure/signals/:**
   ```bash
   cd ~/box/infrastructure/signals
   terraform plan  # Should show no changes
   ```

3. **Test /svc/infrastructure/terraform/:**
   ```bash
   cd /svc/infrastructure/terraform
   terraform plan  # Should show creation of hhair25 records
   ```

## Rollback

If anything goes wrong:
```bash
# Restore from backup
cp ~/box/infrastructure/personal/terraform.tfstate.backup \
   /svc/infrastructure/terraform/terraform.tfstate
```

## Notes

- **State files contain sensitive data** - ensure ~/box is encrypted with git-crypt
- **Terraform state is fragile** - always backup before modifications
- **DNS changes are quick** - TTL is 300s, so errors are recoverable
- **Test with `terraform plan` extensively** before any `apply`
