terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "hoosierciv"

    workspaces {
      name = "hoosierciv-dev"
    }
  }
}
