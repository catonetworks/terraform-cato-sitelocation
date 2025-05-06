# terraform-cato-bulk-sitelocation

Terraform module that takes a path to a csv file as an input, and validates each city, state (if applicable), and country against the Cato siteLocation database and provides outputs to reference dynamically to create sites in bulk. 

<details>
<summary>Example CSV file format</summary>

Create a csv file with the following format.  The first row is the header row and the remaining rows are the asset data.  The header row is used to map the column data to the asset attributes.

```csv
site_name,city,state_name,country_name
site1,Paris,,France
site2,New York City,New York,United
site3,Los Angeles,California,United States
```

</details>

## Example Bulk Import Usage

<details>
<summary>Example Variables for Bulk Import</summary>

## Example Variables for Bulk Import

```hcl
variable "csv_file_path" {
	description =  "Path to the csv file to import"
	type = string
	default = "site_locations.csv"
}

```
</details>

## Proviers and Resources for Bulk Run

```hcl

module "site_location" {
  source = "catonetworks/sitelocation/cato"
  csv_file_path = var.csv_file_path
}

output "invalid_sites" {
  value = module.site_location.invalid_sites
}

output "site_locations" {
  value = {
    for site_name, site in module.site_location.valid_sites : 
      site_name => {
        location_count = site.location_count
        is_valid       = site.is_valid
        locations      = [
          for i, location in site.locations : {
            city         = location.city
            country_code = location.country_code
            country_name = location.country_name
            state_code   = location.state_code
            state_name   = location.state_name
            timezone     = location.timezone
          }
        ]
      }
  }
}

terraform apply
terraform show
```

