locals {
    site_locations_csv = csvdecode(file("${var.csv_file_path}"))
}

data "cato_siteLocation" "site_locations" {
  for_each = { for site in local.site_locations_csv : site.site_name => site }
  filters = flatten([
    [
      {
        field     = "city"
        search    = each.value.city
        operation = "exact"
      }
    ],
    each.value.state_name != "" ? [
      {
        field     = "state_name"
        search    = each.value.state_name
        operation = "exact"
      }
    ] : [],
    [
      {
        field     = "country_name"
        search    = each.value.country_name
        operation = "exact"
      }
    ]
  ])
}

locals {
  validation_results = {
    for site_name, data in data.cato_siteLocation.site_locations :
    site_name => {
      location_count = length(data.locations)
      is_valid       = length(data.locations) > 0
      message        = length(data.locations) > 0 ? "Valid: Found ${length(data.locations)} locations" : "Invalid: No locations found"
      locations      = data.locations
    }
  }

  # List of invalid sites for error reporting
  invalid_sites = [
    for site_name, result in local.validation_results :
    site_name if !result.is_valid
  ]
}

# ## Optional: Use null_resource to fail the plan if any site has no locations
resource "null_resource" "validation_check" {
  count = length(local.invalid_sites) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Validation failed for sites: ${join(", ", local.invalid_sites)}'; exit 1"
  }
}

# Output the validation results
output "valid_sites" {
  value = local.validation_results
}

# Output a summary of invalid sites
output "invalid_sites" {
  value = local.invalid_sites
}